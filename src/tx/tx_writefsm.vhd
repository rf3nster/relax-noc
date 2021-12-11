---------------------------------------------------------------------------
-- Component:
--    Router Transmitter Write FSM
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

entity tx_writefsm is
	port (
		-- System control
		clk : in    std_logic;
		rst : in    std_logic;
	
		-- FIFO status signals
		fifo_full : in    std_logic;

		-- TX Select/Control
		tx_select  : in    std_logic;
		rx_poprqst : out   std_logic;

		-- FIFO Control signals
		fifo_writeen     : out   std_logic;
		rx_dataavailable : in    std_logic
	);
end entity tx_writefsm;

architecture tx_writefsm_impl of tx_writefsm is

	-- Define transmitter write state

	type fsm_state_t is (txWriteState_IDLE, txWriteState_EN);

	signal fsm_state      : fsm_state_t; 
	signal fsm_state_next : fsm_state_t; 

begin

	state_transition_proc : process (clk, rst) is
	begin

		if (rst = '1') then
			fsm_state <= txWriteState_IDLE;
		elsif (rising_edge(clk)) then
			fsm_state <= fsm_state_next;
		end if;

	end process state_transition_proc;

	state_comb_proc : process (fsm_state, fifo_full, tx_select, rx_dataavailable) is
	begin
	
		case fsm_state is
	
			when others =>

				if (fifo_full = '0' and tx_select = '1' and rx_dataavailable = '1') then
					fifo_writeen   <= '1';
					rx_poprqst     <= '1';
					fsm_state_next <= txWriteState_EN;
				else
					fifo_writeen   <= '0';
					rx_poprqst     <= '0';                        
					fsm_state_next <= txWriteState_IDLE;
				end if;

		end case;
	
	end process state_comb_proc;
	   
end architecture tx_writefsm_impl;