module spisub #(parameter WIDTH=16) (
	input clk, rst,
	input SCLK, SS, MOSI,
	output MISO,
	input [WIDTH-1:0] misodata,
	input misovalid,
	output [WIDTH-1:0] mosidata,
	output reg mosivalid
);

	localparam LOGWIDTH = $clog2(WIDTH);
	reg [WIDTH:0] shiftreg;
	assign MISO = shiftreg[WIDTH];
	assign mosidata = shiftreg[WIDTH:1];
	reg [LOGWIDTH-1:0] bitcount;

	// synchronise SCLK and SS to fabric clk and detect SCLK edges
	reg [2:0] sclk_sync;
	reg [1:0] ss_sync;
	always @(posedge clk)
		if (rst) begin
			sclk_sync <= 0;
			ss_sync <= 0;
		end else begin
			sclk_sync <= {SCLK,sclk_sync[2:1]};
			ss_sync <= {SS,ss_sync[1]};
		end
	wire sclk_rising = (sclk_sync[1:0] == 2'b10);
	wire sclk_falling = (sclk_sync[1:0] == 2'b01);

	// capture incoming data bit on rising SCLK edge
	always @(posedge clk)
		if (rst) begin
			bitcount <= 0;
			shiftreg[0] <= 0;
			//mosidata <= 0;
			mosivalid <= 0;
		end else begin
			mosivalid <= 0;
			shiftreg[0] <= MOSI;
			if (~ss_sync[0] & sclk_rising) begin
// verilator lint_off WIDTHEXPAND
				if (bitcount != (WIDTH-1)) begin
// verilator lint_on WIDTHEXPAND
					bitcount <= bitcount + 1;
				end else begin
					bitcount <= 0;
					mosivalid <= 1;
					//mosidata <= {shiftreg[WIDTH-1:1],MOSI};
				end
			end
		end

	// set up next outgoing data bit on falling SCLK edge or SS high
	always @(posedge clk)
		if (rst)
			shiftreg[WIDTH:1] <= 0;
		else if (ss_sync[0] || sclk_falling) begin
			if (ss_sync[0] || ((|bitcount) == 0)) begin
				if (misovalid)
					shiftreg[WIDTH:1] <= misodata;
			end else
				shiftreg[WIDTH:1] <= shiftreg[WIDTH-1:0];
		end

endmodule
