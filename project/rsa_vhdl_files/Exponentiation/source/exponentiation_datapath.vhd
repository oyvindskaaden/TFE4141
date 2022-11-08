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
		exponent_reg_sel  : in std_logic;
		
		-- Reg Load Control
		partial_reg_load  : in std_logic;
		chipher_reg_load  : in std_logic;
		exponent_reg_load : in std_logic;

        -- MultiMod Data in/out ready for partial block
        mm_dir_partial    : in  std_logic;
        mm_dor_partial    : out std_logic;
        
        -- MultiMod Data in/out ready for chipher block
        mm_dir_chipher    : in  std_logic;
        mm_dor_chipher    : out std_logic;
		
		-- Exponentiation values
		exponent_lsb      : out std_logic;
		exponent_is_0     : out std_logic
    );
end exponentiation_datapath;

architecture Behavioral of exponentiation_datapath is
    signal partial_reg  : std_logic_vector(C_block_size-1 downto 0);
    signal chipher_reg  : std_logic_vector(C_block_size-1 downto 0);
    signal exponent_reg : std_logic_vector(C_block_size-1 downto 0);
    
    signal partial_out  : std_logic_vector(C_block_size-1 downto 0);
    signal chipher_out  : std_logic_vector(C_block_size-1 downto 0);

begin
    u_multi_mod_partial: entity work.multi_mod
        generic map (
            C_block_size        => C_block_size
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
    
            A_in                => partial_reg,
            B_in                => partial_reg,
            N_in                => modulus,
            
            -- The following is probably wrong
            M_out               => partial_out,
    
            -- MultiMod (mm) data ready signals
            mm_data_in_ready    => mm_dir_partial,
            mm_data_out_ready   => mm_dor_partial
        );
        
    u_multi_mod_chipher: entity work.multi_mod
        generic map (
            C_block_size        => C_block_size
        )
        port map (
            clk                 => clk,
            reset_n             => reset_n,
    
            A_in                => partial_reg,
            B_in                => chipher_reg,
            N_in                => modulus,
            
            -- The following is probably wrong
            M_out               => chipher_out,
    
            -- MultiMod (mm) data ready signals
            mm_data_in_ready    => mm_dir_chipher,
            mm_data_out_ready   => mm_dor_chipher
        );
       
    result <= partial_out;
    
    -- Partial reg
    process (clk, reset_n) begin
        if (reset_n = '0') then
            partial_reg     <= (others => '0');
            
        elsif (clk'event and clk = '1' and partial_reg_load = '1') then
            -- This is also probably wrong
            if (partial_reg_sel = '1') then
                -- Set partial to message (data)
                partial_reg     <= partial_out;
            else
                partial_reg     <= message;
            end if;
        end if;
    end process;
    
    -- Chipher reg
    process (clk, reset_n) begin
        if (reset_n = '0') then
            --chipher_reg     <= std_logic_vector(to_unsigned(1, 256));
            chipher_reg     <= (others => '0');
        elsif (clk'event and clk = '1' and chipher_reg_load = '1') then
            -- This is also probably wrong
            
            if (chipher_reg_sel = '1') then
                -- Set partial to message (data)
                chipher_reg     <= chipher_out;
            else
                chipher_reg     <= std_logic_vector(to_unsigned(1, C_block_size));
            end if;           
        end if;
    end process;
    
    -- Exponent reg
    
    process (clk, reset_n) begin
        if (reset_n = '0') then
            exponent_reg    <= (others => '0');
            
        elsif (clk'event and clk = '1' and exponent_reg_load = '1') then
            if (exponent_reg_sel = '1') then
                exponent_reg    <= '0' & exponent_reg(C_block_size-1 downto 1);
            else
                exponent_reg    <= key;
            end if;
        end if;
    end process;
    
    -- Set the LSB of the exponent
    --process (exponent_reg) begin
    exponent_lsb    <= exponent_reg(0);
    --end process;
    
    -- Check if there are more bits left in the exponent
    process (exponent_reg) begin
        if (exponent_reg = std_logic_vector(to_unsigned(0, C_block_size))) then
            exponent_is_0   <= '1';
        else
            exponent_is_0   <= '0';
        end if;
        --exponent_is_0 <= exponent_reg AND std_logic_vector(to_unsigned(0, 256));
    end process;
    
    
end Behavioral;
