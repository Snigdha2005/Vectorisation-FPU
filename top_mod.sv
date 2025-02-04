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

`include "/home/himanshu/fpu/vectored_mac2/vectored_mac2.srcs/sources_1/new/param.v"
module top( input clk_p,
            input clk_n,
            input reset

    );
    wire clk;
    
    wire [`VLEN-1:0] a_in;
    wire [`VLEN-1:0] b_in;
    wire [`VLEN-1:0] c_in;
    reg [`VLEN-1:0] o_out;
    
    reg [`I_WIDTH-1:0] a[`VECTOR-1:0];
    reg [`I_WIDTH-1:0] b[`VECTOR-1:0];
    reg [`I_WIDTH-1:0] c[`VECTOR-1:0];
    wire [`I_WIDTH-1:0] out[`VECTOR-1:0];
    
    reg [6:0] addra;
    


   clk_wiz_0 instance_name
 (
  // Clock out ports
  .clk_out1(clk),     // output clk_out1
 // Clock in ports
  .clk_in1_p(clk_p),    // input clk_in1_p
  .clk_in1_n(clk_n)    // input clk_in1_n
);

//vio_0 your_instance_name (
//  .clk(clk),                // input wire clk
//  .probe_in0(o_out),    // input wire [47 : 0] probe_in0
//  .probe_out0(a_in),  // output wire [47 : 0] probe_out0
//  .probe_out1(b_in),  // output wire [47 : 0] probe_out1
//  .probe_out2(c_in)  // output wire [47 : 0] probe_out2
//);

blk_mem_gen_0 A (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [6 : 0] addra
  .douta(a_in)  // output wire [511 : 0] douta
);

blk_mem_gen_1 B (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [6 : 0] addra
  .douta(b_in)  // output wire [511 : 0] douta
);

blk_mem_gen_2 C (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [6 : 0] addra
  .douta(c_in)  // output wire [511 : 0] douta
);
           
     genvar i; 
     
     generate 
     for (i=0;i<`VECTOR;i=i+1) begin 
     
     always @(posedge clk) begin
     
     a[i] <= a_in[`I_WIDTH*i +:`I_WIDTH];
     b[i] <= b_in[`I_WIDTH*i +:`I_WIDTH];
     c[i] <= c_in[`I_WIDTH*i +:`I_WIDTH];
    // o_out[`I_WIDTH*i +:`I_WIDTH]<= out[i];
     
     end
     end
     endgenerate
           
 // MAC module for computation         
    (*DONT_TOUCH ="YES"*)vector_mac VMAC(
            
               .a_in(a),
               .b_in(b),
               .c_in(c),
               .out(out)
           );
           
     
 // packing the output          
 generate
    for (i=0;i<`VECTOR;i=i+1) begin 
                      
         always @(posedge clk) begin
                      
                      
         o_out[`I_WIDTH*i +:`I_WIDTH]<= out[i];
                      
         end
      end
  endgenerate
  
     always @(posedge clk) begin
   // Increment address
       if (!reset) begin
           //for (int j = 0; j < 3; j++) begin
               addra <= addra + 'b1;
           //end
       end
       else begin
           //for (int j = 0; j < 3; j++) begin
           addra <= 'b0;
           //end
       end
   end
  
  
   /*generate
     for (i=0;i<`VECTOR;i=i+1) begin 
                       
         ila_1 my_ila (
         .clk(clk), // input wire clk
     
     
         .probe0(reset), // input wire [0:0]  probe0  
         .probe1(a[i]), // input wire [31:0]  probe1 
         .probe2(b[i]), // input wire [31:0]  probe2 
         .probe3(c[i]), // input wire [31:0]  probe3
         .probe4(out[i]) // input wire [31:0]  probe4
     );
                       
          
       end
   endgenerate
  
// ila_0 your_instance_name (
//      .clk(clk), // input wire clk
  
  
//      .probe0(reset), // input wire [0:0]  probe0  
//      .probe1(a_in), // input wire [511:0]  probe1 
//      .probe2(probe2), // input wire [511:0]  probe2 
//      .probe3(probe3) // input wire [511:0]  probe3
//  );  
            */
    
blk_mem_gen_3 OUT (
  .clka