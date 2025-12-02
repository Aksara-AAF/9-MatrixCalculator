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

        -- Status Signals
        en_alu     : out std_logic;
        en_sys     : out std_logic;
        sys_rst    : out std_logic;
        busy       : out std_logic;
        error_code : out std_logic_vector(3 downto 0); -- 0:OK, 1:Dimensi, 2:DetOver

        -- Feedback
        done_alu, done_sys : in std_logic
    );
end control_unit;

architecture FSM of control_unit is
    -- FSM
    type state_t is (IDLE, CHECK_ERR, EXEC_ALU, EXEC_SYS, FINISH);
    signal state : state_t := IDLE;
begin
    process (clk, rst)
    begin
        if rst = '1' then
            state      <= IDLE;
            error_code <= "0000";
        elsif rising_edge(clk) then
            -- Default Outputs
            en_alu  <= '0';
            en_sys  <= '0';
            sys_rst <= '0';
            busy    <= '1';

            case state is
                when IDLE =>
                    busy    <= '0';
                    sys_rst <= '1'; -- Reset Systolic saat idle
                    if start = '1' then
                        state <= CHECK_ERR;
                    end if;

                when CHECK_ERR =>
                    -- Microprogramming logic (Conditional Branching)
                    if opcode = OP_ADD or opcode = OP_SUB then
                        if (rows_A /= rows_B) or (cols_A /= cols_B) then
                            error_code <= "0001"; -- Error Dimensi Beda
                            state      <= FINISH;
                        else
                            state <= EXEC_ALU;
                        end if;

                    elsif opcode = OP_MUL then
                        if cols_A /= rows_B then
                            error_code <= "0001"; -- Error Syarat Kali
                            state      <= FINISH;
                        else
                            state <= EXEC_SYS;
                        end if;

                    elsif opcode = OP_DET then
                        if (rows_A /= cols_A) or (rows_A > 3) then
                            error_code <= "0010"; -- Error Bukan Persegi / Terlalu Besar
                            state      <= FINISH;
                        else
                            state <= EXEC_ALU;
                        end if;

                    else
                        state <= EXEC_ALU; -- Transpose aman
                    end if;

                when EXEC_ALU =>
                    en_alu <= '1';
                    if done_alu = '1' then
                        state <= FINISH;
                    end if;

                when EXEC_SYS =>
                    en_sys  <= '1';
                    sys_rst <= '0';
                    if done_sys = '1' then
                        state <= FINISH;
                    end if;

                when FINISH =>
                    busy <= '0';
                    if start = '0' then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end FSM;
