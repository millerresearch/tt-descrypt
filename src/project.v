/*
 * Copyright (c) 2026 Richard Miller
 * SPDX-License-Identifier: Apache-2.0
 */

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

  // SPI connections
  wire SS, MOSI, MISO, SCLK;
  assign SS = uio_in[0];
  assign MOSI = uio_in[1];
  assign uio_out[2] = MISO;
  assign SCLK = uio_in[3];
  // enable MISO output only when selected, disable other bidir outputs
  assign uio_oe = {5'b0,~SS,2'b0};

  // All output pins must be assigned.
  assign uo_out  = 0;
  assign uio_out[7:3] = 0;
  assign uio_out[1:0] = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, &ui_in, uio_in[7:4], uio_in[2], 1'b0};

  spides SPIDES(clk, ~rst_n, SCLK, SS, MOSI, MISO);

endmodule
