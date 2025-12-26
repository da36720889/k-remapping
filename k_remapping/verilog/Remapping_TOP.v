`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Y.T. Tsai
// 
// Create Date: 2025/12/03 11:12:32
// Design Name: 
// Module Name: Remapping_TOP
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


module Remapping_TOP#(WIDTH = 16, FRACTIONBIT = 15, OUTPUTWIDTH = 16, FIFO_DEPTH = 2048)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] kclk_data,
    input wire [WIDTH-1:0] oct_data,
    input wire i_valid,
    output reg [OUTPUTWIDTH-1:0] o_data,
    output reg o_valid
    );
localparam delay4oct = 10'd518; 
reg [WIDTH-1:0] oct_data_r, oct_data_r_d1;
wire [WIDTH-1:0] oct_data_ff_out;
reg [9:0] counter;
reg i_valid_r, i_valid_r_d1, rd_en;
wire [OUTPUTWIDTH-1:0] o_data_w;
reg [OUTPUTWIDTH-1:0] o_data_r;
wire o_valid_w;
reg  o_valid_r;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        oct_data_r <= 0;
        oct_data_r_d1 <= 0;
        i_valid_r <= 0;
        i_valid_r_d1 <= 0;
    end else begin
        oct_data_r <= oct_data;
        oct_data_r_d1 <= oct_data_r;
        i_valid_r <= i_valid;
        i_valid_r_d1 <= i_valid_r;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) counter <= 0;
    else if(i_valid_r_d1 && counter < delay4oct) counter <= counter + 1;
    else counter <= counter;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) rd_en <= 0;
    else if(counter == delay4oct) rd_en <= 1;
    else rd_en <= rd_en;
end


 
// replace fifio ip with self design fifo
reg [WIDTH-1:0] data_buffer [0:FIFO_DEPTH-1];
reg [10:0] write_ptr, read_ptr;
reg [10:0] data_ctr;
integer i;
reg [WIDTH-1:0] fifo_out;
assign oct_data_ff_out = fifo_out;

wire wr_en, full, empty;
assign wr_en = i_valid_r_d1;
assign full = (data_ctr == FIFO_DEPTH) ? 1 : 0;
assign empty = (data_ctr == 0) ? 1 : 0;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        write_ptr <= 0;
    end else if (!full && wr_en) begin
        write_ptr <= write_ptr + 1;
    end else begin
        write_ptr <= write_ptr;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i = 0; i < FIFO_DEPTH; i = i + 1)begin
            data_buffer[i] <= 0;
        end
    end else if(!full && wr_en)begin
        data_buffer[write_ptr] <= oct_data_r_d1;
    end else begin
        for(i = 0; i < FIFO_DEPTH; i = i + 1)begin
            data_buffer[i] <= data_buffer[i];
        end
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        read_ptr <= 0;
    end else if (!empty && rd_en)begin
        read_ptr <= read_ptr + 1;
    end else begin
        read_ptr <= read_ptr;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fifo_out <= 0;
    end else if(!empty && rd_en)begin
        fifo_out <= data_buffer[read_ptr];
    end else begin
        fifo_out <= 0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        data_ctr <= 0;
    end else begin
        case({wr_en, rd_en})
        2'b00 : data_ctr <= data_ctr;
        2'b01 : if(data_ctr > 0) data_ctr <= data_ctr - 1;
        2'b10 : if(data_ctr < FIFO_DEPTH-1) data_ctr <= data_ctr + 1;
        2'b11 : data_ctr <= data_ctr; 
        endcase
    end
end


// fifo_generator_0 u_fifo0(
//     .clk(clk),// : IN STD_LOGIC;
//     .rst(!rst_n),// : IN STD_LOGIC;
//     .din(oct_data_r_d1),// : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
//     .wr_en(i_valid_r_d1),// : IN STD_LOGIC;
//     .rd_en(rd_en),// : IN STD_LOGIC;
//     .dout(oct_data_ff_out),// : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
//     .full(),// : OUT STD_LOGIC;
//     .wr_ack(),// : OUT STD_LOGIC;
//     .empty(),// : OUT STD_LOGIC;
//     .data_count(),// : OUT STD_LOGIC_VECTOR(14 DOWNTO 0);
//     .wr_rst_busy(),// : OUT STD_LOGIC;
//     .rd_rst_busy()// : OUT STD_LOGIC
//   );


wire [FRACTIONBIT:0] zcout_fraction_w;
wire zcout_trigger_w;

ZC_kclk u_kclk(
    .clk(clk),
    .rst_n(rst_n),
    .i_data(kclk_data),
    .i_valid(i_valid),
    .o_data(zcout_fraction_w),
    .trigger(zcout_trigger_w),
    .o_valid()
    );

remapping_oct u_oct(
    .clk(clk),
    .rst_n(rst_n),
    .i_data(oct_data_ff_out),
    .i_fraction(zcout_fraction_w),
    .i_valid(i_valid),
    .trigger(zcout_trigger_w),
    .o_data(o_data_w),
    .o_valid(o_valid_w)
    );


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        o_data_r <= 0;
        o_valid_r <= 0;
        o_valid <= 0;
        o_data <= 0;
    end else begin
        o_data_r <= o_data_w;
        o_data <= o_data_r;
        o_valid_r <= o_valid_w;
        o_valid <= o_valid_r;
    end
end
    
endmodule
