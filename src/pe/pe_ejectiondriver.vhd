---------------------------------------------------------------------------
-- Component: 
--    Ejection Port Driver
-- Purpose:
--    Drives Ejection port and writes out results of packets in .CSV
--
-- Requires: VHDL-2008, NON-SYNTHESIZABLE
-- 
-- Written on April 22/2021
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
	use ieee.std_logic_textio.all;
	use std.textio.all;

library work;
	use work.noc_parameterspkg.all;
	use work.pe_componentspkg.all;

entity pe_ejectiondriver is
	generic (
		x_coord : integer range 0 to x_size := 1;
		y_coord : integer range 0 to y_size := 1
	);
	port (
		-- System Control
		clk         : in    std_logic;
		rst         : in    std_logic;
		networkmode : in    std_logic;

		-- Tick Count
		currenttick : in    unsigned (cc_max_width - 1 downto 0);

		-- Crossbar Side
		packet_in              : in    packet_t;
		channela_dataavailable : in    std_logic;
		channelb_dataavailable : in    std_logic;
		channela_txselect      : in    std_logic;
		channelb_txselect      : in    std_logic;
		channela_poprqst       : out   std_logic;
		channelb_poprqst       : out   std_logic 
	);    
end entity pe_ejectiondriver;

architecture pe_ejectiondriver_impl of pe_ejectiondriver is

	-- Data flow signals
	signal dataout_i   : std_logic_vector(channel_data_size * 2 - 1 downto 0); 
	signal originout_i : std_logic_vector(addr_width - 1 downto 0); 
	
	-- Data control signals
	signal datarqst_i       : std_logic;
	signal datatype_i       : std_logic;
	signal lastdatatype_i   : std_logic;
	signal apxavailable_i   : std_logic;
	signal accavailable_i   : std_logic;
	signal datarqstmade_acc : std_logic;
	signal datarqstmade_apx : std_logic;
	signal datavalid_i      : std_logic;

	-- File definitions
	file file_ACC                 : text;
	file file_APX                 : text;
	file file_received_transcript : text;

	-- Define ejection driver read state

	type fsm_state_t is (peReadState_IDLE, peReadState_ACC, peReadState_APX);

	-- Instantiate FSM State Signals		
	signal pe_read_state      : fsm_state_t;
	signal pe_read_state_next : fsm_state_t;  

begin

	ejection_port : component pe_ejectionport
		generic map ( 
			addresswidth => addr_width,
			fifowidth    => channel_data_size,
			fifodepth    => fifo_depth
		)
		port map (
			clk                    => clk,
			rst                    => rst,
			networkmode            => networkmode,
			dataout                => dataout_i,
			originout              => originout_i,
			datarqst               => datarqst_i,
			apxavailable           => apxavailable_i,
			accavailable           => accavailable_i,
			datatype               => datatype_i,
			packet_in              => packet_in,
			channela_dataavailable => channela_dataavailable,
			channelb_dataavailable => channelb_dataavailable,
			datavalid              => datavalid_i,
			channela_txselect      => channela_txselect,
			channelb_txselect      => channelb_txselect,
			channela_poprqst       => channela_poprqst,
			channelb_poprqst       => channelb_poprqst
		);

	clock_proc : process (clk, rst) is

		variable buf_header : line;
	
	begin

		-- Write CSV header on reset
		if (rst = '1') then
			pe_read_state <= peReadState_IDLE;
		elsif (rising_edge(clk)) then
			pe_read_state <= pe_read_state_next;
		end if;

	end process clock_proc;

	state_proc : process (pe_read_state, networkMode, accavailable_i, apxavailable_i) is 
	begin
		
		case pe_read_state is
		
			-- When accurate
			when peReadState_ACC =>
		
				-- Check if network mode is accurate only
				if (networkMode = '0') then 
					if (accavailable_i = '1') then
						datarqst_i         <= '1';
						datatype_i         <= '0';
						datarqstmade_acc   <= '1';
						datarqstmade_apx   <= '0'; 
						pe_read_state_next <= peReadState_ACC;
					else
						datarqst_i         <= '0';
						datatype_i         <= '0';
						datarqstmade_acc   <= '0';
						datarqstmade_apx   <= '0'; 
						pe_read_state_next <= peReadState_IDLE;
					end if;
					
				-- Otherwise in mixed mode
				elsif (networkMode = '1') then
					-- Check if approximate data is available
					if (apxavailable_i = '1') then
						datarqst_i         <= '1';
						datatype_i         <= '1';
						datarqstmade_acc   <= '0';
						datarqstmade_apx   <= '1'; 
						pe_read_state_next <= peReadState_APX;

					-- Or check if accurate data is available
					elsif (accavailable_i = '1') then
						datarqst_i         <= '1';
						datatype_i         <= '0';
						datarqstmade_acc   <= '1';
						datarqstmade_apx   <= '0'; 
						pe_read_state_next <= peReadState_APX;  
							
					-- Otherwise fall back to idle state
					else
						datarqst_i         <= '0';
						datatype_i         <= '0';
						datarqstmade_acc   <= '0';
						datarqstmade_apx   <= '0'; 
						pe_read_state_next <= peReadState_IDLE;
					end if;                                
				end if;

			-- When reading approximate data
			when peReadState_APX =>

				-- Check if accurate data is available
				if (accavailable_i = '1') then
					datarqst_i         <= '1';
					datatype_i         <= '0';
					datarqstmade_acc   <= '1';
					datarqstmade_apx   <= '0'; 
					pe_read_state_next <= peReadState_ACC;
					
				-- Check if appropximate data is available
				elsif (apxavailable_i = '1') then
					datarqst_i         <= '1';
					datatype_i         <= '1';
					datarqstmade_acc   <= '0';
					datarqstmade_apx   <= '1'; 
					pe_read_state_next <= peReadState_APX; 

				-- Fall back to idle otherwise    
				else
					datarqst_i         <= '0';
					datatype_i         <= '0';
					datarqstmade_acc   <= '0';
					datarqstmade_apx   <= '0'; 
					pe_read_state_next <= peReadState_IDLE;                                
				end if;
						
			-- Idle/fallback
			when others =>
				
				-- Check if available data in network mode 0
				if (networkMode = '0' and accavailable_i = '1') then
					datarqst_i         <= '1';
					datatype_i         <= '0';
					datarqstmade_acc   <= '1';
					datarqstmade_apx   <= '0';
					pe_read_state_next <= peReadState_ACC;
	
				-- Check if available data in network mode 1 and apx
				elsif (networkMode = '1' and apxavailable_i = '1') then
					datarqst_i         <= '1';
					datatype_i         <= '1';
					datarqstmade_acc   <= '0';
					datarqstmade_apx   <= '1';
					pe_read_state_next <= peReadState_APX;
	
				-- Check if available data in network mode 1 and acc
				elsif (networkMode = '1' and accavailable_i = '1') then    
					datarqst_i         <= '1';
					datatype_i         <= '0';
					datarqstmade_acc   <= '1';
					datarqstmade_apx   <= '0';
					pe_read_state_next <= peReadState_APX;
	
				-- Fallback
				else
					datarqst_i         <= '0';
					datatype_i         <= '0';
					datarqstmade_acc   <= '0';
					datarqstmade_apx   <= '0';
					pe_read_state_next <= peReadState_IDLE;
				end if;
					
		end case;

	end process state_proc;

	file_write_proc : process (datarqstmade_apx, datarqstmade_acc, accavailable_i, apxavailable_i, currentTick, dataout_i, clk, originout_i, rst) is

		variable buf_line_out : line;
		
	begin

		if (rst = '1') then
			file_open(file_received_transcript, "transcript_received_"&INTEGER'IMAGE(x_coord)&"_"&INTEGER'IMAGE(y_coord)&".csv", write_mode);
			file_close(file_received_transcript);
			
		-- Check if approximate data first
		elsif (datarqstmade_apx = '1' and apxavailable_i = '1' and falling_edge(clk)) then
			report "APX Received"
				severity note;
			file_open(file_received_transcript, "transcript_received_"&INTEGER'IMAGE(x_coord)&"_"&INTEGER'IMAGE(y_coord)&".csv", append_mode);
				
			-- Write ID
			write(buf_line_out, to_integer(unsigned(dataout_i(2*channel_data_size - 1 downto channel_data_size))));
			write(buf_line_out, string'(","));
				
			-- Write type
			write(buf_line_out, string'("Approximate"));
			write(buf_line_out, string'(","));
				
			-- Write Time Sent
			write(buf_line_out, to_integer(unsigned(dataout_i (2*channel_data_size - 1 downto (2*channel_data_size - CC_MAX_WIDTH)))));
			write(buf_line_out, string'(","));
				
			-- Write Time Received
			write(buf_line_out, to_integer(unsigned(currentTick)));
			write(buf_line_out, string'(","));
				
			-- Write X Origin
			write(buf_line_out, to_integer(unsigned(originout_i(X_BITS + Y_BITS - 1 downto Y_BITS))));     
			write(buf_line_out, string'(","));  
				
			-- Write Y Origin                                                    
			write(buf_line_out, to_integer(unsigned(originout_i(Y_BITS - 1 downto 0))));                      
			writeline(file_received_transcript, buf_line_out);
			file_close(file_received_transcript);
			
		-- Check if approximate data first
		elsif (datarqstmade_acc = '1' and accavailable_i = '1' and falling_edge(clk)) then
			report "ACC Received"
				severity note;
			file_open(file_received_transcript, "transcript_received_"&INTEGER'IMAGE(x_coord)&"_"&INTEGER'IMAGE(y_coord)&".csv", append_mode);
				
			-- Write ID
			write(buf_line_out, to_integer(unsigned(dataout_i(2*channel_data_size - 1 downto channel_data_size))));
			write(buf_line_out, string'(","));
				
			-- Write type
			write(buf_line_out, string'("Accurate"));
			write(buf_line_out, string'(","));
				
			-- Write Time Sent
			write(buf_line_out, to_integer(unsigned(dataout_i (2*channel_data_size - 1 downto (2*channel_data_size - CC_MAX_WIDTH)))));
			write(buf_line_out, string'(","));
				
			-- Write Time Received
			write(buf_line_out, to_integer(unsigned(currentTick)));
			write(buf_line_out, string'(","));
				
			-- Write X Origin
			write(buf_line_out, to_integer(unsigned(originout_i(X_BITS + Y_BITS - 1 downto Y_BITS))));     
			write(buf_line_out, string'(","));  
				
			-- Write Y Origin                                                    
			write(buf_line_out, to_integer(unsigned(originout_i(Y_BITS - 1 downto 0))));                      
			writeline(file_received_transcript, buf_line_out);
			file_close(file_received_transcript);                    
		end if;

	end process file_write_proc;
	
end architecture pe_ejectiondriver_impl;   