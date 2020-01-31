library IEEE;
use IEEE.std_logic_1164.all;

entity cordic is generic(stages: INTEGER :=14);
	port(
		x_in:	in std_logic_vector(14 downto 0);
		y_in:	in std_logic_vector(14 downto 0);
		radius:	out std_logic_vector(15 downto 0);
		phase:	out std_logic_vector(15 downto 0);
		clk:		in std_logic;
		rst:		in std_logic
	);	
end cordic;

architecture bhv of cordic is

component cordic_pipeline_stage is generic(stage_number : INTEGER);
	port(
		x_in:		in std_logic_vector(15 downto 0);
		y_in:		in std_logic_vector(15 downto 0);
		x_out:		out std_logic_vector(15 downto 0);
		y_out:		out std_logic_vector(15 downto 0);
		current_angle:	in std_logic_vector(15 downto 0);
		phase_in:	in std_logic_vector(15 downto 0);
		phase_out:	out std_logic_vector(15 downto 0);
		clk:		in std_logic;
		rst:		in std_logic
	);
end component cordic_pipeline_stage;

component pre_rotation is 
	port(
		x_in: 		in std_logic; 	--MSB of x 
		y_in: 		in std_logic; 	--MSB of y
		x_out: 		out std_logic;	--rotated MSB of x
		y_out: 		out std_logic;	--rotated MSB of y
		phase_offset:	out std_logic_vector(15 downto 0); 
		rst: 		in std_logic;	--reset signal active high
		clk: 		in std_logic	--clock
	);
end component pre_rotation;

signal x_MSB : std_logic;
signal y_MSB : std_logic;

signal x_ext : 	std_logic_vector(15 downto 0);
signal y_ext : 	std_logic_vector(15 downto 0);

signal phase_offset_s : std_logic_vector(15 downto 0);
type vector_t is array(0 to stages-1) of std_logic_vector(15 downto 0);
	
signal x_pipeline:	vector_t;
signal y_pipeline:	vector_t;
signal phase_pipeline:	vector_t;

constant angles : vector_t := (
			
    "0001100100100010",
    "0000111011010110",
    "0000011111010111",
    "0000001111111011",
    "0000000111111111",
    "0000000100000000",
    "0000000010000000",
    "0000000001000000",
    "0000000000100000",
    "0000000000010000",
    "0000000000001000",
    "0000000000000100",
    "0000000000000010",
    "0000000000000001"
);

begin
	PRE_ROT: pre_rotation port map(x_in(14), y_in(14), x_MSB, y_MSB,  phase_offset_s, clk, rst);
	EXT_X:	x_ext <= x_MSB & x_MSB & x_in(13 downto 0); --Sign adjustment
	EXT_Y:	y_ext <= y_MSB & y_MSB & y_in(13 downto 0); --Sign adjustment
	
	GEN: for i in 0 to (stages-1) generate
		STAGE_1: if(i = 0) generate
			CRD_1: cordic_pipeline_stage 
			generic map(i) 
			port map(
				x_ext,
				y_ext,
				x_pipeline(i),
				y_pipeline(i),
				angles(i),
				phase_offset_s,
				phase_pipeline(i),
				clk,
				rst);
		end generate STAGE_1;
		STAGE_i: if((i > 0) and  (i < stages)) generate
			CRD_i: cordic_pipeline_stage 
			generic map(i) 
			port map(
				x_pipeline(i-1),
				y_pipeline(i-1),
				x_pipeline(i),
				y_pipeline(i),
				angles(i),
				phase_pipeline(i-1),
				phase_pipeline(i),
				clk,
				rst);
		end generate STAGE_i;
	end generate GEN;
	OUT_PHASE: 	phase <= phase_pipeline(stages-1);
	OUT_RADIUS:	radius <= x_pipeline(stages-1);
end bhv;