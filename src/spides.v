module spides (
	input clk, rst,
	input SCLK, SS, MOSI,
	output MISO);

	localparam
		CMDLEN = 8, DATALEN = 64, WIDTH = CMDLEN + DATALEN,
		KEY = 0, BLOCK = 1, ENCRYPT = 2, DECRYPT = 3;

	wire [63:0] key, plaintext, ciphertext;
	wire rdy, loadkey, loadblock, req, decrypt;
	wire [WIDTH-1:0] misodata = {8'h0,ciphertext};

	wire [WIDTH-1:0] mosidata;
	wire [CMDLEN-1:0] rxcmd = mosidata[WIDTH-1:DATALEN];;
	wire [DATALEN-1:0] rxdata = mosidata[DATALEN-1:0];
	assign plaintext = rxdata;
	assign key = rxdata;
	wire mosivalid;
	assign loadkey = mosivalid & rxcmd[KEY];
	assign loadblock = mosivalid & rxcmd[BLOCK];
	assign req = mosivalid & (rxcmd[ENCRYPT] | rxcmd[DECRYPT]);
	assign decrypt = mosivalid & rxcmd[DECRYPT];

	spisub #(.WIDTH(WIDTH)) SPI (clk, rst, SCLK, SS, MOSI, MISO, misodata, rdy, mosidata, mosivalid);
	des DES (clk, rst, decrypt, key, plaintext, ciphertext, loadkey, loadblock, req, rdy);

endmodule
