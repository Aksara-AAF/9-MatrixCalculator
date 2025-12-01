library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package matrix_pkg is
    -- Definisi konstanta
    constant MAX_SIZE   : integer := 5;
    constant DATA_WIDTH : integer := 8;

    -- Matriks 5x5 ukuran max
    type matrix_5x5 is array (0 to MAX_SIZE - 1, 0 to MAX_SIZE - 1) of signed(DATA_WIDTH - 1 downto 0);

    -- Opcode
    constant OP_ADD       : std_logic_vector(3 downto 0) := "0001";
    constant OP_SUB       : std_logic_vector(3 downto 0) := "0010";
    constant OP_MUL       : std_logic_vector(3 downto 0) := "0011";
    constant OP_TRANSPOSE : std_logic_vector(3 downto 0) := "0100";
    constant OP_DET       : std_logic_vector(3 downto 0) := "0101";

end package matrix_pkg;
