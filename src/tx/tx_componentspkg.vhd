---------------------------------------------------------------------------
-- Package:
--    Router Transmitter Component Declaration Package
-- Purpose:
--    Provides all component declarations for router transmitter components.
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

package tx_componentspkg is

	component tx_writefsm is
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
	end component;

	component tx_readfsm is
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
	end component;    

	component tx_top is 
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

			-- TX Packet defines
			tx_packet_in  : in    packet_t;
			tx_packet_out : out   packet_t;

			-- TX side signaling
			tx_cleartosend  : in    clearToSend_t;
			tx_channelvalid : out   channelValid_t;

			-- Crossbar side channel A signaling
			channela_dataavailable : in    std_logic;
			channela_txselect      : in    std_logic;
			channela_poprqst       : out   std_logic;

			-- Crossbar side channel B signaling
			channelb_dataavailable : in    std_logic;
			channelb_txselect      : in    std_logic;
			channelb_poprqst       : out   std_logic             
		);
	end component;
	
end package tx_componentspkg;