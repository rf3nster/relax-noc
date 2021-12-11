---------------------------------------------------------------------------
-- Component: 
--     Dual output FIFO
-- Purpose:
--    FIFO that is able to output two adjacent cells at the same time.
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
	use ieee.math_real.all;

library work;
	use work.fifo_componentsPkg.all;

entity fifo_dualoutput is
	generic (
		fifowidth : natural := 16;
		fifodepth : natural := 4	
	);
	port (
		-- System control
		clk : in    std_logic;
		rst : in    std_logic;

		-- FIFO Control
		dualoutputen : in    std_logic;
		writeen      : in    std_logic;
		popen        : in    std_logic;

		-- FIFO Status
		fifofull  : out   std_logic;
		fifoempty : out   std_logic;

		-- Data
		datain  : in    std_logic_vector(fifowidth - 1 downto 0);
		dataout : out   std_logic_vector(2 * fifowidth - 1 downto 0)
	);
end entity fifo_dualoutput;

architecture impl of fifo_dualoutput is

	-- Constant for row sizing
	constant fifo_row_len : natural := fifodepth / 2;

	-- Type declaration for row outputs

	type fifo_output_t is array (fifo_row_len - 1 downto 0) of std_logic_vector(fifowidth - 1 downto 0);
	
	-- Create signals of output array type
	signal reg_col_a_outputs        : fifo_output_t;
	signal reg_col_b_outputs        : fifo_output_t;
	signal reg_output_lower_postmux : fifo_output_t;
	signal reg_output_upper_postmux : fifo_output_t;
	
	-- Create counter and pointers
	signal fiforeadpointer  : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fifowritepointer : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fifocounter      : unsigned (integer(log2(real(fifodepth))) downto 0);
	
	-- Create post-action counter signals
	signal fifocounter_plusone  : unsigned (integer(log2(real(fifodepth))) downto 0);
	signal fifocounter_minustwo : unsigned (integer(log2(real(fifodepth))) downto 0);
	signal fifocounter_minusone : unsigned (integer(log2(real(fifodepth))) downto 0);

	-- Create post-action pointer signals
	signal fifowritepointer_plusone : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fiforeadpointer_plustwo  : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fiforeadpointer_plusone  : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fiforeadpointer_new      : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fifowritepointer_new     : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	
	-- Create write enable row select
	signal fifowrite_rowsel : std_logic_vector(fifo_row_len - 1 downto 0);
	
	-- Signal for fifo row select
	signal fifowrite_row : natural range 0 to fifo_row_len - 1;
	signal fiforead_row  : natural range 0 to fifo_row_len - 1;

	-- Register write selects
	signal reg_col_a_write_sel, reg_col_b_write_sel : std_logic_vector(fifo_row_len - 1 downto 0);
	
	-- Internal FIFO Signals
	signal fifo_empty_i : std_logic;
	signal fifo_full_i  : std_logic;

	-- Upper multiplexer for output
	signal dataout_upper_postmux : std_logic_vector(fifowidth - 1 downto 0);

begin

	-- Cast rows
	fiforead_row  <= to_integer(fiforeadpointer(integer(log2(real(fifodepth))) - 1 downto 1));
	fifowrite_row <= to_integer(fifowritepointer(integer(log2(real(fifodepth))) - 1 downto 1));

	-- Cast post-action signals
	fifocounter_plusone      <= fifocounter + 1;
	fifocounter_minustwo     <= fifocounter - 2;
	fifocounter_minusone     <= fifocounter - 1;
	fifowritepointer_plusone <= fifowritepointer + 1;
	fiforeadpointer_plustwo  <= fiforeadpointer + 2;
	fiforeadpointer_plusone  <= fiforeadpointer + 1;

	-- Create write enable signals
	fifo_write_en_sel_proc : process (fifowrite_rowsel, writeen, fifowritepointer, fifo_full_i) is
	begin

		for i in 0 to fifo_row_len - 1 loop

			if (writeen = '1') then
				reg_col_a_write_sel(i) <= fifowrite_rowsel(i) and not(fifowritepointer(0)) and not(fifo_full_i);
				reg_col_b_write_sel(i) <= fifowrite_rowsel(i) and fifowritepointer(0) and not(fifo_full_i);
			else
				reg_col_a_write_sel(i) <= '0';
				reg_col_b_write_sel(i) <= '0';
			end if;

		end loop;

	end process fifo_write_en_sel_proc;

	-- Generate register column A

	reg_col_a : for i in 0 to fifo_row_len - 1 generate

		fifo_reg_generated : component fifo_reg  
			generic map (
				reg_width => fifowidth
			)
			port map (
				clk      => clk,
				rst      => rst,
				write_en => reg_col_a_write_sel(i),
				data_out => reg_col_a_outputs(i),
				data_in  => datain (fifowidth - 1 downto 0)
			);

	end generate reg_col_a;

	-- Generate register column B

	reg_col_b : for i in 0 to fifo_row_len - 1 generate

		fifo_reg_generated : component fifo_reg  
			generic map (
				reg_width => fifowidth
			)
			port map (
				clk      => clk, 
				rst      => rst, 
				write_en => reg_col_b_write_sel(i), 
				data_out => reg_col_b_outputs(i),
				data_in  => datain
			);

	end generate reg_col_b;

	-- Row select process for writing
	fifo_write_row_proc : process (fifowrite_row) is
	begin

		fifowrite_rowsel                <= (others => '0');
		fifowrite_rowsel(fifowrite_row) <= '1';

	end process fifo_write_row_proc;

	-- Pointer update
	pointer_proc : process (rst, clk) is
	begin

		if (rst = '1') then
			fiforeadpointer  <= (others => '0');
			fifowritepointer <= (others => '0');
			fifocounter      <= (others => '0');
		elsif (rising_edge (clk)) then
			-- Write one data, no pop
			if (writeen = '1' and popen = '0' and fifo_full_i = '0') then
				fifocounter      <= fifocounter_plusone;
				fifowritepointer <= fifowritepointer_new;
				fiforeadpointer  <= fiforeadpointer;
				
			-- No write, pop data, no dual pop
			elsif (writeen = '0' and dualoutputen = '0' and popen = '1' and fifo_empty_i = '0') then
				fifocounter      <= fifocounter_minusone;
				fifowritepointer <= fifowritepointer;
				fiforeadpointer  <= fiforeadpointer_new;
				
			-- No write, pop data, dual pop
			elsif (writeen = '0' and dualoutputen = '1' and popen = '1' and fifo_empty_i = '0') then
				fifocounter      <= fifocounter_minustwo;
				fifowritepointer <= fifowritepointer;
				fiforeadpointer  <= fiforeadpointer_new;                        
				
			-- Pop and write at same time, not full or empty, single pop mode
			elsif (writeen = '1' and dualoutputen = '0' and popen = '1' and fifo_full_i = '0' and fifo_empty_i = '0') then 
				fifocounter      <= fifocounter;
				fifowritepointer <= fifowritepointer_new;
				fiforeadpointer  <= fiforeadpointer_new;
				
			-- Pop and write at same time, not full or empty, dual pop mode
			elsif (writeen = '1' and dualoutputen = '1' and popen = '1' and fifo_full_i = '0' and fifo_empty_i = '0') then 
				fifocounter      <= fifocounter_minusone;
				fifowritepointer <= fifowritepointer_new;
				fiforeadpointer  <= fiforeadpointer_new; 
				
			-- Try to pop and write at same time, fifo Empty
			elsif (writeen = '1' and popen = '1' and fifo_empty_i = '1') then 
				fifocounter      <= fifocounter_plusone;
				fifowritepointer <= fifowritepointer_new;
				fiforeadpointer  <= fiforeadpointer; 
				
			-- Try to pop and write at same time, fifo full, single pop
			elsif (writeen = '1' and dualoutputen = '0' and popen = '1' and fifo_full_i = '1') then 
				fifocounter      <= fifocounter_minusone;
				fifowritepointer <= fifowritepointer;
				fiforeadpointer  <= fiforeadpointer_new;                     
				
			-- Try to pop and write at same time, fifo full, dual pop
			elsif (writeen = '1' and dualoutputen = '1' and popen = '1' and fifo_full_i = '1') then 
				fifocounter      <= fifocounter_minustwo;
				fifowritepointer <= fifowritepointer;
				fiforeadpointer  <= fiforeadpointer_new; 
			else
				fifocounter      <= fifocounter;
				fifowritepointer <= fifowritepointer;
				fiforeadpointer  <= fiforeadpointer;
			end if;
		end if;

	end process pointer_proc;

	-- Mux for upper data output half
	dataout (2 * fifowidth - 1 downto fifowidth) <= reg_col_b_outputs(fiforead_row) when (dualoutputen = '1') else
		(others => '0');

	-- Determine status signals
	fifo_empty_i <= '1' when (fifocounter = 0 or (fifocounter = 1 and dualoutputen = '1')) else
		'0';
	fifo_full_i  <= '1' when (to_integer(fifocounter) = fifodepth) else
		'0';
	
	-- Cast status signals externally
	fifoempty <= fifo_empty_i;
	fifofull  <= fifo_full_i;

	-- Wrap around for fifo write pointer
	fifowritepointer_new <= (others => '0') when (fifowritepointer = to_unsigned(fifodepth - 1, fifowritepointer'length)) else
		fifowritepointer_plusone;

	-- Wrap around for fifo read pointer
	fiforeadpointer_new <= (others => '0') 
		when ((fiforeadpointer = to_unsigned(fifodepth - 1, fiforeadpointer'length) and dualoutputen = '0') or (fiforeadpointer = to_unsigned(fifodepth - 2, fiforeadpointer'length) and dualoutputen = '1')) else
		fiforeadpointer_plusone when (dualoutputen = '0') else
		fiforeadpointer_plustwo when (dualoutputen = '1');

	read_row_mux_lower_proc : process (fiforeadpointer, reg_col_a_outputs, reg_col_b_outputs, dualoutputen) is
	begin

		for i in 0 to fifo_row_len - 1 loop

			if (fiforeadpointer(0) = '1' and dualoutputen = '0') then
				reg_output_lower_postmux(i) <= reg_col_b_outputs(i);
			else
				reg_output_lower_postmux(i) <= reg_col_a_outputs(i);
			end if;

		end loop;

	end process read_row_mux_lower_proc;

	dataout (fifowidth - 1 downto 0) <= reg_output_lower_postmux(fiforead_row);

end architecture impl;