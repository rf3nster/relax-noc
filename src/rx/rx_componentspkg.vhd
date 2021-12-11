---------------------------------------------------------------------------
-- Component:
--    Router Receiver Component Declaration Package
-- Purpose:
--    Provides all component declarations for router receiver components.
--      
-- Requires: VHDL-2008
-- 
-- Written on Jan 30/2021, Updated last on April 24/2021
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
	use work.noc_parameterspkg.all;

package rx_componentspkg is

	component rx_writefsm is
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
	end component rx_writefsm;

	component rx_readfsm is
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
	end component rx_readfsm;

	component rx_top is
		generic (
			addresswidth : integer := addr_data_size;
			fifowidth    : integer := channel_data_size;     
			fifodepth    : integer := fifo_depth
		);
		port (
			-- System control
			clk         : in    std_logic;
			rst         : in    std_logic; 
			networkmode : in    std_logic;

			-- RX packet defines
			rx_packet_in  : in    packet_t;
			rx_packet_out : out   packet_t;

			-- RX side signaling
			rx_cleartosend  : out   cleartosend_t;
			rx_channelvalid : in    channelvalid_t;

			-- Crossbar side channel A signaling
			channela_dataavailable : out   std_logic;
			channela_poprqst       : in    std_logic;
			rx_channela_select     : in    std_logic;

			-- Crossbar side channel B signaling
			channelb_dataavailable : out   std_logic;
			channelb_poprqst       : in    std_logic;
			rx_channelb_select     : in    std_logic
		);
	end component;

end package rx_componentspkg;