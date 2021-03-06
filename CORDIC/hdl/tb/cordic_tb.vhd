library IEEE;
use IEEE.std_logic_1164.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use IEEE.numeric_std.all;

-- TESTBENCH

--CORDIC_TB entity------------------------------------------
entity cordic_tb is
end cordic_tb;
------------------------------------------------------------

architecture bhv of cordic_tb is
--Constants-------------------------------------------------
constant stages		: integer := 14; -- Number of stages
constant in_wordlength	: integer := 16; -- Size of input words
constant out_wordlength	: integer := 20; -- Size of output words
constant rst_time	: integer := 15; -- Reset time (clock duration)

-- Clocks needed to fill/flush pipeline
constant filling_clk	:integer := 16;
	-- 14 --> pipeline stages
	-- 1 --> pre_rotation
	-- 1 --> input

-- Input and output files
constant in_file_x	: string := "../../matlab/input/x_q.in";
constant in_file_y	: string := "../../matlab/input/y_q.in";
constant out_file_r	: string := "../../matlab/output/r_q.in";
constant out_file_p	: string := "../../matlab/output/p_q.in";

-- Clock duration
constant t_clk		: time    := 10 ns;
------------------------------------------------------------

--Testbench signals-----------------------------------------
-- Used to visualize number of data read from file
signal data_counter	: integer := - filling_clk - 1;
-- Initialization takes in account the clocks consumed to
	-- fill the pipeline

-- Clock and reset signals
signal clk		: std_logic := '0';
signal rst		: std_logic := '1'; -- Active-high

-- In/out signals of cordic module
signal x_in		: std_logic_vector(in_wordlength-1 downto 0);
signal y_in		: std_logic_vector(in_wordlength-1 downto 0);
signal r_out		: std_logic_vector(out_wordlength-1 downto 0);
signal p_out		: std_logic_vector(out_wordlength-1 downto 0);

-- Used to stop the simulation (active-low)
signal eof		: std_logic := '1';
------------------------------------------------------------

--File pointers for I/O operations--------------------------
file fptr_x	 	: text;
file fptr_y	 	: text;
file fptr_r	 	: text;
file fptr_p	 	: text;
------------------------------------------------------------

--Device under test-----------------------------------------
component cordic is generic(stages: INTEGER := 14;
			in_wordlength: INTEGER := 16;
			out_wordlength: INTEGER := 20);
	port(
		x_in:	in std_logic_vector(in_wordlength-1 downto 0);
		y_in:	in std_logic_vector(in_wordlength-1 downto 0);
		radius:	out std_logic_vector(out_wordlength-1 downto 0);
		phase:	out std_logic_vector(out_wordlength-1 downto 0);
		clk:	in std_logic;
		rst:	in std_logic
	);
end component cordic;
------------------------------------------------------------

begin

--Device under test port mapping----------------------------
	dut: cordic generic map(stages => stages,
			in_wordlength => in_wordlength,
			out_wordlength => out_wordlength)
		port map(
			x_in => x_in,
			y_in => y_in,
			radius => r_out,
			phase => p_out,
			clk => clk,
			rst => rst
		);
------------------------------------------------------------

--Start clock-----------------------------------------------
	CLOCK_GEN:	clk <= (not(clk) and eof) after t_clk/2;
------------------------------------------------------------

--Process used to retrieve data from file and send it to DUT
	get_data_proc: process(clk, rst)
		-- Variables needed for file IO
		variable fstatus_x	: file_open_status;
		variable file_line_x	: line;
		variable fstatus_y	: file_open_status;
		variable file_line_y	: line;
		variable fstatus_r	: file_open_status;
		variable file_line_r	: line;
		variable fstatus_p	: file_open_status;
		variable file_line_p	: line;
		variable x_data		: integer;
		variable y_data		: integer;
		variable r_data		: integer;
		variable p_data		: integer;

		begin
			-- Variable initialization
			x_data 	:= 0;
			y_data	:= 0;
			r_data 	:= 0;
			p_data 	:= 0;
			-- Open files for x,y,r and p
			file_open(fstatus_x, fptr_x, in_file_x, read_mode);
			file_open(fstatus_y, fptr_y, in_file_y, read_mode);
			file_open(fstatus_r, fptr_r, out_file_r, write_mode);
			file_open(fstatus_p, fptr_p, out_file_p, write_mode);

			-- Remove reset (initialized at 1)
			REMOVE_RESET:	rst <= '0' after rst_time*t_clk;

			if (rst = '1') then -- Do reset things
				-- Set all dut inputs to 0
				x_in <= (others => '0');
				y_in <= (others =>'0');
				eof <= '1';
			elsif(rising_edge(clk)) then
				-- Retrieve data from file and send it into input
				-- signals
				if ((not endfile(fptr_x)) and (not endfile(fptr_y))) then -- There is still data to read
					-- X
					readline(fptr_x, file_line_x);
					read(file_line_x, x_data);
					x_in <= std_logic_vector(to_signed(x_data, in_wordlength));
					-- Y
					readline(fptr_y, file_line_y);
					read(file_line_y, y_data);
					y_in <= std_logic_vector(to_signed(y_data, in_wordlength));

					data_counter <= data_counter + 1;
				else -- All data has been read
					-- Stop after writing all values remaining in
					-- pipeline
					eof <= '0' after (filling_clk + 1)*t_clk;
						-- +1 needed to fetch input from file

					file_close(fptr_x);
					file_close(fptr_y);
					file_close(fptr_x);
					file_close(fptr_y);
				end if;
				if(data_counter >= 0) then
					-- Reset is finished start writing to file
					-- Radius
					write(file_line_r, to_integer(signed(r_out)));
					writeline(fptr_r, file_line_r);
					-- Phase
					write(file_line_p, to_integer(signed(p_out)));
					writeline(fptr_p, file_line_p);
				end if;
			end if;
	end process; -- get_data_proc
end bhv; -- cordic_tb
------------------------------------------------------------
