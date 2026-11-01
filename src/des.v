// Data Encryption Standard - encrypt/decrypt one block

// verilator lint_off ASCRANGE

module des (
	input clk,
	input rst,
	input decrypt,
	input [1:64] key,
	input [1:64] plaintext,
	output [1:64] ciphertext,
	input loadkey,
	input loadblock,
	input req,
	output rdy
	);

	reg [4:0] round;
	assign rdy = (round == 17);
	reg [1:64] cryptbuf;
	wire [1:64] initcrypt, nextcrypt, finalcrypt;
	assign ciphertext = cryptbuf;
	reg [1:56] keybuf;
	wire [1:56] initkey, nextkey;
	wire [1:48] subkey;
	reg running;
	reg decrypting;

	always @(posedge clk)
	if (rst) begin
		round <= 0;
		running <= 0;
		decrypting <= 0;
	end else case (round)
		0, 17: begin
				if (running) begin
					running <= 0;
					keybuf <= nextkey;
					cryptbuf <= initcrypt;
					round <= 1;
				end else begin
					if (loadkey)
						keybuf <= initkey;
					if (loadblock)
						cryptbuf <= plaintext;
					running <= req;
					decrypting <= decrypt;
				end
			end
		16: begin
				round <= round + 1;
				cryptbuf <= finalcrypt;
			end
		default: begin
				round <= round + 1;
				cryptbuf <= nextcrypt;
				keybuf <= nextkey;
			end
		endcase

	IP IP (cryptbuf, initcrypt);
	Feistel Feistel (cryptbuf, nextcrypt, subkey);
	IPinverse IPinverse ({nextcrypt[33:64],nextcrypt[1:32]}, finalcrypt);
	PC1 PC1 (key, initkey);
	Keysched Keysched (keybuf, nextkey, round, decrypting);
	PC2 PC2 (keybuf, subkey);

endmodule

// verilator lint_off DECLFILENAME

// Feistel round
module Feistel (
	input [1:64] d,
	output [1:64] q,
	input [1:48] subkey
	);

	wire [1:32] Lin = d[1:32];
	wire [1:32] Rin = d[33:64];
	wire [1:32] Lout;
	wire [1:32] Rout;
	assign q = {Lout,Rout};
	wire [1:48] expand;
	wire [1:32] subst, permute;

	Expansion E (Rin, expand);
	Substitution SBOX (expand ^ subkey, subst);
	Permutation P (subst, permute);
	assign Rout = permute ^ Lin;
	assign Lout = Rin;
endmodule

// key schedule round
module Keysched (
	input [1:56] keyin,
	output [1:56] keyout,
	input [4:0] round,
	input decrypt
	);

	reg [1:56] k;
	assign keyout = k;
	wire [1:28] lkey = keyin[1:28];
	wire [1:28] rkey = keyin[29:56];
	always @(*)
		if (decrypt) case(round)
			0, 17:
				k = {lkey,rkey};
			1, 8, 15:
				k = {lkey[28],lkey[1:27],rkey[28],rkey[1:27]};
			default:
				k = {lkey[27:28],lkey[1:26],rkey[27:28],rkey[1:26]};
		endcase else case(round)
			0, 1, 8, 15, 17:
				k = {lkey[2:28],lkey[1],rkey[2:28],rkey[1]};
			default:
				k = {lkey[3:28],lkey[1:2],rkey[3:28],rkey[1:2]};
		endcase
endmodule

// permuted choice 1
module PC1 (
	// verilator lint_off UNUSEDSIGNAL
	input [1:64] d,
	// verilator lint_on UNUSEDSIGNAL
	output [1:56] q
	);

	assign q = {
		d[57], d[49], d[41], d[33], d[25], d[17], d[9], d[1], d[58], d[50], d[42], d[34], d[26], d[18],
		d[10], d[2], d[59], d[51], d[43], d[35], d[27], d[19], d[11], d[3], d[60], d[52], d[44], d[36],
		d[63], d[55], d[47], d[39], d[31], d[23], d[15], d[7], d[62], d[54], d[46], d[38], d[30], d[22],
		d[14], d[6], d[61], d[53], d[45], d[37], d[29], d[21], d[13], d[5], d[28], d[20], d[12], d[4]
	};
endmodule

// permuted choice 2
module PC2 (
	// verilator lint_off UNUSEDSIGNAL
	input [1:56] d,
	// verilator lint_on UNUSEDSIGNAL
	output [1:48] q
	);

	assign q = {
		d[14], d[17], d[11], d[24], d[1], d[5], d[3], d[28], d[15], d[6], d[21], d[10],
		d[23], d[19], d[12], d[4], d[26], d[8], d[16], d[7], d[27], d[20], d[13], d[2],
		d[41], d[52], d[31], d[37], d[47], d[55], d[30], d[40], d[51], d[45], d[33], d[48],
		d[44], d[49], d[39], d[56], d[34], d[53], d[46], d[42], d[50], d[36], d[29], d[32]
	};
endmodule

// initial permutation
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

// final permutation
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

// expansion function
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

// permutation of S-box outputs
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

// substitution by S-boxes
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

// S-box lookup
module Sbox (
	input [0:255] s,
	input [1:6] d,
	output [1:4] q
	);

	wire [5:0] index = {d[1],d[6],d[2],d[3],d[4],d[5]};
	assign q[1:4] = s[4*index +: 4];
endmodule
