`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Y.T. Tsai
// 
// Create Date: 2025/12/17 11:53:36
// Design Name: 
// Module Name: divider
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


module divider#(WIDTH = 16, FRACTIONBIT = 16)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] i_data_u,
    input wire [WIDTH-1:0] i_data_d,
    input wire i_valid,
    output reg [FRACTIONBIT:0] o_fraction,
    output reg o_valid
    );
reg [FRACTIONBIT:0] o_fraction_w;

reg [WIDTH-1:0] data_d;
reg [WIDTH-1:0] data_u;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        data_u <= 0;
        data_d <= 0;
    end else if(i_valid) begin
        data_u <= i_data_u;
        data_d <= i_data_d;
    end else begin
        data_u <= data_u;
        data_d <= data_d;
    end
end

// counter for division
reg [5:0] counter;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) counter <= 0;
    else if(i_valid) counter <= 0;
    else if(counter < FRACTIONBIT) counter <= counter + 1;
    else counter <= counter;
end

// division process
reg [WIDTH:0] data_u_e, data_u_o;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        data_u_e <= 0;
        data_u_o <= 0;
        o_fraction_w <= 0;
    end else begin
        case(counter)
        6'd0 : begin
            if(data_u >= data_d)begin
                data_u_e <= (data_u - data_d) << 1;
                o_fraction_w[FRACTIONBIT-counter] <= 1;
                data_u_o <= data_u_o;
            end else begin
                data_u_e <= data_u << 1;
                o_fraction_w[FRACTIONBIT-counter] <= 0;
                data_u_o <= data_u_o;
            end
        end
        6'd1, 6'd3, 6'd5, 6'd7, 6'd9, 6'd11, 6'd13, 6'd15 : begin
            if(data_u_e >= data_d)begin
                data_u_o <= (data_u_e - data_d) << 1;
                o_fraction_w[FRACTIONBIT-counter] <= 1;
                data_u_e <= data_u_e;
            end else begin
                data_u_o <= data_u_e << 1;
                o_fraction_w[FRACTIONBIT-counter] <= 0;
                data_u_e <= data_u_e;
            end
        end
        6'd2, 6'd4, 6'd6, 6'd8, 6'd10, 6'd12, 6'd14, 6'd16: begin
            if(data_u_o >= data_d)begin
                data_u_e <= (data_u_o - data_d) << 1;
                o_fraction_w[FRACTIONBIT-counter] <= 1;
                data_u_o <= data_u_o;
            end else begin
                data_u_e <= data_u_o << 1;
                o_fraction_w[FRACTIONBIT-counter] <= 0;
                data_u_o <= data_u_o;
            end
        end
        default: begin
            data_u_e <= data_u_e;
            data_u_o <= data_u_o;
            o_fraction_w <= o_fraction_w;
        end
        endcase
    end
end

// single pulse for o_valid
reg valid_sig;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        valid_sig <= 0;
    end else if(counter == FRACTIONBIT-1)begin
        valid_sig <= 1;
    end else begin
        valid_sig <= 0;
    end
end

// output
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin 
        o_fraction <= 0;
        o_valid <= 0;
    end else if(counter == 6'd16 && valid_sig) begin
        o_fraction <= o_fraction_w;
        o_valid <= 1;
    end else begin
        o_fraction <= o_fraction;
        o_valid <= 0;
    end
end

endmodule


// reg [WIDTH-1+1:0] data_u_1, data_u_2, data_u_3, data_u_4, data_u_5, data_u_6, data_u_7, data_u_8, data_u_9, data_u_10,
//                   data_u_11, data_u_12, data_u_13, data_u_14, data_u_15, data_u_16;

// reg [WIDTH-1+1:0] data_u_17, data_u_18, data_u_19, data_u_20, data_u_21, data_u_22, data_u_23, data_u_24, data_u_25, data_u_26,
//                   data_u_27, data_u_28, data_u_29, data_u_30, data_u_31, data_u_32;

// // first cycle calculate o_fraction_w[FRACTIONBIT]
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_1 <= 0;
//         o_fraction_w[16] <= 0;
//     end else if(counter == 6'd0) begin
//         if(data_u >= data_d)begin
//             data_u_1 <= (data_u - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-0] <= 1;
//         end else begin
//             data_u_1 <= data_u << 1;
//             o_fraction_w[FRACTIONBIT-0] <= 0;
//         end
//     end else begin
//         data_u_1 <= data_u_1;
//         o_fraction_w[FRACTIONBIT-0] <= o_fraction_w[FRACTIONBIT-0];
//     end
// end

// // 2nd cycle calculate o_fraction_w[FRACTIONBIT -1]
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n) begin 
//         data_u_2 <= 0;
//         o_fraction_w[15] <= 0;
//     end else if(counter == 6'd1) begin
//         if(data_u_1 >= data_d)begin
//             data_u_2 <= (data_u_1 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-1] <= 1;
//         end else begin
//             data_u_2 <= data_u_1 << 1;
//             o_fraction_w[FRACTIONBIT-1] <= 0;
//         end
//     end else begin
//         data_u_2 <= data_u_2;
//         o_fraction_w[FRACTIONBIT-1] <= o_fraction_w[FRACTIONBIT-1];
//     end
// end

// // 3rd cycle calculate o_fraction_w[FRACTIONBIT -2]
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_3 <= 0;
//         o_fraction_w[14] <= 0;
//     end else if(counter == 6'd2) begin
//         if(data_u_2 >= data_d)begin
//             data_u_3 <= (data_u_2 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-2] <= 1;
//         end else begin
//             data_u_3 <= data_u_2 << 1;
//             o_fraction_w[FRACTIONBIT-2] <= 0;
//         end
//     end else begin
//         data_u_3 <= data_u_3;
//         o_fraction_w[FRACTIONBIT-2] <= o_fraction_w[FRACTIONBIT-2];
//     end
// end

// // 4th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_4 <= 0;
//         o_fraction_w[13] <= 0;
//     end else if(counter == 6'd3) begin
//         if(data_u_3 >= data_d)begin
//             data_u_4 <= (data_u_3 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-3] <= 1;
//         end else begin
//             data_u_4 <= data_u_3 << 1;
//             o_fraction_w[FRACTIONBIT-3] <= 0;
//         end
//     end else begin
//         data_u_4 <= data_u_4;
//         o_fraction_w[FRACTIONBIT-3] <= o_fraction_w[FRACTIONBIT-3];
//     end
// end

// // 5th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_5 <= 0;
//         o_fraction_w[12] <= 0;
//     end else if(counter == 6'd4) begin
//         if(data_u_4 >= data_d)begin
//             data_u_5 <= (data_u_4 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-4] <= 1;
//         end else begin
//             data_u_5 <= data_u_4 << 1;
//             o_fraction_w[FRACTIONBIT-4] <= 0;
//         end
//     end else begin
//         data_u_5 <= data_u_5;
//         o_fraction_w[FRACTIONBIT-4] <= o_fraction_w[FRACTIONBIT-4];
//     end
// end

// // 6th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_6 <= 0;
//         o_fraction_w[11] <= 0;
//     end else if(counter == 6'd5) begin
//         if(data_u_5 >= data_d)begin
//             data_u_6 <= (data_u_5 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-5] <= 1;
//         end else begin
//             data_u_6 <= data_u_5 << 1;
//             o_fraction_w[FRACTIONBIT-5] <= 0;
//         end
//     end else begin
//         data_u_6 <= data_u_6;
//         o_fraction_w[FRACTIONBIT-5] <= o_fraction_w[FRACTIONBIT-5];
//     end
// end

// // 7th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_7 <= 0;
//         o_fraction_w[10] <= 0;
//     end else if(counter == 6'd6) begin
//         if(data_u_6 >= data_d)begin
//             data_u_7 <= (data_u_6 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-6] <= 1;
//         end else begin
//             data_u_7 <= data_u_6 << 1;
//             o_fraction_w[FRACTIONBIT-6] <= 0;
//         end
//     end else begin
//         data_u_7 <= data_u_7;
//         o_fraction_w[FRACTIONBIT-6] <= o_fraction_w[FRACTIONBIT-6];
//     end
// end

// // 8th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_8 <= 0;
//         o_fraction_w[9] <= 0;
//     end else if(counter == 6'd7) begin
//         if(data_u_7 >= data_d)begin
//             data_u_8 <= (data_u_7 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-7] <= 1;
//         end else begin
//             data_u_8 <= data_u_7 << 1;
//             o_fraction_w[FRACTIONBIT-7] <= 0;
//         end
//     end else begin
//         data_u_8 <= data_u_8;
//         o_fraction_w[FRACTIONBIT-7] <= o_fraction_w[FRACTIONBIT-7];
//     end
// end

// // 9th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_9 <= 0;
//         o_fraction_w[8] <= 0;
//     end else if(counter == 6'd8) begin
//         if(data_u_8 >= data_d)begin
//             data_u_9 <= (data_u_8 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-8] <= 1;
//         end else begin
//             data_u_9 <= data_u_8 << 1;
//             o_fraction_w[FRACTIONBIT-8] <= 0;
//         end
//     end else begin
//         data_u_9 <= data_u_9;
//         o_fraction_w[FRACTIONBIT-8] <= o_fraction_w[FRACTIONBIT-8];
//     end 
// end

// // 10th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_10 <= 0;
//         o_fraction_w[7] <= 0;
//     end else if(counter == 6'd9) begin
//         if(data_u_9 >= data_d)begin
//             data_u_10 <= (data_u_9 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-9] <= 1;
//         end else begin
//             data_u_10 <= data_u_9 << 1;
//             o_fraction_w[FRACTIONBIT-9] <= 0;
//         end
//     end else begin
//         data_u_10 <= data_u_10;
//         o_fraction_w[FRACTIONBIT-9] <= o_fraction_w[FRACTIONBIT-9];
//     end
// end

// // 11th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_11 <= 0;
//         o_fraction_w[6] <= 0;
//     end else if(counter == 6'd10) begin
//         if(data_u_10 >= data_d)begin
//             data_u_11 <= (data_u_10 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-10] <= 1;
//         end else begin
//             data_u_11 <= data_u_10 << 1;
//             o_fraction_w[FRACTIONBIT-10] <= 0;
//         end
//     end else begin
//         data_u_11 <= data_u_11;
//         o_fraction_w[FRACTIONBIT-10] <= o_fraction_w[FRACTIONBIT-10];
//     end
// end

// // 12th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_12 <= 0;
//         o_fraction_w[5] <= 0;
//     end else if(counter == 6'd11) begin
//         if(data_u_11 >= data_d)begin
//             data_u_12 <= (data_u_11 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-11] <= 1;
//         end else begin
//             data_u_12 <= data_u_11 << 1;
//             o_fraction_w[FRACTIONBIT-11] <= 0;
//         end
//     end else begin
//         data_u_12 <= data_u_12;
//         o_fraction_w[FRACTIONBIT-11] <= o_fraction_w[FRACTIONBIT-11];
//     end
// end

// // 13th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_13 <= 0;
//         o_fraction_w[4] <= 0;
//     end else if(counter == 6'd12) begin
//         if(data_u_12 >= data_d)begin
//             data_u_13 <= (data_u_12 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-12] <= 1;
//         end else begin
//             data_u_13 <= data_u_12 << 1;
//             o_fraction_w[FRACTIONBIT-12] <= 0;
//         end
//     end else begin
//         data_u_13 <= data_u_13;
//         o_fraction_w[FRACTIONBIT-12] <= o_fraction_w[FRACTIONBIT-12];
//     end
// end

// // 14th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_14 <= 0;
//         o_fraction_w[3] <= 0;
//     end else if(counter == 6'd13) begin
//         if(data_u_13 >= data_d)begin
//             data_u_14 <= (data_u_13 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-13] <= 1;
//         end else begin
//             data_u_14 <= data_u_13 << 1;
//             o_fraction_w[FRACTIONBIT-13] <= 0;
//         end
//     end else begin
//         data_u_14 <= data_u_14;
//         o_fraction_w[FRACTIONBIT-13] <= o_fraction_w[FRACTIONBIT-13];
//     end
// end

// // 15th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_15 <= 0;
//         o_fraction_w[2] <= 0;
//     end else if(counter == 6'd14) begin
//         if(data_u_14 >= data_d)begin
//             data_u_15 <= (data_u_14 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-14] <= 1;
//         end else begin
//             data_u_15 <= data_u_14 << 1;
//             o_fraction_w[FRACTIONBIT-14] <= 0;
//         end
//     end else begin
//         data_u_15 <= data_u_15;
//         o_fraction_w[FRACTIONBIT-14] <= o_fraction_w[FRACTIONBIT-14];
//     end
// end

// // 16th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_16 <= 0;
//         o_fraction_w[1] <= 0;
//     end else if(counter == 6'd15) begin
//         if(data_u_15 >= data_d)begin
//             data_u_16 <= (data_u_15 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-15] <= 1;
//         end else begin
//             data_u_16 <= data_u_15 << 1;
//             o_fraction_w[FRACTIONBIT-15] <= 0;
//         end
//     end else begin
//         data_u_16 <= data_u_16;
//         o_fraction_w[FRACTIONBIT-15] <= o_fraction_w[FRACTIONBIT-15];
//     end
// end

// // 17th
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin 
//         data_u_17 <= 0;
//         o_fraction_w[0] <= 0;
//     end else if(counter == 6'd16) begin
//         if(data_u_16 >= data_d)begin
//             data_u_17 <= (data_u_16 - data_d) << 1;
//             o_fraction_w[FRACTIONBIT-16] <= 1;
//         end else begin
//             data_u_17 <= data_u_16 << 1;
//             o_fraction_w[FRACTIONBIT-16] <= 0;
//         end
//     end else begin
//         data_u_17 <= data_u_17;
//         o_fraction_w[FRACTIONBIT-16] <= o_fraction_w[FRACTIONBIT-16];
//     end
// end
