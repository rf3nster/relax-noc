---------------------------------------------------------------------------
-- Component:
--    Router Transmitter Top Level
-- Purpose:
--    Controls transmission of data from one router to another.
--      
-- Requires: VHDL-2008
-- 
-- Written on December 24/2021, Updated on May 15/2021
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
	use work.fifo_componentspkg.all;
	use work.tx_componentspkg.all;
	use work.noc_parameterspkg.all;

entity tx_top is 
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
		tx_cleartosend  : in    cleartosend_t;
		tx_channelvalid : out   channelvalid_t;

		-- Crossbar side channel A signaling
		channela_dataavailable : in    std_logic;
		channela_txselect      : in    std_logic;
		channela_poprqst       : out   std_logic;

		-- Crossbar side channel B signaling
		channelb_dataavailable : in    std_logic;
		channelb_txselect      : in    std_logic;
		channelb_poprqst       : out   std_logic             
	);
end entity tx_top;

architecture tx_top_impl of tx_top is

	attribute dont_touch                  : string;
	attribute dont_touch of channela_fifo : label is "TRUE";
	attribute dont_touch of channelb_fifo : label is "TRUE";

	-- Channel A Signals
	signal channela_popen_i      : std_logic;
	signal channela_writeen_i    : std_logic;
	signal channela_fifo_full_i  : std_logic;
	signal channela_fifo_empty_i : std_logic;
	-- Signals for concatenation
	signal tx_channela_fifo_in  : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0); 
	signal tx_channela_fifo_out : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0); 
	
	-- Channel B Signals
	signal channelb_popen_i      : std_logic;
	signal channelb_writeen_i    : std_logic;
	signal channelb_fifo_full_i  : std_logic;
	signal channelb_fifo_empty_i : std_logic; 
	-- Signals for concatenation
	signal tx_channelb_fifo_in  : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0);
	signal tx_channelb_fifo_out : std_logic_vector(addr_data_size + channel_data_size - 1 downto 0);        
	
begin

	-- Concatenate everything (Channel A)
	tx_channela_fifo_in (addr_data_size + channel_data_size - 1 downto addr_data_size) <= tx_packet_in.dataa;
	tx_channela_fifo_in (addr_data_size - 1 downto 0)                                  <= tx_packet_in.addra;        
	tx_packet_out.dataa                                                                <= tx_channela_fifo_out (addr_data_size + channel_data_size - 1 downto addr_data_size);
	tx_packet_out.addra                                                                <= tx_channela_fifo_out (addr_data_size - 1 downto 0);   
	
	-- Concatenate everything (Channel B)
	tx_channelb_fifo_in (addr_data_size + channel_data_size - 1 downto addr_data_size) <= tx_packet_in.datab;
	tx_channelb_fifo_in (addr_data_size - 1 downto 0)                                  <= tx_packet_in.addrb;        
	tx_packet_out.datab                                                                <= tx_channelb_fifo_out (addr_data_size + channel_data_size - 1 downto addr_data_size);
	tx_packet_out.addrb                                                                <= tx_channelb_fifo_out (addr_data_size - 1 downto 0);            
	   
	-------------------------------------------
	----------- FIFO Instantiations -----------
	-------------------------------------------
		
	-- Channel A FIFO
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
			fifofull  => channela_fifo_full_i,
			fifoempty => channela_fifo_empty_i,
			datain    => tx_channela_fifo_in,
			dataout   => tx_channela_fifo_out
		);

	-- Channel B FIFO
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
			fifofull  => channelb_fifo_full_i,
			fifoempty => channelb_fifo_empty_i, 
			datain    => tx_channelb_fifo_in,
			dataout   => tx_channelb_fifo_out
		);

	-------------------------------------------
	--------- Write FSM Instantiations --------
	-------------------------------------------

	-- Channel A
	channela_write_fsm : component tx_writefsm
		port map (
			clk              => clk, 
			rst              => rst,
			fifo_full        => channela_fifo_full_i,
			tx_select        => channela_txselect,
			rx_poprqst       => channela_poprqst,
			fifo_writeen     => channela_writeen_i,
			rx_dataavailable => channela_dataavailable
		);         
	   
	-- Channel B
	channelb_write_fsm : component tx_writefsm
		port map (
			clk              => clk,
			rst              => rst,
			fifo_full        => channelb_fifo_full_i,
			tx_select        => channelb_txselect,
			rx_poprqst       => channelb_poprqst,
			fifo_writeen     => channelb_writeen_i,
			rx_dataavailable => channelb_dataavailable
		);

	-------------------------------------------
	--------- Read FSM Instantiations ---------
	-------------------------------------------

	-- Channel A
	channela_read_fsm : component tx_readfsm
		port map (
			clk             => clk,
			rst             => rst,
			fifo_empty      => channela_fifo_empty_i,
			fifo_popen      => channela_popen_i,
			tx_cleartosend  => tx_cleartosend.cleartosenda,
			tx_channelvalid => tx_channelvalid.channelvalida
		);      
				
	-- Channel B
	channelb_read_fsm : component tx_readfsm
		port map (
			clk             => clk,
			rst             => rst,
			fifo_empty      => channelb_fifo_empty_i,
			fifo_popen      => channelb_popen_i,
			tx_cleartosend  => tx_cleartosend.cleartosendb,
			tx_channelvalid => tx_channelvalid.channelvalidb
		);

end architecture tx_top_impl;