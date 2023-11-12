/*



*/

`timescale			    1ns/1ns
`default_nettype	    none

module i2c_master_wb #
(
    parameter DEFAULT_PRESCALE = 1,
    parameter FIXED_PRESCALE = 0,
    parameter CMD_FIFO = 1,
    parameter CMD_FIFO_DEPTH = 32,
    parameter WRITE_FIFO = 1,
    parameter WRITE_FIFO_DEPTH = 32,
    parameter READ_FIFO = 1,
    parameter READ_FIFO_DEPTH = 32
)
(
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] wbs_adr_i,   // ADR_I() address
    input  wire [31:0] wbs_dat_i,   // DAT_I() data in
    output wire [31:0] wbs_dat_o,   // DAT_O() data out
    input  wire        wbs_we_i,    // WE_I write enable input
    input  wire  [1:0] wbs_sel_i,   // SEL_I() select input
    input  wire        wbs_stb_i,   // STB_I strobe input
    output wire        wbs_ack_o,   // ACK_O acknowledge output
    input  wire        wbs_cyc_i,   // CYC_I cycle input

    // I2C interface
    input  wire        i2c_scl_i,
    output wire        i2c_scl_o,
    output wire        i2c_scl_t,
    input  wire        i2c_sda_i,
    output wire        i2c_sda_o,
    output wire        i2c_sda_t
);

    assign wbs_dat_o[31:0]  =   16'b0;

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
        .wbs_adr_i(wbs_adr_i[3:1]),   // ADR_I() address
        .wbs_dat_i(wbs_dat_i[15:0]),   // DAT_I() data in
        .wbs_dat_o(wbs_dat_o[15:0]),   // DAT_O() data out
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
        .i2c_sda_t(i2c_sda_o),
    );

endmodule