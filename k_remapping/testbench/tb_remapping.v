`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Y.T. Tsai
// 
// Create Date: 2025/11/24 13:57:38
// Design Name: 
// Module Name: tb_ZC
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


module tb_remapping#(WIDTH = 16, FRACTIONBIT = 15, OUTPUTWIDTH = 16)();

reg clk, rst_n, i_valid, i_enable;
reg signed [WIDTH-1:0] i_data, i_data_oct;
wire [OUTPUTWIDTH -1:0] o_data_oct;
wire o_valid_oct;

Remapping_TOP uu_Remapping_TOP(
    .clk(clk),
    .rst_n(rst_n),
    .kclk_data(i_data),
    .oct_data(i_data_oct),
    .i_valid(i_valid),
    .o_data(o_data_oct),
    .o_valid(o_valid_oct)
    );


reg [15: 0] k_clk_data [0:8192000];
reg [15: 0] oct_data [0:8192000];
// reg k_thm [0:8192000];


initial $readmemh("C:/Users/ /Downloads/kclk.txt",k_clk_data);
initial $readmemh("C:/Users/ /Downloads/mirror.txt",oct_data);

// initial $readmemh("C:/Users/ /Downloads/kclock_theory_pulse.txt",k_thm);

always #10 clk = ~clk;

integer i = 0;
// integer j = 0;
integer output_file;


initial begin
    output_file = $fopen("C:/Users/ /Downloads/oct_signal_remapping.coe", "w");
    forever begin
    @(posedge clk);
        if(o_valid_oct)begin
             $fwrite(output_file, "%h\n", o_data_oct); 
        end
    end
end

// reg trigger_fpga_d1, trigger_diff, trigger_fpga;
// always@(posedge clk)begin
//     trigger_fpga_d1 <= i_trigger;
// end

// always@(*)begin
//     trigger_fpga = i_trigger - trigger_fpga_d1;
//     trigger_diff = trigger_fpga - k_thm_sig;
// end

// initial begin
//     #2800;
//     for( j=0; j<8192000; j = j + 1) begin
//         @(posedge clk)
//             k_thm_sig <= k_thm[j- ];
//     end
// end
 
// initial begin
//     output_file0 = $fopen("C:/Users/ /Downloads/trigger_diff.coe", "w");
//     forever begin
//     @(posedge clk);
//     if(j > 100)begin
//         $fwrite(output_file0, "%h\n", trigger_diff); 
//     end
            
//     end
// end

initial begin
    clk = 0;
    rst_n = 1;
    i_valid = 0;
    i_enable = 0;
    #300;
    rst_n = 0;
    #500;
    rst_n = 1;
    #2000;
    i_valid = 1;
    i_enable = 1;

    for( i=0; i<8192000; i = i + 1) begin
        i_valid = 0;
        @(negedge clk)//begin
            i_valid <= 1;
            i_data <= k_clk_data[i];
            i_data_oct <= oct_data[i/*-105 - 17*/];   //104
    end

    i_valid = 0;


    #10000;
    $fclose(output_file);
    $finish;


end

endmodule
