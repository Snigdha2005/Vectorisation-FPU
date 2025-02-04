


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2024 04:16:02 PM
// Design Name: 
// Module Name: parameter
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



`ifndef PARAMETERS_V
`define PARAMETERS_V

`define E_WIDTH 8 
`define M_WIDTH 7
`define DEPTH 256
`define I_WIDTH  (`M_WIDTH + `E_WIDTH + 1)

`define VECTOR 3

`define VLEN (`VECTOR *`I_WIDTH)


`endif
