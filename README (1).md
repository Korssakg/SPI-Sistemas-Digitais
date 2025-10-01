# Trabalho 1 - Processador com SPI

Alunos:  
- **Guilherme Korssak Gonçalves**  
- **Fernando Rossini Meggiolaro**

---

## Descrição

Este trabalho implementa um processador simples em SystemVerilog, dividido em estágios de execução, que se comunica com as unidades funcionais (ALU, multiplicador e barrel-shifter) através de uma interface **SPI**.

O processador possui:  
- Banco de registradores.  
- Unidade de Controle com máquina de estados (FSM).  
- ALU com instruções `ADD`, `SUB`, `AND`, `OR`.  
- Multiplicador (`MUL`) via SPI.  
- Barrel-shifter (`SHL`, `SHR`) via SPI.  
- Testbench para validação automática (comparação expected vs. actual).  

---

## Estrutura do Projeto

```
sim/
 ├── Isa.sv          # Definição das instruções, operações e pacotes
 ├── Spi.sv          # Interface SPI usada na comunicação
 ├── Alu.sv          # Unidade Aritmética e Lógica
 ├── Mul.sv          # Unidade multiplicadora (via SPI)
 ├── Bas.sv          # Unidade barrel-shifter (via SPI)
 ├── Processor.sv    # Processador principal
 ├── ProcessorTb.sv  # Testbench
 ├── sim.do          # Script de simulação (ModelSim)
 └── wave.do         # Configuração de waveform
```

---

## Simulação

A simulação foi feita no **ModelSim - Intel FPGA Starter Edition**.  
Abaixo um exemplo de waveform mostrando a execução das instruções, com registradores variando e operações sendo processadas corretamente pela ALU via SPI:

![Simulação no ModelSim](fb037753-b7c3-43ac-bc4f-2f4911551e5d.png)

---

## Como rodar

1. Abrir o ModelSim.  
2. Executar o script de simulação:

```tcl
do sim.do
```

3. Abrir o waveform com:

```tcl
do wave.do
```

4. Rodar a simulação completa:

```tcl
run -all
```

---

## Resultados

- Instruções `ADD`, `SUB`, `AND`, `OR` testadas e validadas.  
- Novas instruções `MUL`, `SHL`, `SHR` integradas via SPI.  
- Banco de registradores inicializado pelo testbench com valores incrementais.  
- Resultados observados no waveform confirmam execução correta.  
