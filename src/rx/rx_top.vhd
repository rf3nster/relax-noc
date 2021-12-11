---------------------------------------------------------------------------
-- Component:
--    Router Channel Receiver
-- Purpose:
--    Router component that handles all inbound traffic on a single link.
--      
-- Requires: VHDL-2008
-- 
-- Written on Jan 26/2021, Updated on May 15/2021
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
	use work.rx_componentspkg.all;
	use work.fifo_componentspkg.all;
	use work.noc_parameterspkg.all;

entity rx_top is
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
end entity rx_top;

architecture rx_top_impl of rx_top is

	attribute dont_touch                  : string;
	attribute dont_touch of channela_fifo : label is "TRUE";
	attribute dont_touch of channelb_fifo : label is "TRUE";

	-- Channel A Signals
	signal channela_popen_i     : std_logic;
	signal channela_writeen_i   : std_logic;
	signal channela_fifofull_i  : std_logic;
	signal channela_fifoempty_i : std_logic;
	-- Signals for concatenation
	signal rx_channela_fifo_in  : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0);  
	signal rx_channela_fifo_out : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0);  
	
	-- Channel B Signals
	signal channelb_popen_i     : std_logic;
	signal channelb_writeen_i   : std_logic;
	signal channelb_fifofull_i  : std_logic;
	signal channelb_fifoempty_i : std_logic; 
	-- Signals for concatenation
	signal rx_channelb_fifo_in  : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0);
	signal rx_channelb_fifo_out : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0);

begin

	-- Concatenate everything (Channel A)
	rx_channela_fifo_in (addr_data_size + channel_data_size - 1 downto addr_data_size) <= rx_packet_in.dataA;
	rx_channela_fifo_in (addr_data_size - 1 downto 0)                                  <= rx_packet_in.addrA;        
	rx_packet_out.dataa                                                                <= rx_channela_fifo_out (addr_data_size + channel_data_size - 1 downto addr_data_size);
	rx_packet_out.addra                                                                <= rx_channela_fifo_out (addr_data_size - 1 downto 0);   
	
	-- Concatenate everything (Channel B)
	rx_channelb_fifo_in (addr_data_size + channel_data_size - 1 downto addr_data_size) <= rx_packet_in.dataB;
	rx_channelb_fifo_in (addr_data_size - 1 downto 0)                                  <= rx_packet_in.addrB;        
	rx_packet_out.datab                                                                <= rx_channelb_fifo_out (addr_data_size + channel_data_size - 1 downto addr_data_size);
	rx_packet_out.addrb                                                                <= rx_channelb_fifo_out (addr_data_size - 1 downto 0);    
	
	-------------------------------------------
	----------- FIFO Instantiations -----------
	-------------------------------------------

	-- Channel A
	channela_fifo : component fifo_normal
		generic map (
			fifowidth => (addr_data_size + channel_data_size),
			fifodepth => fifodepth
		)
		port map (
			clk       => clk,
			rst       => rst,
			popen     => channela_popen_i, 
			writeen   => channela_writeen_i,
			fifofull  => channela_fifofull_i,
			fifoempty => channela_fifoempty_i,
			datain    => rx_channela_fifo_in,
			dataout   => rx_channela_fifo_out
		);

	-- Channel B
	channelb_fifo : component fifo_normal
		generic map (
			fifowidth => (addr_data_size + channel_data_size),
			fifodepth => fifodepth
		)
		port map (
			clk       => clk,
			rst       => rst,
			popen     => channelb_popen_i, 
			writeen   => channelb_writeen_i,
			fifofull  => channelb_fifofull_i,
			fifoempty => channelb_fifoempty_i,
			datain    => rx_channelb_fifo_in,
			dataout   => rx_channelb_fifo_out
		);

	-------------------------------------------
	--------- Write FSM Instantiations --------
	-------------------------------------------
		
	-- Channel A
	channela_write_fsm : component rx_writefsm
		port map (
			clk             => clk,
			rst             => rst,
			fifo_full       => channela_fifofull_i,
			fifo_writeen    => channela_writeen_i,
			rx_channelvalid => rx_channelvalid.channelvalida, 
			rx_cleartosend  => rx_cleartosend.cleartosenda
		); 	
	
	-- Channel B
	channelb_write_fsm : component rx_writefsm
		port map (
			clk             => clk,
			rst             => rst,
			fifo_full       => channelb_fifofull_i,
			fifo_writeen    => channelb_writeen_i,
			rx_channelvalid => rx_channelvalid.channelvalidb, 
			rx_cleartosend  => rx_cleartosend.cleartosendb
		);

	-------------------------------------------
	--------- Read FSM Instantiations ---------
	-------------------------------------------

	-- Channel A
	channela_read_fsm : component rx_readfsm
		port map (
			clk           => clk, 
			rst           => rst,
			fifo_empty    => channela_fifoempty_i,
			fifo_popen    => channela_popen_i,
			fifo_poprqst  => channela_poprqst, 
			rx_select     => rx_channela_select,
			dataavailable => channela_dataavailable
		);     

	-- Channel B	
	channelb_read_fsm : component rx_readfsm
		port map (
			clk           => clk,
			rst           => rst,
			fifo_empty    => channelb_fifoempty_i,
			fifo_popen    => channelb_popen_i,
			fifo_poprqst  => channelb_poprqst,
			rx_select     => rx_channelb_select,
			dataavailable => channelb_dataavailable
		);
			
end architecture rx_top_impl;