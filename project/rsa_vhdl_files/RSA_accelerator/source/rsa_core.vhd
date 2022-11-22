--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018-2019
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--   RSA encryption core template. This core currently computes
--   C = M xor key_n
--
--   Replace/change this module so that it implements the function
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity rsa_core is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256;
		NO_CORES              : integer := 4
	);
	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid            : out std_logic;
		-- Slave ready to accept a new message
		msgout_ready            :  in std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last             : out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)

	);
end rsa_core;

architecture rtl of rsa_core is

	type state is (NOT_LAST, LAST, HOLD);
	signal curr_msgstate, next_msgstate : state;
begin
	i_exponentiation : entity work.exponentiation
		generic map (
			C_block_size => C_BLOCK_SIZE
		)
		port map (
			message   => msgin_data  ,
			key       => key_e_d     ,
			valid_in  => msgin_valid ,
			ready_in  => msgin_ready ,
			ready_out => msgout_ready,
			valid_out => msgout_valid,
			result    => msgout_data ,
			modulus   => key_n       ,
			clk       => clk         ,
			reset_n   => reset_n
		);
	

	msgFSM: process (curr_msgstate, msgin_last, msgin_ready, msgout_valid) begin
		case (curr_msgstate) is
			when (NOT_LAST) => 
				msgout_last 	<= '0';

				if (msgin_last = '1' and msgin_ready = '1') then
					next_msgstate 	<= LAST;
				else
					next_msgstate 	<= NOT_LAST;
				end if;

			when (LAST) =>
			    msgout_last 	<= '0';
			    
				if (msgout_valid = '1') then
					msgout_last		<= '1';
					next_msgstate   <= HOLD;
				else 
				    next_msgstate 	<= LAST;
				end if;
				
			when (HOLD) =>
			    msgout_last		<= '1';
			    
			    if (msgout_valid = '0') then
			        next_msgstate 	<= NOT_LAST;
			        msgout_last 	<= '0';
			    else
			        next_msgstate   <= HOLD;
			    end if;
			when others => 
				msgout_last 	<= '0';
				next_msgstate	<= NOT_LAST;
			 
		end case;
	end process msgFSM;

	msgfsmSync : process(reset_n, clk) 
    begin
        if (reset_n = '0') then
            curr_msgstate <= NOT_LAST;
        elsif (clk'event and clk='1') then
            curr_msgstate <= next_msgstate;
        end if;
    end process msgfsmSync;

	rsa_status   <= (others => '0');
end rtl;
