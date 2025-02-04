// mdoule for vectoriae top 

// N = VECTOR LANES
// VLEN = N*precision = length of vector input
`include "/home/himanshu/fpu/vectored_mac2/vectored_mac2.srcs/sources_1/new/param.v"
module vector_mac
 (
        a_in,b_in,c_in,out
   
   
);
   input [`I_WIDTH-1:0] a_in[`VECTOR-1:0];
   input [`I_WIDTH-1:0] b_in[`VECTOR-1:0];
   input [`I_WIDTH-1:0] c_in[`VECTOR-1:0];

   output  [`I_WIDTH-1:0] out [`VECTOR-1:0];

//logic [I_WIDTH-1:0] a[VECTOR-1:0];
//logic [I_WIDTH-1:0] b[VECTOR-1:0];
//logic [I_WIDTH-1:0] c[VECTOR-1:0];

//logic [I_WIDTH-1:0] out_int[VECTOR-1:0]; // intermediate output

genvar i;
// unpacking the input data  
//generate 
//    for(i=0;i<VECTOR;i=i+1) begin 
//        always @(posedge clk) begin 
//             a[i] = a_in[I_WIDTH*i +: I_WIDTH];
//             b[i] = b_in[I_WIDTH*i +: I_WIDTH];
//             c[i] = c_in[I_WIDTH*i +: I_WIDTH];
        
//        end
    
//    end

//endgenerate

// calling MAC modules
generate 
    for(i=0;i<`VECTOR;i=i+1) begin 
        mac #( .E_WIDTH(`E_WIDTH), .M_WIDTH(`M_WIDTH)) mac_inst
        	(   .a(a_in[i]),
                .b(b_in[i]),
                .c(c_in[i]),
        	    .out(out[i]) );

    end

endgenerate

//// packing the input data 
//generate 
//    for(i=0;i<VECTOR;i=i+1) 
//        always @(posedge clk) begin 

//            out[I_WIDTH*i +: I_WIDTH] =  out_int[i]  ;
//        end

//endgenerate



endmodule