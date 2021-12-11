---------------------------------------------------------------------------
-- Component:
--    Router Transmitter Read FSM
-- Purpose:
--    Controls reading data from router receiver to crossbar
--      
-- Requires: VHDL-2008
-- 
-- Written on December 24/2021, Updated last on April 24/2021
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

entity tx_readfsm is
	port (
		-- System control
		clk : in    std_logic;
		rst : in    std_logic;
			
		-- FIFO status signals
		fifo_empty : in    std_logic;

		-- FIFO Control signals
		fifo_popen : out   std_logic;

		-- Channel signaling
		tx_cleartosend  : in    std_logic;
		tx_channelvalid : out   std_logic
	);
end entity tx_readfsm;

architecture tx_readfsm_impl of tx_readfsm is
	
	-- Define receiver pop state

	type fsm_state_t is (txPopState_IDLE, txPopState_ACTIVE);

	-- Instantiate FSM State Signals
	signal fsm_state      : fsm_state_t;  
	signal fsm_state_next : fsm_state_t;  

begin
	
	state_transition_proc : process (clk, rst) is
	begin

		if (rst ='1') then
			fsm_state <= txPopState_IDLE;
		elsif (rising_edge (clk)) then
			fsm_state <= fsm_state_next;
		end if;

	end process state_transition_proc;

	state_comb_proc : process (fsm_state, fifo_empty, tx_clearToSend) is 
	begin
	
		case fsm_state is
	
			when others =>
		
				if (fifo_empty = '0' and tx_cleartosend = '1') then
					fifo_popen      <= '1';
					tx_channelvalid <= '1';
					fsm_state_next  <= txPopState_ACTIVE;
				else
					fifo_popen      <= '0';
					tx_channelvalid <= '0';
					fsm_state_next  <= txPopState_IDLE;
				end if;
			
		end case;
	
	end process state_comb_proc;                            

end architecture tx_readfsm_impl;
