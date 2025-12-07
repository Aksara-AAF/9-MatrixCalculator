library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.matrix_pkg.all;

entity control_unit is
    port (
        clk, rst       : in std_logic;
        start          : in std_logic;
        opcode         : in std_logic_vector(3 downto 0);
        rows_A, cols_A : in integer;
        rows_B, cols_B : in integer;
        -- Out
        en_alu     : out std_logic;
        en_sys     : out std_logic;
        sys_rst    : out std_logic;
        busy       : out std_logic;
        error_code : out std_logic_vector(3 downto 0);
        -- In
        done_alu, done_sys : in std_logic
    );
end control_unit;

architecture FSM of control_unit is
    type state_t is (IDLE, CHECK_ERR, EXEC_ALU, EXEC_SYS, WAIT_SYS, FINISH);
    signal state : state_t := IDLE;
begin
    process (clk, rst)
    begin
        -- Inisialisasi output saat Reset Asynchronous
        if rst = '1' then
            state      <= IDLE;
            error_code <= "0000";
            en_alu     <= '0';
            en_sys     <= '0';
            sys_rst    <= '1'; -- Default Reset Systolic Aktif
            busy       <= '0';
            
        elsif rising_edge(clk) then
            -- Default Outputs tiap clock
            en_alu  <= '0';
            en_sys  <= '0';
            sys_rst <= '0';
            busy    <= '1';

            case state is
                when IDLE =>
                    busy    <= '0';
                    sys_rst <= '1'; -- Pastikan systolic di-reset saat idle
                    error_code <= "0000";
                    if start = '1' then
                        state <= CHECK_ERR;
                    end if;

                when CHECK_ERR =>
                    sys_rst <= '1'; -- Tahan reset
                    
                    if opcode = OP_ADD or opcode = OP_SUB then
                        if (rows_A /= rows_B) or (cols_A /= cols_B) then
                            error_code <= "0001"; state <= FINISH;
                        else state <= EXEC_ALU; end if;

                    elsif opcode = OP_MUL then
                        if cols_A /= rows_B then
                            error_code <= "0001"; state <= FINISH;
                        else state <= EXEC_SYS; end if;

                    elsif opcode = OP_DET then
                        if (rows_A /= cols_A) or (rows_A > 5) then
                            error_code <= "0001"; state <= FINISH;
                        else state <= EXEC_ALU; end if;

                    elsif opcode = OP_INVERSE then
                        if (rows_A /= cols_A) or (rows_A > 3) then
                            error_code <= "0001"; state <= FINISH;
                        else state <= EXEC_ALU; end if;

                    else
                        state <= EXEC_ALU; -- Transpose
                    end if;

                when EXEC_ALU =>
                    en_alu <= '1';
                    sys_rst <= '1';
                    if done_alu = '1' then
                        state <= FINISH;
                    end if;

                when EXEC_SYS =>
                    en_sys <= '1'; 
                    sys_rst <= '0'; -- Lepas reset systolic
                    state <= WAIT_SYS;

                when WAIT_SYS =>
                    en_sys <= '1'; -- Tahan enable tetap HIGH
                    sys_rst <= '0';
                    if done_sys = '1' then
                        state <= FINISH;
                    end if;

                when FINISH =>
                    busy <= '0';
                    sys_rst <= '1';
                    if start = '0' then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end FSM;
