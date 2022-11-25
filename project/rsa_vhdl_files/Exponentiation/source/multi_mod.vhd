----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2022 11:47:49
-- Design Name: 
-- Module Name: multi_mod - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multi_mod is
    Generic (
		C_block_size : integer := 256
    );
    Port (
        clk                 : in    std_logic;
        reset_n             : in    std_logic;
    
        A_in                : in    std_logic_vector(C_block_size-1 downto 0);
        B_in                : in    std_logic_vector(C_block_size-1 downto 0);
        N_in                : in    std_logic_vector(C_block_size-1 downto 0);
        
        M_out               : out   std_logic_vector(C_block_size-1 downto 0);
    
        -- MultiMod (mm) data ready signals
        mm_data_in_valid    : in    std_logic;
        mm_data_in_ready    : out   std_logic;

        mm_data_out_valid   : out   std_logic;
        mm_data_out_ready   : in    std_logic

    );
end multi_mod;

architecture Behavioral of multi_mod is
    signal borrow_1n, borrow_2n     : std_logic;
    signal mod_sel                  : std_logic_vector(1 downto 0);
    
    signal A_reg_load               : std_logic;
    signal B_reg_load               : std_logic;
    signal M_reg_load               : std_logic;
    --signal N_reg_load               : std_logic;
    
    signal B_reg_sel                : std_logic;
    
    
    signal mm_reset_n               : std_logic;

begin
    u_multi_mod_control: entity work.multi_mod_control
        generic map (
            C_block_size        => C_block_size
        )
		port map (
		    -- Clock and Reset
	        clk                 => clk,
            reset_n             => reset_n,
            
            -- Seperate MM Reset
            mm_reset_n          => mm_reset_n,
            
            -- Data readiness
            mm_data_in_valid    => mm_data_in_valid,
            mm_data_out_valid   => mm_data_out_valid,
            mm_data_in_ready    => mm_data_in_ready,
            mm_data_out_ready   => mm_data_out_ready,
            
            -- Register load signals
            A_reg_load          => A_reg_load,
            B_reg_load          => B_reg_load,
            M_reg_load          => M_reg_load,
            
            -- Source selction for the B register
            B_reg_sel           => B_reg_sel,
            
            -- Selection of correct calculation result
            mod_sel             => mod_sel,
            
            -- Borrow signals
            borrow_1n           => borrow_1n,
            borrow_2n           => borrow_2n
            
		);


	u_multi_mod_datapath: entity work.multi_mod_datapath 
        generic map (
            C_block_size        => C_block_size
        )
        port map (
	        -- Clock and Reset
	        clk         => clk,
            --reset_n     => reset_n,
            
            -- Connect the seperate datapath reset
            reset_n  => mm_reset_n,
            
            -- Data in connection
            A_in        => A_in,
			B_in        => B_in,
			N_in        => N_in,

            -- Data out connection
			M_out       => M_out,
                        
            -- Register load signals
            A_reg_load  => A_reg_load,
            B_reg_load  => B_reg_load,
            M_reg_load  => M_reg_load,
			
			-- Source selction for the B register
            B_reg_sel   => B_reg_sel,
            
            -- Borrow signals
            borrow_1n   => borrow_1n,
            borrow_2n   => borrow_2n,
            
            -- Selection of correct calculation result
            mod_sel     => mod_sel
		);
	



end Behavioral;
