---------------------------------------------------------------------------
-- Package:
--    Network Tile Components Package
-- Purpose:
--    Defines tile components for network
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

package tile_componentspkg is

	component tile_synth_top is
		generic (
			x_coord : integer range 0 to x_size := 0;
			y_coord : integer range 0 to y_size := 0
		);
		port (
			-- System Control
			clk         : in    std_logic;
			rst         : in    std_logic;
			networkmode : in    std_logic;
	
			-- North Inbound
			northpacket_in       : in    packet_t;
			northchannelvalid_in : in    channelvalid_t;
			northcleartosend_out : out   cleartosend_t;
			
			-- North Outbound
			northcleartosend_in   : in    cleartosend_t;
			northpacket_out       : out   packet_t;
			northchannelvalid_out : out   channelvalid_t;
	
			-- South Inbound
			southpacket_in       : in    packet_t;
			southchannelvalid_in : in    channelvalid_t;
			southcleartosend_out : out   cleartosend_t;
			
			-- South Outbound
			southcleartosend_in   : in    cleartosend_t;
			southpacket_out       : out   packet_t;
			southchannelvalid_out : out   channelvalid_t;
	
			-- West Inbound
			westpacket_in       : in    packet_t;
			westchannelvalid_in : in    channelvalid_t;
			westcleartosend_out : out   cleartosend_t;
	
			-- West Outbound
			westcleartosend_in   : in    cleartosend_t;
			westpacket_out       : out   packet_t;
			westchannelvalid_out : out   channelvalid_t;
	
			-- East Inbound
			eastpacket_in       : in    packet_t;
			eastchannelvalid_in : in    channelvalid_t;
			eastcleartosend_out : out   cleartosend_t;
	
			-- East Outbound
			eastcleartosend_in   : in    cleartosend_t;
			eastpacket_out       : out   packet_t;
			eastchannelvalid_out : out   channelvalid_t;
	
			-- PE Injection
			pe_inj_destin      : in    std_logic_vector(addr_width - 1 downto 0);
			pe_inj_datain      : in    std_logic_vector(2 * channel_data_size - 1 downto 0);
			p_inj_writeen      : in    std_logic;
			pe_inj_datatype    : in    std_logic;
			pe_inj_accfifofull : out   std_logic;
			pe_inj_apxfifofull : out   std_logic;
	
			-- PE Ejection
			pe_ej_datarqst     : in    std_logic;
			pe_ej_datatype     : in    std_logic;		
			pe_ej_dataout      : out   std_logic_vector(2 * channel_data_size - 1 downto 0);
			pe_ej_originout    : out   std_logic_vector(addr_width - 1 downto 0);
			pe_ej_accavailable : out   std_logic;
			pe_ej_apxavailable : out   std_logic                          
		);
	end component;

	component tile_top is
		generic (
			x_coord : integer range 0 to x_size := 0;
			y_coord : integer range 0 to y_size := 0
		);
		port (
			-- System Control
			clk             : in    std_logic;
			rst             : in    std_logic;
			networkmode     : in    std_logic;
			injectionenable : in    std_logic;
			
			-- Tick Count
			currenttick : in    unsigned(cc_max_width - 1 downto 0);
			
			-- North Inbound
			northpacket_in       : in    packet_t;
			northchannelvalid_in : in    channelvalid_t;
			northcleartosend_out : out   cleartosend_t;

			-- North Outbound
			northcleartosend_in   : in    cleartosend_t;			
			northpacket_out       : out   packet_t;
			northchannelvalid_out : out   channelvalid_t;

			-- South Inbound
			southpacket_in       : in    packet_t;
			southchannelvalid_in : in    channelvalid_t;
			southcleartosend_out : out   cleartosend_t;

			-- South Outbound
			southcleartosend_in   : in    cleartosend_t;
			southpacket_out       : out   packet_t;
			southchannelvalid_out : out   channelvalid_t;

			-- West Inbound
			westpacket_in       : in    packet_t;
			westchannelvalid_in : in    channelvalid_t;
			westcleartosend_out : out   cleartosend_t;

			-- West Outbound
			westcleartosend_in   : in    cleartosend_t;
			westpacket_out       : out   packet_t;
			westchannelvalid_out : out   channelvalid_t;

			-- East Inbound
			eastpacket_in       : in    packet_t;
			eastchannelvalid_in : in    channelvalid_t;
			eastcleartosend_out : out   cleartosend_t;

			-- East Outbound
			eastcleartosend_in   : in    cleartosend_t;  
			eastpacket_out       : out   packet_t;
			eastchannelvalid_out : out   channelvalid_t        
		);    
	end component;

end package tile_componentspkg;