`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2024 08:57:46
// Design Name: 
// Module Name: memory
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


module memory(
    input clk,
    output reg [4095:0] dout[4],
    input [4095:0] din[4], input reset, input wea
    );
    reg [3:0][3:0] address = '{{3{3'b000}}};
    
    always @(posedge clk) begin
    // Increment address
        if (reset) begin
            for (int j = 0; j < 4; j+=1) begin
                address[j] <= address[j] + 3'b001;
            end
        end
        else begin
            for (int j = 0; j < 4; j+=1) begin
            address[j] <= 3'b000;
            end
        end
    end
    
    genvar i;
    generate
        for (i = 0; i < 4; i+=1) begin : block_ram_gen
            blk_mem_gen_0 mem_accesses (
                .clka(clk),
                .wea(wea),
                .addra(address[i]),
                .dina(din[i]),
                .douta(dout[i])
        );
        end
    endgenerate
    
   /*blk_mem_gen_0 memA(
  .clka(clk),    // input wire clka
  .wea(wea),      // input wire [0 : 0] wea
  .addra(address[0]),  // input wire [3 : 0] addra
  .dina(dina),    // input wire [4095 : 0] dina
  .douta(douta[0])  // output wire [4095 : 0] douta
);*/
endmodule
