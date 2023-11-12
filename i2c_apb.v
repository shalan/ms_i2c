
/*
	Copyright 2019 Mohamed Shalan 

	Author: Mohamed Shalan (mshalan@aucegypt.edu)

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	    http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

*/


`timescale			1ns/1ns
`default_nettype	none

`define		APB_BLOCK(name, init)		always @(posedge PCLK or negedge PRESETn) if(~PRESETn) name <= init;
`define		APB_REG(name, init, size)	`APB_BLOCK(name, init) else if(apb_we & (PADDR[15:0]==``name``_ADDR)) name <= PWDATA[``size``-1:0];
`define		APB_ICR(size)				`APB_BLOCK(ICR_REG, ``size``'b0) else if(apb_we & (PADDR[15:0]==ICR_REG_ADDR)) ICR_REG <= PWDATA[``size``-1:0]; else ICR_REG <= ``size``'d0;


module APB2I2C(
    //APB Inputs
    input wire          PCLK,
    input wire          PRESETn,
    input wire          PWRITE,
    input wire [31:0]   PWDATA,
    input wire [31:0]   PADDR,
    input wire          PENABLE,
    input wire          PSEL,
    
    //APB Outputs
    output wire         PREADY,
    output wire [31:0]  PRDATA,

    // IRQ
    output wire         irq,

    // i2c Ports
    input 	wire scl_i,	    // SCL-line input
	output 	wire scl_o,	    // SCL-line output (always 1'b0)
	output 	wire scl_oen_o, // SCL-line output enable (active low)
	input	wire sda_i,     // SDA-line input
	output	wire sda_o,	    // SDA-line output (always 1'b0)
	output	wire sda_oen_o // SDA-line output enable (active low)
    
);

    assign PREADY = 1'b1; //always ready

    wire [7:0]      io_do;
    wire            io_we = (PADDR[15:8] != 8'h0F) & PENABLE & PWRITE & PREADY & PSEL;
    wire            io_re = (PADDR[15:8] != 8'h0F) & PENABLE & ~PWRITE & PREADY & PSEL;

    wire [7:0]      ris;
    wire            i2c_irq;

    reg [7:0]       RIS_REG, IM_REG, ICR_REG;
    wire [7:0]      MIS_REG = ris & IM_REG;

    // Interrupts Handeling
    localparam[15:0] ICR_REG_ADDR = 16'h0f00;
	localparam[15:0] RIS_REG_ADDR = 16'h0f04;
	localparam[15:0] IM_REG_ADDR = 16'h0f08;
	localparam[15:0] MIS_REG_ADDR = 16'h0f0c;

    `APB_REG(IM_REG, 0, 8)
    `APB_ICR(8)

    integer i;
    always @(posedge PCLK or negedge PRESETn)
	    if(~PRESETn) RIS_REG <= 8'd0;
		else begin
            for(i=0; i<8; i=i+1)
			    if(ris[i]) RIS_REG[i] <= 1'b1; else if(ICR_REG[i]) RIS_REG[i] <= 1'b0;
		end

    assign IRQ = |MIS_REG;

    i2c_master i2c (
            .sys_clk(PCLK),
            .sys_rst(~PRESETn),
            //
            .io_a(PADDR[7:2]),
            .io_di(PWDATA[7:0]),
            .io_do(io_do),
            .io_re(io_re),
            .io_we(io_we),
            //
            .i2c_irq(i2c_irq),
            //
            .scl_i(scl_i),	   // SCL-line input
            .scl_o(scl_o),	   // SCL-line output (always 1'b0)
            .scl_oen_o(scl_oen_o), // SCL-line output enable (active low)
            .sda_i(sda_i),		// SDA-line input
            .sda_o(sda_o),	   // SDA-line output (always 1'b0)
            .sda_oen_o(sda_oen_o)  // SDA-line output enable (active low)
    );

    assign PRDATA[31:0] = io_do;//I2C_DATA_REG;
  
endmodule