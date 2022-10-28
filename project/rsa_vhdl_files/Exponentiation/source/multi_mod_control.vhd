----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/18/2022 11:26:16 AM
-- Design Name: 
-- Module Name: multi_mod_control - Behavioral
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
use IEEE.std_logic_signed.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multi_mod_control is
    generic (
		C_block_size : integer := 256;
		COUNTER_WIDTH : integer := 8
	);
    Port (
    
        mm_data_in_ready    : in std_logic;     
        mm_data_out_ready   : out std_logic;     

        -- Datapath control logic
        A_reg_load  : out std_logic;
        B_reg_load  : out std_logic;
        M_reg_load  : out std_logic;
        N_reg_load  : out std_logic;

        B_reg_sel   : out std_logic;

        mod_sel     : out std_logic_vector(1 downto 0);

        -- Borrow signals
        borrow_1n   : in std_logic;
        borrow_2n   : in std_logic;

        -- Reset and Clock
        reset_n     : in std_logic;
        clk         : in std_logic
    );
end multi_mod_control;

architecture Behavioral of multi_mod_control is
    signal cnt_en       : std_logic;
    signal cnt_out      : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal cnt_reset_n  : std_logic;
    
    
    type state is (IDLE, SETUP, RUNNING, DONE);
    signal curr_state, next_state : state;
begin

    counter : entity work.counter 
    generic map (
      COUNTER_WIDTH => COUNTER_WIDTH)
    port map (
      clk           => clk,
      reset_n       => cnt_reset_n,
      cnt_en        => cnt_en,
      y             => cnt_out);


    A_reg_load <= mm_data_in_ready;
    N_reg_load <= mm_data_in_ready;
    

    process(mm_data_in_ready, cnt_out) begin
        if(mm_data_in_ready = '1') then
            cnt_reset_n <= '0';
            
            if(cnt_out = 255) then
                cnt_en <= '0';
            else
                cnt_en <= '1';
            end if;
        else
            cnt_en <= '0';
            cnt_reset_n <= '1';
            
        end if; 

    end process;


    fsmComb : process(curr_state) begin
        case (curr_state) is
        when IDLE =>
            cnt_en <= '0';
            cnt_reset_n <= '0';
            
            
            if(mm_data_in_ready = '1') then
                next_state <= RUNNING;
            else
                next_state <= IDLE;
            end if;
        when RUNNING =>
            cnt_en <= '1';
            cnt_reset_n <= '1';
            
            if(cnt_out = 255) then
                next_state <= DONE;
            else
                next_state <= RUNNING;
            end if;
            
        when DONE =>
            cnt_en <= '0';
            cnt_reset_n <= '0';
            
            next_state <= IDLE;
        
    end process;

end Behavioral;
