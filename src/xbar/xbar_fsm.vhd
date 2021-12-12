---------------------------------------------------------------------------
-- Component:
--    Router Crossbar Finite State Machine Selector
-- Purpose:
--    Chooses the current receiver to pass data from. Operates in a round 
--    robin manner. Has the ability to provide two clock cycles for 
--    passing data if operating in mixed mode. 

--    Selection order: North -> South -> West -> East -> PE
--      
-- Requires: VHDL-2008
-- 
-- Copyright 2021 Rick Fenster
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
---------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library work;
	use work.noc_parametersPkg.all;
	use work.xbar_componentspkg.all;

entity xbar_fsm is
	port (
		-- System control
		clk            : in    std_logic;
		rst            : in    std_logic;
		secondcycle_en : in    std_logic;
		enable         : in    std_logic;

		-- Data signaling
		dataavailable : in    xbar_dataavailable_t;
		fifoselect    : out   unsigned (2 downto 0)
	);
end entity xbar_fsm;

architecture xbar_fsm_impl of xbar_fsm is

	-- Define crossbar selector state

	type xbar_state_t is (xbar_IDLE, xbar_NORTH, xbar_SOUTH, xbar_EAST, xbar_WEST, xbar_PE);

	-- Instantiate FSM State Signals	
	signal xbar_state      : xbar_state_t;
	signal xbar_state_next : xbar_state_t;

	-- Additional cycle control signals
	signal secondcycle      : std_logic;
	signal secondcycle_next : std_logic;

begin

	clock_proc : process (enable, rst, clk) is
	begin

		if (enable = '0' or rst = '1') then
			xbar_state  <= xbar_IDLE;
			secondcycle <= '0';
		elsif (rising_edge(clk)) then
			xbar_state  <= xbar_state_next;
			secondcycle <= secondcycle_next;
		end if;
			
	end process clock_proc;

	state_proc : process (xbar_state, enable, secondcycle, secondcycle_en, dataavailable) is
	begin

		case xbar_state is
					
			when xbar_NORTH =>
			
				if (enable = '0') then
					xbar_state_next  <= xbar_IDLE;
					secondcycle_next <= '0';
				elsif (secondcycle_en = '1' and secondcycle = '0' and dataavailable.North = '1') then
					xbar_state_next  <= xbar_NORTH;
					secondcycle_next <= '1';
				else
					xbar_state_next  <= xbar_SOUTH;
					secondcycle_next <= '0';
				end if;   
	 
				fifoselect <= "001";

			when xbar_SOUTH =>
		
				if (enable = '0') then
					xbar_state_next  <= xbar_IDLE;
					secondcycle_next <= '0';
				elsif (secondcycle_en = '1' and secondcycle = '0' and dataavailable.South = '1') then
					xbar_state_next  <= xbar_SOUTH;
					secondcycle_next <= '1';
				else
					xbar_state_next  <= xbar_WEST;
					secondcycle_next <= '0';
				end if;    

				fifoselect <= "010";
			
			when xbar_WEST =>
			
				if (enable = '0') then
					xbar_state_next  <= xbar_IDLE;
					secondcycle_next <= '0';
				elsif (secondcycle_en = '1' and secondcycle = '0' and dataavailable.West = '1') then
					xbar_state_next  <= xbar_WEST;
					secondcycle_next <= '1';
				else
					xbar_state_next  <= xbar_EAST;
					secondcycle_next <= '0';
				end if;

				fifoselect <= "011"; 
			
			when xbar_EAST =>
				
				if (enable = '0') then
					xbar_state_next  <= xbar_IDLE;
					secondcycle_next <= '0';
				elsif (secondcycle_en = '1' and secondcycle = '0' and dataavailable.East = '1') then
					xbar_state_next  <= xbar_EAST;
					secondcycle_next <= '1';
				else
					xbar_state_next  <= xbar_PE;
					secondcycle_next <= '0';
				end if;

				fifoselect <= "100";
				
			when xbar_PE =>
				
				if (enable = '0') then
					xbar_state_next  <= xbar_IDLE;
					secondcycle_next <= '0';
				elsif (secondcycle_en = '1' and secondcycle = '0' and dataavailable.PE = '1') then
					xbar_state_next  <= xbar_PE;
					secondcycle_next <= '1';
				else
					xbar_state_next  <= xbar_NORTH;
					secondcycle_next <= '0';
				end if;

				fifoselect <= "101";                                                                                 
					
			-- Idle
			when others =>

				if (enable = '0') then
					xbar_state_next  <= xbar_IDLE;
					secondcycle_next <= '0';
				else
					xbar_state_next <= xbar_NORTH;
				end if;

				fifoselect <= "000";
				
		end case;

	end process state_proc;

end architecture xbar_fsm_impl;