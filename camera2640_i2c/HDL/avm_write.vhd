library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity avm_write is
  generic (
    DATAWIDTH       : integer := 32;
    BYTEENABLEWIDTH : integer := 4;
    ADDRESSWIDTH    : integer := 32;
    FIFODEPTH       : integer := 32;
    FIFODEPTH_LOG2  : integer := 5;
    FIFOUSEMEMORY   : integer := 1
  );
  port (
    --Clock and reset
    clk  : in std_logic;
    rstn : in std_logic;
    --Control inputs and outputs
    control_fixed_location : in  std_logic;
    control_write_base     : in  std_logic_vector(ADDRESSWIDTH-1 downto 0);
    control_write_length   : in  std_logic_vector(ADDRESSWIDTH-1 downto 0);
    control_go             : in  std_logic;
    control_done           : out std_logic;
    --Logic inputs and outputs
    user_write_buffer : in  std_logic;
    user_buffer_data  : in  std_logic_vector(DATAWIDTH-1 downto 0);
    user_buffer_full  : out std_logic;
    --Master inputs and outputs
    master_address     : out std_logic_vector(ADDRESSWIDTH-1 downto 0);
    master_write       : out std_logic;
    master_byteenable  : out std_logic_vector(BYTEENABLEWIDTH-1 downto 0);
    master_writedata   : out std_logic_vector(DATAWIDTH-1 downto 0);
    master_waitrequest : in  std_logic
  );
end avm_write;

architecture rtl of avm_write is
  component scfifo
  generic (
    add_ram_output_register : string;
    intended_device_family  : string;
    lpm_numwords            : integer;
    lpm_showahead           : string;
    lpm_type                : string;
    lpm_width               : integer;
    lpm_widthu              : integer;
    overflow_checking       : string;
    underflow_checking      : string;
    use_eab                 : string
  );
  port (
    clock : in  std_logic;
    aclr  : in  std_logic;
    data  : in  std_logic_vector(31 downto 0);
    full  : out std_logic;
    empty : out std_logic;
    q     : out std_logic_vector(31 downto 0);
    rdreq : in  std_logic;
    wrreq : in  std_logic
  );
  end component;
  signal control_fixed_location_d1 : std_logic;
  signal control_done_s            : std_logic;
  signal address                   : std_logic_vector(ADDRESSWIDTH-1 downto 0);
  signal length                    : std_logic_vector(ADDRESSWIDTH-1 downto 0);
  signal increment_address         : std_logic;
  signal read_fifo                 : std_logic;
  signal user_buffer_empty         : std_logic;
  function FIFOUSEEAB ( FIFOUSEMEMORY : integer ) return string is
  begin
    if (FIFOUSEMEMORY = 1) then
        return "ON";
    else
        return "OFF";
    end if ;
  end function FIFOUSEEAB;
begin
  --Registering the control_fixed_location_d1
  U1_PROC: process(clk,rstn)
  begin
    if (rstn='0') then
      control_fixed_location_d1 <= '0';
    else
      if (rising_edge(clk)) then
        if (control_go='1') then
          control_fixed_location_d1 <= control_fixed_location;
        end if;
      end if;
    end if;
  end process;
  --Master word increment counter
  U2_PROC: process(clk,rstn)
  begin
    if (rstn='0') then
      address <= (others => '0');
    else
      if (rising_edge(clk)) then
        if (control_go='1') then
          address <= control_write_base;
        else
          if ((increment_address='1') and (control_fixed_location_d1='0')) then
            address <= address + BYTEENABLEWIDTH;
          end if;
        end if;
      end if;
    end if;
  end process;
  --Master length logic
  U3_PROC: process(clk,rstn)
  begin
    if (rstn='0') then
      length <= (others => '0');
    else
      if (rising_edge(clk)) then
        if (control_go='1') then
          length <= control_write_length;
        else
          if (increment_address='1') then
            length <= length - BYTEENABLEWIDTH;
          end if;
        end if;
      end if;
    end if;
  end process;
  --Single clock FIFO
  U4_SCFIFO: scfifo
  generic map (
    add_ram_output_register => "OFF",
    intended_device_family => "Cyclone V",
    lpm_numwords => FIFODEPTH,
    lpm_showahead => "ON",
    lpm_type => "scfifo",
    lpm_width => DATAWIDTH,
    lpm_widthu => FIFODEPTH_LOG2,
    overflow_checking => "OFF",
    underflow_checking => "OFF",
    use_eab => FIFOUSEEAB(FIFOUSEMEMORY)
  )
  port map (
    clock => clk,
    aclr  => rstn,
    data  => user_buffer_data,
    full  => user_buffer_full,
    empty => user_buffer_empty,
    q     => master_writedata,
    rdreq => read_fifo,
    wrreq => user_write_buffer
  );
  --Controlled signals going to the master/control ports
  master_address <= address;
  master_byteenable <= (others => '1');
  control_done_s <= '1' when (length = 0) else '0';
  control_done <= control_done_s;
  master_write <= '1' when ((user_buffer_empty='0') and (control_done_s='0')) else '0';
  increment_address <= '1' when ((user_buffer_empty='0') and (master_waitrequest='0') and (control_done_s='0')) else '0';
  read_fifo <= increment_address;
end rtl;
