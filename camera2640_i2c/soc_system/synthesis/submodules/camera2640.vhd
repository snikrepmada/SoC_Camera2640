library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity camera2640 is
  port (
    clk          : in    std_logic;
    rstn         : in    std_logic;
    capture      : in    std_logic;
    sda          : inout std_logic;
    scl          : inout std_logic;
    vsync        : in    std_logic;
    hsync        : in    std_logic;
    pclk         : in    std_logic;
    data_in      : in    std_logic_vector(7 downto 0);
    avs_address  : in    std_logic_vector(15 downto 0);
    avs_data_out : out   std_logic_vector(7 downto 0);
    avs_rd_req   : in    std_logic;
    avs_wait     : out   std_logic;
    debug        : out   std_logic_vector(3 downto 0));
end entity camera2640;

architecture rtl of camera2640 is
  component ov2640_init is
    port (
      clk    : in    std_logic;
      rstn   : in    std_logic;
      en     : in    std_logic;
      status : out   std_logic;
      sda    : inout std_logic;
      scl    : inout std_logic);
  end component ov2640_init;
  component capture_frame is
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
  end component capture_frame;
  signal init_en     : std_logic;
  signal init_status : std_logic;
  signal cap_en      : std_logic;
  signal cap_status  : std_logic_vector(1 downto 0);
  signal run_state   : integer;
begin

  U0_CAMERA2640_INIT : ov2640_init
    port map (
      clk    => clk,
      rstn   => rstn,
      en     => init_en,
      status => init_status,
      sda    => sda,
      scl    => scl);

  U1_CAPTURE_FRAME : capture_frame
    port map (
      clk          => clk,
      rstn         => rstn,
      en           => capture,
      status       => cap_status,
      vsync        => vsync,
      hsync        => hsync,
      pclk         => pclk,
      data_in      => data_in,
      avs_address  => avs_address,
      avs_data_out => avs_data_out,
      avs_rd_req   => avs_rd_req,
      avs_wait     => avs_wait);

  U2_PROGRAM_STATE : process(clk, rstn)
  begin
    if rstn = '0' then
      run_state <= 0;
    else
      if rising_edge(clk) then
        case run_state is
          when 0 =>
            init_en   <= '1';
            run_state <= 1;
          when 1 =>
            init_en <= '0';
            if init_status = '1' then
              run_state <= 2;
            else
              run_state <= 1;
            end if;
          when 2 =>
            init_en <= '0';
          when others =>
            init_en <= '0';
        end case;
      end if;
    end if;
  end process;

  debug <= cap_status & "0" & init_status;

end architecture rtl;
