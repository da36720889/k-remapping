`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Y.T. Tsai
// 
// Create Date: 2025/12/02 10:32:12
// Design Name: 
// Module Name: remapping_oct
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module remapping_oct#(WIDTH = 16, FRACTIONBIT = 15, OUTPUTWIDTH = 16)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH - 1:0] i_data,
    input wire [FRACTIONBIT : 0] i_fraction,
    input wire i_valid,
    input wire trigger,
    output reg [OUTPUTWIDTH - 1:0] o_data,
    output reg o_valid
    );


// add reg at input
reg [WIDTH-1:0] i_data_r, i_data_r_d1;
reg [FRACTIONBIT : 0] i_fraction_r;
reg i_valid_r, trigger_r, trigger_r_d1;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        i_data_r <= 0;
        i_data_r_d1 <= 0;
        i_valid_r <= 0;
        i_fraction_r <= 0;
        trigger_r <= 0;
        trigger_r_d1 <= 0;
    end else begin
        i_data_r <= i_data;
        i_data_r_d1 <= i_data_r;
        i_valid_r <= i_valid;
        i_fraction_r <= i_fraction;
        trigger_r <= trigger;
        trigger_r_d1 <= trigger_r;
    end
end

// fifo_generator_0 u_fifo_0(
//     .clk(clk),// : IN STD_LOGIC;
//     .rst(!rst_n),// : IN STD_LOGIC;
//     .din(i_data_r),// : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
//     .wr_en(i_valid_r),// : IN STD_LOGIC;
//     .rd_en(rd_en),// : IN STD_LOGIC;
//     .dout(data_ff_out),// : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
//     .full(),// : OUT STD_LOGIC;
//     .wr_ack(),// : OUT STD_LOGIC;
//     .empty(),// : OUT STD_LOGIC;
//     .data_count(data_count),// : OUT STD_LOGIC_VECTOR(14 DOWNTO 0);
//     .wr_rst_busy(),// : OUT STD_LOGIC;
//     .rd_rst_busy()// : OUT STD_LOGIC
//   );

 
// calculate fractional part
integer ONE = 1 << FRACTIONBIT;
reg [FRACTIONBIT : 0] ano_part_fraction;
always@(*)begin
    if(trigger_r)begin
        ano_part_fraction = ONE - i_fraction_r;
    end else begin
        ano_part_fraction = 0;
    end
end

 
//  linear interpolation calculation
reg [WIDTH+FRACTIONBIT:0] data0, data1;
reg [WIDTH+2+FRACTIONBIT:0] data_sum;
always@(*)begin
    data_sum = data0 + data1;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        data0 <= 0;
        data1 <= 0;
    end else if(trigger_r)begin
        data0 <= i_data_r * i_fraction_r;
        data1 <= i_data_r_d1 * ano_part_fraction;
    end else begin
        data0 <= 0;
        data1 <= 0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        o_data <= 0;
        o_valid <= 0;
    end else if(trigger_r_d1)begin
        o_data <= (data_sum[FRACTIONBIT-1:0] >= (1 << (FRACTIONBIT-1))) ? (data_sum >> FRACTIONBIT) +1 : (data_sum >> FRACTIONBIT);
        o_valid <= 1;
    end else begin
        o_data <= 0;
        o_valid <= 0;
    end
end

endmodule
