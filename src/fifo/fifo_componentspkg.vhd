---------------------------------------------------------------------------
-- Packages: 
--     FIFO Component Declarations
-- Purpose:
--    Provides component declarations for FIFO Components.
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

package fifo_componentspkg is

	component fifo_reg is
		generic (
			reg_width : natural := 8
		);
		port (
			-- System Control
			clk : in    std_logic;
			rst : in    std_logic;

			-- FIFO Control
			write_en : in    std_logic;

			-- Data
			data_in  : in    std_logic_vector(reg_width - 1 downto 0);
			data_out : out   std_logic_vector(reg_width - 1 downto 0)
		);
	end component;

	component fifo_normal is
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
	end component;

	component fifo_dualoutput is
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
	end component;

	component fifo_dualpop is
		generic (
			fifowidth : natural := 16;
			fifodepth : natural := 4
		);
		port (
			-- System Control
			clk : in    std_logic;
			rst : in    std_logic;

			-- FIFO Control
			dualpopen : in    std_logic;
			writeen   : in    std_logic;
			popen     : in    std_logic;

			-- FIFO Status
			fifofull  : out   std_logic;
			fifoempty : out   std_logic;

			-- Data
			datain  : in    std_logic_vector(fifowidth - 1 downto 0);
			dataout : out   std_logic_vector(fifowidth - 1 downto 0)
		);
	end component;

	component fifo_dualwrite is
		generic (
			fifowidth : natural := 16;
			fifodepth : natural := 4
		);
		port (
			-- System Control
			clk : in    std_logic;
			rst : in    std_logic;

			-- FIFO Control
			dualwriteen : in    std_logic;
			writeen     : in    std_logic;
			popen       : in    std_logic;

			-- FIFO Status
			fifofull  : out   std_logic;
			fifoempty : out   std_logic;

			-- Data
			datain  : in    std_logic_vector(2 * fifowidth - 1 downto 0);
			dataout : out   std_logic_vector(fifowidth - 1 downto 0)
		);
	end component;

	component fifo_duplicatewrite is
		generic (
			fifowidth : natural := 16;
			fifodepth : natural := 4
		);
		port (
			-- System Control
			clk : in    std_logic;
			rst : in    std_logic;

			-- FIFO Control
			duplicatewriteen : in    std_logic;
			writeen          : in    std_logic;
			popen            : in    std_logic;

			-- FIFO Status
			fifofull  : out   std_logic;
			fifoempty : out   std_logic;

			-- Data
			datain  : in    std_logic_vector(fifowidth - 1 downto 0);
			dataout : out   std_logic_vector(fifowidth - 1 downto 0)
		);
	end component;   

end package fifo_componentspkg;