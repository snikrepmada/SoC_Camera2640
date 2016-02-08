library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity capture_frame is
  port (
    clk          : in  std_logic;
    rstn         : in  std_logic;
    en           : in  std_logic;
    status       : out std_logic_vector(1 downto 0);
    vsync        : in  std_logic;
    hsync        : in  std_logic;
    pclk         : in  std_logic;
    data_in      : in  std_logic_vector(7 downto 0);
    avs_address  : in  std_logic_vector(15 downto 0);
    avs_data_out : out std_logic_vector(7 downto 0);
    avs_rd_req   : in  std_logic;
    avs_wait     : out std_logic);
end entity capture_frame;

architecture rtl of capture_frame is
  component altera_edge_detector is
    generic (
      PULSE_EXT             : integer;
      EDGE_TYPE             : integer;
      IGNORE_RST_WHILE_BUSY : integer);
    port (
      clk       : in  std_logic;
      rst_n     : in  std_logic;
      signal_in : in  std_logic;
      pulse_out : out std_logic);
  end component altera_edge_detector;
  component frame_ram is
    port (
      data      : in  std_logic_vector (7 downto 0);
      rdaddress : in  std_logic_vector (15 downto 0);
      rdclock   : in  std_logic;
      wraddress : in  std_logic_vector (15 downto 0);
      wrclock   : in  std_logic := '1';
      wren      : in  std_logic := '0';
      q         : out std_logic_vector (7 downto 0));
  end component frame_ram;
  signal vsync_start : std_logic;
  signal vsync_end   : std_logic;
  signal pclk_en     : std_logic;
  signal pclk_cnt    : std_logic_vector(15 downto 0);
  signal p_cnt       : std_logic_vector(15 downto 0);
  signal rd_addr     : std_logic_vector(15 downto 0);
  signal wr_addr     : std_logic_vector(15 downto 0);
  signal ram_rw      : std_logic;
  signal capture     : std_logic;
  signal en_p        : std_logic;
  signal frame_state : integer;
begin
  U0_CAPTURE : altera_edge_detector
    generic map (
      PULSE_EXT             => 0,
      EDGE_TYPE             => 0,
      IGNORE_RST_WHILE_BUSY => 0)
    port map (
      clk       => clk,
      rst_n     => rstn,
      signal_in => en,
      pulse_out => en_p);

  U0_VSYNC_START : altera_edge_detector
    generic map (
      PULSE_EXT             => 0,
      EDGE_TYPE             => 1,
      IGNORE_RST_WHILE_BUSY => 0)
    port map (
      clk       => clk,
      rst_n     => rstn,
      signal_in => vsync,
      pulse_out => vsync_start);

  U1_VSYNC_END : altera_edge_detector
    generic map (
      PULSE_EXT             => 0,
      EDGE_TYPE             => 0,
      IGNORE_RST_WHILE_BUSY => 0)
    port map (
      clk       => clk,
      rst_n     => rstn,
      signal_in => vsync,
      pulse_out => vsync_end);

  U2_START_FRAME : process(clk, rstn)
  begin
    if rstn = '0' then
      frame_state <= 0;
      capture     <= '0';
      status      <= "00";
    else
      if rising_edge(clk) then
        case frame_state is
          when 0 =>
            capture <= '0';
            status  <= "01";
            if en_p = '1' then
              frame_state <= 1;
            else
              frame_state <= 0;
            end if;
          when 1 =>
            capture <= '0';
            status  <= "10";
            if vsync_start = '1' then
              frame_state <= 2;
            else
              frame_state <= 1;
            end if;
          when 2 =>
            capture <= '1';
            status  <= "10";
            if vsync_end = '1' then
              frame_state <= 3;
            else
              frame_state <= 2;
            end if;
          when 3 =>
            capture <= '0';
            status  <= "11";
          when others =>
            capture <= '0';
            status  <= "00";
        end case;
      end if;
    end if;
  end process;

  U3_PCLK_CNT : process(rstn, pclk_en, pclk)
  begin
    if rstn = '0' then
      pclk_cnt <= (others => '0');
      p_cnt    <= (others => '0');
    else
      if pclk_en = '1'then
        if rising_edge(pclk) then
          pclk_cnt <= std_logic_vector(unsigned(pclk_cnt) + to_unsigned(1, 16));
          p_cnt    <= std_logic_vector(unsigned(p_cnt) + to_unsigned(1, 16));
        end if;
      else
        pclk_cnt <= (others => '0');
      end if;
    end if;
  end process;

  wr_addr <= p_cnt;

  U4_FRAME_RAM : frame_ram
    port map (
      data      => data_in,
      rdaddress => avs_address,
      rdclock   => clk,
      wraddress => wr_addr,
      wrclock   => pclk,
      wren      => ram_rw,
      q         => avs_data_out);

  ram_rw   <= vsync and hsync and capture;
  pclk_en  <= vsync and hsync and capture;
  avs_wait <= '1' when (vsync and hsync and capture and avs_rd_req) = '1' else '0';

end architecture rtl;
