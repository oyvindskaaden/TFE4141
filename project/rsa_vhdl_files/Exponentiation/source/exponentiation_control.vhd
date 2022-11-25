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
    port (
        -- Clock and Reset
        clk                 : in    std_logic;
        reset_n             : in    std_logic;

        --input controll
        valid_in	        : in    std_logic;
        ready_in	        : out   std_logic;
        
        --ouput controll
        ready_out	        : in    std_logic;
        valid_out	        : out   std_logic;
        
        -- Reg Control
        partial_reg_sel     : out   std_logic;
        chipher_reg_sel     : out   std_logic;
        exponent_reg_sel    : out   std_logic;
        
        -- Reg Load Control
        partial_reg_load    : out   std_logic;
        chipher_reg_load    : out   std_logic;
        exponent_reg_load   : out   std_logic;

        -- MultiMod Data in/out ready for partial block
        mm_div_partial      : out   std_logic;
        mm_dir_partial      : in    std_logic;
        mm_dov_partial      : in    std_logic;
        mm_dor_partial      : out   std_logic;

        -- MultiMod Data in/out ready for chipher block		
		mm_div_chipher      : out   std_logic;
        mm_dir_chipher      : in    std_logic;
        mm_dov_chipher      : in    std_logic;
        mm_dor_chipher      : out   std_logic;
        
        -- Seperate MM Reset
        mm_reset_n          : out   std_logic;

        -- Exponentiation data
        exponent_lsb        : in std_logic;
        exponent_is_0       : in std_logic
    );
end exponentiation_control;

architecture Behavioral of exponentiation_control is
    type state is (IDLE, SETUP, MULTIMOD, MULTIMOD_SETUP, RUNNING, OUT_WAIT, DONE);
    signal curr_state, next_state   : state;
begin
    --expFSM: process (curr_state, valid_in, exponent_lsb, exponent_is_0, mm_dor_partial, mm_dor_chipher, ready_out) begin
    expFSM: process (curr_state, valid_in, mm_dir_partial, mm_dir_chipher, mm_dov_partial, mm_dov_chipher, exponent_lsb, exponent_is_0, ready_out) begin
        case (curr_state) is
        when IDLE       =>
            partial_reg_sel     <= '0';
            chipher_reg_sel     <= '0';
            exponent_reg_sel    <= '0';

            partial_reg_load    <= '0';
            chipher_reg_load    <= '0';
            exponent_reg_load   <= '0';
            
            ready_in            <= '0';
            valid_out           <= '0';
            
            mm_div_partial      <= '0';
            mm_div_chipher      <= '0';
            
            mm_dor_partial      <= '0';
            mm_dor_chipher      <= '0';
            
            mm_reset_n          <= '0';

            
            if (valid_in = '1') then
                next_state      <= SETUP;
            else
                next_state      <= IDLE;
            end if;
            
        when SETUP      =>
            partial_reg_sel     <= '0';
            chipher_reg_sel     <= '0';
            exponent_reg_sel    <= '0';

            partial_reg_load    <= '1';
            chipher_reg_load    <= '1';
            exponent_reg_load   <= '1';
            
            ready_in            <= '1';
            valid_out           <= '0';
            
            mm_div_partial      <= '1';
            mm_div_chipher      <= '1';
            
            mm_dor_partial      <= '0';
            mm_dor_chipher      <= '0';
            
            mm_reset_n          <= '0';

            
            next_state          <= MULTIMOD_SETUP;
        
        when MULTIMOD_SETUP =>
            
            partial_reg_sel     <= '1';
            chipher_reg_sel     <= '1';
            exponent_reg_sel    <= '1';

            partial_reg_load    <= '0';
            chipher_reg_load    <= '0';
            exponent_reg_load   <= '0';
            
            mm_dor_partial      <= '0';
            mm_dor_chipher      <= '0';
            
            mm_div_partial      <= '1';
            mm_div_chipher      <= '1';
            
            
            ready_in            <= '0';
            valid_out           <= '0';
            
            mm_reset_n          <= '1';

            
            if (mm_dir_partial = '1' and mm_dir_chipher = '1') then
                next_state      <= MULTIMOD;
            else
                next_state      <= MULTIMOD_SETUP;
            end if;
            
        when MULTIMOD   => 
            partial_reg_sel     <= '1';
            chipher_reg_sel     <= '1';
            exponent_reg_sel    <= '1';

            partial_reg_load    <= '0';
            chipher_reg_load    <= '0';
            exponent_reg_load   <= '0';
            
            mm_div_partial      <= '0';
            mm_div_chipher      <= '0';
            
            mm_dor_partial      <= '0';
            mm_dor_chipher      <= '0';
            
            
            mm_reset_n          <= '1';
            
            ready_in            <= '0';
            valid_out           <= '0';
            
            if ((mm_dov_partial = '1') and (mm_dov_chipher = '1')) then
                next_state      <= RUNNING;
            else
                next_state      <= MULTIMOD;
            end if;
        
        
        when RUNNING    =>
            partial_reg_sel     <= '1';
            chipher_reg_sel     <= '1';
            exponent_reg_sel    <= '1';

            partial_reg_load    <= '1';
            --chipher_reg_load    <= '1';
            exponent_reg_load   <= '1';
            
            ready_in            <= '0';
            valid_out           <= '0';
            
            mm_div_partial      <= '0';
            mm_div_chipher      <= '0';
            
            mm_dor_partial      <= '1';
            mm_dor_chipher      <= '1';
            
            --mm_reset_n          <= '0';
            mm_reset_n          <= '1';
            
            if(exponent_lsb = '1') then
                chipher_reg_load    <= '1';
            else
                chipher_reg_load    <= '0';
            end if;
            
            if(exponent_is_0 = '1') then
                next_state      <= OUT_WAIT;
            else
                next_state      <= MULTIMOD_SETUP;
            end if;
                        
        
        when OUT_WAIT   =>
            partial_reg_sel     <= '0';
            chipher_reg_sel     <= '0';
            exponent_reg_sel    <= '0';

            partial_reg_load    <= '0';
            chipher_reg_load    <= '0';
            exponent_reg_load   <= '0';
            
            valid_out           <= '0';
            ready_in            <= '0';
            
            mm_div_partial      <= '0';
            mm_div_chipher      <= '0';
            
            mm_dor_partial      <= '0';
            mm_dor_chipher      <= '0';
            
            mm_reset_n          <= '1';
            --mm_reset_n          <= '0';

            next_state          <= DONE;
        when DONE       =>
            
            partial_reg_sel     <= '0';
            chipher_reg_sel     <= '0';
            exponent_reg_sel    <= '0';

            partial_reg_load    <= '0';
            chipher_reg_load    <= '0';
            exponent_reg_load   <= '0';
            
            valid_out           <= '1';
            ready_in            <= '0';
            
            mm_div_partial      <= '0';
            mm_div_chipher      <= '0';
            
            mm_dor_partial      <= '0';
            mm_dor_chipher      <= '0';
            
            
            mm_reset_n          <= '1';

        
            if(ready_out = '1') then
                next_state      <= IDLE;
            else
                next_state      <= DONE;
                
            end if;
            
        when others => 
            partial_reg_sel     <= '0';
            chipher_reg_sel     <= '0';
            exponent_reg_sel    <= '0';

            partial_reg_load    <= '0';
            chipher_reg_load    <= '0';
            exponent_reg_load   <= '0';
            
            ready_in            <= '0';
            valid_out           <= '0';
            
            mm_div_partial      <= '0';
            mm_div_chipher      <= '0';
            
            mm_dor_partial      <= '0';
            mm_dor_chipher      <= '0';
            
            mm_reset_n          <= '0';
        
            next_state          <= IDLE;     
        end case;
     end process;
     
     expSyncFSM: process (clk, reset_n) begin
        if (reset_n = '0') then
            curr_state  <= IDLE;
        elsif (clk'event and clk='1') then
            curr_state  <= next_state;
        else
            null;
        end if;
    end process;
    
end Behavioral;
