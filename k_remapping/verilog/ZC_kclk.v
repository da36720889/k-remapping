`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Y.T. Tsai
// 
// Create Date: 2025/12/02 08:27:35
// Design Name: 
// Module Name: ZC_kclk
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


module ZC_kclk#(WIDTH = 16, FRACTIONBIT = 15, FIFO_DEPTH = 2048)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH - 1:0] i_data,
    input wire i_valid,
    output reg [FRACTIONBIT :0] o_data,
    output reg trigger,
    output reg o_valid
    );
 
// add reg at input 
reg [WIDTH-1:0] i_data_r;
reg i_valid_r;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        i_data_r <= 0;
        i_valid_r <= 0;
    end else begin
        i_data_r <= i_data;
        i_valid_r <= i_valid;
    end
end
 
// find mean value by first 500 samples
wire [WIDTH -1 : 0] data_ff_out;
reg [WIDTH : 0] sum_max_min;
reg [WIDTH - 1:0] mean_value, max_value, min_value;
reg [9:0] sample_counter;
reg rd_en;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) sum_max_min <= 0;
    else sum_max_min <= max_value + min_value;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) min_value <= 16'hFFFF;
    else if(i_valid_r)begin
        if(sample_counter < 10'd500)begin
            if(i_data_r < min_value) min_value <= i_data_r;
            else  min_value <= min_value;
        end else min_value <= min_value;
    end else min_value <= 16'hFFFF;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) max_value <= 0;
    else if(i_valid_r)begin
        if(sample_counter < 10'd500)begin
            if(i_data_r > max_value) max_value <= i_data_r;
            else  max_value <= max_value;
        end else max_value <= max_value;
    end else max_value <= 0;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) sample_counter <= 0;
    else if(i_valid_r && sample_counter < 10'd500) sample_counter <= sample_counter + 1;
    else sample_counter <= sample_counter;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_en <= 0;
        mean_value <= 0;
    end else if(sample_counter == 10'd500)begin
        rd_en <= 1;
        mean_value <= sum_max_min >> 1;
    end else begin
        rd_en <= rd_en;
        mean_value <= mean_value;
    end 
end
 
// replace fifio ip with self design fifo
reg [WIDTH-1:0] data_buffer [0:FIFO_DEPTH-1];
reg [10:0] write_ptr, read_ptr;
reg [10:0] data_ctr;
integer i;
reg [WIDTH-1:0] fifo_out;
assign data_ff_out = fifo_out;

wire wr_en, full, empty;
assign wr_en = i_valid_r;
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
        data_buffer[write_ptr] <= i_data_r;
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

// wire [14:0] data_count;
// fifo_generator_0 u_fifo(
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

 
// zero crossing detection and kclk output
reg [WIDTH-1:0] data_ff_out_r; 
reg [WIDTH-1:0] fraction_u;
reg [FRACTIONBIT:0] o_fraction;
reg trigger_w, trigger_w_p0, trigger_w_p1, trigger_w_p2, trigger_w_p3, trigger_w_p4, trigger_w_p5, trigger_w_p6, trigger_w_p7, trigger_w_p8,
     trigger_w_p9, trigger_w_p10, trigger_w_p11, trigger_w_p12, trigger_w_p13, trigger_w_p14, trigger_w_p15, trigger_w_p16, trigger_w_p17;
reg [WIDTH-1:0] fraction_d;
reg [4:0] pickcase; // to select division unit, 17 dividers is used to fit worst case
reg div_valid;      // to indicate division valid signal
reg [WIDTH-1:0]i_data_u_w, i_data_d_w;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        data_ff_out_r <= 0;
    end else begin 
        data_ff_out_r <= data_ff_out;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fraction_u <= 0;
        fraction_d <= 0;
    end else if(data_ff_out >= mean_value && data_ff_out_r < mean_value)begin   // rising edge
        fraction_u <= (mean_value - data_ff_out_r);
        fraction_d <= data_ff_out - data_ff_out_r;
    end else if(data_ff_out < mean_value && data_ff_out_r >= mean_value)begin   // falling edge
        fraction_u <= (data_ff_out_r - mean_value);
        fraction_d <= data_ff_out_r - data_ff_out;
    end else begin
        fraction_u <= 0;
        fraction_d <= 0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        pickcase <= 0;
        div_valid <= 0;
    end else if(data_ff_out >= mean_value && data_ff_out_r < mean_value && pickcase < 5'd17)begin   //rising edge
        // pickcase <= pickcase + 1;           
        // div_valid <= 1;
        pickcase <= pickcase;
        div_valid <= 0;
    end else if(data_ff_out >= mean_value && data_ff_out_r < mean_value && pickcase == 5'd17) begin  //rising edge
        // pickcase <= 0;
        // div_valid <= 1;
        pickcase <= pickcase;
        div_valid <= 0;
    end else if(data_ff_out < mean_value && data_ff_out_r >= mean_value && pickcase < 5'd17)begin   // falling edge
        pickcase <= pickcase + 1;
        div_valid <= 1;
        // pickcase <= pickcase;
        // div_valid <= 0;
    end else if(data_ff_out < mean_value && data_ff_out_r >= mean_value && pickcase == 5'd17)begin  // falling edge
        pickcase <= 0;
        div_valid <= 1;
        // pickcase <= pickcase;
        // div_valid <= 0;
    end else begin
        pickcase <= pickcase;
        div_valid <= 0;
    end
end


reg div_u1_sig, div_u2_sig, div_u3_sig, div_u4_sig, div_u5_sig, div_u6_sig, div_u7_sig, div_u8_sig, div_u9_sig,
         div_u10_sig, div_u11_sig, div_u12_sig, div_u13_sig, div_u14_sig, div_u15_sig, div_u16_sig, div_u17_sig;
wire o_valid_u1, o_valid_u2, o_valid_u3, o_valid_u4, o_valid_u5, o_valid_u6, o_valid_u7, o_valid_u8, o_valid_u9,
         o_valid_u10, o_valid_u11, o_valid_u12, o_valid_u13, o_valid_u14, o_valid_u15, o_valid_u16, o_valid_u17;
wire [FRACTIONBIT+1:0] o_fraction_u1_w, o_fraction_u2_w, o_fraction_u3_w, o_fraction_u4_w, o_fraction_u5_w, o_fraction_u6_w, o_fraction_u7_w, 
                o_fraction_u8_w, o_fraction_u9_w, o_fraction_u10_w, o_fraction_u11_w, o_fraction_u12_w, o_fraction_u13_w, o_fraction_u14_w, 
                o_fraction_u15_w, o_fraction_u16_w, o_fraction_u17_w;

always@(*)begin
    if(div_valid) begin
        i_data_u_w = fraction_u;
        i_data_d_w = fraction_d;
        case(pickcase)
        5'b00000 : begin
            div_u1_sig  = 1;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b00001 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 1;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b00010 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 1;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b00011 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 1;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b00100 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 1;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b00101 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 1;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b00110 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 1;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b00111 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 1;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b01000 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 1;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b01001 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 1;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b01010 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 1;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b01011 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 1;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b01100 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 1;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b01101 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 1;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b01110 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 1;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        5'b01111 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 1;
            div_u17_sig = 0;
        end
        5'b10000 : begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 1;
        end
        default: begin
            div_u1_sig  = 0;
            div_u2_sig  = 0;
            div_u3_sig  = 0;
            div_u4_sig  = 0;
            div_u5_sig  = 0;
            div_u6_sig  = 0;
            div_u7_sig  = 0;
            div_u8_sig  = 0;
            div_u9_sig  = 0;
            div_u10_sig = 0;
            div_u11_sig = 0;
            div_u12_sig = 0;
            div_u13_sig = 0;
            div_u14_sig = 0;
            div_u15_sig = 0;
            div_u16_sig = 0;
            div_u17_sig = 0;
        end
        endcase
    end else begin
        i_data_u_w = 0;
        i_data_d_w = 0;
        div_u1_sig  = 0;
        div_u2_sig  = 0;
        div_u3_sig  = 0;
        div_u4_sig  = 0;
        div_u5_sig  = 0;
        div_u6_sig  = 0;
        div_u7_sig  = 0;
        div_u8_sig  = 0;
        div_u9_sig  = 0;
        div_u10_sig = 0;
        div_u11_sig = 0;
        div_u12_sig = 0;
        div_u13_sig = 0;
        div_u14_sig = 0;
        div_u15_sig = 0;
        div_u16_sig = 0;
        div_u17_sig = 0;
    end
end
wire [16:0] frac_case;
assign frac_case = {o_valid_u17, o_valid_u16, o_valid_u15, o_valid_u14, o_valid_u13, o_valid_u12, o_valid_u11, o_valid_u10,
        o_valid_u9, o_valid_u8, o_valid_u7, o_valid_u6, o_valid_u5, o_valid_u4, o_valid_u3, o_valid_u2, o_valid_u1};

reg [FRACTIONBIT:0] o_fraction_w;
always@(*)begin
    case(frac_case)
     17'b00000000000000001 : o_fraction_w = (o_fraction_u1_w[0]) ? (o_fraction_u1_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u1_w[1+:(FRACTIONBIT+1)];
     17'b00000000000000010 : o_fraction_w = (o_fraction_u2_w[0]) ? (o_fraction_u2_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u2_w[1+:(FRACTIONBIT+1)];
     17'b00000000000000100 : o_fraction_w = (o_fraction_u3_w[0]) ? (o_fraction_u3_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u3_w[1+:(FRACTIONBIT+1)];
     17'b00000000000001000 : o_fraction_w = (o_fraction_u4_w[0]) ? (o_fraction_u4_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u4_w[1+:(FRACTIONBIT+1)];
     17'b00000000000010000 : o_fraction_w = (o_fraction_u5_w[0]) ? (o_fraction_u5_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u5_w[1+:(FRACTIONBIT+1)];
     17'b00000000000100000 : o_fraction_w = (o_fraction_u6_w[0]) ? (o_fraction_u6_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u6_w[1+:(FRACTIONBIT+1)];
     17'b00000000001000000 : o_fraction_w = (o_fraction_u7_w[0]) ? (o_fraction_u7_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u7_w[1+:(FRACTIONBIT+1)];
     17'b00000000010000000 : o_fraction_w = (o_fraction_u8_w[0]) ? (o_fraction_u8_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u8_w[1+:(FRACTIONBIT+1)];
     17'b00000000100000000 : o_fraction_w = (o_fraction_u9_w[0]) ? (o_fraction_u9_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u9_w[1+:(FRACTIONBIT+1)];
     17'b00000001000000000 : o_fraction_w = (o_fraction_u10_w[0]) ? (o_fraction_u10_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u10_w[1+:(FRACTIONBIT+1)];
     17'b00000010000000000 : o_fraction_w = (o_fraction_u11_w[0]) ? (o_fraction_u11_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u11_w[1+:(FRACTIONBIT+1)];
     17'b00000100000000000 : o_fraction_w = (o_fraction_u12_w[0]) ? (o_fraction_u12_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u12_w[1+:(FRACTIONBIT+1)];
     17'b00001000000000000 : o_fraction_w = (o_fraction_u13_w[0]) ? (o_fraction_u13_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u13_w[1+:(FRACTIONBIT+1)];
     17'b00010000000000000 : o_fraction_w = (o_fraction_u14_w[0]) ? (o_fraction_u14_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u14_w[1+:(FRACTIONBIT+1)];
     17'b00100000000000000 : o_fraction_w = (o_fraction_u15_w[0]) ? (o_fraction_u15_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u15_w[1+:(FRACTIONBIT+1)];
     17'b01000000000000000 : o_fraction_w = (o_fraction_u16_w[0]) ? (o_fraction_u16_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u16_w[1+:(FRACTIONBIT+1)];
     17'b10000000000000000 : o_fraction_w = (o_fraction_u17_w[0]) ? (o_fraction_u17_w[1+:(FRACTIONBIT+1)] + 1) : o_fraction_u17_w[1+:(FRACTIONBIT+1)];
     default: o_fraction_w = 0;
    endcase
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) o_fraction <= 0;
    else if(|frac_case) o_fraction <= o_fraction_w;
    else o_fraction <= o_fraction;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        trigger_w_p17 <= 0;
        trigger_w_p16 <= 0;
        trigger_w_p15 <= 0;
        trigger_w_p14 <= 0;
        trigger_w_p13 <= 0;
        trigger_w_p12 <= 0;
        trigger_w_p11 <= 0;
        trigger_w_p10 <= 0;
        trigger_w_p9 <= 0;
        trigger_w_p8 <= 0;
        trigger_w_p7 <= 0;
        trigger_w_p6 <= 0;
        trigger_w_p5 <= 0;
        trigger_w_p4 <= 0;
        trigger_w_p3 <= 0;
        trigger_w_p2 <= 0;
        trigger_w_p1 <= 0;
        trigger_w <= 0;
    end else begin 
        trigger_w_p17 <= div_valid;
        trigger_w_p16 <= trigger_w_p17;
        trigger_w_p15 <= trigger_w_p16;
        trigger_w_p14 <= trigger_w_p15;
        trigger_w_p13 <= trigger_w_p14;
        trigger_w_p12 <= trigger_w_p13;
        trigger_w_p11 <= trigger_w_p12;
        trigger_w_p10 <= trigger_w_p11;
        trigger_w_p9 <= trigger_w_p10;
        trigger_w_p8 <= trigger_w_p9;
        trigger_w_p7 <= trigger_w_p8;
        trigger_w_p6 <= trigger_w_p7;
        trigger_w_p5 <= trigger_w_p6;
        trigger_w_p4 <= trigger_w_p5;
        trigger_w_p3 <= trigger_w_p4;
        trigger_w_p2 <= trigger_w_p3;
        trigger_w_p1 <= trigger_w_p2;
        trigger_w_p0 <= trigger_w_p1;
        trigger_w <= trigger_w_p0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        o_data <= 0;
        trigger <= 0;
    end else if(trigger_w)begin
        o_data <= o_fraction;
        trigger <= trigger_w;   
    end else begin
        o_data <= 0;
        trigger <= 0;
    end
end

divider u_divider_01(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u1_sig),
    .o_fraction(o_fraction_u1_w),
    .o_valid(o_valid_u1)
);
divider u_divider_02(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u2_sig),
    .o_fraction(o_fraction_u2_w),
    .o_valid(o_valid_u2)
);
divider u_divider_03(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u3_sig),
    .o_fraction(o_fraction_u3_w),
    .o_valid(o_valid_u3)
);
divider u_divider_04(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u4_sig),
    .o_fraction(o_fraction_u4_w),
    .o_valid(o_valid_u4)
);
divider u_divider_05(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u5_sig),
    .o_fraction(o_fraction_u5_w),
    .o_valid(o_valid_u5)
);
divider u_divider_06(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u6_sig),
    .o_fraction(o_fraction_u6_w),
    .o_valid(o_valid_u6)
);
divider u_divider_07(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u7_sig),
    .o_fraction(o_fraction_u7_w),
    .o_valid(o_valid_u7)
);
divider u_divider_08(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u8_sig),
    .o_fraction(o_fraction_u8_w),
    .o_valid(o_valid_u8)
);
divider u_divider_09(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u9_sig),
    .o_fraction(o_fraction_u9_w),
    .o_valid(o_valid_u9)
);
divider u_divider_10(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u10_sig),
    .o_fraction(o_fraction_u10_w),
    .o_valid(o_valid_u10)
);
divider u_divider_11(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u11_sig),
    .o_fraction(o_fraction_u11_w),
    .o_valid(o_valid_u11)
);
divider u_divider_12(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u12_sig),
    .o_fraction(o_fraction_u12_w),
    .o_valid(o_valid_u12)
);
divider u_divider_13(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u13_sig),
    .o_fraction(o_fraction_u13_w),
    .o_valid(o_valid_u13)
);
divider u_divider_14(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u14_sig),
    .o_fraction(o_fraction_u14_w),
    .o_valid(o_valid_u14)
);
divider u_divider_15(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u15_sig),
    .o_fraction(o_fraction_u15_w),
    .o_valid(o_valid_u15)
);
divider u_divider_16(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u16_sig),
    .o_fraction(o_fraction_u16_w),
    .o_valid(o_valid_u16)
);
divider u_divider_17(
    .clk(clk),
    .rst_n(rst_n),
    .i_data_u(i_data_u_w),
    .i_data_d(i_data_d_w),
    .i_valid(div_u17_sig),
    .o_fraction(o_fraction_u17_w),
    .o_valid(o_valid_u17)
);

// =================================== using reciprocal table ========================================== //
// wire [WIDTH-1:0] reciprocal_out;
// wire [WIDTH-1:0] fraction_d_w;
// reg [WIDTH-1:0] reciprocal_rom [0:(1 << WIDTH) - 1];
// initial $readmemh("C:/Users/ /Documents/OCT_project/OCT_project.srcs/sources_1/reciprocaltable_FRACTIONBIT15.coe", reciprocal_rom);
// // always@(*) fraction_d = (data_ff_out >= data_ff_out_r) ? (data_ff_out - data_ff_out_r) : (data_ff_out_r - data_ff_out);
// assign fraction_d_w = fraction_d;
// assign reciprocal_out = reciprocal_rom[fraction_d_w]; 

// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin
//         o_fraction <= 0;
//     // end else if(data_ff_out_r >= data_ff_out_r_d1)begin
//     //     o_fraction <= fraction_u * reciprocal_out;
//     end else begin
//         o_fraction <= fraction_u * reciprocal_out;
//         // o_fraction <= (fraction_u << FRACTIONBIT) / fraction_d;  
//     end
// end


endmodule
