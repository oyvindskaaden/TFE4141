library ieee;
use ieee.std_logic_1164.all;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input controll
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;

		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput controll
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end exponentiation;


architecture expBehave of exponentiation is
begin
	result <= message xor modulus;
	ready_in <= ready_out;
	valid_out <= valid_in;

	multi_mod_control: entity work.multi_mod_control
		port map (

		)


	multi_mod_datapath: entity work.multi_mod_datapath
		port map (
			A_in => message;
			B_in => message;

			n_in => key;

			M_out => result;

			clk => clk;
			reset_n => reset_n;
		);


end expBehave;
