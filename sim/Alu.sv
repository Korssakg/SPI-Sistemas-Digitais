`default_nettype none
import Isa::*;

module Alu(
    input  var logic i_clock,   // clock
    input  var logic i_reset,   // reset assíncrono
    Spi.SlaveSpi spi            // interface SPI (slave)
);

    // --------------------------------------------------
    // Buffers de entrada/saída e contadores de bits
    // --------------------------------------------------
    logic [REGISTER_SIZE-1:0] packet_in;   // pacote recebido
    logic [REGISTER_SIZE-1:0] packet_out;  // pacote de resposta
    int counter_in;                        // contador de recepção
    int counter_out;                       // contador de transmissão

    // --------------------------------------------------
    // Máquina de estados (FSM) 
    // --------------------------------------------------
    typedef enum logic [4:0] {
        ST_RECV_PREAMBLE = 5'b00001, // aguardando início
        ST_SHIFT_IN      = 5'b00010, // recebendo bits
        ST_EXECUTE       = 5'b00100, // executa operação
        ST_SEND_PREAMBLE = 5'b01000, // envia start bit
        ST_SHIFT_OUT     = 5'b10000  // envia bits do resultado
    } state_t;

    state_t current_state, next_state;

    // --------------------------------------------------
    // Decodificação do pacote recebido
    // --------------------------------------------------
    AluOperation op_code;
    logic [REGISTER_SIZE-1:0] op_1, op_2;
    assign { op_2, op_1, op_code } = packet_in;

    // --------------------------------------------------
    // Saída MISO controlada por estado
    // --------------------------------------------------
    always_comb begin
        spi.miso = 1'b0; // valor padrão

        // Quando nss = 0 (slave habilitado)
        if (!spi.nss) begin
            case (current_state)
                ST_SEND_PREAMBLE: spi.miso = 1'b1;                      // bit inicial
                ST_SHIFT_OUT    : spi.miso = packet_out[counter_out];   // transmite bits
                default         : spi.miso = 1'b0;
            endcase
        end
    end

    // --------------------------------------------------
    // Próximo estado da FSM
    // --------------------------------------------------
    always_comb begin
        next_state = ST_RECV_PREAMBLE;

        if (!i_reset) begin
            next_state = ST_RECV_PREAMBLE;
        end else begin
            case (current_state)
                ST_RECV_PREAMBLE: begin
                    // Início da recepção se nss=0 e MOSI=1
                    if (!spi.nss && spi.mosi) next_state = ST_SHIFT_IN;
                    else                      next_state = ST_RECV_PREAMBLE;
                end
                ST_SHIFT_IN: begin
                    // Se já recebeu todos os bits → EXECUTE
                    if (counter_in == $bits(packet_in)-1) next_state = ST_EXECUTE;
                    else                                  next_state = ST_SHIFT_IN;
                end
                ST_EXECUTE: begin
                    next_state = ST_SEND_PREAMBLE;
                end
                ST_SEND_PREAMBLE: begin
                    // Aguarda master baixar MOSI para iniciar envio do resultado
                    if (!spi.mosi) next_state = ST_SHIFT_OUT;
                    else           next_state = ST_SEND_PREAMBLE;
                end
                ST_SHIFT_OUT: begin
                    // Se terminou de enviar → volta ao início
                    if (counter_out == $bits(packet_out)-1) next_state = ST_RECV_PREAMBLE;
                    else                                    next_state = ST_SHIFT_OUT;
                end
                default: next_state = ST_RECV_PREAMBLE;
            endcase
        end
    end

    // --------------------------------------------------
    // Bloco sequencial: controla contadores e operações
    // --------------------------------------------------
    always_ff @(posedge i_clock or negedge i_reset) begin : state_machine
        if (!i_reset) begin
            // Reset dos registradores
            current_state <= ST_RECV_PREAMBLE;
            counter_in    <= 0;
            counter_out   <= 0;
            packet_in     <= '0;
            packet_out    <= '0;
        end
        else begin
            case (current_state)
                ST_RECV_PREAMBLE: begin
                    counter_in  <= 0;
                    counter_out <= 0;
                end
                ST_SHIFT_IN: begin
                    // Recebe bits em série (LSB-first)
                    packet_in[counter_in] <= spi.mosi;
                    if (counter_in == $bits(packet_in)-1) counter_in <= 0;
                    else                                   counter_in <= counter_in + 1;
                end
                ST_EXECUTE: begin
                    // Executa a operação de acordo com o opcode
                    case (op_code)
                        ADD: packet_out <= op_1 + op_2;
                        SUB: packet_out <= op_1 - op_2;
                        AND: packet_out <= (op_1 & op_2);
                        OR : packet_out <= (op_1 | op_2);
                        default: packet_out <= '0;
                    endcase
                end
                ST_SEND_PREAMBLE: begin
                    // Prepara saída → zera contador de transmissão
                    counter_out <= 0;
                end
                ST_SHIFT_OUT: begin
                    // Envia bits do resultado em série
                    if (counter_out == $bits(packet_out)-1) counter_out <= 0;
                    else                                    counter_out <= counter_out + 1;
                end
            endcase

            // Atualiza estado
            current_state <= next_state;
        end
    end : state_machine

    // --------------------------------------------------
    // Aliases para compatibilidade com wave.do
    // --------------------------------------------------
    logic [REGISTER_SIZE-1:0] alu_counter_out;
    assign alu_counter_out = packet_out; // expõe resultado completo

    // counter_in já é usado diretamente
endmodule : Alu
