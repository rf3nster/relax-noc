---------------------------------------------------------------------------
-- Component:
--    Processing Element Injection Port FSM
-- Purpose:
--    Finite State Machine to handle injection of data into network.
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

library work;
	use work.noc_parameterspkg.all;

entity pe_injectionfsm is
	port (
		-- System control
		clk : in    std_logic;
		rst : in    std_logic;
		
		-- Crossbar side
		datarqst      : in    std_logic;
		rx_select     : in    std_logic;
		dataavailable : out   std_logic;

		-- FIFO Side
		fifo_empty     : in    std_logic;
		fifo_full      : in    std_logic;
		fifo_writerqst : in    std_logic;
		fifo_popen     : out   std_logic;
		fifo_writeen   : out   std_logic
	);
end entity pe_injectionfsm;

architecture pe_injectionfsm_impl of pe_injectionfsm is

	-- Define injection driver channel transmit and fifo write states

	type fifo_state_t is (fifoState_IDLE, fifoState_WRITE);

	type channel_state_t is (channelState_IDLE, channelState_TRANSMIT);

	-- Instantiate FSM State Signals
	signal fifo_state         : fifo_state_t;
	signal fifo_state_next    : fifo_state_t;
	signal channel_state      : channel_state_t;
	signal channel_state_next : channel_state_t;

	-- Internal FIFO control signals
	signal fifo_writeen_i : std_logic;
	signal fifopopen_i    : std_logic;

begin

	state_change_proc : process (clk, rst) is
	begin
	
		if (rst = '1') then
			channel_state <= channelState_IDLE;
		elsif (rising_edge(clk)) then 
			channel_state <= channel_state_next;
			fifo_state    <= fifo_state_next;
		end if;
	
	end process state_change_proc;

	fifo_proc : process (fifo_state, fifo_full, fifo_writerqst) is 
	begin
	
		case fifo_state is
	
			when others =>
	
				if (fifo_full = '0' and fifo_writerqst = '1') then
					fifo_writeen_i  <= '1';
					fifo_state_next <= fifoState_WRITE;
				else
					fifo_writeen_i  <= '0';
					fifo_state_next <= fifoState_IDLE;
				end if;
		
		end case; 
		
	end process fifo_proc;
		
	transmission_proc : process (channel_state, fifo_empty, datarqst, rx_select) is
	begin
	
		case channel_state is
	
			when others =>
	
				if (fifo_empty = '0' and datarqst = '1' and rx_select = '1') then
					channel_state_next <= channelState_TRANSMIT;
					fifopopen_i        <= '1';
				else
					channel_state_next <= channelState_IDLE;
					fifopopen_i        <= '0';
				end if;
			
		end case;
		
	end process transmission_proc; 

	-- Cast external signals
	fifo_popen    <= fifopopen_i;
	fifo_writeen  <= fifo_writeen_i;
	dataavailable <= not(fifo_empty);

end architecture pe_injectionfsm_impl;