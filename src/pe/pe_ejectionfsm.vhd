---------------------------------------------------------------------------
-- Component: 
--    Ejection Port FSM Driver
-- Purpose:
--    Drives Ejection port and writes out results of packets in .CSV
--
-- Requires: VHDL-2008, NON-SYNTHESIZABLE
-- 
-- Written on April 22/2021
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

entity pe_ejectionfsm is
	port (
		-- System control
		clk : in    std_logic;
		rst : in    std_logic;
			
		-- FIFO control signals
		fifo_popen   : out   std_logic;
		fifo_writeen : out   std_logic;
														
		-- FIFO State
		fifo_full  : in    std_logic;
		fifo_empty : in    std_logic;
			
		-- Request and status signals
		datavalid : out   std_logic;
		popsrc    : out   std_logic;
		writerqst : in    std_logic;
		datarqst  : in    std_logic
	);
end entity pe_ejectionfsm;

architecture pe_ejectionfsm_impl of pe_ejectionfsm is

	-- Define ejection driver pop and write states
	
	type fsm_pop_state_t is (popState_IDLE, popState_ACTIVE);
	
	type fsm_write_state_t is (writeState_IDLE, writeState_ACTIVE);
	
	-- Instantiate FSM State Signals	
	signal fsm_pop_state        : fsm_pop_state_t;
	signal fsm_pop_state_next   : fsm_pop_state_t; 
	signal fsm_write_state      : fsm_write_state_t;
	signal fsm_write_state_next : fsm_write_state_t; 

begin

	-- State transition process
	state_transition_proc : process (clk, rst) is
	begin  

		if (rst = '1') then
			fsm_pop_state   <= popState_IDLE;
			fsm_write_state <= writeState_IDLE;
		elsif (rising_edge(clk)) then
			fsm_pop_state   <= fsm_pop_state_next;
			fsm_write_state <= fsm_write_state_next;                    
		end if;

	end process state_transition_proc;

	-- Write process for obtaining data from crossbar
	write_proc : process (fifo_full, writerqst, fsm_write_state) is 
	begin

		case fsm_write_state is

			when others =>

				if (fifo_full = '0' and writerqst = '1') then
					fifo_writeen         <= '1';
					popsrc               <= '1';
					fsm_write_state_next <= writeState_ACTIVE;
				else
					fifo_writeen         <= '0';
					fsm_write_state_next <= writeState_IDLE;
					popsrc               <= '0';
				end if;
	
		end case;
	
	end process write_proc;

	-- Process to pop data to processing element
	pop_proc : process (fifo_empty, datarqst, fsm_pop_state) is 
	begin
	
		case fsm_pop_state is
	
			when others =>
	
				if (fifo_empty = '0' and datarqst = '1') then
					fifo_popen         <= '1';
					datavalid          <= '1';
					fsm_pop_state_next <= popState_ACTIVE;
				else
					fifo_popen         <= '0';
					datavalid          <= '0';
					fsm_pop_state_next <= popState_IDLE;
				end if;
		
		end case;
	
	end process pop_proc;  

end architecture pe_ejectionfsm_impl;