----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2022 12:45:02
-- Design Name: 
-- Module Name: exponentiation_datapath - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity exponentiation_datapath is
    Generic (
		C_block_size : integer := 256
	);
    Port (
        -- Clock and Reset
        clk         : in std_logic;
        reset_n     : in std_logic;
        
        --input data
		message 	: in    std_logic_vector ( C_block_size-1 downto 0 );
		key 		: in    std_logic_vector ( C_block_size-1 downto 0 );
		
		--modulus
		modulus 	: in    std_logic_vector(C_block_size-1 downto 0);
		
		--output data
		result 		: out   std_logic_vector(C_block_size-1 downto 0);
		
		-- Reg control
		partial_reg_sel   : in std_logic;
		chipher_reg_sel   : in std_logic;
		key_reg_sel       : in std_logic;
		
		-- Reg Load Control
		partial_reg_load  : in std_logic;
		chipher_reg_load  : in std_logic;
		key_reg_load      : in std_logic
    );
end exponentiation_datapath;

architecture Behavioral of exponentiation_datapath is
    signal partial_reg  : std_logic_vector(C_block_size-1 downto 0);
    signal chipher_reg  : std_logic_vector(C_block_size-1 downto 0);
    signal exponent_reg : std_logic_vector(C_block_size-1 downto 0);
    
    signal mm_dir_partial : std_logic;
    signal mm_dor_partial : std_logic;
    
    signal mm_dir_chipher : std_logic;
    signal mm_dor_chipher : std_logic;

begin
    u_multi_mod_partial: entity work.multi_mod
        port map (
            clk                 => clk,
            reset_n             => reset_n,
    
            A_in                => partial_reg,
            B_in                => partial_reg,
            N_in                => modulus,
            
            -- The following is probably wrong
            M_out               => partial_reg,
    
            -- MultiMod (mm) data ready signals
            mm_data_in_ready    => mm_dir_partial,
            mm_data_out_ready   => mm_dor_partial
        );
        
    u_multi_mod_chipher: entity work.multi_mod
        port map (
            clk                 => clk,
            reset_n             => reset_n,
    
            A_in                => partial_reg,
            B_in                => chipher_reg,
            N_in                => modulus,
            
            -- The following is probably wrong
            M_out               => chipher_reg,
    
            -- MultiMod (mm) data ready signals
            mm_data_in_ready    => mm_dir_chipher,
            mm_data_out_ready   => mm_dor_chipher
        );
       
    -- Reset all registers
    process (clk, reset_n) begin
        if (reset_n = '0') then
            partial_reg     <= (others => '0');
            chipher_reg     <= std_logic_vector(to_unsigned(1, 256));
            exponent_reg    <= (others => '0');
            
        elsif (clk'event and clk = '1') then
            if (key_reg_sel = '1') then
                exponent_reg    <= key;
            elsif (key_reg_sel = '0') then
                exponent_reg    <= '0' & exponent_reg(255 downto 1);
            end if;
        end if;
    end process;
    
end Behavioral;
