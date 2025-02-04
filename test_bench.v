

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2024 09:53:32 AM
// Design Name: 
// Module Name: test
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


module test(

    );
    parameter width = 16;
                reg clk;
                 reg [width-1:0] a;
                reg [width-1:0] b;
                reg [width-1:0] c;
                //reg [1:0] mode;
                wire [width-1:0] result_out;
             
    
    
    
    
     mac dut( 
                       
                         .a(a),
                         .b(b),
                         .c(c),
                         .clk(clk),
                       // mode,
                        .out(result_out)
                       //over,
                      // under
                   );
                   
         initial begin 
         clk = 0;
         //mode = 2'b00;
//         a_in = 48'h0000402fe000; b_in= 48'h0000406fe000;c_in = 48'h0000402fe000;
//         #15 a_in = 48'h0000402fe000; b_in= 48'h0000c06fe000;c_in = 48'h0000402fe000;
//         #10 a_in = 48'h0000402fe000; b_in= 48'h0000406fe000;c_in = 48'h0000402fe000;
//           a_in = 'hc15d; b_in= 'hc15d;c_in='h415d;
//           #5 a_in = 'hc15d; b_in= 'h715d;c_in='hc15d;
          // #5 a_in = 32'h402f; b_in= 32'h406f;c_in=32'hc06f;
//          #4 a = 'b01001111101000111101011110100010; b= 'b01001110110011100000100001000101; c= 'b01001111010000110100001010001001; 
//          #7 a = 'b11001111111100111001101101100001; b= 'b01001111100001000001001010001001; c= 'b01001111001100011000111110111111;
//          #7 a = 'b11001111010011100110101010000000; b='b01001111010011110011101000101110;  c= 'b01001111111111111010001100111000;
#3 a= 'hcccd; b='h2936; c = 'hb396;
          
          #100 $finish;
         end
         always #5 clk =~clk;
endmodule
