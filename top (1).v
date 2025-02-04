`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/06/2024 02:35:06 PM
// Design Name: 
// Module Name: top
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

`include "C:/Users/SnigdhaYS/vectorisation_fpu/vectorisation_fpu.srcs/sources_1/new/param.v"
`include "C:/Users/SnigdhaYS/vectorisation_fpu/vectorisation_fpu.srcs/sources_1/new/memory.sv"
module top( input clk_p,
            input clk_n

    );
    wire clk;
    
    wire [`VLEN-1:0] a_in;
    wire [`VLEN-1:0] b_in;
    wire [`VLEN-1:0] c_in;
    reg [`VLEN-1:0] o_out;
    reg reset;
    reg wea;
    memory mem_access(.clk(clk), .dout({a_in, b_in, c_in, `VLEN-1'b0}), .din({{3{`VLEN-1'b0}}, o_out}), .reset(reset), .wea(wea)); 
    reg [`I_WIDTH-1:0] a[`VECTOR-1:0];
    reg [`I_WIDTH-1:0] b[`VECTOR-1:0];
    reg [`I_WIDTH-1:0] c[`VECTOR-1:0];
    wire [`I_WIDTH-1:0] out[`VECTOR-1:0];
   
    
//    mem A( .clk(clk),
//            .we(we),
//            .en(en),
//            .addr(addr),
//            .d_in(a_wr),
//            .d_out(a_in)
//         );
      
//    mem B(   .clk(clk),
//             .we(we),
//             .en(en),
//             .addr(addr),
//             .d_in(b_wr),
//             .d_out(b_in)
//           );
     
//     mem C( .clk(clk),
//            .we(we),
//            .en(en),
//            .addr(addr),
//            .d_in(c_wr),
//            .d_out(c_in)
//           );

   clk_wiz_0 instance_name
 (
  // Clock out ports
  .clk_out1(clk),     // output clk_out1
 // Clock in ports
  .clk_in1_p(clk_p),    // input clk_in1_p
  .clk_in1_n(clk_n)    // input clk_in1_n
);

vio_0 your_instance_name (
  .clk(clk),                // input wire clk
  .probe_in0(o_out),    // input wire [47 : 0] probe_in0
  .probe_out0(a_in),  // output wire [47 : 0] probe_out0
  .probe_out1(b_in),  // output wire [47 : 0] probe_out1
  .probe_out2(c_in)  // output wire [47 : 0] probe_out2
);
           
     genvar i; 
     
     generate 
     for (i=0;i<`VECTOR;i=i+1) begin 
     
     always @(posedge clk) begin
     
     a[i] <= a_in[`I_WIDTH*i +:`I_WIDTH];
     b[i] <= b_in[`I_WIDTH*i +:`I_WIDTH];
     c[i] <= c_in[`I_WIDTH*i +:`I_WIDTH];
     o_out[`I_WIDTH*i +:`I_WIDTH]<= out[i];
     
     end
     end
     endgenerate
           
          
    vector_mac
            VMAC(
            
               .a_in(a),
               .b_in(b),
               .c_in(c),
           
               .out(out)
           );
           
        
                              
     

endmodule
