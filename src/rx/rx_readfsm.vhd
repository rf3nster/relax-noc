---------------------------------------------------------------------------
-- Component:
--    Router Receiver Read FSM
-- Purpose:
--    Finite State Machine for receiver to control inbound flow of data 
--    on a single channel to crossbar.
--      
-- Requires: VHDL-2008
-- 
-- Written on Jan 26/2021, Updated on March 17/2021
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

entity rx_readfsm is
	port (
		-- System control
		clk : in    std_logic;
		rst : in    std_logic;

		-- FIFO status signals
		fifo_empty : in    std_logic; 

		-- FIFO control signals
		fifo_popen   : out   std_logic;       
		fifo_poprqst : in    std_logic;
		rx_select    : in    std_logic;
		dataavailable : out   std_logic
	);
end entity rx_readfsm;

architecture rx_readfsm_impl of rx_readfsm is
	
	-- Define receiver pop state

	type fsm_state_t is (rxPopState_IDLE, rxPopState_ACTIVE);

	-- Instantiate FSM State Signals	
	signal fsm_state      : fsm_state_t;
	signal fsm_state_next : fsm_state_t;  

begin

	-- State transition process
	state_transition_proc : process (clk, rst) is 
	begin  

		if (rst = '1') then
			fsm_state <= rxPopState_IDLE;
		elsif (rising_edge(clk)) then
			fsm_state <= fsm_state_next;
		end if;
	
	end process state_transition_proc;

	state_comb_proc : process (fifo_empty, fsm_state, fifo_popRqst, rx_select) is
	begin
	
		-- By default, go back to idle states
		fsm_state_next <= rxPopState_IDLE;
		fifo_popEn     <= '0';

		-- Case for FIFO Write State
		case fsm_state is
	
			when rxPopState_IDLE =>

				-- When in accurate only mode and data is present
				if (fifo_empty = '0' and fifo_popRqst = '1' and rx_select = '1') then
					fifo_popEn     <= '1';                                                                     
					fsm_state_next <= rxPopState_ACTIVE;                   
				-- Fall back to idle
				else
					fifo_popEn     <= '0';                        
					fsm_state_next <= rxPopState_IDLE;    
				end if;
		
			when rxPopState_ACTIVE =>
		
				-- When in accurate only mode and data is present
				if (fifo_empty = '0' and fifo_popRqst = '1' and rx_select = '1') then
					fifo_popEn     <= '1';                         
					fsm_state_next <= rxPopState_ACTIVE;
				else                
					fifo_popEn     <= '0';                        
					fsm_state_next <= rxPopState_IDLE;    
				end if;                    
			
			when others =>
				fifo_popEn     <= '0';
				fsm_state_next <= rxPopState_IDLE; 
			
		end case;
	
	end process state_comb_proc;

	-- Add concurrent signal assignments
	dataavailable <= NOT(fifo_empty);

end architecture rx_readfsm_impl;