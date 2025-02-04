// parameters.v 

`ifndef PARAMETERS_V
`define PARAMETERS_V

// parameters definition

`define E_WIDTH1 5    
`define E_WIDTH2 8    
`define E_WIDTH3 8    
`define E_WIDTH4 8    
`define M_WIDTH1 10
`define M_WIDTH2 7
`define M_WIDTH3 10
`define M_WIDTH4 53
// PARAMETERS FOR NUMBER OF MODULES USER WANTS

`define N1 1 // HP
`define N2 1 // BF
`define N3 5 // TF
`define N4 1 // SP

`define I_WIDTH1  (`M_WIDTH1 + `E_WIDTH1 + 1)
`define I_WIDTH2  (`M_WIDTH2 + `E_WIDTH2 + 1)
`define I_WIDTH3  (`M_WIDTH3 + `E_WIDTH3 + 1)
`define I_WIDTH4  (`M_WIDTH4 + `E_WIDTH4 + 1)



// Define MAX macro
`define MAX(a,b) ((a>b)? a:b)
`define MAX_OF(a,b,c,d) `MAX(`MAX(`MAX(a,b),c),d)

`define P (`N1*`I_WIDTH1)
`define Q (`N2*`I_WIDTH2)
`define R (`N3*`I_WIDTH3)
`define S (`N4*`I_WIDTH4)

// Calculate maximum number of modules and maximum input width
//`define T `MAX_OF(`N1,`N2,`N3,`N4)
//`define I `MAX_OF(`I_WIDTH1,`I_WIDTH2,`I_WIDTH3,`I_WIDTH4)


// Calculate total input width
`define IO `MAX_OF(`P,`Q,`R,`S)


`endif
