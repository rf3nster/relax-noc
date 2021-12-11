---------------------------------------------------------------------------
-- Component:
--    Router Receiver Write FSM
-- Purpose:
--    Controls writing data from router Crossbar to crossbar
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

entity rx_writefsm is
	port (
		-- System control
		clk : in    std_logic;
		rst : in    std_logic;

		-- FIFO status signals
		fifo_full : in    std_logic; 

		-- FIFO Control signals
		fifo_writeen : out   std_logic;

		-- Channel signaling
		rx_channelvalid : in    std_logic;
		rx_cleartosend  : out   std_logic
	);
end entity rx_writefsm;

architecture rx_writefsm_impl of rx_writefsm is
	
	-- Define receiver write state

	type fsm_state_t is (rxWriteState_IDLE, rxWriteState_EN);

	-- Instantiate FSM State Signals	
	signal fsm_state      : fsm_state_t; 
	signal fsm_state_next : fsm_state_t;  

begin

	-- State transition process
	state_transition_proc : process (clk, rst) is
	begin  

		if (rst = '1') then
			fsm_state <= rxWriteState_IDLE;
		elsif (rising_edge(clk)) then
			fsm_state <= fsm_state_next;
		end if;
	
	end process state_transition_proc;

	state_comb_proc : process (fifo_full, rx_channelvalid, fsm_state) is
	begin

		-- Case for FIFO Write State
		case fsm_state is
	
			-- Write and idle state
			when rxWriteState_EN | rxWriteState_IDLE =>
	
				if (fifo_full = '0' and rx_channelvalid = '1') then
					fsm_state_next <= rxWriteState_EN;
					fifo_writeen   <= '1';
				else
					fsm_state_next <= rxWriteState_IDLE;
					fifo_writeen   <= '0';
				end if; 
					
			-- Idle/Others        
			when others =>

				if (fifo_full = '0' and rx_channelvalid = '1') then
					fsm_state_next <= rxWriteState_EN;
					fifo_writeen   <= '1';
				else
					fsm_state_next <= rxWriteState_IDLE;
					fifo_writeen   <= '0';
				end if; 

		end case;

	end process state_comb_proc;

	-- Concurrent signal assignment
	rx_cleartosend <= not(fifo_full);

end architecture rx_writefsm_impl;