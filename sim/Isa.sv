`default_nettype none
package Isa;

    // --------------------------------------------------
    // Parâmetros globais
    // --------------------------------------------------
    parameter int REGISTER_SIZE       = 32;    // largura dos registradores
    parameter int REGISTER_BANK_SIZE  = 1024;  // quantidade de registradores

    // --------------------------------------------------
    // Operações suportadas pela ALU
    // --------------------------------------------------
    typedef enum logic [3:0] {
        ADD = 4'b0000,
        SUB = 4'b0001,
        AND = 4'b0010,
        OR  = 4'b0011
    } AluOperation;

    // --------------------------------------------------
    // Estrutura de uma instrução ISA
    // --------------------------------------------------
    typedef struct packed {
        logic [3:0] op_code;                        // operação
        logic [9:0] rs_1;                           // registrador fonte 1
        logic [9:0] rs_2;                           // registrador fonte 2
        logic [9:0] rd;                             // registrador destino
    } Instruction;

    // --------------------------------------------------
    // Pacote transmitido para a ALU via SPI
    // --------------------------------------------------
    typedef struct packed {
        logic [REGISTER_SIZE-1:0] op_1;             // operando 1
        logic [REGISTER_SIZE-1:0] op_2;             // operando 2
        AluOperation              op_code;          // código da operação
    } AluPacket;

endpackage : Isa
