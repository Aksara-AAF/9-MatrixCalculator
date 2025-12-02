library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package matrix_pkg is
    -- konstanta
    constant MAX_SIZE   : integer := 5;
    constant DATA_WIDTH : integer := 8;

    -- Matriks 5x5, signed 8-bit
    type matrix_5x5 is array (0 to MAX_SIZE - 1, 0 to MAX_SIZE - 1) of signed(DATA_WIDTH - 1 downto 0);

    -- Opcode
    constant OP_ADD       : std_logic_vector(3 downto 0) := "0001";
    constant OP_SUB       : std_logic_vector(3 downto 0) := "0010";
    constant OP_MUL       : std_logic_vector(3 downto 0) := "0011";
    constant OP_TRANSPOSE : std_logic_vector(3 downto 0) := "0100";
    constant OP_DET       : std_logic_vector(3 downto 0) := "0101";
    --constant OP_INVERSE : std_logic_vector(3 downto 0) := "0110";

    -- Jika hasil > 127, setting jadi 127. Jika < -128, setting jadi -128
    function saturate(val : signed) return signed;

end package matrix_pkg;

package body matrix_pkg is
    function saturate(val : signed) return signed is
        variable res          : signed(DATA_WIDTH - 1 downto 0);
    begin

        if val > to_signed(127, val'length) then -- Jika lebih besar dari 127, mentok di 127
            res := to_signed(127, DATA_WIDTH);
        elsif val < to_signed(-128, val'length) then -- Jika lebih kecil dari -128, mentok di -128
            res := to_signed(-128, DATA_WIDTH);
        else
            res := resize(val, DATA_WIDTH); -- Jika nilai normal
        end if;
        return res;
    end function;
end package body matrix_pkg;
