-----------------------------------------------------------------------------------------------------------------------------------------------------------------
--         .-+%########%+:.                                               +#######################%+:-                                                         --
--      :###################@.                                           .############@=+:.                                                                    --
--    :#########*---=#########.                                          +#@=*-.                             .-*=%###                                          --
--   *########-      *########               ..                                                             .#######:              ..                          --
--   =#########%*.             +#######-%##########:   .#######*-@####+ %#######. %#######-@##########- -###############+  .*#############%.    #######+-%####%--
--   .@###############@+-     .##########=+=########%  +##############.:#######* -#####################.%###############.-#######+--*@######+  *##############.--
--      -=#################-  =#######=      %#######..##########=***- @######@  %#######:     ########    @######=     %######-     .#######  ##########=***- --
--             -*%########## .#######=       #######@ =#######+       *#######: :#######*     *#######:   *#######.    %####################% +#######=        --
--########:        %#######@ =#######.      =#######--#######+       .#######%  @######@      #######@    #######+    -#######==============-.#######=         --
--#########+.   .*########@.-########-    .########. %#######        +#######- *#######:     *#######-   +#######-    :######%     .%######* =#######.         --
--.@####################@-  @####################:  :#######*       .#######=  #######%     .#######%    ############- %########@@#######@. -#######+          --
--   .*@############%:.    :#######+-@#######@:.    @######@        =#######. +#######-     =#######.    .%#########=   .*@##########@+.    %#######.          --
--                         ########.                                                                                                                           --
--                        *#######*                                                                                                                            --
--                       .#@%+:..                                                                                                                              --
--																																																					--
-- https://github.com/solegstar/Sprinter-VGA-HDMI-module																																			--
--																																																					--
-- FPGA firmware for Sprinter VGA Module																																								--
--																																																					--
-- @author Andy Karpov <andy.karpov@gmail.com>																																						--
-- @HDMI codec by MVV <https://github.com/mvvproject/ReVerSE-U16>																																--
-- @author Oleh Starychenko <solegstar@gmail.com>																																					--
-- Ukraine, 2021																																																--
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity Sprinter_VGA_HDMI is

port (
	-- Clocks
	TG42 			: in std_logic := '0';
	WR_COL		: in std_logic := '0';
	CLK_7125		: out std_logic := '0';
	DAC_BCK		: in std_logic := '0';
	DAC_DATA	: in std_logic := '0';
	DAC_WS		: in std_logic := '0';

	-- TV IN
	TV_R 			: in std_logic_vector(7 downto 0) := "00000000";
	TV_G 			: in std_logic_vector(7 downto 0) := "00000000";
	TV_B 			: in std_logic_vector(7 downto 0) := "00000000";
	TV_HS 		: in std_logic := '0';
	TV_VS 		: in std_logic := '0';
	TV_SYNC 		: in std_logic := '0';
	TV_nSYNC 	: out std_logic;
	TV_nBLANK 	: out std_logic;
	TV_nSYNC_IN : in std_logic := '0';
	TV_SYNC_IN 	: out std_logic;
	
	-- HDMI
	HDMI_D0		: out std_logic;
	HDMI_D1		: out std_logic;
	HDMI_D2		: out std_logic;
	HDMI_CLK		: out std_logic;
	HDMI_SCL		: in std_logic := '0';
	HDMI_SDA		: in std_logic := '0';
	HDMI_CEC		: in std_logic := '0';
	HDMI_ARC		: in std_logic := '0';
	HDMI_DET		: in std_logic := '0';

	-- VGA 
	VGA_nVGA_IN : in std_logic := '0';
	VGA_VGA_IN	: out std_logic;
	VGA_R 		: out std_logic_vector(7 downto 0);
	VGA_G 		: out std_logic_vector(7 downto 0);
	VGA_B 		: out std_logic_vector(7 downto 0);
	VGA_HS 		: out std_logic;
	VGA_VS 		: out std_logic
	);
end Sprinter_VGA_HDMI;

architecture rtl of Sprinter_VGA_HDMI is

signal CLK_PIXEL_TV	: std_logic := '0';
signal CLK_VGA			: std_logic := '0';
signal CLK_DVI			: std_logic := '0';
signal CLK_PIXEL_VGA	: std_logic := '0';
signal locked			: std_logic;
signal TV_VS_REG		: std_logic;
signal TV_HS_REG		: std_logic;
signal TV_R_REG		: std_logic_vector(7 downto 0) := "00000000";
signal TV_G_REG		: std_logic_vector(7 downto 0) := "00000000";
signal TV_B_REG		: std_logic_vector(7 downto 0) := "00000000";
signal VGA_R_REG		: std_logic_vector(7 downto 0) := "00000000";
signal VGA_G_REG		: std_logic_vector(7 downto 0) := "00000000";
signal VGA_B_REG		: std_logic_vector(7 downto 0) := "00000000";
signal VGA_BLANK		: std_logic := '0';
signal VGA_VS_O		: std_logic := '0';
signal VGA_HS_O		: std_logic := '0';

begin

-- PLL1
U1: entity work.altpll0
port map (
	inclk0			=> TG42,
	locked			=> locked,
	c0 				=> CLK_DVI,
	c1 				=> CLK_PIXEL_VGA,
	c2 				=> CLK_VGA
	);
	
-- Scandoubler	
U2: entity work.vga_pal 
port map (
	RGB_IN 				=> TV_R_REG&TV_G_REG&TV_B_REG,
	KSI_IN 				=> not TV_VS,
	SSI_IN 				=> not TV_HS,
	CLK 					=> CLK_PIXEL_TV,
	CLK2 					=> CLK_VGA,
	DS80					=> '0',		
	RGB_O(23 downto 16)	=> VGA_R_REG,
	RGB_O(15 downto 8)	=> VGA_G_REG,
	RGB_O(7 downto 0)		=> VGA_B_REG,
	VGA_BLANK_O 		=> VGA_BLANK,
	VSYNC_VGA			=> VGA_VS_O,
	HSYNC_VGA			=> VGA_HS_O
);

-- HDMI
inst_dvid: entity work.hdmi
port map(
	CLK_DVI		=> CLK_DVI,				-- clk 140mhz
	CLK_PIXEL	=> CLK_PIXEL_VGA,		-- clk 28mhz
	R				=> VGA_R_REG(0)&VGA_R_REG(1)&VGA_R_REG(2)&VGA_R_REG(3)&VGA_R_REG(4)&VGA_R_REG(5)&VGA_R_REG(6)&VGA_R_REG(7),
	G				=> VGA_G_REG(0)&VGA_G_REG(1)&VGA_G_REG(2)&VGA_G_REG(3)&VGA_G_REG(4)&VGA_G_REG(5)&VGA_G_REG(6)&VGA_G_REG(7),
	B				=> VGA_B_REG(0)&VGA_B_REG(1)&VGA_B_REG(2)&VGA_B_REG(3)&VGA_B_REG(4)&VGA_B_REG(5)&VGA_B_REG(6)&VGA_B_REG(7),
	BLANK			=> not VGA_BLANK,
	HSYNC			=> VGA_HS_O,
	VSYNC			=> VGA_VS_O,
	TMDS_D0		=> HDMI_D0,
	TMDS_D1		=> HDMI_D1,
	TMDS_D2		=> HDMI_D2,
	TMDS_CLK		=> HDMI_CLK
);

-------------------------------------------------------------------------------
-- clocks

process (CLK_VGA)
begin 
	if (CLK_VGA'event and CLK_VGA = '1') then 
		CLK_PIXEL_TV <= not(CLK_PIXEL_TV);
		TV_VS_REG <= TV_VS;
		TV_HS_REG <= TV_HS;
		TV_nSYNC <= not TV_SYNC;
		TV_SYNC_IN <= not TV_nSYNC_IN;
		VGA_VGA_IN	<= not VGA_nVGA_IN;
	end if;
end process;

process (WR_COl, TV_R, TV_G, TV_B, TV_R_REG, TV_G_REG, TV_B_REG)
begin 
	if (WR_COl'event and WR_COl = '1') then 
		TV_R_REG <= TV_R;
		TV_G_REG <= TV_G;
		TV_B_REG <= TV_B;
	end if;
end process;

process (VGA_nVGA_IN, VGA_VS_O, VGA_HS_O, VGA_BLANK, TV_VS, TV_HS, VGA_R_REG, VGA_G_REG, VGA_B_REG, TV_R_REG, TV_G_REG, TV_B_REG, CLK_VGA,
			TV_VS_REG, TV_HS_REG, CLK_PIXEL_TV) 
begin
	if (VGA_nVGA_IN = '0') then 
		VGA_VS <= VGA_VS_O;      -- кадровые синхроимпульсы для VGA
		VGA_HS <= VGA_HS_O;      -- строчные синхроимпульсы для VGA
		VGA_R <= VGA_R_REG;
		VGA_G <= VGA_G_REG;
		VGA_B <= VGA_B_REG;
		if (VGA_BLANK = '0') then
			TV_nBLANK <= '0';
		else
			TV_nBLANK <= 'Z';
		end if;
		CLK_7125 <= CLK_VGA and VGA_BLANK;
	else 
		VGA_VS <= TV_VS_REG;
		VGA_HS <= TV_HS_REG;
		TV_nBLANK <= not (TV_VS_REG or TV_HS_REG);
		VGA_R <= TV_R_REG;
		VGA_G <= TV_G_REG;
		VGA_B <= TV_B_REG;
		CLK_7125 <= not (TV_VS_REG or TV_HS_REG) and CLK_PIXEL_TV;
	end if;
end process;

end rtl;
