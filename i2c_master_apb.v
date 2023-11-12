/*
    Copyright (c) 2023 Mohamed Shalan (mshalan@aucegypt.edu)

    APB Interface with Interrupt management for the 
    i2c Master Controller by Alex Forencich

	Licensed under the Apache License, Version 2.0 (the "License"); 
	you may not use this file except in compliance with the License. 
	You may obtain a copy of the License at:
	http://www.apache.org/licenses/LICENSE-2.0
	
    Unless required by applicable law or agreed to in writing, software 
	distributed under the License is distributed on an "AS IS" BASIS, 
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
	See the License for the specific language governing permissions and 
	limitations under the License.
*/

`timescale			    1ns/1ns
`default_nettype	    none

`define		APB_BLOCK(name, init)		always @(posedge PCLK or negedge PRESETn) if(~PRESETn) name <= init;
`define		APB_REG(name, init, size)	`APB_BLOCK(name, init) else if(apb_we & (PADDR[15:0]==``name``_ADDR)) name <= PWDATA[``size``-1:0];

module i2c_master_apb #
(
    parameter DEFAULT_PRESCALE = 1,
    parameter FIXED_PRESCALE = 0,
    parameter CMD_FIFO = 1,
    parameter CMD_FIFO_DEPTH = 16,
    parameter WRITE_FIFO = 1,
    parameter WRITE_FIFO_DEPTH = 16,
    parameter READ_FIFO = 1,
    parameter READ_FIFO_DEPTH = 16
)
(
    input wire          PCLK,
    input wire          PRESETn,
 
    // APB  Interface
    input wire          PWRITE,
    input wire [31:0]   PWDATA,
    input wire [31:0]   PADDR,
    input wire          PENABLE,
    input wire          PSEL,
    
    output wire         PREADY,
    output wire [31:0]  PRDATA,

    // I2C interface
    input  wire        i2c_scl_i,
    output wire        i2c_scl_o,
    output wire        i2c_scl_t,
    input  wire        i2c_sda_i,
    output wire        i2c_sda_o,
    output wire        i2c_sda_t,

    output wire        IRQ
);

    localparam[15:0] RIS_REG_ADDR = 16'h0f04;
    localparam[15:0] IM_REG_ADDR = 16'h0f08;
    localparam[15:0] MIS_REG_ADDR = 16'h0f0c;

    wire        clk         = PCLK;
    wire        rst         = ~PRESETn;
    wire  [2:0] wbs_adr_i   = PADDR[3:1];
    wire [15:0] wbs_dat_i   = PWDATA[15:0];
    wire [15:0] wbs_dat_o;
    wire        wbs_we_i    = PWRITE; 
    wire  [1:0] wbs_sel_i   = 2'b11;
    wire        wbs_stb_i   = (PADDR[15:8] != 8'h0F) & PSEL & PENABLE;
    wire        wbs_ack_o;
    wire        wbs_cyc_i   = (PADDR[15:8] != 8'h0F) & PSEL;

    wire [15:0] flags;

    assign PREADY = wbs_ack_o;
    assign PRDATA = (PADDR[15:8] != 8'h0F)          ? {16'b0, wbs_dat_o}:
                    (PADDR[15:0] == RIS_REG_ADDR)   ? {23'b0, RIS_REG}  :
                    (PADDR[15:0] == MIS_REG_ADDR)   ? {23'b0, MIS_REG}  :
                    (PADDR[15:0] == IM_REG_ADDR)    ? {23'b0, IM_REG}   :
                    32'hDEADBEEF;
    
    i2c_master_wbs_16 #
    (
        .DEFAULT_PRESCALE(DEFAULT_PRESCALE),
        .FIXED_PRESCALE(FIXED_PRESCALE),
        .CMD_FIFO(CMD_FIFO),
        .CMD_FIFO_DEPTH (CMD_FIFO_DEPTH),
        .WRITE_FIFO(WRITE_FIFO),
        .WRITE_FIFO_DEPTH (WRITE_FIFO_DEPTH),
        .READ_FIFO(READ_FIFO),
        .READ_FIFO_DEPTH(READ_FIFO_DEPTH)
    )
    master_inst (
        .clk(clk),
        .rst(rst),

        /*
        * Host interface
        */
        .wbs_adr_i(wbs_adr_i),   // ADR_I() address
        .wbs_dat_i(wbs_dat_i),   // DAT_I() data in
        .wbs_dat_o(wbs_dat_o),   // DAT_O() data out
        .wbs_we_i(wbs_we_i),    // WE_I write enable input
        .wbs_sel_i(wbs_sel_i),   // SEL_I() select input
        .wbs_stb_i(wbs_stb_i),   // STB_I strobe input
        .wbs_ack_o(wbs_ack_o),   // ACK_O acknowledge output
        .wbs_cyc_i(wbs_cyc_i),   // CYC_I cycle input

        // I2C interface
        .i2c_scl_i(i2c_scl_i),
        .i2c_scl_o(i2c_scl_o),
        .i2c_scl_t(i2c_scl_t),
        .i2c_sda_i(i2c_sda_i),
        .i2c_sda_o(i2c_sda_o),
        .i2c_sda_t(i2c_sda_t),

        .flags(flags)
    );

    // Interrupts Handeling

    wire		    apb_valid	= PSEL & PENABLE;
	wire		    apb_we	= PWRITE & apb_valid;
    
    wire [8:0]      RIS_REG = {flags[15:8], flags[3]};
    reg [8:0]       IM_REG;
    wire [8:0]      MIS_REG = RIS_REG & IM_REG;

    `APB_REG(IM_REG, 0, 9)

    assign IRQ = |MIS_REG;


endmodule