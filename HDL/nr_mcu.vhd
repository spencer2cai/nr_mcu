library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


--  系统有内置寄存器，作为变量使用
--  0x01  读异步某总线到mcu的R0
--  0x02  写mcu的R0到异步总线某地址
--  0x03  代码指针跳跃绝对地址
--  0x0C  代码指针跳跃绝对地址,若R0等于0
--  0x04  读内置寄存器到mcu的R0
--  0x05  写mcu的R0到内置寄存器
--  0x06  给R0寄存器赋值常数
--  0x07  R0与内置寄存器求和，结果放在R0内
--  0x08  R0与内置寄存器AND，结果放在R0内
--  0x09  R0与内置寄存器OR，结果放在R0内
--  0x0A  R0与内置寄存器XOR，结果放在R0内
--  0x0B  DELAY多少个CLK


entity nr_mcu is
generic( 
    INTER_NUM : integer := 32;  --多少个内置寄存器
    INTER_NUM_2 : integer := 5  --2的幂次方
 );
port (
    clk       : in  std_logic := '0';
    enable    : in  std_logic := '0';
    code_addr : out std_logic_vector(15 downto 0) := (others => '0');
    code_din  : in  std_logic_vector(39 downto 0) := (others => '0');
    emif_addr : out std_logic_vector(31 downto 0) := (others => '0');
    emif_wr_n : out std_logic := '0';
    emif_rd_n : out std_logic := '0';
    emif_din  : out std_logic_vector(31 downto 0) := (others => '0');
    emif_dout : in  std_logic_vector(31 downto 0) := (others => '0')
    );
end nr_mcu;

architecture Behavioral of nr_mcu is

constant EMIF_RD_CODE : std_logic_vector(7 downto 0):= x"01";
constant EMIF_WR_CODE : std_logic_vector(7 downto 0):= x"02";

constant JUMP_GO_CODE : std_logic_vector(7 downto 0):= x"11";
constant JUMP_EQ_CODE : std_logic_vector(7 downto 0):= x"12";
constant JUMP_NQ_CODE : std_logic_vector(7 downto 0):= x"13";

constant INTER_RD_CODE: std_logic_vector(7 downto 0):= x"21";
constant INTER_WR_CODE: std_logic_vector(7 downto 0):= x"22";
constant SET_R0_CODE: std_logic_vector(7 downto 0):= x"23";

constant ADD_R0_CODE: std_logic_vector(7 downto 0):= x"31";
constant AND_R0_CODE: std_logic_vector(7 downto 0):= x"32";
constant OR_R0_CODE : std_logic_vector(7 downto 0):= x"33";
constant XOR_R0_CODE: std_logic_vector(7 downto 0):= x"34";
constant SHL_R0_CODE: std_logic_vector(7 downto 0):= x"35";
constant SHR_R0_CODE: std_logic_vector(7 downto 0):= x"36";
constant SHL4_R0_CODE: std_logic_vector(7 downto 0):= x"37";
constant SHR4_R0_CODE: std_logic_vector(7 downto 0):= x"38";

constant DELAY_CODE: std_logic_vector(7 downto 0):= x"41";

constant CALLON_CODE: std_logic_vector(7 downto 0):= x"51";
constant CALLBK_CODE: std_logic_vector(7 downto 0):= x"52";


type U32_ARRAY is array (NATURAL RANGE <>) OF std_logic_vector(31 downto 0);
type state is (c_idle,c_code,c_read,c_write,c_jump,c_jumpe,c_jumpn,c_callon,c_callbk,c_iread,c_iwrite,c_setR0,
    c_addR0,c_andR0,c_orR0,c_xorR0,c_shl,c_shr,c_shl4,c_shr4,c_delay,  c_opt1,c_err);
signal c_state : state;
signal code_cnt: std_logic_vector(1 downto 0):= (others => '0'); 
signal code_opt: std_logic_vector(7 downto 0):= (others => '0'); 
signal code_data: std_logic_vector(31 downto 0):= (others => '0'); 
signal inter_reg: U32_ARRAY(INTER_NUM-1 downto 0):= (others => x"00000000"); --内置寄存器
signal inter_R0: std_logic_vector(31 downto 0):= (others => '0'); 
signal emif_read_cnt: std_logic_vector(3 downto 0):= (others => '0'); 
signal emif_wr_cnt: std_logic_vector(3 downto 0):= (others => '0'); 
signal code_addr_i: std_logic_vector(15 downto 0):= (others => '0'); 
signal code_addr_bk1: std_logic_vector(15 downto 0):= (others => '0'); 
signal code_addr_bk2: std_logic_vector(15 downto 0):= (others => '0'); 
signal code_addr_bk3: std_logic_vector(15 downto 0):= (others => '0'); 
signal code_addr_bk4: std_logic_vector(15 downto 0):= (others => '0'); 
signal delay_cnt: std_logic_vector(31 downto 0):= (others => '0'); 








begin
    
process(clk)
begin
if (clk' event and clk = '1') then
    if (enable='0') then
        c_state <= c_idle;
    else
        case (c_state) is
            when (c_idle) => 
                c_state <= c_code;
            when (c_code) =>
                if(code_cnt="11")then
                    if(code_opt=EMIF_RD_CODE)then
                        c_state <= c_read;
                    elsif(code_opt=EMIF_WR_CODE)then
                        c_state <= c_write;
                    elsif(code_opt=JUMP_GO_CODE)then
                        c_state <= c_jump;
                    elsif(code_opt=JUMP_EQ_CODE)then
                        c_state <= c_jumpe;
                    elsif(code_opt=JUMP_NQ_CODE)then
                        c_state <= c_jumpn;
                    elsif(code_opt=CALLON_CODE)then
                        c_state <= c_callon;
                    elsif(code_opt=CALLBK_CODE)then
                        c_state <= c_callbk;
                    elsif(code_opt=INTER_RD_CODE)then
                        c_state <= c_iread;
                    elsif(code_opt=INTER_WR_CODE)then
                        c_state <= c_iwrite;
                    elsif(code_opt=SET_R0_CODE)then
                        c_state <= c_setR0;
                    elsif(code_opt=ADD_R0_CODE)then
                        c_state <= c_addR0;
                    elsif(code_opt=AND_R0_CODE)then
                        c_state <= c_andR0;
                    elsif(code_opt=OR_R0_CODE)then
                        c_state <= c_orR0;
                    elsif(code_opt=XOR_R0_CODE)then
                        c_state <= c_xorR0;
                    elsif(code_opt=SHL_R0_CODE)then
                        c_state <= c_shl;
                    elsif(code_opt=SHR_R0_CODE)then
                        c_state <= c_shr;
                    elsif(code_opt=SHL4_R0_CODE)then
                        c_state <= c_shl4;
                    elsif(code_opt=SHR4_R0_CODE)then
                        c_state <= c_shr4;
                    elsif(code_opt=DELAY_CODE)then
                        c_state <= c_delay;
                    else
                        c_state <= c_err;
                    end if;
                end if;
            when (c_read) =>
                if(emif_read_cnt=x"9")then c_state <= c_opt1;end if; --读时序
            when (c_write) =>
                if(emif_wr_cnt=x"5")then c_state <= c_opt1;end if; --写时序
            when (c_jump) =>
                c_state <= c_idle;
            when (c_jumpe) =>
                c_state <= c_idle;
            when (c_jumpn) =>
                c_state <= c_idle;
            when (c_callon) =>
                c_state <= c_idle;
            when (c_callbk) =>
                c_state <= c_idle;
            when (c_iread) =>
                c_state <= c_opt1;
            when (c_iwrite) =>
                c_state <= c_opt1;
            when (c_setR0) =>
                c_state <= c_opt1;
            when (c_addR0) =>
                c_state <= c_opt1;
            when (c_andR0) =>
                c_state <= c_opt1;
            when (c_orR0) =>
                c_state <= c_opt1;
            when (c_xorR0) =>
                c_state <= c_opt1;
            when (c_shl) =>
                c_state <= c_opt1;
            when (c_shr) =>
                c_state <= c_opt1;
            when (c_shl4) =>
                c_state <= c_opt1;
            when (c_shr4) =>
                c_state <= c_opt1;
            when (c_delay) =>
                if(delay_cnt=code_data)then c_state <= c_opt1;end if;



            when (c_opt1) =>
                c_state <= c_idle;
            when (c_err) =>
                c_state <= c_err;
            when others =>
                c_state <= c_idle;
        end case;
    end if;
end if;
end process;

process(clk)
begin
if (clk' event and clk = '1') then
    if(c_state=c_code)then code_cnt <= code_cnt + '1';else code_cnt <= (others => '0'); end if;
    if(c_state=c_read)then emif_read_cnt <= emif_read_cnt + '1';else emif_read_cnt <= (others => '0'); end if;
    if(c_state=c_write)then emif_wr_cnt <= emif_wr_cnt + '1';else emif_wr_cnt <= (others => '0'); end if;
    if(c_state=c_delay)then delay_cnt <= delay_cnt + '1';else delay_cnt <= (others => '0'); end if;
end if;
end process;

process(clk)
begin
if (clk' event and clk = '1') then
    if (c_state=c_code)and(code_cnt="10") then
        code_opt <= code_din(39 downto 32);       --操作码   
        code_data <= code_din(31 downto 0);         --操作数
    end if;
end if;
end process;

process(clk)
begin
if (clk' event and clk = '1') then
    if (c_state=c_read) then
        if(emif_read_cnt=x"0")then
            emif_addr <= code_data;
            emif_wr_n <= '1';
            emif_rd_n <= '1';
            emif_din <= (others => '0'); 
        elsif(emif_read_cnt=x"1")then
            emif_rd_n <= '0';
        elsif(emif_read_cnt=x"9")then
            emif_rd_n <= '1';
        end if;
    elsif(c_state=c_write)then
        if(emif_wr_cnt=x"0")then 
            emif_addr <= code_data;
            emif_wr_n <= '1';
            emif_rd_n <= '1';
            emif_din <= inter_R0; 
        elsif(emif_wr_cnt=x"4")then
            emif_wr_n <= '0';
        elsif(emif_wr_cnt=x"5")then
            emif_wr_n <= '1';
        end if;
    else
        emif_addr <= (others => '0'); 
        emif_wr_n <= '1';
        emif_rd_n <= '1';
        emif_din <= (others => '0'); 
    end if;
end if;
end process;

process(clk)
begin
if (clk' event and clk = '1') then
    if (c_state=c_read)and(emif_read_cnt=x"9") then
        inter_R0 <= emif_dout;
    elsif(c_state=c_iread)then
        inter_R0 <= inter_reg(conv_integer(code_data(INTER_NUM_2-1 downto 0)));
    elsif(c_state=c_setR0)then
        inter_R0 <= code_data;
    elsif(c_state=c_addR0)then
        inter_R0 <= inter_reg(conv_integer(code_data(INTER_NUM_2-1 downto 0))) + inter_R0;
    elsif(c_state=c_andR0)then
        inter_R0 <= inter_reg(conv_integer(code_data(INTER_NUM_2-1 downto 0))) and inter_R0;
    elsif(c_state=c_orR0)then
        inter_R0 <= inter_reg(conv_integer(code_data(INTER_NUM_2-1 downto 0))) or inter_R0;
    elsif(c_state=c_xorR0)then
        inter_R0 <= inter_reg(conv_integer(code_data(INTER_NUM_2-1 downto 0))) xor inter_R0;
    elsif(c_state=c_shl)then
        inter_R0 <= inter_R0(30 downto 0) & '0';
    elsif(c_state=c_shr)then
        inter_R0 <= '0' & inter_R0(31 downto 1);
    elsif(c_state=c_shl4)then
        inter_R0 <= inter_R0(27 downto 0) & "0000";
    elsif(c_state=c_shr4)then
        inter_R0 <= "0000" & inter_R0(31 downto 4);
    end if;
end if;
end process;

process(clk)
begin
if (clk' event and clk = '1') then
    if (c_state=c_iwrite) then
        inter_reg(conv_integer(code_data(INTER_NUM_2-1 downto 0))) <= inter_R0; 
    end if;
end if;
end process;

process(clk)
begin
if (clk' event and clk = '1') then
    if (enable='0') then
        code_addr_i <= (others => '0'); 
    elsif(c_state=c_opt1)then
        code_addr_i <= code_addr_i + '1';
    elsif(c_state=c_jump)then
        code_addr_i <= code_data(15 downto 0);       
    elsif(c_state=c_jumpe)then
        if(inter_R0=x"00000000")then 
            code_addr_i <= code_data(15 downto 0); 
        else  
            code_addr_i <= code_addr_i + '1';
        end if;
    elsif(c_state=c_jumpn)then
        if(inter_R0/=x"00000000")then 
            code_addr_i <= code_data(15 downto 0); 
        else  
            code_addr_i <= code_addr_i + '1';
        end if;
    elsif(c_state=c_callon)then
        code_addr_i <= code_data(15 downto 0);   --增加一个跳转堆栈
        code_addr_bk1 <= code_addr_i + '1';
        code_addr_bk2 <= code_addr_bk1;
        code_addr_bk3 <= code_addr_bk2;
        code_addr_bk4 <= code_addr_bk3;
    elsif(c_state=c_callbk)then
        code_addr_i <= code_addr_bk1;
        code_addr_bk1 <= code_addr_bk2;
        code_addr_bk2 <= code_addr_bk3;
        code_addr_bk3 <= code_addr_bk4;
    end if;
end if;
end process;

code_addr <= code_addr_i;



end Behavioral;
