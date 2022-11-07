----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2022 12:45:02
-- Design Name: 
-- Module Name: exponentiation_control - Behavioral
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

entity exponentiation_control is
    generic (
		C_block_size : integer := 256
	);
    port (
        -- Clock and Reset
        clk         : in    std_logic;
        reset_n     : in    std_logic;
        
        --input controll
        valid_in	: in    std_logic;
        ready_in	: out   std_logic;
        
        --ouput controll
        ready_out	: in    std_logic;
        valid_out	: out   std_logic;
        
        partial_reg_sel     : out std_logic;
        chipher_reg_sel     : out std_logic;
        exponent_reg_sel    : out std_logic;
        
        partial_reg_load    : out std_logic;
        chipher_reg_load    : out std_logic;
        exponent_reg_load   : out std_logic;

        -- MultiMod Data in/out ready for partial block
        mm_dir_partial      : out std_logic;
        mm_dor_partial      : in std_logic;
        
        -- MultiMod Data in/out ready for chipher block
        mm_dir_chipher      : out std_logic;
        mm_dor_chipher      : in std_logic;
        
        exponent_lsb        : in std_logic;
        exponent_is_0       : in std_logic
    );
end exponentiation_control;

architecture Behavioral of exponentiation_control is
    type state is (IDLE, SETUP, MULTIMOD, RUNNING, DONE);
    signal curr_state, next_state   : state;
begin

    expFSM: process (exponent_lsb) begin
        case (curr_state) is
            when IDLE       =>
                partial_reg_sel   <= '0';
                chipher_reg_sel   <= '0';
                exponent_reg_sel  <= '0';

                partial_reg_load  <= '0';
                chipher_reg_load  <= '0';
                exponent_reg_load <= '0';
                
                ready_in <= '0';
                valid_out <= '0';
                
                mm_dir_partial <= '0';
                mm_dir_chipher <= '0';

                
                if (valid_in) then
                    next_state <= SETUP;
                end if;
                
            when SETUP      =>
                partial_reg_sel   <= '0';
                chipher_reg_sel   <= '0';
                exponent_reg_sel  <= '0';

                partial_reg_load  <= '1';
                chipher_reg_load  <= '1';
                exponent_reg_load <= '1';
                
                ready_in <= '1';
                valid_out <= '0';
                
                mm_dir_partial <= '0';
                mm_dir_chipher <= '0';
                
                next_state <= MULTIMOD;
            
            when RUNNING    =>
                partial_reg_sel   <= '1';
                chipher_reg_sel   <= '1';
                exponent_reg_sel  <= '1';

                partial_reg_load  <= '1';
                chipher_reg_load  <= '1';
                exponent_reg_load <= '1';
                
                ready_in <= '0';
                valid_out <= '0';
                
                mm_dir_partial <= '0';
                mm_dir_chipher <= '0';
                
                if(exponent_is_0 = '1') then
                    next_state <= DONE;
                else
                    next_state <= MULTIMOD;
                end if;
                            
            when MULTIMOD   => 
                partial_reg_sel   <= '1';
                chipher_reg_sel   <= '1';
                exponent_reg_sel  <= '1';

                partial_reg_load  <= '0';
                chipher_reg_load  <= '0';
                exponent_reg_load <= '0';
                
                mm_dir_partial <= '1';
                mm_dir_chipher <= '1';
                
                ready_in <= '0';
                valid_out <= '0';
                
                if (mm_dor_partial = '1' and mm_dor_chipher = '1') then
                    next_state <= RUNNING;
                else
                    next_state <= MULTIMOD;
                end if;
            

            when DONE       =>
                
                partial_reg_sel   <= '0';
                chipher_reg_sel   <= '0';
                exponent_reg_sel  <= '0';

                partial_reg_load  <= '0';
                chipher_reg_load  <= '0';
                exponent_reg_load <= '0';
                
                valid_out <= '1';
                ready_in <= '0';
                
                mm_dir_partial <= '0';
                mm_dir_chipher <= '0';
            
                if(ready_out = '1') then
                    next_state <= IDLE;
                else
                    next_state <= DONE;
                    
                end if;
                
        end case;
     end process;
     
     expSyncFSM: process (clk, reset_n) begin
        if (reset_n = '0') then
          curr_state <= IDLE;
        elsif rising_edge(clk) then
          curr_state <= next_state;
        end if;
    end process;
    
end Behavioral;
