library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity i2cm_tb is
  generic (
    WIDTH      : integer := 32;
    CLK_PER    : time    := 20 ns;
    RST_CYCLES : integer := 1
    );
end entity i2cm_tb;

architecture tb of i2cm_tb is

  component i2cm is
    port (
      clk     : in    std_logic;
      rstn    : in    std_logic;
      addr    : in    std_logic_vector(6 downto 0);
      wr_reg  : in    std_logic_vector(7 downto 0);
      wr_data : in    std_logic_vector(7 downto 0);
      rd_reg  : in    std_logic_vector(7 downto 0);
      rd_data : out   std_logic_vector(7 downto 0);
      rw      : in    std_logic;
      en      : in    std_logic;
      busy    : out   std_logic;
      sda     : inout std_logic;
      scl     : inout std_logic);
  end component i2cm;

  signal clk     : std_logic;
  signal clk_s   : std_logic;
  signal rstn    : std_logic;
  signal addr    : std_logic_vector(6 downto 0);
  signal wr_reg  : std_logic_vector(7 downto 0);
  signal wr_data : std_logic_vector(7 downto 0);
  signal rd_reg  : std_logic_vector(7 downto 0);
  signal rd_data : std_logic_vector(7 downto 0);
  signal rw      : std_logic;
  signal en      : std_logic;
  signal busy    : std_logic;
  signal sda     : std_logic;
  signal scl     : std_logic;

begin

  UUT : i2cm
    port map (
      clk     => clk,
      rstn    => rstn,
      addr    => addr,
      wr_reg  => wr_reg,
      wr_data => wr_data,
      rd_reg  => rd_reg,
      rd_data => rd_data,
      rw      => rw,
      en      => en,
      busy    => busy,
      sda     => sda,
      scl     => scl);

  CLK_PROC : process
  begin
    clk   <= '1';
    clk_s <= '1';
    wait for CLK_PER/2;
    clk   <= '0';
    clk_s <= '0';
    wait for CLK_PER/2;
  end process;

  STIM_PROC : process
  begin
    --Initialize the signals
    rstn    <= '0';
    en      <= '0';
    addr    <= "1100000";
    rw      <= '0';
    wr_reg  <= x"ff";
    wr_data <= x"01";

    --Reset the UUT
    rstn <= '0';
    wait until rising_edge(clk_s);
    for i in 1 to RST_CYCLES loop
      wait until rising_edge(clk_s);
    end loop;  --i
    rstn <= '1';

    --Start the test
    assert false report "Starting the I2C testing..." severity note;

    --Test the signals
    en <= '1';
    wait for 1000*CLK_PER;
    en <= '0';
    wait for 20000*CLK_PER;

    --Terminate the simulation
    wait for 2000*CLK_PER;
    assert false report "Assertion to stop simulation" severity failure;
  end process;
end architecture tb;
