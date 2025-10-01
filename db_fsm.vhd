library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity db_fsm is
	port (
    	clk : in std_logic;
    	reset : in std_logic;
    	sw : in std_logic;
    	db : out std_logic
	);
end db_fsm;

architecture arch of db_fsm is
	-- Constante para tempo de debounce (~10ms com clock de 50MHz)
	constant N : integer := 19;
   
	signal q_reg : unsigned(N-1 downto 0);
	signal m_tick : std_logic;

	type state_type is (zero, wait1_1, wait1_2, wait1_3,
                    	one, wait0_1, wait0_2, wait0_3);
	signal state_reg, state_next : state_type;

begin
	-- ================================================================
	-- CORREÇÃO AQUI: Contador de rolagem livre (mais simples e robusto)
	-- ================================================================
	process(clk, reset)
	begin
    	if reset = '1' then
        	q_reg <= (others => '0');
    	elsif rising_edge(clk) then
        	-- Ele simplesmente incrementa. Quando chegar ao máximo,
        	-- ele naturalmente voltará a zero no próximo ciclo.
        	q_reg <= q_reg + 1;
    	end if;
	end process;

	-- O tick continua sendo gerado quando o contador atinge o valor máximo
	m_tick <= '1' when q_reg = (2**N - 1) else '0';


	-- Registrador de estado da FSM de debounce (sem alterações)
	process(clk, reset)
	begin
    	if reset = '1' then
        	state_reg <= zero;
    	elsif rising_edge(clk) then
        	-- O registrador de estado só avança no tick,
        	-- então ele não é afetado diretamente pela velocidade do contador.
        	if m_tick = '1' then
           	state_reg <= state_next;
        	end if;
    	end if;
	end process;
   
	-- Lógica de transição de estados (sem alterações)
	process(state_reg, sw)
	begin
    	state_next <= state_reg;
    	case state_reg is
        	when zero => if sw = '1' then state_next <= wait1_1; end if;
        	when wait1_1 => if sw = '0' then state_next <= zero; else state_next <= wait1_2; end if;
        	when wait1_2 => if sw = '0' then state_next <= zero; else state_next <= wait1_3; end if;
        	when wait1_3 => if sw = '0' then state_next <= zero; else state_next <= one; end if;
        	when one => if sw = '0' then state_next <= wait0_1; end if;
        	when wait0_1 => if sw = '1' then state_next <= one; else state_next <= wait0_2; end if;
        	when wait0_2 => if sw = '1' then state_next <= one; else state_next <= wait0_3; end if;
        	when wait0_3 => if sw = '1' then state_next <= one; else state_next <= zero; end if;
    	end case;
	end process;
   
	-- Lógica de saída (sem alterações)
	db <= '1' when state_reg = one else '0';

end arch;
