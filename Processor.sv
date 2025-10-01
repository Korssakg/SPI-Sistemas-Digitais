`default_nettype none
import Isa::*;

// ======================================================
// Módulo Processor
// ======================================================
module Processor(
    input  var logic i_clock,            // clock
    input  var logic i_reset,            // reset assíncrono
    input  var Instruction i_instruction // instrução de entrada
);

    // --------------------------------------------------
    // Instância da interface SPI (canal 1)
    // --------------------------------------------------
    Spi#(1) u_spi();

    // --------------------------------------------------
    // Instância da ALU (comunicação via SPI)
    // --------------------------------------------------
    Alu u_alu(
        .i_clock(i_clock),
        .i_reset(i_reset),
        .spi(u_spi)
    );

    // --------------------------------------------------
    // Banco de registradores do processador
    // --------------------------------------------------
    logic [REGISTER_BANK_SIZE-1:0][REGISTER_SIZE-1:0] registers;

    // Pacote recebido da ALU
    logic [REGISTER_SIZE-1:0] packet_in;

    // Pacote a ser enviado para a ALU
    AluPacket alu_packet_out;

    // Contadores de transmissão/recepção
    int tx_bit_idx;
    int rx_bit_idx;

    // --------------------------------------------------
    // Decodificação da instrução de entrada
    // --------------------------------------------------
    AluOperation op_kind;
    logic [$clog2(REGISTER_BANK_SIZE)-1:0] src_a, src_b, dst_d;

    always_comb begin
        // Cast explícito do opcode para o tipo enum
        op_kind = AluOperation'(i_instruction.op_code);
        src_a   = i_instruction.rs_1;
        src_b   = i_instruction.rs_2;
        dst_d   = i_instruction.rd;
    end

    // --------------------------------------------------
    // Máquina de estados (FSM em Gray code)
    // --------------------------------------------------
    typedef enum logic [2:0] {
        ST_FETCH    = 3'b000,
        ST_EXECUTE  = 3'b001,
        ST_TX_HDR   = 3'b011,
        ST_TX_DATA  = 3'b010,
        ST_RX_DATA  = 3'b110,
        ST_STORE    = 3'b111
    } state_t;

    // Alias (compatibilidade com testbench)
    localparam state_t STORE = ST_STORE;

    state_t current_state, next_state;

    // --------------------------------------------------
    // Sinais auxiliares
    // --------------------------------------------------
    logic start_hdr;
    logic spi_enable;

    // --------------------------------------------------
    // Construção do pacote a enviar
    // --------------------------------------------------
    always_comb begin
        alu_packet_out = '{ op_2: registers[src_b],
                            op_1: registers[src_a],
                            op_code: op_kind };
    end

    // --------------------------------------------------
    // Controle do SPI
    // --------------------------------------------------
    always_comb begin
        u_spi.sclk = i_clock;
        u_spi.nss  = 1'b1;
        u_spi.mosi = 1'b0;
        start_hdr  = 1'b0;
        spi_enable = 1'b0;

        case (current_state)
            ST_FETCH:    ; // idle
            ST_EXECUTE:  begin
                            u_spi.nss  = 1'b0;
                            start_hdr  = 1'b1;
                            spi_enable = 1'b1;
                         end
            ST_TX_HDR:   begin
                            u_spi.nss  = 1'b0;
                            u_spi.mosi = 1'b1;
                            spi_enable = 1'b1;
                         end
            ST_TX_DATA:  begin
                            u_spi.nss  = 1'b0;
                            u_spi.mosi = alu_packet_out[tx_bit_idx];
                            spi_enable = 1'b1;
                         end
            ST_RX_DATA:  begin
                            u_spi.nss  = 1'b0;
                            spi_enable = 1'b1;
                         end
            ST_STORE:    ; // fim da transação
        endcase
    end

    // --------------------------------------------------
    // Próximo estado
    // --------------------------------------------------
    always_comb begin
        next_state = ST_FETCH;
        if (!i_reset) begin
            next_state = ST_FETCH;
        end else begin
            case (current_state)
                ST_FETCH   : next_state = (i_instruction == '0) ? ST_FETCH : ST_EXECUTE;
                ST_EXECUTE : next_state = ST_TX_HDR;
                ST_TX_HDR  : next_state = ST_TX_DATA;
                ST_TX_DATA : next_state = (tx_bit_idx == $bits(alu_packet_out)-1) ? ST_RX_DATA : ST_TX_DATA;
                ST_RX_DATA : next_state = (rx_bit_idx == $bits(packet_in)-1)      ? ST_STORE   : ST_RX_DATA;
                ST_STORE   : next_state = ST_FETCH;
                default    : next_state = ST_FETCH;
            endcase
        end
    end

    // --------------------------------------------------
    // Sequencial
    // --------------------------------------------------
    always_ff @(posedge i_clock or negedge i_reset) begin : StateMachine
        if (!i_reset) begin
            current_state <= ST_FETCH;
            tx_bit_idx    <= 0;
            rx_bit_idx    <= 0;
            packet_in     <= '0;
            registers     <= '{default:'0};
        end else begin
            case (current_state)
                ST_FETCH: begin
                    tx_bit_idx <= 0;
                    rx_bit_idx <= 0;
                end
                ST_EXECUTE: begin
                    tx_bit_idx <= 0;
                end
                ST_TX_HDR: begin end
                ST_TX_DATA: begin
                    if (tx_bit_idx == $bits(alu_packet_out)-1) tx_bit_idx <= 0;
                    else                                      tx_bit_idx <= tx_bit_idx + 1;
                end
                ST_RX_DATA: begin
                    packet_in[rx_bit_idx] <= u_spi.miso;
                    if (rx_bit_idx == $bits(packet_in)-1) rx_bit_idx <= 0;
                    else                                 rx_bit_idx <= rx_bit_idx + 1;
                end
                ST_STORE: begin
                    registers[dst_d] <= packet_in;
                end
            endcase

            current_state <= next_state;
        end
    end : StateMachine

    // --------------------------------------------------
    // Aliases para compatibilidade com testbench/wave.do
    // --------------------------------------------------
    logic [REGISTER_SIZE-1:0] operation;
    logic [$clog2(REGISTER_BANK_SIZE)-1:0] rs_1, rs_2, rd;
    assign operation = i_instruction.op_code;
    assign rs_1      = i_instruction.rs_1;
    assign rs_2      = i_instruction.rs_2;
    assign rd        = i_instruction.rd;

    logic [REGISTER_SIZE-1:0] alu_counter_out;
    assign alu_counter_out = u_alu.packet_out;

    int counter_in;
    assign counter_in = u_alu.counter_in;

endmodule : Processor
