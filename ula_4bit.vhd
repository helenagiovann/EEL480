library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ula_4bit is
	port (
    	clk   : in  std_logic;
    	reset : in  std_logic;
    	btn   : in  std_logic;
    	sw	: in  std_logic_vector(3 downto 0);
    	-- MUDANÇA: A saída agora tem 8 bits para resultado + flags
    	led   : out std_logic_vector(7 downto 0)
	);
end entity;

architecture rtl of ula_4bit is

	component db_fsm is
    	port ( clk: in std_logic; reset: in std_logic; sw: in std_logic; db: out std_logic );
	end component;

	-- Sinais da FSM e de controle
	signal btn_db     	: std_logic;
	signal btn_db_ff  	: std_logic := '0';
	signal btn_press_edge : std_logic;
	type state_type is (s_choose_op, s_load_a, s_load_b, s_show_result);
	signal state : state_type := s_choose_op;

	-- Registradores e resultados
	signal op_code  	: std_logic_vector(3 downto 0) := "0000";
	signal reg_a, reg_b : unsigned(3 downto 0) := (others => '0');
	signal r_sum, r_sub, r_inc, r_dec : unsigned(4 downto 0);
	signal r_and, r_or, r_not, r_xnor : std_logic_vector(3 downto 0);
	signal final_result : std_logic_vector(4 downto 0);
    
	-- ================================================================
	-- MUDANÇA: Sinais para as 4 flags
	-- ================================================================
	signal flag_n, flag_v, flag_c, flag_z : std_logic;

begin

	-- Instanciação e Detector de Borda (sem alterações)
	U1_db_fsm: db_fsm port map (clk=>clk, reset=>reset, sw=>btn, db=>btn_db);
	process(clk) begin if rising_edge(clk) then btn_db_ff <= btn_db; end if; end process;
	btn_press_edge <= btn_db and (not btn_db_ff);

	-- Máquina de Estados Principal (sem alterações)
	process(clk)
	begin
    	if rising_edge(clk) then
        	if reset = '1' then
            	state <= s_choose_op;
            	reg_a <= (others => '0');
            	reg_b <= (others => '0');
            	op_code <= (others => '0');
        	elsif btn_press_edge = '1' then
            	case state is
                	when s_choose_op => op_code <= sw; state <= s_load_a;
                	when s_load_a => reg_a <= unsigned(sw); state <= s_load_b;
                	when s_load_b => reg_b <= unsigned(sw); state <= s_show_result;
                	when s_show_result => state <= s_choose_op;
            	end case;
        	end if;
    	end if;
	end process;

	-- Lógica Combinacional das Operações (sem alterações)
	r_sum <= ('0' & reg_a) + ('0' & reg_b);
	r_sub <= ('0' & reg_a) - ('0' & reg_b);
	r_inc <= ('0' & reg_a) + 1;
	r_dec <= ('0' & reg_a) - 1;
	r_and  <= std_logic_vector(reg_a) and std_logic_vector(reg_b);
	r_or   <= std_logic_vector(reg_a) or  std_logic_vector(reg_b);
	r_not  <= not std_logic_vector(reg_a);
	r_xnor <= std_logic_vector(reg_a) xnor std_logic_vector(reg_b);

	-- Multiplexador de Saída (sem alterações)
	with op_code select
    	final_result <= std_logic_vector(r_sum) when "0000",
                    	std_logic_vector(r_sub) when "0001",
                    	std_logic_vector(r_inc) when "0010",
                    	std_logic_vector(r_dec) when "0011",
                    	'0' & r_and         	when "0100",
                    	'0' & r_or          	when "0101",
                    	'0' & r_not         	when "0110",
                    	'0' & r_xnor        	when "0111",
                    	"00000"             	when others;

	-- ================================================================
	-- MUDANÇA: Lógica para calcular as flags
	-- ================================================================
	-- Flag Zero (Z): Ativa se o resultado de 4 bits for "0000"
	flag_z <= '1' when final_result(3 downto 0) = "0000" else '0';
    
	-- Flag Negativo (N): Ativa se o bit mais significativo do resultado for '1'
	flag_n <= final_result(3);

	-- Flags Carry (C) e Overflow (V) são mais complexas e dependem da operação
	process(op_code, reg_a, reg_b, r_sum, r_sub, r_inc, r_dec)
	begin
    	-- Padrão: flags desligadas para operações lógicas
    	flag_c <= '0';
    	flag_v <= '0';
    	case op_code is
        	when "0000" | "0010" => -- Soma e Incremento
            	flag_c <= r_sum(4); -- Carry é o 5º bit da soma
            	-- Overflow: se dois positivos dão um negativo, ou dois negativos dão um positivo
            	if (reg_a(3) = reg_b(3)) and (reg_a(3) /= r_sum(3)) then
                	flag_v <= '1';
            	end if;
            	if op_code = "0010" then -- Caso especial do Incremento
               	if reg_a = "0111" then flag_v <= '1'; end if; -- 7+1=8, estouro em 4 bits com sinal
            	end if;

        	when "0001" | "0011" => -- Subtração e Decremento
            	flag_c <= not r_sub(4); -- Carry em subtração é not(borrow)
            	-- Overflow: se um pos-neg dá neg, ou um neg-pos dá pos
            	if (reg_a(3) /= reg_b(3)) and (reg_b(3) = r_sub(3)) then
                	flag_v <= '1';
            	end if;
             	if op_code = "0011" then -- Caso especial do Decremento
               	if reg_a = "1000" then flag_v <= '1'; end if; -- -8 - 1 = -9, estouro em 4 bits com sinal
            	end if;
       	 
        	when others =>
            	null; -- Mantém o padrão '0'
    	end case;
	end process;
    
	-- ================================================================
	-- MUDANÇA: Concatena as flags e o resultado para a saída de 8 LEDs
	-- ================================================================
	led <= flag_n & flag_v & flag_c & flag_z & final_result(3 downto 0);

end rtl;
