`default_nettype none

interface Spi#(parameter int NumberOfSlaves = 1);

	logic sclk;
	logic miso;
	logic mosi;
	logic [NumberOfSlaves - 1 : 0] nss;

	modport MasterSpi(
		input miso,

		output sclk,
		output mosi,
		output nss
	);

	modport SlaveSpi(
		input sclk,
		input mosi,
		input nss,

		output miso
	);

	property one_hot_slave_select;
		@(posedge sclk) $countones(~nss) <= 1;
	endproperty

	assert_one_hot_slave_select: assert property (one_hot_slave_select)
		else $error("SPI protocol violation: More than one slave selected! nss=%b at time %0t", nss, $time);

endinterface: Spi
