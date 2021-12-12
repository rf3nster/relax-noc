---------------------------------------------------------------------------
-- Package:
--    Router Components Package
-- Purpose:
--    Provides all component declarations for router top levels.
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
	use work.noc_parameterspkg.all;

package router_componentspkg is

	component router_top is
		generic (
			router_loc_x : integer range 0 to x_size := 0;
			router_loc_y : integer range 0 to y_size := 0
		);
		port (
			-- System control
			clk         : in    std_logic;
			rst         : in    std_logic;
			networkmode : in    std_logic;

			-------------
			-- RX Side --
			-------------
			-- North
			rx_north_packet       : in    packet_t;
			rx_north_channelvalid : in    channelvalid_t;
			rx_north_cleartosend  : out   cleartosend_t;
			-- South
			rx_south_packet       : in    packet_t;
			rx_south_channelvalid : in    channelvalid_t;
			rx_south_cleartosend  : out   cleartosend_t;
			-- West
			rx_west_packet       : in    packet_t;
			rx_west_channelvalid : in    channelvalid_t;
			rx_west_cleartosend  : out   cleartosend_t;
			-- East
			rx_east_packet       : in    packet_t;
			rx_east_channelvalid : in    channelvalid_t;
			rx_east_cleartosend  : out   cleartosend_t;
			-- PE Injection
			rx_pe_packet                 : in    packet_t;
			rx_pe_channela_dataavailable : in    std_logic;
			rx_pe_channelb_dataavailable : in    std_logic;
			rx_pe_channela_poprqst       : out   std_logic;
			rx_pe_channelb_poprqst       : out   std_logic;
			rx_pe_channela_select        : out   std_logic;
			rx_pe_channelb_select        : out   std_logic;
	
			-------------
			-- TX Side --
			-------------
			-- North
			tx_north_cleartosend  : in    cleartosend_t;
			tx_north_packet       : out   packet_t;
			tx_north_channelvalid : out   channelvalid_t;
			-- South
			tx_south_cleartosend  : in    cleartosend_t;
			tx_south_packet       : out   packet_t;
			tx_south_channelvalid : out   channelvalid_t;
			-- West
			tx_west_cleartosend  : in    cleartosend_t;
			tx_west_packet       : out   packet_t;
			tx_west_channelvalid : out   channelvalid_t;
			-- East
			tx_east_cleartosend  : in    cleartosend_t;
			tx_east_packet       : out   packet_t;
			tx_east_channelvalid : out   channelvalid_t;
			-- PE Ejection
			tx_pe_channela_poprqst       : in    std_logic;
			tx_pe_channelb_poprqst       : in    std_logic; 
			tx_pe_packet                 : out   packet_t;
			tx_pe_channela_dataavailable : out   std_logic;
			tx_pe_channelb_dataavailable : out   std_logic;
			tx_pe_channela_txselect      : out   std_logic;
			tx_pe_channelb_txselect      : out   std_logic     
		);
	end component;

end package router_componentspkg;