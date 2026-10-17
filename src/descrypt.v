// Data Encryption Standard - encrypt/decrypt one block

`default_nettype none

module tt_um_millerresearch_descrypt (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
	);

	wire decrypt = ui_in[0];
	wire shiftin = ui_in[1];
	wire shiftreq = ui_in[2];
	wire req = ui_in[3];

	wire shiftout = keybuf[1];
	wire rdy = (round == 18);
	assign ui_out[0] = shiftout;
	assign ui_out[1] = rdy;
	assign ui_out[7:2] = 0;
	assign uio_out = 0;
	assign uio_oe = 0;

	wire rst = ~rst_n;

	reg [4:0] round;
	reg [1:64] cryptbuf;
	wire [1:64] initcrypt, nextcrypt, finalcrypt;
	reg [1:64] keybuf;
	reg startkey;
	wire [1:56] initkey, nextkey;
	wire [1:48] subkey;
	wire [1:48] sboxin;
	wire [1:32] sboxout;

	always @(posedge clk)
	if (rst) begin
		round <= 0;
		startkey <= 0;
	end else if (shiftreq) begin
		{keybuf,cryptbuf} <= {keybuf[2:64],cryptbuf,shiftin};
		round <= 0;
		startkey <= 0;
	end else if (req) begin
		startkey <= 1;
		keybuf[1:56] <= initkey;
		cryptbuf <= initcrypt;
	end else if (startkey) begin
		startkey <= 0;
		keybuf[1:56] <= nextkey;
		round <= 1;
	end else if (round != 0 && round != 18) begin
		round <= round + 1;
		keybuf[1:56] <= nextkey;
		cryptbuf <= (round == 17? finalcrypt : nextcrypt);
	end

	IP IP_(cryptbuf, initcrypt);
	IPinverse IPinverse_({cryptbuf[33:64],cryptbuf[1:32]}, finalcrypt);
	Feistelround Feistel_(sboxin, sboxout, cryptbuf[1:32], cryptbuf[33:64], subkey, nextcrypt[1:32], nextcrypt[33:64]);
	Substitution SBOX(sboxin, sboxout);
	KP KP_(keybuf, initkey);
	Keysched Keysched_(keybuf[1:56], round, decrypt, nextkey);
	Keysub Keysub_(keybuf[1:56], subkey);

endmodule

module Keysched (
	input [1:56] keyin,
	input [4:0] round,
	input decrypt,
	output [1:56] keyout
	);

	reg [1:56] k;
	assign keyout = k;
	wire [1:28] lkey = keyin[1:28];
	wire [1:28] rkey = keyin[29:56];
	always @(*) case(round)
		0:
			if (decrypt)
				k = {lkey,rkey};
			else
				k = {lkey[2:28],lkey[1],rkey[2:28],rkey[1]};
		1, 8, 15:
			if (decrypt)
				k = {lkey[28],lkey[1:27],rkey[28],rkey[1:27]};
			else
				k = {lkey[2:28],lkey[1],rkey[2:28],rkey[1]};
		default:
			if (decrypt)
				k = {lkey[27:28],lkey[1:26],rkey[27:28],rkey[1:26]};
			else
				k = {lkey[3:28],lkey[1:2],rkey[3:28],rkey[1:2]};
	endcase
endmodule

module Keysub (
	input [1:56] d,
	output [1:48] q
	);

	assign q = {
		d[14], d[17], d[11], d[24], d[1], d[5], d[3], d[28], d[15], d[6], d[21], d[10],
		d[23], d[19], d[12], d[4], d[26], d[8], d[16], d[7], d[27], d[20], d[13], d[2],
		d[41], d[52], d[31], d[37], d[47], d[55], d[30], d[40], d[51], d[45], d[33], d[48],
		d[44], d[49], d[39], d[56], d[34], d[53], d[46], d[42], d[50], d[36], d[29], d[32]
	};
endmodule

module IP (
	input [1:64] d,
	output [1:64] q
);

	assign q = {
		d[58], d[50], d[42], d[34], d[26], d[18], d[10], d[2],
		d[60], d[52], d[44], d[36], d[28], d[20], d[12], d[4],
		d[62], d[54], d[46], d[38], d[30], d[22], d[14], d[6],
		d[64], d[56], d[48], d[40], d[32], d[24], d[16], d[8],
		d[57], d[49], d[41], d[33], d[25], d[17], d[9], d[1],
		d[59], d[51], d[43], d[35], d[27], d[19], d[11], d[3],
		d[61], d[53], d[45], d[37], d[29], d[21], d[13], d[5],
		d[63], d[55], d[47], d[39], d[31], d[23], d[15], d[7]
	};
endmodule

module IPinverse (
	input [1:64] d,
	output [1:64] q
	);

	assign q = {
		d[40], d[8], d[48], d[16], d[56], d[24], d[64], d[32],
		d[39], d[7], d[47], d[15], d[55], d[23], d[63], d[31],
		d[38], d[6], d[46], d[14], d[54], d[22], d[62], d[30],
		d[37], d[5], d[45], d[13], d[53], d[21], d[61], d[29],
		d[36], d[4], d[44], d[12], d[52], d[20], d[60], d[28],
		d[35], d[3], d[43], d[11], d[51], d[19], d[59], d[27],
		d[34], d[2], d[42], d[10], d[50], d[18], d[58], d[26],
		d[33], d[1], d[41], d[9], d[49], d[17], d[57], d[25]
	};
endmodule

module KP (
	input [1:64] d,
	output [1:56] q
	);

	assign q = {
		d[57], d[49], d[41], d[33], d[25], d[17], d[9], d[1], d[58], d[50], d[42], d[34], d[26], d[18],
		d[10], d[2], d[59], d[51], d[43], d[35], d[27], d[19], d[11], d[3], d[60], d[52], d[44], d[36],
		d[63], d[55], d[47], d[39], d[31], d[23], d[15], d[7], d[62], d[54], d[46], d[38], d[30], d[22],
		d[14], d[6], d[61], d[53], d[45], d[37], d[29], d[21], d[13], d[5], d[28], d[20], d[12], d[4]
	};
endmodule

module Feistelround (
	output [1:48] sboxin,
	input [1:32] sboxout,
	input [1:32] Lin,
	input [1:32] Rin,
	input [1:48] subkey,
	output [1:32] Lout,
	output [1:32] Rout
	);

	wire [1:48] expand;
	wire [1:32] subst, permute;

	Expansion FE (Rin, expand);
	assign sboxin = expand ^ subkey;
	Permutation FP (sboxout, permute);
	assign Rout = permute ^ Lin;
	assign Lout = Rin;
endmodule

module Expansion (
	input [1:32] d,
	output [1:48] q
	);

	assign q = {
		d[32], d[1], d[2], d[3], d[4], d[5],
		d[4], d[5], d[6], d[7], d[8], d[9],
		d[8], d[9], d[10], d[11], d[12], d[13],
		d[12], d[13], d[14], d[15], d[16], d[17],
		d[16], d[17], d[18], d[19], d[20], d[21],
		d[20], d[21], d[22], d[23], d[24], d[25],
		d[24], d[25], d[26], d[27], d[28], d[29],
		d[28], d[29], d[30], d[31], d[32], d[1]
	};
endmodule

module Permutation (
	input [1:32] d,
	output [1:32] q
	);

	assign q = {
		d[16], d[7], d[20], d[21], d[29], d[12], d[28], d[17],
		d[1], d[15], d[23], d[26], d[5], d[18], d[31], d[10],
		d[2], d[8], d[24], d[14], d[32], d[27], d[3], d[9],
		d[19], d[13], d[30], d[6], d[22], d[11], d[4], d[25]
	};
endmodule

module Substitution (
	input [1:48] d,
	output [1:32] q
	);

	wire [0:255] s1 = {
		4'd14, 4'd4, 4'd13, 4'd1, 4'd2, 4'd15, 4'd11, 4'd8, 4'd3, 4'd10, 4'd6, 4'd12, 4'd5, 4'd9, 4'd0, 4'd7,
		4'd0, 4'd15, 4'd7, 4'd4, 4'd14, 4'd2, 4'd13, 4'd1, 4'd10, 4'd6, 4'd12, 4'd11, 4'd9, 4'd5, 4'd3, 4'd8,
		4'd4, 4'd1, 4'd14, 4'd8, 4'd13, 4'd6, 4'd2, 4'd11, 4'd15, 4'd12, 4'd9, 4'd7, 4'd3, 4'd10, 4'd5, 4'd0,
		4'd15, 4'd12, 4'd8, 4'd2, 4'd4, 4'd9, 4'd1, 4'd7, 4'd5, 4'd11, 4'd3, 4'd14, 4'd10, 4'd0, 4'd6, 4'd13
	};
	wire [0:255] s2 = {
		4'd15, 4'd1, 4'd8, 4'd14, 4'd6, 4'd11, 4'd3, 4'd4, 4'd9, 4'd7, 4'd2, 4'd13, 4'd12, 4'd0, 4'd5, 4'd10,
		4'd3, 4'd13, 4'd4, 4'd7, 4'd15, 4'd2, 4'd8, 4'd14, 4'd12, 4'd0, 4'd1, 4'd10, 4'd6, 4'd9, 4'd11, 4'd5,
		4'd0, 4'd14, 4'd7, 4'd11, 4'd10, 4'd4, 4'd13, 4'd1, 4'd5, 4'd8, 4'd12, 4'd6, 4'd9, 4'd3, 4'd2, 4'd15,
		4'd13, 4'd8, 4'd10, 4'd1, 4'd3, 4'd15, 4'd4, 4'd2, 4'd11, 4'd6, 4'd7, 4'd12, 4'd0, 4'd5, 4'd14, 4'd9
	};
	wire [0:255] s3 = {
		4'd10, 4'd0, 4'd9, 4'd14, 4'd6, 4'd3, 4'd15, 4'd5, 4'd1, 4'd13, 4'd12, 4'd7, 4'd11, 4'd4, 4'd2, 4'd8,
		4'd13, 4'd7, 4'd0, 4'd9, 4'd3, 4'd4, 4'd6, 4'd10, 4'd2, 4'd8, 4'd5, 4'd14, 4'd12, 4'd11, 4'd15, 4'd1,
		4'd13, 4'd6, 4'd4, 4'd9, 4'd8, 4'd15, 4'd3, 4'd0, 4'd11, 4'd1, 4'd2, 4'd12, 4'd5, 4'd10, 4'd14, 4'd7,
		4'd1, 4'd10, 4'd13, 4'd0, 4'd6, 4'd9, 4'd8, 4'd7, 4'd4, 4'd15, 4'd14, 4'd3, 4'd11, 4'd5, 4'd2, 4'd12
	};
	wire [0:255] s4 = {
		4'd7, 4'd13, 4'd14, 4'd3, 4'd0, 4'd6, 4'd9, 4'd10, 4'd1, 4'd2, 4'd8, 4'd5, 4'd11, 4'd12, 4'd4, 4'd15,
		4'd13, 4'd8, 4'd11, 4'd5, 4'd6, 4'd15, 4'd0, 4'd3, 4'd4, 4'd7, 4'd2, 4'd12, 4'd1, 4'd10, 4'd14, 4'd9,
		4'd10, 4'd6, 4'd9, 4'd0, 4'd12, 4'd11, 4'd7, 4'd13, 4'd15, 4'd1, 4'd3, 4'd14, 4'd5, 4'd2, 4'd8, 4'd4,
		4'd3, 4'd15, 4'd0, 4'd6, 4'd10, 4'd1, 4'd13, 4'd8, 4'd9, 4'd4, 4'd5, 4'd11, 4'd12, 4'd7, 4'd2, 4'd14
	};
	wire [0:255] s5 = {
		4'd2, 4'd12, 4'd4, 4'd1, 4'd7, 4'd10, 4'd11, 4'd6, 4'd8, 4'd5, 4'd3, 4'd15, 4'd13, 4'd0, 4'd14, 4'd9,
		4'd14, 4'd11, 4'd2, 4'd12, 4'd4, 4'd7, 4'd13, 4'd1, 4'd5, 4'd0, 4'd15, 4'd10, 4'd3, 4'd9, 4'd8, 4'd6,
		4'd4, 4'd2, 4'd1, 4'd11, 4'd10, 4'd13, 4'd7, 4'd8, 4'd15, 4'd9, 4'd12, 4'd5, 4'd6, 4'd3, 4'd0, 4'd14,
		4'd11, 4'd8, 4'd12, 4'd7, 4'd1, 4'd14, 4'd2, 4'd13, 4'd6, 4'd15, 4'd0, 4'd9, 4'd10, 4'd4, 4'd5, 4'd3
	};
	wire [0:255] s6 = {
		4'd12, 4'd1, 4'd10, 4'd15, 4'd9, 4'd2, 4'd6, 4'd8, 4'd0, 4'd13, 4'd3, 4'd4, 4'd14, 4'd7, 4'd5, 4'd11,
		4'd10, 4'd15, 4'd4, 4'd2, 4'd7, 4'd12, 4'd9, 4'd5, 4'd6, 4'd1, 4'd13, 4'd14, 4'd0, 4'd11, 4'd3, 4'd8,
		4'd9, 4'd14, 4'd15, 4'd5, 4'd2, 4'd8, 4'd12, 4'd3, 4'd7, 4'd0, 4'd4, 4'd10, 4'd1, 4'd13, 4'd11, 4'd6,
		4'd4, 4'd3, 4'd2, 4'd12, 4'd9, 4'd5, 4'd15, 4'd10, 4'd11, 4'd14, 4'd1, 4'd7, 4'd6, 4'd0, 4'd8, 4'd13
	};
	wire [0:255] s7 = {
		4'd4, 4'd11, 4'd2, 4'd14, 4'd15, 4'd0, 4'd8, 4'd13, 4'd3, 4'd12, 4'd9, 4'd7, 4'd5, 4'd10, 4'd6, 4'd1,
		4'd13, 4'd0, 4'd11, 4'd7, 4'd4, 4'd9, 4'd1, 4'd10, 4'd14, 4'd3, 4'd5, 4'd12, 4'd2, 4'd15, 4'd8, 4'd6,
		4'd1, 4'd4, 4'd11, 4'd13, 4'd12, 4'd3, 4'd7, 4'd14, 4'd10, 4'd15, 4'd6, 4'd8, 4'd0, 4'd5, 4'd9, 4'd2,
		4'd6, 4'd11, 4'd13, 4'd8, 4'd1, 4'd4, 4'd10, 4'd7, 4'd9, 4'd5, 4'd0, 4'd15, 4'd14, 4'd2, 4'd3, 4'd12
	};
	wire [0:255] s8 = {
		4'd13, 4'd2, 4'd8, 4'd4, 4'd6, 4'd15, 4'd11, 4'd1, 4'd10, 4'd9, 4'd3, 4'd14, 4'd5, 4'd0, 4'd12, 4'd7,
		4'd1, 4'd15, 4'd13, 4'd8, 4'd10, 4'd3, 4'd7, 4'd4, 4'd12, 4'd5, 4'd6, 4'd11, 4'd0, 4'd14, 4'd9, 4'd2,
		4'd7, 4'd11, 4'd4, 4'd1, 4'd9, 4'd12, 4'd14, 4'd2, 4'd0, 4'd6, 4'd10, 4'd13, 4'd15, 4'd3, 4'd5, 4'd8,
		4'd2, 4'd1, 4'd14, 4'd7, 4'd4, 4'd10, 4'd8, 4'd13, 4'd15, 4'd12, 4'd9, 4'd0, 4'd3, 4'd5, 4'd6, 4'd11
	};

	Sbox S1 (s1, d[1:6], q[1:4]);
	Sbox S2 (s2, d[7:12], q[5:8]);
	Sbox S3 (s3, d[13:18], q[9:12]);
	Sbox S4 (s4, d[19:24], q[13:16]);
	Sbox S5 (s5, d[25:30], q[17:20]);
	Sbox S6 (s6, d[31:36], q[21:24]);
	Sbox S7 (s7, d[37:42], q[25:28]);
	Sbox S8 (s8, d[43:48], q[29:32]);
endmodule

module Sbox (
	input [0:255] s,
	input [1:6] d,
	output [1:4] q
	);

	wire [5:0] index = {d[1],d[6],d[2],d[3],d[4],d[5]};
	assign q[1:4] = s[4*index +: 4];
endmodule
