---------------------------------------------------------------------------
-- Component: 
--     Normal FIFO
-- Purpose:
--    Traditional First-In First-Out buffer
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
	use work.fifo_componentspkg.all;

entity fifo_normal is
	generic (
		fifowidth : natural := 16;
		fifodepth : natural := 4
	);
	port (
		-- System Control
		clk : in    std_logic;
		rst : in    std_logic;

		--  FIFO Control
		writeen : in    std_logic;
		popen   : in    std_logic;

		-- FIFO Status
		fifofull  : out   std_logic;
		fifoempty : out   std_logic;

		-- Data
		datain  : in    std_logic_vector(fifowidth - 1 downto 0);
		dataout : out   std_logic_vector(fifowidth - 1 downto 0)
	);
end entity fifo_normal;

architecture impl of fifo_normal is

	-- Constant for row sizing	
	constant fifo_row_len : natural := fifodepth / 2;

	-- Type declaration for row outputs

	type fifo_output_t is array (fifo_row_len - 1 downto 0) of std_logic_vector(fifowidth - 1 downto 0);

	-- Create signals of output array type
	signal reg_col_a_outputs  : fifo_output_t;
	signal reg_col_b_outputs  : fifo_output_t;
	signal reg_output_postmux : fifo_output_t;

	-- Register write selects
	signal reg_col_a_write_sel : std_logic_vector(fifo_row_len - 1 downto 0);
	signal reg_col_b_write_sel : std_logic_vector(fifo_row_len - 1 downto 0);

	-- Create counter and pointers
	signal fiforeadpointer  : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fifowritepointer : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fifocounter      : unsigned (integer(log2(real(fifodepth))) downto 0);
	
	-- Create post-action counter signals
	signal fifocounter_plusone  : unsigned (integer(log2(real(fifodepth))) downto 0);
	signal fifocounter_minusone : unsigned (integer(log2(real(fifodepth))) downto 0);
	
	-- Create post-action pointer signals
	signal fifowritepointer_plusone : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fiforeadpointer_plusone  : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fiforeadpointer_new      : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	signal fifowritepointer_new     : unsigned (integer(log2(real(fifodepth))) - 1 downto 0);
	
	-- Internal status signals
	signal fifo_empty_i : std_logic;
	signal fifo_full_i  : std_logic;

	-- Create write enable row select
	signal fifowrite_rowsel : std_logic_vector(fifo_row_len - 1 downto 0);

	-- Signal for fifo row
	signal fifowrite_row, fiforead_row : natural range 0 to fifo_row_len - 1; 

begin

	-- Cast post-action signals
	fifocounter_plusone      <= fifocounter + 1;
	fifocounter_minusone     <= fifocounter - 1;
	fifowritepointer_plusone <= fifowritepointer + 1;
	fiforeadpointer_plusone  <= fiforeadpointer + 1;

	-- Cast rows
	fiforead_row  <= to_integer(fiforeadpointer(integer(log2(real(fifodepth))) - 1 downto 1));
	fifowrite_row <= to_integer(fifowritepointer(integer(log2(real(fifodepth))) - 1 downto 1));
		
	-- Generate registers
		
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
				data_in  => dataIn
			);

	end generate reg_col_a;

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
				data_in  => dataIn
			);

	end generate reg_col_b;        

	-- Wrap around for fifo write pointer
	fifowritepointer_new <= (others => '0') 
		when ((fifowritepointer = to_unsigned(fifodepth - 1, fifowritepointer'length))) else
		fifowritepointer_plusone;

	-- Wrap around for fifo read pointer
	fiforeadpointer_new <= (others => '0') 
		when ((fiforeadpointer = to_unsigned(fifodepth - 1, fiforeadpointer'length))) else
		fiforeadpointer_plusone;

	-- Row select process for writing
	fifo_write_row_sel_proc : process (fifowrite_row) is
	begin

		fifowrite_rowsel                <= (others => '0');
		fifowrite_rowsel(fifowrite_row) <= '1';

	end process fifo_write_row_sel_proc;

	-- Create write enable signals
	fifo_writeen_rowsel_proc : process (fifowrite_rowsel, writeen, fifowritepointer, fifo_full_i) is
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

	end process fifo_writeen_rowsel_proc;
		
	dataOut <= reg_output_postmux(fiforead_row);
		
	-- Determine status signals
	fifo_empty_i <= '1' when fifocounter = 0 else
		'0';
	fifo_full_i  <= '1' when (to_integer(fifocounter) = fifodepth) else
		'0';
		
	-- Cast status signals externally
	fifoEmpty <= fifo_empty_i;
	fifoFull  <= fifo_full_i;

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

			-- No write, pop data
			elsif (writeen = '0' and popen = '1' and fifo_empty_i = '0') then
				fifocounter      <= fifocounter_minusone;
				fifowritepointer <= fifowritepointer;
				fiforeadpointer  <= fiforeadpointer_new;
		
			-- Pop and write at same time, not full or empty, single write mode
			elsif (writeen = '1' and popen = '1' and fifo_full_i = '0' and fifo_empty_i = '0') then 
				fifocounter      <= fifocounter;
				fifowritepointer <= fifowritepointer_new;
				fiforeadpointer  <= fiforeadpointer_new;

			-- Try to pop and write at same time, fifo Empty, single write
			elsif (writeen = '1' and popen = '1' and fifo_empty_i = '1') then 
				fifocounter      <= fifocounter_plusone;
				fifowritepointer <= fifowritepointer_new;
				fiforeadpointer  <= fiforeadpointer_new;               

			-- Try to pop and write, fifo full
			elsif (writeen = '1' and popen = '1' and fifo_full_i = '1') then 
				fifocounter      <= fifocounter_minusone;
				fifowritepointer <= fifowritepointer_new;
				fiforeadpointer  <= fiforeadpointer_new; 
			else
				fifocounter      <= fifocounter;
				fifowritepointer <= fifowritepointer;
				fiforeadpointer  <= fiforeadpointer;
			end if;
		end if;
	
	end process pointer_proc;

	read_row_mux_proc : process (fiforeadpointer, reg_col_a_outputs, reg_col_b_outputs) is
	begin
	
		for i in 0 to fifo_row_len - 1 loop

			if (fiforeadpointer(0) = '1') then
				reg_output_postmux(i) <= reg_col_b_outputs(i);
			else
				reg_output_postmux(i) <= reg_col_a_outputs(i);
			end if;
	
		end loop;

	end process read_row_mux_proc;

end architecture impl;