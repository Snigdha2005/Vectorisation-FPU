// mdoule for vectoriae top 

// N = VECTOR LANES
// VLEN = N*precision = length of vector input

//`include "/home/himanshu/fpu/vectored_mac/vectored_mac.srcs/sources_1/new/parameter.v"
module vector_mac#(parameter E_WIDTH=8,parameter M_WIDTH=7,parameter VECTOR=8, parameter I_WIDTH= E_WIDTH+M_WIDTH+1,parameter VLEN = I_WIDTH*VECTOR)
(

   input clk,
   input [VLEN-1:0] a_in,
   input [VLEN-1:0] b_in,
   input [VLEN-1:0] c_in,

   output logic [VLEN-1:0] out
);

logic [I_WIDTH-1:0] a[VECTOR-1:0];
logic [I_WIDTH-1:0] b[VECTOR-1:0];
logic [I_WIDTH-1:0] c[VECTOR-1:0];

logic [I_WIDTH-1:0] out_int[VECTOR-1:0]; // intermediate output

genvar i;
// unpacking the input data  
generate 
   for(i=0;i<VECTOR;i=i+1) begin 
       always @(posedge clk) begin 
            a[i] = a_in[I_WIDTH*i +: I_WIDTH];
            b[i] = b_in[I_WIDTH*i +: I_WIDTH];
            c[i] = c_in[I_WIDTH*i +: I_WIDTH];
       
       end
   
   end

endgenerate

// calling MAC modules
generate 
   for(i=0;i<VECTOR;i=i+1) begin 
       mac #( .E_WIDTH(E_WIDTH), .M_WIDTH(M_WIDTH)) mac_inst
           (   .a(a[i]),
               .b(b[i]),
               .c(c[i]),
               .out(out_int[i]) );

   end

endgenerate

// packing the input data 
generate 
   for(i=0;i<VECTOR;i=i+1) 
       always @(posedge clk) begin 

           out[I_WIDTH*i +: I_WIDTH] =  out_int[i]  ;
       end

endgenerate



endmodule