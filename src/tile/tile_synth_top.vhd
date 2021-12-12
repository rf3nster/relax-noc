---------------------------------------------------------------------------
-- Component:
--    Network Tile
-- Purpose:
--    Synthesizable network tile, contains router and no stimuli
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
	use work.pe_componentspkg.all;
	use work.router_componentspkg.all;
	use work.noc_parameterspkg.all;

entity tile_synth_top is
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
		pe_inj_writeen     : in    std_logic;
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

	-- Vivado Attributes to prevent IO Buffers being allocated
	attribute io_buffer_type                          : string;
	attribute io_buffer_type of clk                   : signal is "none";
	attribute io_buffer_type of rst                   : signal is "none";    
	attribute io_buffer_type of networkmode           : signal is "none";
	attribute io_buffer_type of northpacket_in        : signal is "none";
	attribute io_buffer_type of northchannelvalid_in  : signal is "none";
	attribute io_buffer_type of northcleartosend_out  : signal is "none";  
	attribute io_buffer_type of northpacket_out       : signal is "none";   
	attribute io_buffer_type of northchannelvalid_out : signal is "none";
	attribute io_buffer_type of northcleartosend_in   : signal is "none";   
	attribute io_buffer_type of southpacket_in        : signal is "none";
	attribute io_buffer_type of southchannelvalid_in  : signal is "none";
	attribute io_buffer_type of southcleartosend_out  : signal is "none";  
	attribute io_buffer_type of southpacket_out       : signal is "none";   
	attribute io_buffer_type of southchannelvalid_out : signal is "none";
	attribute io_buffer_type of southcleartosend_in   : signal is "none"; 
	attribute io_buffer_type of westpacket_in         : signal is "none";
	attribute io_buffer_type of westchannelvalid_in   : signal is "none";
	attribute io_buffer_type of westcleartosend_out   : signal is "none";  
	attribute io_buffer_type of westpacket_out        : signal is "none";   
	attribute io_buffer_type of westchannelvalid_out  : signal is "none";
	attribute io_buffer_type of westcleartosend_in    : signal is "none"; 
	attribute io_buffer_type of eastpacket_in         : signal is "none";
	attribute io_buffer_type of eastchannelvalid_in   : signal is "none";
	attribute io_buffer_type of eastcleartosend_out   : signal is "none";  
	attribute io_buffer_type of eastpacket_out        : signal is "none";   
	attribute io_buffer_type of eastchannelvalid_out  : signal is "none";
	attribute io_buffer_type of eastcleartosend_in    : signal is "none";      
	attribute io_buffer_type of pe_inj_destin         : signal is "none";
	attribute io_buffer_type of pe_inj_datain         : signal is "none";
	attribute io_buffer_type of pe_inj_writeen        : signal is "none";  
	attribute io_buffer_type of pe_inj_datatype       : signal is "none";   
	attribute io_buffer_type of pe_inj_accfifofull    : signal is "none";
	attribute io_buffer_type of pe_inj_apxfifofull    : signal is "none";
	attribute io_buffer_type of pe_ej_dataout         : signal is "none";
	attribute io_buffer_type of pe_ej_originout       : signal is "none";
	attribute io_buffer_type of pe_ej_datarqst        : signal is "none";  
	attribute io_buffer_type of pe_ej_datatype        : signal is "none";   
	attribute io_buffer_type of pe_ej_accavailable    : signal is "none";
	attribute io_buffer_type of pe_ej_apxavailable    : signal is "none";                  
	attribute keep_hierarchy                          : string;
	attribute keep_hierarchy of tile_synth_top        : entity is "yes";
end entity tile_synth_top;

architecture tile_synth_top_impl of tile_synth_top is

	-- PE Injection Signals
	signal rx_pe_packet                 : packet_t;
	signal rx_pe_channela_dataavailable : std_logic;
	signal rx_pe_channelb_dataavailable : std_logic;
	signal rx_pe_channela_poprqst       : std_logic;
	signal rx_pe_channelb_poprqst       : std_logic;
	signal rx_pe_channela_select        : std_logic;
	signal rx_pe_channelb_select        : std_logic;

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
			destin                 => pe_inj_destin,
			datain                 => pe_inj_datain,
			writeen                => pe_inj_writeen,
			datatype               => pe_inj_datatype,
			accfifofull            => pe_inj_accfifofull,
			apxfifofull            => pe_inj_apxfifofull,
			rx_packet_out          => rx_pe_packet,
			channela_dataavailable => rx_pe_channela_dataavailable,
			channelb_dataavailable => rx_pe_channelb_dataavailable,   
			channela_poprqst       => rx_pe_channela_poprqst,
			channelb_poprqst       => rx_pe_channelb_poprqst, 
			rx_channela_select     => rx_pe_channela_select,
			rx_channelb_select     => rx_pe_channelb_select
		);

	-- Instance Ejection port
	ejport : component pe_ejectionport
		port map (
			clk                    => clk, 
			rst                    => rst, 
			networkmode            => networkmode,
			dataout                => pe_ej_dataout, 
			originout              => pe_ej_originout,
			datarqst               => pe_ej_datarqst,
			datatype               => pe_ej_datatype,
			accavailable           => pe_ej_accavailable,
			apxavailable           => pe_ej_apxavailable,
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
			rx_north_packet       => northpacket_in,
			rx_north_cleartosend  => northcleartosend_out,
			rx_north_channelvalid => northchannelvalid_in,
			-- South
			rx_south_packet       => southpacket_in,
			rx_south_cleartosend  => southcleartosend_out,
			rx_south_channelvalid => southchannelvalid_in,
			-- West
			rx_west_packet       => westpacket_in,
			rx_west_cleartosend  => westcleartosend_out,
			rx_west_channelvalid => westchannelvalid_in,
			-- East
			rx_east_packet       => eastpacket_in,
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

end architecture tile_synth_top_impl;
