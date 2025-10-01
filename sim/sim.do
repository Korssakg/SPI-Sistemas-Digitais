if {[file isdirectory work]} { vdel -all -lib work }

vlib work
vmap work work

set SOURCES ""
set TOP_ENTITY "work.ProcessorTb"

# Interfaces
append SOURCES "./Spi.sv "

# Packages
append SOURCES "./Isa.sv "

# Modules
append SOURCES "./Alu.sv ./Processor.sv "

# Testbenches
append SOURCES "./ProcessorTb.sv "

# Compile Verilog (use eval so the SOURCES string is split into words)
eval vlog -work work $SOURCES

# Run testbench
vsim -voptargs=+acc $TOP_ENTITY

do wave.do
run 30ns
