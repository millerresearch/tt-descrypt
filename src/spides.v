module spides (
	input clk, rst,
	input SCLK, SS, MOSI,
	output MISO);

	localparam
		CMDLEN = 8, DATALEN = 64, WIDTH = CMDLEN + DATALEN,
		KEY = 0, BLOCK = 1, ENCRYPT = 2, DECRYPT = 3;

	reg [63:0] key, block;
	wire [63:0] ciphertext;
	wire rdy, loadkey, loadblock, req, decrypt;
	wire [WIDTH-1:0] misodata = {8'h0,block};

	wire [WIDTH-1:0] mosidata;
	wire [CMDLEN-1:0] rxcmd = mosidata[WIDTH-1:DATALEN];
	wire [DATALEN-1:0] rxdata = mosidata[DATALEN-1:0];
	wire mosivalid;
	assign loadkey = mosivalid & rxcmd[KEY];
	assign loadblock = mosivalid & rxcmd[BLOCK];
	assign req = mosivalid & (rxcmd[ENCRYPT] | rxcmd[DECRYPT]);
	assign decrypt = mosivalid & rxcmd[DECRYPT];

	reg req_q, decrypt_q, rdy_q;
	always @(posedge clk)
	if (rst) begin
		req_q <= 0;
		decrypt_q <= 0;
		rdy_q <= 0;
		key <= 0;
		block <= 64'h4445536372797074;
	end else begin
		if (mosivalid)
			rdy_q <= 0;
		else if (rdy)
			rdy_q <= 1;
		if (loadkey)
			key <= rxdata;
		if (loadblock)
			block <= rxdata;
		else if (rdy)
			block <= ciphertext;
		req_q <= req;
		decrypt_q <= decrypt;
	end

	spisub #(.WIDTH(WIDTH)) SPI (clk, rst, SCLK, SS, MOSI, MISO, misodata, rdy_q, mosidata, mosivalid);
	des DES (clk, rst, decrypt_q, key, block, ciphertext, req_q, rdy);

endmodule
