# ULA de 4 Bits com Detecção de Flags (VHDL)

Uma Unidade Lógica Aritmética (ULA) de 4 bits implementada em VHDL para demonstrar operações aritméticas e lógicas básicas, além da lógica de controle de estados e detecção de *debounce* de botão.

## Visão Geral

Este projeto implementa uma ULA de 4 bits capaz de realizar 8 operações distintas. O resultado da operação e 4 *flags* de estado (N, V, C, Z) são exibidos em um conjunto de 8 LEDs. A interação é feita através de um botão (`btn`) para controlar a máquina de estados e 4 chaves (`sw`) para fornecer dados de entrada e código de operação.

### Arquitetura e Componentes

| Arquivo | Descrição |
| :--- | :--- |
| **`ula_4bit.vhd`** | Entidade principal da ULA. Contém a FSM de controle, a lógica combinacional das operações, o multiplexador de saída e a lógica de detecção de *flags* (Zero, Negativo, Carry e Overflow). |
| **`db_fsm.vhd`** | Componente de máquina de estados para realizar o *debounce* do botão (`btn`), garantindo uma transição de estado estável na ULA. |
| **`ula_4bit.ucf`** | Arquivo de restrições (User Constraint File) para mapear as portas da entidade (`clk`, `reset`, `btn`, `sw`, `led`) aos pinos de um FPGA (placa Nexys ou similar). |

## Operações Implementadas (Op Code - `sw`)

A seleção da operação é feita no estado `s_choose_op` usando as chaves `sw(3 downto 0)`.

| Op Code | Operação | Saída (`final_result`) | Flags (Cálculo) |
| :---: | :--- | :--- | :--- |
| `0000` | **Soma** | `reg_a + reg_b` | Carry (`r_sum(4)`), Overflow, Zero, Negativo |
| `0001` | **Subtração** | `reg_a - reg_b` | Borrow (`not r_sub(4)`), Overflow, Zero, Negativo |
| `0010` | **Incremento** | `reg_a + 1` | Carry (`r_sum(4)`), Overflow, Zero, Negativo |
| `0011` | **Decremento** | `reg_a - 1` | Borrow (`not r_sub(4)`), Overflow, Zero, Negativo |
| `0100` | **AND** | `reg_a and reg_b` | Flags desativadas ('0') |
| `0101` | **OR** | `reg_a or reg_b` | Flags desativadas ('0') |
| `0110` | **NOT** | `not reg_a` | Flags desativadas ('0') |
| `0111` | **XNOR** | `reg_a xnor reg_b` | Flags desativadas ('0') |

## Fluxo de Funcionamento (FSM Principal)

O botão (`btn`) atua como um comando de transição de estado, disparado na borda de subida (`btn_press_edge`).

1.  **`s_choose_op`**: O código de operação é lido das chaves (`sw`) e armazenado em `op_code`.
2.  **`s_load_a`**: O valor de `reg_a` é lido das chaves (`sw`).
3.  **`s_load_b`**: O valor de `reg_b` é lido das chaves (`sw`).
4.  **`s_show_result`**: O resultado e as *flags* são exibidos nos LEDs.
5.  **Próxima Pressione:** Volta para `s_choose_op` para escolher uma nova operação.

##  Mapeamento de Saída (`led`)

A saída de 8 bits (`led`) é uma concatenação do resultado de 4 bits e das 4 *flags* de estado.


| Bit do LED | Sinal | Descrição |
| :---: | :--- | :--- |
| **`led(7)`** | `flag_n` | **Negativo**: Resultado de 4 bits é negativo (MSB é '1'). |
| **`led(6)`** | `flag_v` | **Overflow**: Ocorreu um estouro na operação. |
| **`led(5)`** | `flag_c` | **Carry**: Bit de carry (soma) ou *not-borrow* (subtração). |
| **`led(4)`** | `flag_z` | **Zero**: O resultado de 4 bits é igual a "0000". |
| **`led(3:0)`**| Resultado | Os 4 bits menos significativos do resultado da operação. |

##  Tecnologias e Ferramentas

* **Linguagem de Descrição de Hardware:** VHDL (IEEE STD\_LOGIC\_1164, NUMERIC\_STD)

