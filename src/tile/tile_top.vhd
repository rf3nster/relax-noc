---------------------------------------------------------------------------
-- Component:
--    Network Tile
-- Purpose:
--    Mesh topology network tile, contains router and processing element
--    drivers.
-- 
-- Requires: VHDL-2008, NON-SYNTHESIZABLE
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
	use work.pe_componentspkg.all;
	use work.router_componentspkg.all;
	use work.noc_parameterspkg.all;

entity tile_top is
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
end entity tile_top;

architecture tile_top_weighted_impl of tile_top is
	
	-- PE Injection Signals
	signal rx_pe_packet                 : packet_t;
	signal rx_pe_channela_dataavailable : std_logic;
	signal rx_pe_channelb_dataavailable : std_logic;
	signal rx_pe_channela_poprqst       : std_logic;
	signal rx_pe_channelb_poprqst       : std_logic;
	signal rx_pe_channela_select        : std_logic;
	signal rx_pe_channelb_select        : std_logic;
	signal rx_pe_data_in                : std_logic_vector(2 * channel_data_size - 1 downto 0);
	signal rx_pe_dest_in                : std_logic_vector(addr_width - 1 downto 0);
	signal rx_pe_accfifofull_i          : std_logic;
	signal rx_pe_apxfifofull_i          : std_logic; 
	signal rx_pe_writeen_i              : std_logic;
	signal rx_pe_datatype_i             : std_logic;
	signal rx_pe_injectionenable        : std_logic;

	-- PE Ejection Signals
	signal tx_pe_packet                 : packet_t;
	signal tx_pe_channela_dataavailable : std_logic;
	signal tx_pe_channelb_dataavailable : std_logic;
	signal tx_pe_channela_txselect      : std_logic;
	signal tx_pe_channelb_txselect      : std_logic;
	signal tx_pe_channela_poprqst       : std_logic;
	signal tx_pe_channelb_poprqst       : std_logic;

begin
	
	-- Instance Injection Port
	injport : component pe_injectionport
		generic map (
			router_loc_x => x_coord,
			router_loc_y => y_coord
		)
		port map (
			clk                    => clk,
			rst                    => rst, 
			networkmode            => networkmode,
			destin                 => rx_pe_dest_in,
			datain                 => rx_pe_data_in,
			writeen                => rx_pe_writeen_i,
			datatype               => rx_pe_datatype_i,
			accfifofull            => rx_pe_accfifofull_i,
			apxfifofull            => rx_pe_apxfifofull_i,
			rx_packet_out          => rx_pe_packet,
			channela_dataavailable => rx_pe_channela_dataavailable,
			channelb_dataavailable => rx_pe_channelb_dataavailable,   
			channela_poprqst       => rx_pe_channela_poprqst,
			channelb_poprqst       => rx_pe_channelb_poprqst, 
			rx_channela_select     => rx_pe_channela_select,
			rx_channelb_select     => rx_pe_channelb_select
		);

	-- Instance Injection Traffic Generator
	injdriver : component pe_injectiondriver
		generic map (
			x_coord => x_coord,
			y_coord => y_coord
		)
		port map (
			clk             => clk,
			rst             => rst,
			networkmode     => networkmode,
			currenttick     => currenttick,
			injectionenable => injectionenable,
			destout         => rx_pe_dest_in,
			dataout         => rx_pe_data_in,
			writeen         => rx_pe_writeen_i,
			datatype        => rx_pe_datatype_i,
			accfifofull     => rx_pe_accfifofull_i,
			apxfifofull     => rx_pe_apxfifofull_i
		);
		
	-- Instance Ejection driver
	ejdriver : component pe_ejectiondriver
		generic map (
			x_coord => x_coord, 
			y_coord => y_coord
		)
		port map (
			clk                    => clk,
			rst                    => rst, 
			networkmode            => networkmode,
			currenttick            => currenttick,
			packet_in              => tx_pe_packet, 
			channela_dataavailable => tx_pe_channela_dataavailable,
			channelb_dataavailable => tx_pe_channelb_dataavailable,
			channela_txselect      => tx_pe_channela_txselect,
			channelb_txselect      => tx_pe_channelb_txselect, 
			channela_poprqst       => tx_pe_channela_poprqst,
			channelb_poprqst       => tx_pe_channelb_poprqst
		);

	-- Instance the router
	router : component router_top
		generic map (
			router_loc_x => x_coord, 
			router_loc_y => y_coord
		)
		port map (
			-- System control
			clk         => clk, 
			rst         => rst, 
			networkmode => networkmode,
			-------------
			-- RX Side --
			-------------
			-- North
			rx_north_packet       => northPacket_in,
			rx_north_cleartosend  => northcleartosend_out,
			rx_north_channelvalid => northchannelvalid_in,
			-- South
			rx_south_packet       => southPacket_in,
			rx_south_cleartosend  => southcleartosend_out,
			rx_south_channelvalid => southchannelvalid_in,
			-- West
			rx_west_packet       => westPacket_in,
			rx_west_cleartosend  => westcleartosend_out,
			rx_west_channelvalid => westchannelvalid_in,
			-- East
			rx_east_packet       => eastPacket_in,
			rx_east_cleartosend  => eastcleartosend_out,
			rx_east_channelvalid => eastchannelvalid_in,
			-- PE Injection
			rx_pe_packet                 => rx_pe_packet,
			rx_pe_channela_dataavailable => rx_pe_channela_dataavailable,
			rx_pe_channelb_dataavailable => rx_pe_channelb_dataavailable,
			rx_pe_channela_poprqst       => rx_pe_channela_poprqst,
			rx_pe_channelb_poprqst       => rx_pe_channelb_poprqst,
			rx_pe_channela_select        => rx_pe_channela_select,
			rx_pe_channelb_select        => rx_pe_channelb_select,
			
			-------------
			-- TX Side --
			-------------
			-- North
			tx_north_packet       => northpacket_out,
			tx_north_cleartosend  => northcleartosend_in,
			tx_north_channelvalid => northchannelvalid_out,
			-- South
			tx_south_packet       => southpacket_out,
			tx_south_cleartosend  => southcleartosend_in,
			tx_south_channelvalid => southchannelvalid_out,
			-- West
			tx_west_packet       => westpacket_out,
			tx_west_cleartosend  => westcleartosend_in,
			tx_west_channelvalid => westchannelvalid_out,
			-- East
			tx_east_packet       => eastpacket_out,
			tx_east_cleartosend  => eastcleartosend_in,
			tx_east_channelvalid => eastchannelvalid_out,
			-- PE Ejection
			tx_pe_packet                 => tx_pe_packet,
			tx_pe_channela_dataavailable => tx_pe_channela_dataavailable,
			tx_pe_channelb_dataavailable => tx_pe_channelb_dataavailable,
			tx_pe_channela_txselect      => tx_pe_channela_txselect,
			tx_pe_channelb_txselect      => tx_pe_channelb_txselect,
			tx_pe_channela_poprqst       => tx_pe_channela_poprqst,
			tx_pe_channelb_poprqst       => tx_pe_channelb_poprqst 
		);

end architecture tile_top_weighted_impl;