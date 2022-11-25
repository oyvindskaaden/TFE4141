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
--use IEEE.std_logic_signed.all;

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
    
        -- Reset and Clock
        reset_n             : in std_logic;
        clk                 : in std_logic;

        -- Seperate MM datapath reset
        mm_reset_n          : out std_logic;
        
        -- Data valid and ready signals
        mm_data_in_valid    : in    std_logic;
        mm_data_in_ready    : out   std_logic;
        mm_data_out_valid   : out   std_logic;
        mm_data_out_ready   : in    std_logic; 

        -- Datapath control logic
        A_reg_load          : out std_logic;
        B_reg_load          : out std_logic;
        M_reg_load          : out std_logic;

        -- Source selction for the B register
        B_reg_sel           : out std_logic;

        -- Selection of correct calculation result
        mod_sel             : out std_logic_vector(1 downto 0);

        -- Borrow signals
        borrow_1n           : in std_logic;
        borrow_2n           : in std_logic
        
    );
end multi_mod_control;

architecture Behavioral of multi_mod_control is
    signal cnt_en       : std_logic;
    signal cnt_out      : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal cnt_reset_n  : std_logic;
    
    
    type state is (IDLE, SETUP, RUNNING, WAIT_OUT, DONE);
    signal curr_state, next_state : state;
    
    signal borrow       : std_logic_vector(1 downto 0);
begin

    borrow <= (borrow_1n & borrow_2n);
    
    counter : entity work.counter 
    generic map (
      COUNTER_WIDTH => COUNTER_WIDTH)
    port map (
      clk           => clk,
      reset_n       => cnt_reset_n,
      cnt_en        => cnt_en,
      y             => cnt_out
    );


    fsmComb : process(curr_state, mm_data_in_valid, cnt_out, mm_data_out_ready) begin
        case (curr_state) is
        when IDLE =>
            mm_reset_n          <= '0';
            
            cnt_en              <= '0';
            cnt_reset_n         <= '0';
            
            A_reg_load          <= '0';
            --N_reg_load          <= '0';
            M_reg_load          <= '0';
            B_reg_load          <= '0';
            
            B_reg_sel           <= '0';
            
            mm_data_out_valid   <= '0';
            mm_data_in_ready    <= '0';
            
            if(mm_data_in_valid = '1') then
                next_state      <= SETUP;
            else
                next_state      <= IDLE;
            end if;
            
            
        when SETUP => 
            mm_reset_n          <= '1';
            
            cnt_en              <= '1';
            cnt_reset_n         <= '1';
            
            A_reg_load          <= '1';
            --N_reg_load          <= '1';
            B_reg_load          <= '1';
            M_reg_load          <= '0';

            
            B_reg_sel           <= '0';
            
            mm_data_out_valid   <= '0';
            mm_data_in_ready    <= '1';

            next_state <= RUNNING;
            --if(mm_data_in_valid = '1') then
            --    next_state <= RUNNING;
            --else
            --    next_state <= IDLE;
            --end if;
           
        when RUNNING =>
            mm_reset_n          <= '1';
            
            cnt_en              <= '1';
            cnt_reset_n         <= '1';
            
            A_reg_load          <= '0';
            --N_reg_load          <= '0';
            B_reg_load          <= '1';
            M_reg_load          <= '1';
            
            B_reg_sel           <= '1';
            
            mm_data_out_valid   <= '0';
            mm_data_in_ready    <= '0';
            
         
            if (cnt_out = std_logic_vector(TO_UNSIGNED(C_block_size, 8))) then
                next_state      <= WAIT_OUT;
            else
                next_state      <= RUNNING;
            end if;
            
        when WAIT_OUT =>
            mm_reset_n          <= '1';
            
            cnt_en              <= '0';
            cnt_reset_n         <= '0';
            
            A_reg_load          <= '0';
            --N_reg_load          <= '0';
            B_reg_load          <= '0';
            M_reg_load          <= '0';
            
            B_reg_sel           <= '1';
            
            mm_data_in_ready <= '0';

            mm_data_out_valid   <= '0';
            
            next_state      <= DONE;
            
        when DONE =>
            mm_reset_n          <= '1';
            
            cnt_en              <= '1';
            cnt_reset_n         <= '1';
            
            A_reg_load          <= '0';
            --N_reg_load          <= '0';
            B_reg_load          <= '0';
            M_reg_load          <= '0';
            
            B_reg_sel           <= '1';
            
            mm_data_in_ready    <= '0';

            mm_data_out_valid   <= '1';
            
            if (mm_data_out_ready = '1') then
                next_state      <= IDLE;
            else
                next_state      <= DONE;
            end if;

        when others =>
            mm_reset_n          <= '0';
            
            cnt_en              <= '0';
            cnt_reset_n         <= '0';
            
            A_reg_load          <= '0';
            --N_reg_load          <= '0';
            M_reg_load          <= '0';
            B_reg_load          <= '0';
            
            B_reg_sel           <= '0';
            
            mm_data_out_valid   <= '0';
            mm_data_in_ready    <= '0';
            
            next_state          <= IDLE;
        
        end case;
        
    end process fsmComb;
    
    fsmSync : process(reset_n, clk) 
    begin
        if (reset_n = '0') then
            curr_state  <= IDLE;
        elsif (clk'event and clk='1') then
            curr_state  <= next_state;
        end if;
    end process fsmSync;
    
    
    process(borrow) 
    begin
        case borrow is
            when b"00" => --borrow_1n = 0, borrow_2n = 0. 2n <= res < 3n  
                mod_sel <= b"10";
            when b"01" => --borrow_1n = 0, borrow_2n = 1.  n <= res < 2n  
                mod_sel <= b"01";
            when b"11" => --borrow_1n = 1, borrow_2n = 1. res <= n  
                mod_sel <= b"00";
            when others => --borrow_1n = 1, borrow_2n = 0. Won't happen
                mod_sel <= b"11";
        end case;
    end process; 

end Behavioral;
