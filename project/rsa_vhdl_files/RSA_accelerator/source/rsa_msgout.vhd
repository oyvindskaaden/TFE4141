--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--   The purpose of this unit is to serialize a 256 bit message on to an
--   32-bit wide AXI stream interface.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rsa_msgout is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256;

		-- Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		C_M_AXIS_TDATA_WIDTH  : integer := 32;
		-- Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		C_M_START_COUNT       : integer := 32
	);
	port (

		-- Global ports
		M_AXIS_ACLK : in std_logic;
		--
		M_AXIS_ARESETN  : in std_logic;
		-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted.
		M_AXIS_TVALID   : out std_logic;
		-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		M_AXIS_TDATA    : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		-- TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		M_AXIS_TSTRB    : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_AXIS_TLAST    : out std_logic;
		-- TREADY indicates that the slave can accept a transfer in the current cycle.
		M_AXIS_TREADY   : in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgout_ready             : out std_logic;
		-- Message that will be sent in to the rsa_msgout module
		msgout_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last              :  in std_logic
	);
end rsa_msgout;

architecture rtl of rsa_msgout is
	-- Number of chunks needed to form a message of C_BLOCK_SIZE bits.
	constant C_CHUNK_SIZE        : integer := C_M_AXIS_TDATA_WIDTH;
	constant MSG_BUFLEN          : integer := C_BLOCK_SIZE/C_CHUNK_SIZE;

	signal msgbuf_r              : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
	signal msgbuf_nxt            : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
	signal msgbuf_slot_valid_r   : std_logic_vector(MSG_BUFLEN-1 downto 0);
	signal msgbuf_slot_valid_nxt : std_logic_vector(MSG_BUFLEN-1 downto 0);
	signal msgbuf_en             : std_logic;
	signal msgbuf_last_nxt       : std_logic_vector(MSG_BUFLEN-1 downto 0);
	signal msgbuf_last_r         : std_logic_vector(MSG_BUFLEN-1 downto 0);
	signal msgbuf_empty          : std_logic;
	signal msgbuf_one_chunk_left : std_logic;

	signal output_message        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
	signal msgout_accept         : std_logic;
	signal msgout_ready_i        : std_logic;

	signal m_axis_accept         : std_logic;
	signal m_axis_tvalid_i       : std_logic;


begin
	--------------------------------------------------------------------------------
	-- Store incoming messages. These messages are loaded into a wide 256 bit
	-- register and then sent out on a 32-bit AXI stream interface.
	--------------------------------------------------------------------------------
	process(M_AXIS_ARESETN, M_AXIS_ACLK)
	begin
		if(M_AXIS_ARESETN='0')then
			-- Reset the message buffer and all flags
			msgbuf_r              <= (others => '0');
			msgbuf_slot_valid_r   <= (others => '0');
			msgbuf_last_r         <= (others => '0');
		elsif(M_AXIS_ACLK'event and M_AXIS_ACLK='1') then
			if(msgbuf_en = '1') then
				msgbuf_r            <= msgbuf_nxt;
				msgbuf_slot_valid_r <= msgbuf_slot_valid_nxt;
				msgbuf_last_r       <= msgbuf_last_nxt;
			end if;
		end if;
	end process;

 process(msgbuf_r, m_axis_accept, msgout_accept, msgout_data, msgout_last, msgbuf_slot_valid_r, msgbuf_last_r)
		variable data_accepted: std_logic_vector(1 downto 0);
		constant C_CHUNK_WITH_ZEROS : std_logic_vector(C_CHUNK_SIZE-1 downto 0) := (others => '0');
	begin
		data_accepted := (msgout_accept & m_axis_accept);
		case(data_accepted) is

			-- New message accepted but no message sent out
			-- Store the incoming message and mark all slots as valid
			-- Capture the last flag if it is set and ensure the last flag will be
			-- set for the last 32-bit chunk.
			when "10" =>
				msgbuf_nxt            <= msgout_data;
				msgbuf_slot_valid_nxt <= (others => '1');
				msgbuf_last_nxt       <= ((MSG_BUFLEN-1) => msgout_last, others => '0');

			-- No new message is sent in but a chunk is sent out on the
			-- stream interface.
			-- Shift data and all flags
			when "01" =>
				msgbuf_nxt            <= C_CHUNK_WITH_ZEROS & msgbuf_r(C_BLOCK_SIZE-1 downto C_CHUNK_SIZE);
				msgbuf_slot_valid_nxt <= '0' & msgbuf_slot_valid_r(MSG_BUFLEN-1 downto 1);
				msgbuf_last_nxt       <= '0' & msgbuf_last_r(MSG_BUFLEN-1 downto 1);

			-- New message in and a chunk is sent out
			-- Load in a new message
			when "11" =>
				msgbuf_nxt            <= msgout_data;
				msgbuf_slot_valid_nxt <= (others => '1');
				msgbuf_last_nxt       <= ((MSG_BUFLEN-1) => msgout_last, others => '0');

			-- Neither new message accepted nor any chunk sent out
			-- Do not change the data or the flags
			when others => --when "00" =>
				msgbuf_nxt            <= msgbuf_r;
				msgbuf_slot_valid_nxt <= msgbuf_slot_valid_r;
				msgbuf_last_nxt       <= msgbuf_last_r;

		end case;
	end process;

	-- The message buffer must be updated every cycle a new message is accepted or
	-- a new chunk is sent out on the axi stream interface.
	msgbuf_en <= m_axis_accept or msgout_accept;

	--------------------------------------------------------------------------------
	-- Generate control signals
	--------------------------------------------------------------------------------
	-- We can accept a new message if all the chunks from the previous message
	-- has already been serialized on to the axi stream interface.
	msgbuf_empty          <= not msgbuf_slot_valid_r(0);
	msgbuf_one_chunk_left <= (not msgbuf_slot_valid_r(1)) and msgbuf_slot_valid_r(0);

	msgout_ready_i        <= msgbuf_empty or (msgbuf_one_chunk_left and m_axis_tready);
	msgout_accept         <= msgout_ready_i and msgout_valid;
	msgout_ready          <= msgout_ready_i;

	M_AXIS_TLAST          <= msgbuf_last_r(0);
	M_AXIS_TDATA          <= msgbuf_r(C_CHUNK_SIZE-1 downto 0);
	m_axis_tvalid_i       <= msgbuf_slot_valid_r(0);
	M_AXIS_TVALID         <= m_axis_tvalid_i;
	m_axis_accept         <= m_axis_tvalid_i and M_AXIS_TREADY;
	-- Send only data bytes
	M_AXIS_TSTRB          <= (others => '1');

end rtl;
