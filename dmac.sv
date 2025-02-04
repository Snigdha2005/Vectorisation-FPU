`timescale 1ns / 1ps


//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/27/2024 06:00:15 PM
// Design Name: 
// Module Name: dynamic_fpu
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
//+++++++++++++++++++++++++++++++++++++++++++++++++//
// Mode --> 00: BF16, 01: HP.10:TF, 11:SP///
//------------------------------------------------=//

module dynamic_fpu( 
        input clk,
        input [47:0] a_in,
        input [47:0] b_in,
        input [47:0] c_in,
        input [1:0] mode,
        output reg [47:0] result_out,
        output reg [2:0] over,
        output reg [2:0] under
    );

 
   logic [47:0] a_inr;
   logic [47:0] b_inr;
   logic [47:0] c_inr;
   logic [1:0] mode_r;
   
   always @(posedge clk) begin 
   
   a_inr <=a_in;
   b_inr <= b_in;
   c_inr <= c_in;
   mode_r <= mode;
   
   
   
   end 
    
    // first stage 
    logic [23:0] ma;
    logic [23:0] mb;    
    logic [23:0] mc;
    logic [23:0] e_a;
    logic [23:0] e_b;
    logic [23:0] e_c;
    logic [2:0] s_a;
    logic [2:0] s_b;
    logic [2:0] s_c;
    logic [23:0] mar; 
    logic [23:0] mbr;
    logic [23:0] mcr;
    logic [23:0] e_ar;
    logic [23:0] e_br;
    logic [23:0] e_cr;
    logic [2:0] s_ar;
    logic [2:0] s_br;
    logic [2:0] s_cr;
    //logic [1:0] mode_r1;
    
    // input processing block 
     (*DONT_TOUCH = "YES"*)inpprocessing ip(
       . a_in(a_inr),
       . b_in(b_inr),
       . c_in(c_inr),
       . mode(mode_r),
       . ma(ma), 
       . mb(mb),
       . mc(mc),
       . e_a(e_a),
       . e_b(e_b),
       . e_c(e_c),
       . s_a(s_a),
       . s_b(s_b),
       . s_c(s_c)
       );
     
     /*  
       always @(posedge clk) begin 
       
       mar <= ma;    
       mbr <= mb;    
       mcr <= mc;    
       e_ar <= e_a;
       e_br <= e_b;
       e_cr <= e_c;
       s_ar <= s_a;
       s_br <= s_b;
       s_cr <= s_c;
       mode_r1 <= mode;
       
       end
       */
       
       // second stage variables and blocks 
       logic [47:0] mult_signi;
       logic [26:0] em;
       logic [2:0] sm;
       logic [47:0] mult_signir;
       logic [26:0] emr;
       logic [2:0] smr;
       logic [1:0] mode_r2;
       logic [2:0] s_cr2;
       logic [23:0] e_cr2;
       logic [23:0] mcr2;
       
       

      // multiplier 
       multi #(24) mul(
         .a(ma),
         .b(mb),
         .mo(mode_r),
         .out(mult_signi) // significand multipication result
       );
       
       // exponent addition 
       expo_add exp_addition(
        .e_a(e_a),
        .e_b(e_b),
        .s_a(s_a),
        .s_b(s_b),
        .mode(mode_r),
        .s_m(sm),
        .e_out(em)
       
       );
     
       
       always @(posedge clk) begin 
       emr<= em;
       smr<=sm;
       mult_signir <= mult_signi;
       mode_r2 <= mode_r;
       s_cr2 <= s_c; // buffering the data for next stage 
       e_cr2 <= e_c;
       mcr2  <= mc;
       
       end
       
       // third stage of pipeline
       
       logic [26:0] nemo; // normalised exponent 
       logic [47:0] nsigni; // normalised signigicand
       logic [26:0] nemor;
       logic [47:0] nsignir;
       logic [1:0] mode_r3;
       
       // adder/ sub input/outputs  
       logic [71:0] sig_a;
       logic [71:0] sig_b; // inputs to adder 
       logic [23:0] fexp_a;
       logic [2:0] final_sign;
       logic [2:0] of;
       //logic [2:0] uf;
       
       logic [71:0] sig_ar;
       logic [71:0] sig_br; // inputs to adder 
       logic [23:0] fexp_ar;
       logic [2:0] final_signr;
       logic [2:0] ofr;
       logic [2:0] sub_i;
       assign sub_i = s_cr2 ^ smr;
       logic [2:0] sub_ir;
       
       
       
         norma_mul normalization_multiplier(
                         .data(mult_signir),
                         .mode(mode_r2),
                         .e_m(emr), // so that it can accomodate 3 bf exponents
                         .e_m_o(nemo), // output exponent
                         .data_o(nsigni)
                        );
                        
         align alligner(
                         .exc(e_cr2), // exponent of c 
                         .exm(nemo), // exponent after multiplication 
                         .mm(nsigni), // multiplication output 
                         .mc(mcr2), // third input output 
                         .s_c(s_cr2), // sign  of c 
                         .s_m(smr), // sign after multiplication 
                         .mode(mode_r2),
                         .a(sig_a),
                         .b(sig_b),
                         .fe(fexp_a), // final exponent
                         .fs(final_sign), // final sign 
                         .over(of) // overflow 
                         //.uf(uf) // underflow  
                       );
                        
         always @(posedge clk) begin 
        // nsignir<= nsigni;
         //nemor   <= nemo;
          sig_ar           <= sig_a; // significand 
          sig_br           <= sig_b; 
          fexp_ar          <= fexp_a; // final exponent after comparing the ec and em 
          final_signr      <= final_sign;
          ofr              <= of;
          mode_r3          <= mode_r2;
         // ufr              <= uf;
         sub_ir            <= sub_i;
         
         
         
         end
        // fourth pipeline stage 
        
        logic [74:0] add_data;
        logic [71:0] sub_data;
        
        logic [74:0] add_datar;
        logic [71:0] sub_datar;
       // logic [2:0] sub_i;
        logic [1:0] mode_r4;
        
        logic [2:0]final_sign_4r;
        logic [2:0]ofr_4;
        
        logic [1:0] mode_r4b;
        
        logic [2:0]final_sign_4rb;
        logic [2:0]ofr_4b;
        logic [23:0] fexp_arb;
        
       
      //  reg [74:0] add_datar;
        //reg [71:0] sub_datar;
         adder addsub_multi(
                       .a_in(sig_ar),
                       .b_in(sig_br),
                       .mode(mode_r3),
                       .sub(sub_ir),
                       .add_data(add_data), // 75 bits 
                       .sub_data(sub_data) // 72 bits 
       );
       
       always @(posedge clk) begin 
       final_sign_4rb <= final_signr;
       ofr_4b         <= ofr;
       fexp_arb       <= fexp_ar;
       mode_r4b       <= mode_r3;
       add_datar      <= add_data;
       sub_datar      <= sub_data;
       
       
       
       end
       
       
       
       logic [71:0] ndaa; // normalized data afte addition 
       logic [26:0] neaa; // normalized exp after addition 
       logic [71:0] ndas; // normalized data afte subtraction 
       logic [26:0] neas; // normalized exp after subtraction 
       
       logic [14:0] shamt_l;
       
       
       
       // normalization block after addition 
       norma_add normalize(
                         .data(add_datar),
                         .mode(mode_r4b),
                         .e_m(fexp_arb), // this is coming from exponent alligner block 
                         .e_m_o(neaa), // output exponent of addition
                         .data_o(ndaa) // output
       
           );
        
        //-------------------------------block for leading zero counter 
        lzd leading_zero(
                            .data(sub_datar),
                            .mode(mode_r4b),
                            .count(shamt_l) // output
        );
        
        left_shift normalize_sub(
                            .data(sub_datar),
                            .exp(fexp_arb),
                            .mode(mode_r4b),
                            .count(shamt_l),
                            .expo(neas), // output
                            .datao(ndas) // output
            );
            logic [71:0] round_inp;
            logic [26:0] fexp_i; 
            reg  [71:0] round_inpr;
            reg  [26:0] fexp_ir; // intermediate final exponent

// this module is to select data and pass to next rounding block 
             data_sel data_logic(
               .ndaa(ndaa),
               .ndas(ndas),
               .neaa(neaa),
               .neas(neas),
               .mode(mode_r4b),
               .sign_i(sub_ir),
               .round_data(round_inp), // 72 bits data output for rounder 
               .fexp(fexp_i)                 // 27 bits final expo
);

         always @(posedge clk) begin 
         
                round_inpr <= round_inp;
                fexp_ir    <= fexp_i;
                mode_r4    <= mode_r4b;
                final_sign_4r <= final_sign_4rb;
                ofr_4 <= ofr_4b;
         
         
         end
         
         // fifth pipeline stage 
        
        logic [26:0] r_data; 
        logic [22:0] f_m; // final mantissa after rounding 
        logic [23:0] f_e; // final exponent
        
        
        round rounder(
                    .data(round_inpr), // 72 bits data to round
                    .mo(mode_r4),   // mode 
                    .r_data(r_data) // round data output 27 bits 27 bits is choosen to accomodate 9*3 bits round data for bf 
        );
        
        logic [2:0] uf_norm; // output of final norm block 
        logic [2:0] ov_norm; // output of final norm block 
        
        // final normalisation after rounding 
         norm_final final_norma(
                         .data(r_data), // rounding data 
                         .exp(fexp_ir), 
                         .mode(mode_r4),
                         .f_m(f_m), // final mantissa output reg[22:0]
                         .f_e(f_e),   //output reg [23:0]
                         .uf(uf_norm),
                         .ov(ov_norm)
        
        );

        
        logic [2:0] over_f;
        logic [2:0] under_f;
        logic [47:0] final_out;
        
         outprocess out_processing(
                 .fm(f_m), // final mantissa 
                 .fe(f_e), // final exponent
                 .fs(final_sign_4r), // final sign 
                 .ov1(ofr_4), //overflow due to multiplication 
                 .ov2(ov_norm), // overflow due to addition 
                 .uf(uf_norm),
                 .mode(mode_r4),
                 .over(over_f),
                 .under(under_f),
                 .final_out(final_out)
       );
       
       always @(posedge clk) begin 
       
       over       <= over_f;
       under      <= under_f;
       result_out <= final_out;
       
       
       end
        
     
        

       
      
        
       
endmodule

module inpprocessing(
    input [47:0] a_in,
    input [47:0] b_in,
    input [47:0] c_in,
    input [1:0]  mode,
    output reg [23:0] ma, // mantissa of a 
    output reg [23:0] mb,
    output reg [23:0] mc,
    output reg [23:0] e_a,
    output reg [23:0] e_b,
    output reg [23:0] e_c,
    output reg [2:0] s_a,
    output reg [2:0] s_b,
    output reg [2:0] s_c

);

// variables for mantissa 
logic [23:0] am_sp;
logic [23:0] bm_sp;
logic [23:0] cm_sp;

logic [7:0] am_bf[2:0];
logic [7:0] bm_bf[2:0];
logic [7:0] cm_bf[2:0];

logic [11:0] am_hp[1:0]; // 12 bit for making it compatible with multiplier
logic [11:0] bm_hp[1:0];
logic [11:0] cm_hp[1:0];

logic [11:0] am_tf[1:0];
logic [11:0] bm_tf[1:0];
logic [11:0] cm_tf[1:0];

// variables for exponent

logic [7:0] ae_sp;
logic [7:0] be_sp;
logic [7:0] ce_sp;

logic [7:0] ae_bf[2:0];
logic [7:0] be_bf[2:0];
logic [7:0] ce_bf[2:0];

logic [7:0] ae_hp[1:0]; 
logic [7:0] be_hp[1:0];
logic [7:0] ce_hp[1:0];

logic [7:0] ae_tf[1:0];
logic [7:0] be_tf[1:0];
logic [7:0] ce_tf[1:0];

// variables for sign 

logic  sa_sp;
logic  sb_sp;
logic  sc_sp;

logic  sa_bf[2:0];
logic  sb_bf[2:0];
logic  sc_bf[2:0];

logic  sa_hp[1:0]; 
logic  sb_hp[1:0];
logic  sc_hp[1:0];

logic  sa_tf[1:0];
logic  sb_tf[1:0];
logic  sc_tf[1:0];

// unpacing the mantissas and preappending 1 to msb
assign am_sp = {1'b1,a_in[22:0]}; // preappending the hidden 1 bit to msb
assign bm_sp = {1'b1,b_in[22:0]};
assign cm_sp = {1'b1,c_in[22:0]};

assign am_bf[0] = {1'b1,a_in[6:0]};
assign bm_bf[0] = {1'b1,b_in[6:0]};
assign cm_bf[0] = {1'b1,c_in[6:0]};

assign am_bf[1] = {1'b1,a_in[22:16]};
assign bm_bf[1] = {1'b1,b_in[22:16]};
assign cm_bf[1] = {1'b1,c_in[22:16]};

assign am_bf[2] = {1'b1,a_in[38:32]};
assign bm_bf[2] = {1'b1,b_in[38:32]};
assign cm_bf[2] = {1'b1,c_in[38:32]};

assign am_hp[0] = {1'b0,1'b1,a_in[9:0]};
assign bm_hp[0] = {1'b0,1'b1,b_in[9:0]};
assign cm_hp[0] = {1'b0,1'b1,c_in[9:0]};

assign am_hp[1] = {1'b0,1'b1,a_in[25:16]};
assign bm_hp[1] = {1'b0,1'b1,b_in[25:16]};
assign cm_hp[1] = {1'b0,1'b1,c_in[25:16]};

assign am_tf[0] = {1'b0,1'b1,a_in[9:0]};
assign bm_tf[0] = {1'b0,1'b1,b_in[9:0]};
assign cm_tf[0] = {1'b0,1'b1,c_in[9:0]};

assign am_tf[1] = {1'b0,1'b1,a_in[28:19]};
assign bm_tf[1] = {1'b0,1'b1,b_in[28:19]};
assign cm_tf[1] = {1'b0,1'b1,c_in[28:19]};

// assigning exponents 
assign ae_sp = {a_in[30:23]}; 
assign be_sp = {b_in[30:23]};
assign ce_sp = {c_in[30:23]};

assign ae_bf[0] = {a_in[14:7]};
assign be_bf[0] = {b_in[14:7]};
assign ce_bf[0] = {c_in[14:7]};

assign ae_bf[1] = {a_in[30:23]};
assign be_bf[1] = {b_in[30:23]};
assign ce_bf[1] = {c_in[30:23]};

assign ae_bf[2] = {a_in[46:39]};
assign be_bf[2] = {b_in[46:39]};
assign ce_bf[2] = {c_in[46:39]};

assign ae_hp[0] = {3'b000,a_in[14:10]}; // padding 0 to make it compatable with exponent addition
assign be_hp[0] = {3'b000,b_in[14:10]};
assign ce_hp[0] = {3'b000,c_in[14:10]};

assign ae_hp[1] = {1'b000,a_in[30:26]};
assign be_hp[1] = {1'b000,b_in[30:26]};
assign ce_hp[1] = {1'b000,c_in[30:26]};

assign ae_tf[0] = {a_in[17:10]};
assign be_tf[0] = {b_in[17:10]};
assign ce_tf[0] = {c_in[17:10]};

assign ae_tf[1] = {a_in[36:29]};
assign be_tf[1] = {b_in[36:29]};
assign ce_tf[1] = {c_in[36:29]};

// assign signs 

assign  sa_sp = a_in[31];
assign  sb_sp = b_in[31];
assign  sc_sp = c_in[31];

assign  sa_bf[0] = a_in[15];
assign  sb_bf[0] = b_in[15];
assign  sc_bf[0] = c_in[15];

assign  sa_bf[1] = a_in[31];
assign  sb_bf[1] = b_in[31];
assign  sc_bf[1] = c_in[31];

assign  sa_bf[2] = a_in[47];
assign  sb_bf[2] = b_in[47];
assign  sc_bf[2] = c_in[47];

assign  sa_hp[0] = a_in[15]; 
assign  sb_hp[0] = b_in[15];
assign  sc_hp[0] = c_in[15];

assign  sa_hp[1] = a_in[31]; 
assign  sb_hp[1] = b_in[31];
assign  sc_hp[1] = c_in[31];

assign  sa_tf[0] = a_in[18];
assign  sb_tf[0] = b_in[18];
assign  sc_tf[0] = c_in[18];

assign  sa_tf[1] = a_in[37];
assign  sb_tf[1] = b_in[37];
assign  sc_tf[1] = c_in[37];

always @(*) begin

    case (mode) 

    2'b00: begin
        ma <= {am_bf[2],am_bf[1],am_bf[0]};
        mb <= {bm_bf[2],bm_bf[1],bm_bf[0]};
        mc <= {cm_bf[2],cm_bf[1],cm_bf[0]};
    end
    2'b01: begin
        ma <= {am_hp[1],am_hp[0]};
        mb <= {bm_hp[1],bm_hp[0]};
        mc <= {cm_hp[1],cm_hp[0]};
        
    end

    2'b10: begin
        ma <= {am_tf[1],am_tf[0]};
        mb <= {bm_tf[1],bm_tf[0]};
        mc <= {cm_tf[1],cm_tf[0]}; 

    end

    2'b11: begin 
        ma <= am_sp;
        mb <= bm_sp;
        mc <= cm_sp; 

    end
    endcase

end

always @(*) begin

    case (mode) 

    2'b00: begin
        e_a <= {ae_bf[2],ae_bf[1],ae_bf[0]};
        e_b <= {be_bf[2],be_bf[1],be_bf[0]};
        e_c <= {ce_bf[2],ce_bf[1],ce_bf[0]};
        

    end
    2'b01: begin
        e_a <= {8'b0,ae_hp[1],ae_hp[0]}; 
        e_b <= {8'b0,be_hp[1],be_hp[0]};
        e_c <= {8'b0,ce_hp[1],ce_hp[0]};
        
    end

    2'b10: begin 
        e_a <= {8'b0,ae_tf[1],ae_tf[0]};
        e_b <= {8'b0,be_tf[1],be_tf[0]};
        e_c <= {8'b0,ce_tf[1],ce_tf[0]};

    end

    2'b11: begin 
        e_a <= {16'b0,ae_sp};
        e_b <= {16'b0,be_sp};
        e_c <= {16'b0,ce_sp};

    end
    endcase

end

always @(*) begin

    case (mode) 

    2'b00: begin
        s_a <= {sa_bf[2],sa_bf[1],sa_bf[0]};
        s_b <= {sb_bf[2],sb_bf[1],sb_bf[0]};
        s_c <= {sc_bf[2],sc_bf[1],sc_bf[0]};
        

    end
    2'b01: begin
        s_a <= {1'b0,sa_hp[1],sa_hp[0]};
        s_b <= {1'b0,sb_hp[1],sb_hp[0]};
        s_c <= {1'b0,sc_hp[1],sc_hp[0]};
        
    end

    2'b10: begin 
        s_a <= {1'b0,sa_tf[1],sa_tf[0]};
        s_b <= {1'b0,sb_tf[1],sb_tf[0]};
        s_c <= {1'b0,sc_tf[1],sc_tf[0]};

    end

    2'b11: begin 
        s_a <= {2'b0,sa_sp};
        s_b <= {2'b0,sb_sp};
        s_c <= {2'b0,sc_sp};

    end
    endcase

end


endmodule
module left_shift(
    input [71:0] data,
    input [23:0] exp, // this is output of alligner module 
    input [1:0] mode,
    input [14:0] count,
    output reg[26:0] expo,
    output reg[71:0] datao
);


   // variables for multiplied mantissa 
logic [32:0] tmm_hp[1:0];
logic [23:0] tmm_bf[2:0];
logic [71:0] tmm_sp; // difference  is of 72 bits 

// after the extention to accomodate the right shift 
logic [32:0] nmm_hp[1:0];
logic [23:0] nmm_bf[2:0];
logic [71:0] nmm_sp;

// variables for exponent 
logic [5:0] emm_hp[1:0];
logic [8:0] emm_bf[2:0];
logic [8:0] emm_sp;
logic [4:0] em_hp[1:0];
logic [7:0] em_bf[2:0];
logic [7:0] em_sp;

logic [6:0] count_sp; // count value for single precision
logic [5:0] count_hp [1:0]; // count value for hp and tf 
logic [4:0] count_bf [2:0]; // count value for bf


// assigning values for hp and tf mode 
assign tmm_hp[0] = data[32:0];
assign tmm_hp[1] = data[65:33];

// assigning values for bfloat mode 
assign tmm_bf[0] = data[23:0];
assign tmm_bf[1] = data[47:24];
assign tmm_bf[2] = data[71:48];

// assigning value for sp 
assign tmm_sp = data[71:0];

// unpacking the exponents 

assign em_hp[0] = exp[4:0];
assign em_hp[1] = exp[12:8];

assign em_bf[0] = exp[7:0];
assign em_bf[1] = exp[15:8];
assign em_bf[2] = exp[23:16];

assign em_sp = exp[7:0];

assign count_sp = count[6:0];
assign count_bf[0] = count[4:0];
assign count_bf[1] = count[9:5];
assign count_bf[2] = count[14:10];

assign count_hp[0] = count[5:0];
assign count_hp[1] = count[11:6];

always @(*) begin 

    case(mode) 

    2'b00: begin // bf 
        nmm_bf[0] = tmm_bf[0]<<count_bf[0];
        emm_bf[0] = (em_bf[0]>count_bf[0])? (em_bf[0]-count_bf[0]): 9'b0;
        nmm_bf[1] = tmm_bf[1]<<count_bf[1];
        emm_bf[1] = (em_bf[1]>count_bf[1])? (em_bf[1]-count_bf[1]): 9'b0;
        nmm_bf[2] = tmm_bf[2]<<count_bf[2];
        emm_bf[2] = (em_bf[2]>count_bf[2])? (em_bf[2]-count_bf[2]): 9'b0;

        expo = {emm_bf[2],emm_bf[1],emm_bf[0]};
        datao = {nmm_bf[2],nmm_bf[1],nmm_bf[0]};


    end
    2'b01: begin // hp
        
        nmm_hp[0] = tmm_hp[0] << count_hp[0];
        emm_hp[0] = (em_hp[0]>count_hp[0])? (em_hp[0]-count_hp[0]): 6'b0; 
        nmm_hp[1] = tmm_hp[1] << count_hp[1];
        emm_hp[1] = (em_hp[1]>count_hp[1])? (em_hp[1]-count_hp[1]): 6'b0; 

        expo = {15'b0,emm_hp[1],emm_hp[0]};
        datao = {{6{1'b0}},nmm_hp[1],nmm_hp[0]};


    end
    2'b10: begin // hp
        
        nmm_hp[0] = tmm_hp[0] << count_hp[0];
        emm_bf[0] = (em_bf[0]>count_hp[0])? (em_bf[0]-count_hp[0]): 9'b0; 
        nmm_hp[1] = tmm_hp[1] << count_hp[1];
        emm_bf[1] = (em_bf[1]>count_hp[1])? (em_bf[1]-count_hp[1]): 9'b0; 

        expo = {{9{1'b0}},emm_bf[1],emm_bf[0]};
        datao = {{6{1'b0}},nmm_hp[1],nmm_hp[0]};


    end
    2'b11 : begin // sp 
        nmm_sp = tmm_sp << count_sp;
        emm_sp = (em_sp > count_sp)? (em_sp - count_sp) : 8'b0;

        expo = {{18{1'b0}},emm_sp};
        datao = {{24{1'b0}},nmm_sp};


    end 
    endcase



end

endmodule



//??? pad a 0 to for the tf and hp case because we need to multiply the 11 bits 

//+++++++++++++++++++++++++++++++++++++++++++++++++//
// Mode --> 00: BF16, 01: HP.10:TF, 11:SP///
//------------------------------------------------=//
// I need to pad a zero if the mode is hp or tf since it is 11 bits only;  
module multi #(parameter I_WIDTH=24)(
        input [I_WIDTH-1:0] a,b,
        input [1:0] mo, // mode of operation
        //input clk,
        output reg [2*I_WIDTH-1:0] out 
    

    );
    
    
    // now i will take 8 bit input and split into two 4 bit and perform multiplication on that and at last i will combine 
    logic [3:0] a_i [5:0];
    logic [3:0] b_i [5:0];
    logic [47:0] pp [5:0][5:0]; // since maximum of 24 bit multiplication we are supporting pipeline reg reg 
    //logic [47:0] ipp [5:0][5:0]; // since maximum of 24 bit multiplication we are supporting 

    // three registers for the BF16
    logic [15:0] out_bf [2:0];
    // two registers  for HP a
    logic [23:0] out_hp[1:0];
    
    reg [47:0] part0, part1, part2, part3, part4, part5;

    // two registers for TF32
   // logic [23:0] out_tf[1:0];
    
    //logic [47:0] out_inter[3:0]; //  output for intermediate values 
        


    genvar k;
    generate 
        for(k=0;k<6;k=k+1) begin 
            assign a_i[k] = a[4*k+:4];
            assign b_i[k] = b[4*k+:4];

        end


    endgenerate 

 
     
    
    // lets perform multiplication on that and accumulate the result 
    
    // for getting partial products
//    mult_4b mul0(a_i[0],b_i[0],pp[0]);
//    mult_4b mul1(a_i[0],b_i[1],pp[1]);
//    mult_4b mul2(a_i[1],b_i[0],pp[2]);
//    mult_4b mul3(a_i[1],b_i[1],pp[3]);
    genvar i,j;
    generate 
        for(i=0;i<6;i++) begin
            for(j=0;j<6;j++) begin 

            mult_4b mul0(.a(b_i[i]),.b(a_i[j]),.c(pp[i][j]));

            end

        end
    endgenerate
//    generate 

//    for(i=0;i<6;i++) begin
//        for(j=0;j<6;j++) begin 
//            always @(posedge clk)
//            pp[i][j] <= ipp[i][j] ;


//        end
//    end


//    endgenerate

    
    always @(*) begin 
    // now we have arranged the result so we will sum the partial products
    // left shifting by (i+j)*4 since 4 is the length of unit multiplier
    case(mo)
    2'b00: begin // BF-16
         out_hp[1] <= 'b0; out_hp[0] <= 'b0;
         out_bf[0] <= pp[0][0]+(pp[0][1]<<4)+(pp[1][0]<<4)+(pp[1][1]<<8);
         out_bf[1] <= pp[2][2]+(pp[2][3]<<4)+(pp[3][2]<<4)+(pp[3][3]<<8);
         out_bf[2] <= pp[4][4]+(pp[4][5]<<4)+(pp[5][4]<<4)+(pp[5][5]<<8);
         

         end 
    2'b01: begin // HP
         out_bf[0] <= 'b0; out_bf[1] <= 'b0; out_bf[2] <= 'b0;
         out_hp[0] <= pp[0][0]+(pp[0][1]<<4)+(pp[0][2]<<8)+(pp[1][0]<<4)+(pp[1][1]<<8)+(pp[1][2]<<12)+(pp[2][0]<<8)+(pp[2][1]<<12)+(pp[2][2]<<16);
         out_hp[1] <= pp[3][3]+(pp[3][4]<<4)+(pp[3][5]<<8)+(pp[4][3]<<4)+(pp[4][4]<<8)+(pp[4][5]<<12)+(pp[5][3]<<8)+(pp[5][4]<<12)+(pp[5][5]<<16); 
         

        
        end 
    2'b10: begin 
        out_bf[0] <= 'b0; out_bf[1] <= 'b0; out_bf[2] <= 'b0;
        out_hp[0] <= pp[0][0]+(pp[0][1]<<4)+(pp[0][2]<<8)+(pp[1][0]<<4)+(pp[1][1]<<8)+(pp[1][2]<<12)+(pp[2][0]<<8)+(pp[2][1]<<12)+(pp[2][2]<<16);
        out_hp[1] <= pp[3][3]+(pp[3][4]<<4)+(pp[3][5]<<8)+(pp[4][3]<<4)+(pp[4][4]<<8)+(pp[4][5]<<12)+(pp[5][3]<<8)+(pp[5][4]<<12)+(pp[5][5]<<16); 
        
    
    end //TF32
    2'b11: begin
      out_bf[0] <= 'b0; out_bf[1] <= 'b0; out_bf[2] <= 'b0; out_hp[1] <= 'b0; out_hp[0] <= 'b0; 
      //  out = pp[0][0]+(pp[0][1]<<4)+(pp[0][2]<<8)+(pp[0][3]<<12)+(pp[0][4]<<16)+(pp[0][5]<<20)+(pp[1][0]<<4)+(pp[1][1]<<8)+(pp[1][2]<<12)+(pp[1][3]<<16)+(pp[1][4]<<20)+(pp[1][5]<<24)+(pp[2][0]<<8)+(pp[2][1]<<12)+(pp[2][2]<<16)+(pp[2][3]<<20)+(pp[2][4]<<24)+(pp[2][5]<<28)+(pp[3][0]<<12)+(pp[3][1]<<16)+(pp[3][2]<<20)+(pp[3][3]<<24)+(pp[3][4]<<28)+(pp[3][5]<<32)+(pp[4][0]<<16)+(pp[4][1]<<20)+(pp[4][2]<<24)+(pp[4][3]<<28)+(pp[4][4]<<32)+(pp[4][5]<<36)+(pp[5][0]<<20)+(pp[5][1]<<24)+(pp[5][2]<<28)+(pp[5][3]<<32)+(pp[5][4]<<36)+(pp[5][5]<<40);
      
      
       part0 <= pp[0][0] + (pp[0][1] << 4) + (pp[0][2] << 8) + (pp[0][3] << 12) + (pp[0][4] << 16) + (pp[0][5] << 20);
       part1 <= (pp[1][0] << 4) + (pp[1][1] << 8) + (pp[1][2] << 12) + (pp[1][3] << 16) + (pp[1][4] << 20) + (pp[1][5] << 24);
       part2 <= (pp[2][0] << 8) + (pp[2][1] << 12) + (pp[2][2] << 16) + (pp[2][3] << 20) + (pp[2][4] << 24) + (pp[2][5] << 28);
       part3 <= (pp[3][0] << 12) + (pp[3][1] << 16) + (pp[3][2] << 20) + (pp[3][3] << 24) + (pp[3][4] << 28) + (pp[3][5] << 32);
       part4 <= (pp[4][0] << 16) + (pp[4][1] << 20) + (pp[4][2] << 24) + (pp[4][3] << 28) + (pp[4][4] << 32) + (pp[4][5] << 36);
       part5 <= (pp[5][0] << 20) + (pp[5][1] << 24) + (pp[5][2] << 28) + (pp[5][3] << 32) + (pp[5][4] << 36) + (pp[5][5] << 40);
      
       

         end //sp
    //default: out = 0;
        

    endcase
    end
    
    always @(*) begin 
    
    case (mo)
    
    2'b00: out <= {out_bf[2],out_bf[1],out_bf[0]};
    
    2'b01: out <= {out_hp[1],out_hp[0]};
    
    2'b10: out <= {out_hp[1],out_hp[0]};
    
    2'b11: out <= part0 + part1 + part2 + part3 + part4 + part5;
    
    endcase 
   
    
    end
    
    
endmodule
// 4 bit unit multiplier 
module mult_4b( 
        input [3:0] a,b,
        output [47:0] c
        );
        logic [7:0] d;
        assign d = a*b;
        assign c = {{40{1'b0}},d};
endmodule 


module lzd( input [71:0] data,
            input [1:0] mode,
            output reg  [14:0] count
);

parameter DATA_WIDTH = 3;

logic [2:0] a [23:0];
logic [1:0] co [23:0];
integer p,q,r;
logic fg[23:0];
logic flag[2:0];

logic [6:0] count_sp; // count value for single precision
logic [5:0] count_hp [1:0]; // count value for hp and tf 
logic [4:0] count_bf [2:0]; // count value for bf

genvar i;
generate 
    for(i=0;i<24;i=i+1) begin
        assign a[i] = data[DATA_WIDTH*i +: DATA_WIDTH]; 
    end

endgenerate


genvar j;
generate 
    for(j=0;j<24;j=j+1) begin 

        b_lzd u(.a(a[j]),.count(co[j]),.flag(fg[j]));

    end
endgenerate

always@(*) begin 
 count= 'b0; flag[0] = 'b0;flag[1] = 'b0;flag[2] = 'b0; count_sp = 'b0; count_hp[0]= 'b0; count_hp[1]= 'b0;
 count_bf[0] ='b0;count_bf[1] ='b0;count_bf[2] ='b0;
 case(mode)
 2'b00: begin 
    for (p=7;p>=0;p=p-1) begin
        if(flag[0]==0) begin
        if(fg[p]==0) count_bf[0] = count_bf[0]+co[p];
        else begin 
        
        count_bf[0] = count_bf[0]+co[p];
        flag[0] ='b1;
        
        end // for else
    
    
    end // for  if
    else count_bf[0] = count_bf[0];
    end // for 
    
    for (q=15;q>=8;q=q-1) begin
        if(flag[1]==0) begin
        if(fg[q]==0) count_bf[1] = count_bf[1]+co[q];
        else begin 
        
        count_bf[1] = count_bf[1]+co[q];
        flag[1] ='b1;
        
        end // for else
    
    
    end // for  if
    else count_bf[1] = count_bf[1];
    end // for 
    
    for (r=23;r>=16;r=r-1) begin
        if(flag[2]==0) begin
        if(fg[r]==0) count_bf[2] = count_bf[2]+co[r];
        else begin 
        
        count_bf[2] = count_bf[2]+co[r];
        flag[2] ='b1;
        
        end // for else
    
    
    end // for  if
    else count_bf[2] = count_bf[2];
    end // for 
 
    count = {count_bf[2],count_bf[1],count_bf[0]};
 
 
 end // for case 00
 
  2'b01: begin
 
     for (p=10;p>=0;p=p-1) begin
     if(flag[0]==0) begin
     if(fg[p]==0) count_hp[0] = count_hp[0]+co[p];
     else begin 
     
     count_hp[0] = count_hp[0]+co[p];
     flag[0] ='b1;
     
     end // for else
 
 
 end // for  if
 else count_hp[0] = count_hp[0];
 end // for 

   for (q=21;q>=11;q=q-1) begin
      if(flag[1]==0) begin
      if(fg[q]==0) count_hp[1] = count_hp[1]+co[q];
      else begin 
      
      count_hp[1] = count_hp[1]+co[q];
      flag[1] ='b1;
      
      end // for else
  
  
  end // for  if
  else count_hp[1] = count_hp[1];
  end // for 
  count = {count_hp[1],count_hp[0]};
 
 
 
 end // case 01
 
 2'b10: begin
 
     for (p=10;p>=0;p=p-1) begin
     if(flag[0]==0) begin
     if(fg[p]==0) count_hp[0] = count_hp[0]+co[p];
     else begin 
     
     count_hp[0] = count_hp[0]+co[p];
     flag[0] ='b1;
     
     end // for else
 
 
 end // for  if
 else count_hp[0] = count_hp[0];
 end // for 

   for (q=21;q>=11;q=q-1) begin
      if(flag[1]==0) begin
      if(fg[q]==0) count_hp[1] = count_hp[1]+co[q];
      else begin 
      
      count_hp[1] = count_hp[1]+co[q];
      flag[1] ='b1;
      
      end // for else
  
  
  end // for  if
  else count_hp[1] = count_hp[1];
  end // for 
  count = {count_hp[1],count_hp[0]};
 
 
 
 end // case 10
 2'b11: begin
 
 for (p=23;p>=0;p=p-1) begin 
    if(flag[0]==0) begin
        if(fg[p]==0) count_sp = count_sp+co[p];
        else begin 
        
        count_sp = count_sp+co[p];
        flag[0] ='b1;
        
        end // for else
    
    
    end // for  if
    else count_sp = count_sp;
    
 
 
    end // end of for loop 
    count = count_sp;
    end // end of 11 case
    
    default: count = 'b0;
    
    
 endcase   
 end // end for always
 
     


endmodule

module b_lzd(  
    input [2:0] a,
    output flag,
    output [1:0] count

            
);
    assign count = a[2]?2'd0:(a[1]?2'd1:(a[0]?2'd2:2'd3));
    assign flag = |a; // if this signal is zero that means it will not have any 1's in it


endmodule



//+++++++++++++++++++++++++++++++++++++++++++++++++//
// Mode --> 00: BF16, 01: HP.10:TF, 11:SP///
//------------------------------------------------=//
module norma_add(input [74:0] data,
                 input [1:0] mode,
                 input [23:0] e_m, // so that it can accomodate 3 bf exponents
                 output reg [26:0] e_m_o, // output exponent
                 output reg [71:0] data_o

    );
    // variables for multiplied mantissa 
    logic [33:0] tmm_hp[1:0];
    logic [24:0] tmm_bf[2:0];
    logic [72:0] tmm_sp; // sum is of 73 bits 
    // after the extention to accomodate the right shift 
    logic [32:0] nmm_hp[1:0];
    logic [23:0] nmm_bf[2:0];
    logic [71:0] nmm_sp;
    
    // variables for exponent 
    logic [5:0] emm_hp[1:0];
    logic [8:0] emm_bf[2:0];
    logic [8:0] emm_sp;
    logic [4:0] em_hp[1:0];
    logic [7:0] em_bf[2:0];
    logic [7:0] em_sp;
    
    
    
    // assigning values for hp and tf mode 
    assign tmm_hp[0] = data[33:0];
    assign tmm_hp[1] = data[67:34];
    
    // assigning values for bfloat mode 
    assign tmm_bf[0] = data[24:0];
    assign tmm_bf[1] = data[49:25];
    assign tmm_bf[2] = data[74:50];
    
    // assigning value for sp 
    assign tmm_sp = data[72:0];
    
    // unpacking the exponents 
    
    assign em_hp[0] = e_m[4:0];
    assign em_hp[1] = e_m[12:8];
    
    assign em_bf[0] = e_m[7:0];
    assign em_bf[1] = e_m[15:8];
    assign em_bf[2] = e_m[23:16];
    
    assign em_sp = e_m[7:0];
    
    always @(*) begin 
     emm_sp = 'b0; emm_hp[0] = 'b0; emm_hp[1]='b0; emm_bf[0]='b0;emm_bf[1]='b0;emm_bf[2]='b0;
    
    case(mode)
    2'b00: begin 
    
    if(tmm_bf[0][24]) begin 
        emm_bf[0] = em_bf[0]+'b1;
        nmm_bf[0] = tmm_bf[0][24:1];
    end
    else begin 
        emm_bf[0] = em_bf[0];
        nmm_bf[0] = tmm_bf[0][23:0];
    end
    
     if(tmm_bf[1][24]) begin 
        emm_bf[1] = em_bf[1]+'b1;
        nmm_bf[1] = tmm_bf[1][24:1];
    end
    else begin 
        emm_bf[1] = em_bf[1];
        nmm_bf[1] = tmm_bf[1][23:0];
    end
    
    if(tmm_bf[2][24]) begin 
        emm_bf[2] = em_bf[2]+'b1;
        nmm_bf[2] = tmm_bf[2][24:1];
    end
    else begin 
        emm_bf[2] = em_bf[2];
        nmm_bf[2] = tmm_bf[2][23:0];
    end
    
    data_o = {nmm_bf[2],nmm_bf[1],nmm_bf[0]};
    e_m_o = {emm_bf[2],emm_bf[1],emm_bf[0]};
    
    end// case 00
    2'b01: begin 
    if(tmm_hp[0][33]) begin 
        emm_hp[0] = em_hp[0]+'b1;
        nmm_hp[0] = tmm_hp[0][33:1];
    end
    else begin 
        emm_hp[0] = em_hp[0];
        nmm_hp[0] = tmm_hp[0][32:0];
    end
    
    if(tmm_hp[1][33]) begin 
        emm_hp[1] = em_hp[1]+'b1;
        nmm_hp[1] = tmm_hp[1][33:1];
    end
    else begin 
        emm_hp[1] = em_hp[1];
        nmm_hp[1] = tmm_hp[1][32:0];
    end
    
    data_o = {6'b0,nmm_hp[1],nmm_hp[0]};
    e_m_o = {15'b0,emm_hp[1],emm_hp[0]};
    
    
    
    
    end// case 01
    2'b10: begin 
    
   if(tmm_hp[0][33]) begin 
         emm_bf[0] = em_bf[0]+'b1;
         nmm_hp[0] = tmm_hp[0][33:1];
     end
     else begin 
         emm_bf[0] = em_bf[0];
         nmm_hp[0] = tmm_hp[0][32:0];
     end
     
     if(tmm_hp[1][33]) begin 
         emm_bf[1] = em_bf[1]+'b1;
         nmm_hp[1] = tmm_hp[1][33:1];
     end
     else begin 
         emm_bf[1] = em_bf[1];
         nmm_hp[1] = tmm_hp[1][32:0];
     end
     
     data_o = {6'b0,nmm_hp[1],nmm_hp[0]};
     e_m_o = {15'b0,emm_bf[1],emm_bf[0]};
    
    
    
    end// case 10
    
    2'b11: begin 
    if(tmm_sp[72]) begin 
         emm_sp = em_sp+'b1;
         nmm_sp = tmm_sp[72:1];
     end
     else begin 
         emm_sp = em_sp;
         nmm_sp = tmm_sp[71:0];
     end
     data_o = nmm_sp;
     e_m_o = {18'b0,emm_sp};
 
    end// case 11

    
    
    
    endcase
    end // always
    
    
    
    
endmodule




module norm_final(
    input [26:0] data, // rounding data 
    input [26:0] exp, 
    input [1:0] mode,
    output reg[22:0] f_m, // final mantissa 
    output reg [23:0] f_e,
    output reg [2:0] uf, // this under flow flag I will send to final as this stage will determine underflow
    output reg [2:0] ov

);

logic [24:0] m_sp;
logic [8:0] m_bf[2:0];
logic [11:0] m_hp[1:0];

logic [22:0] fm_sp;
logic [6:0] fm_bf[2:0];
logic [9:0] fm_hp[1:0];

logic [8:0] exp9b [2:0]; /// it will accomodate 9 bit exponents
logic [5:0] exp6b [1:0]; 

logic [8:0] fexp9b [2:0]; //come back
logic [5:0] fexp6b [1:0];

 

// assigning the mantissas 
assign  m_sp = data[24:0];
assign m_bf[0]  = data[8:0];
assign m_bf[1] = data[17:9];
assign m_bf[2] = data[26:18];

assign m_hp[0] = data[11:0];
assign m_hp[1] = data[23:12];

// asssigning the exponents
assign exp9b[0] = exp[8:0];
assign exp9b[1] = exp[17:9];
assign exp9b[2] = exp[26:18];

assign exp6b[0] = exp[5:0];
assign exp6b[1] = exp[11:6];

always @(*) begin 

    case(mode)

    2'b00: begin // bfloat16
    fm_sp = 'b0;
    fm_hp[0] = 'b0;
    fm_hp[1] = 'b0;
        if(m_bf[0][8]) begin 

            fexp9b[0] = exp9b[0] +1'b1 ;
            fm_bf[0] = m_bf[0][7:1];

        end
        else begin 
            fexp9b[0] = exp9b[0];
            fm_bf[0] = m_bf[0][6:0];

        end

        if(m_bf[1][8]) begin 

            fexp9b[1] = exp9b[1] +1'b1 ;
            fm_bf[1] = m_bf[1][7:1];

        end
        else begin 
            fexp9b[1] = exp9b[1];
            fm_bf[1] = m_bf[1][6:0];

        end

        if(m_bf[2][8]) begin 

            fexp9b[2] = exp9b[2] +1'b1 ;
            fm_bf[2] = m_bf[2][7:1];

        end
        else begin 
            fexp9b[2] = exp9b[2];
            fm_bf[2] = m_bf[2][6:0];

        end
        end

        2'b01: begin // hp mode 
        fm_sp = 'b0;
        fm_bf[0] = 'b0;
        fm_bf[1] = 'b0;
        fm_bf[2] = 'b0;

            if(m_hp[0][11]) begin 

                fexp6b[0] = exp6b[0] +1'b1;
                fm_hp[0]  = m_hp[0][10:1];
 
            end
            else begin 
                fexp6b[0] = exp6b[0];
                fm_hp[0]  = m_hp[0][9:0];


            end

            if(m_hp[1][11]) begin 

                fexp6b[1] = exp6b[1] +1'b1;
                fm_hp[1]  = m_hp[1][10:1];
 
            end
            else begin 
                fexp6b[1] = exp6b[1];
                fm_hp[1]  = m_hp[1][9:0];


            end


        end

        2'b10: begin // tf mode 
         fm_sp = 'b0;
        fm_bf[0] = 'b0;
        fm_bf[1] = 'b0;
        fm_bf[2] = 'b0;

            if(m_hp[0][11]) begin 

                fexp9b[0] = exp9b[0] +1'b1;
                fm_hp[0]  = m_hp[0][10:1];
 
            end
            else begin 
                fexp9b[0] = exp9b[0];
                fm_hp[0]  = m_hp[0][9:0];


            end

            if(m_hp[1][11]) begin 

                fexp9b[1] = exp9b[1] +1'b1;
                fm_hp[1]  = m_hp[1][10:1];
 
            end
            else begin 
                fexp9b[1] = exp9b[1];
                fm_hp[1]  = m_hp[1][9:0];


            end


        end

        2'b11: begin 
        fm_bf[0] = 'b0;
        fm_bf[1] = 'b0;
        fm_bf[2] = 'b0;
        fm_hp[0] = 'b0;
        fm_hp[1] = 'b0;

            if (m_sp[24]) begin 
                fexp9b[0] = exp9b[0] +1'b1; 
                fm_sp = m_sp[23:1];

            end
            else begin 
                fexp9b[0] = exp9b[0];
                fm_sp = m_sp[22:0];


            end


        end 

    endcase


end

always @(*) begin 

    case(mode) 

    2'b00: begin 
        f_m[22:21] = 2'b0;
        if(fexp9b[0]==0) begin 
            f_e[7:0] = 8'b0;
            f_m[6:0] = 7'b0;
            uf[0] = 1'b1;
            ov[0] = 1'b0;
             
        end

        else if(fexp9b[0]>254)  begin 
            f_e[7:0] = 8'b11111111;
            f_m[6:0] = 7'b0;
            ov[0] = 1'b1;
            uf[0] = 1'b0;
            

        end
        else begin 

            f_e[7:0] = fexp9b[0][7:0];
            f_m[6:0]= fm_bf[0]; 
            uf[0] = 1'b0;
            ov[0] = 1'b0;


        end 
        

        if(fexp9b[1]==0) begin 
            f_e[15:8] = 8'b0;
            f_m[13:7] = 7'b0;
            uf[1] = 1'b1; 
            ov[1] = 1'b0;
        end

        else if(fexp9b[1]>254)  begin 
            f_e[15:8] = 8'b11111111;
            f_m[13:7] = 7'b0;
            ov[1] = 1'b1;
            uf[1] = 1'b0;

        end
        else begin 

            f_e[15:8] = fexp9b[1][7:0];
            f_m[13:7]= fm_bf[1]; 
            uf[1] = 1'b0;
            ov[1] = 1'b0;


        end 

        if(fexp9b[2]==0) begin 
            f_e[23:16] = 8'b0;
            f_m[20:14] = 7'b0;
            uf[2] = 1'b1;
            ov[2] = 1'b0;
        end

        else if(fexp9b[2]>254)  begin 
            f_e[23:16] = 8'b11111111;
            f_m[20:14] = 7'b0;
            ov[2] = 1'b1;
            uf[2] = 1'b0;

        end
        else begin 

            f_e[23:16] = fexp9b[2][7:0];
            f_m[20:14]= fm_bf[2]; 
            uf[2] = 1'b0;
            ov[2] = 1'b0;


        end 

        
    end 
    2'b01 : begin // half precision 
        ov[2] = 1'b0;
        uf[2] = 1'b0;
        f_e[23:10] = 'b0;
        f_m[22:20] =3'b0;
        if(fexp6b[0]==0) begin 
            f_e[4:0] = 5'b0;
            f_m[9:0] = 10'b0;
            uf[0] = 1'b1;
            ov[0] = 1'b0;
        end

        else if(fexp6b[0]>31)  begin 
            f_e[4:0] = 5'b11111;
            f_m[9:0] = 10'b0;
            ov[0] = 1'b1;
            uf[0] = 1'b0;

        end
        else begin 

            f_e[4:0] = fexp6b[0][4:0];
            f_m[9:0]= fm_hp[0]; 
            uf[0] = 1'b0;
            ov[0] = 1'b0;


        end 

        if(fexp6b[1]==0) begin 
            f_e[9:5] = 5'b0;
            f_m[19:10] = 10'b0;
            uf[1] = 1'b1;
            ov[1] = 1'b0;
        end

        else if(fexp6b[1]>31)  begin 
            f_e[9:5] = 5'b11111;
            f_m[19:10] = 10'b0;
            ov[1] = 1'b1;
            uf[1] = 1'b0;

        end
        else begin 

            f_e[9:5] = fexp6b[1][4:0];
            f_m[19:10]= fm_hp[1]; 
            uf[1] = 1'b0;
            ov[1] = 1'b0;


        end 


    end
    2'b10: begin 
        ov[2] = 1'b0;
        uf[2] = 1'b0;
        f_e[23:16] = 'b0;
        f_m[22:20] =3'b0;
        if(fexp9b[0]==0) begin 
            f_e[7:0] = 8'b0;
            f_m[9:0] = 10'b0;
            uf[0] = 1'b1;
            ov[0] = 1'b0;
        end

        else if(fexp9b[0]>254)  begin 
            f_e[7:0] = 8'b11111111;
            f_m[9:0] = 10'b0;
            ov[0] = 1'b1;
            uf[0] = 1'b0;

        end
        else begin 

            f_e[7:0] = fexp9b[0][7:0];
            f_m[9:0]= fm_hp[0]; 
            uf[0] = 1'b0;
            ov[0] = 1'b0;


        end 

        if(fexp9b[1]==0) begin 
            f_e[15:8] = 8'b0;
            f_m[19:10] = 10'b0;
            uf[1] = 1'b1;
            ov[1] = 1'b0;
        end

        else if(fexp9b[1]>254)  begin 
            f_e[15:8] = 8'b11111111;
            f_m[19:10] = 10'b0;
            ov[1] = 1'b1;
            uf[1] = 1'b0;

        end
        else begin 

            f_e[15:8] = fexp9b[1][7:0];
            f_m[19:10]= fm_hp[1]; 
            uf[1] = 1'b0;
            ov[1] = 1'b0;


        end 

    end

    2'b11: begin 

        ov[1] = 1'b0;ov[2] = 1'b0;
        uf[1] = 1'b0; uf[2] = 1'b0;
        f_e[23:8] = 'b0;
        if(fexp9b[0]==0) begin 
            f_e[7:0] = 8'b0;
            f_m = 23'b0;
            uf[0] = 1'b1;
            ov[0] = 1'b0;
        end

        else if(fexp9b[0]>254)  begin 
            f_e[7:0] = 8'b11111111;
            f_m = 23'b0;
            ov[0] = 1'b1;
            uf[0] = 1'b0;

        end
        else begin 

            f_e[7:0] = fexp9b[0][7:0];
            f_m= fm_sp; 
            uf[0] = 1'b0;
            ov[0] = 1'b0;


        end 

    end


    endcase 


end 
endmodule



//+++++++++++++++++++++++++++++++++++++++++++++++++//
// Mode --> 00: BF16, 01: HP.10:TF, 11:SP///
//------------------------------------------------=//
module norma_mul(input [47:0] data,
                 input [1:0] mode,
                 input [26:0] e_m, // so that it can accomodate 3 bf exponents
                 output reg [26:0] e_m_o, // output exponent
                 output reg [47:0] data_o

    );
    // variables for multiplied mantissa 
    logic [21:0] tmm_hp[1:0];
    logic [15:0] tmm_bf[2:0];
    logic [47:0] tmm_sp;
    // after the extention to accomodate the right shift 
    logic [21:0] nmm_hp[1:0];
    logic [15:0] nmm_bf[2:0];
    logic [47:0] nmm_sp;
    
    // variables for exponent 
    logic [5:0] emm_hp[1:0];
    logic [8:0] emm_bf[2:0];
    logic [8:0] emm_sp;
    logic [5:0] em_hp[1:0];
    logic [8:0] em_bf[2:0];
    logic [8:0] em_sp;
    
    
    
    // assigning values for hp and tf mode 
    assign tmm_hp[0] = data[21:0];
    assign tmm_hp[1] = data[45:24];
    
    // assigning values for bfloat mode 
    assign tmm_bf[0] = data[15:0];
    assign tmm_bf[1] = data[31:16];
    assign tmm_bf[2] = data[47:32];
    
    // assigning value for sp 
    assign tmm_sp = data;
    
    // unpacking the exponents 
    
    assign em_hp[0] = e_m[5:0];
    assign em_hp[1] = e_m[14:9];
    
    assign em_bf[0] = e_m[8:0];
    assign em_bf[1] = e_m[17:9];
    assign em_bf[2] = e_m[26:18];
    
    assign em_sp = e_m[8:0];
    
    always @(*) begin 
     emm_sp = 'b0; emm_hp[0] = 'b0; emm_hp[1]='b0; emm_bf[0]='b0;emm_bf[1]='b0;emm_bf[2]='b0;
    
    case(mode)
    2'b00: begin 
    
    if(tmm_bf[0][15]) begin 
        emm_bf[0] = em_bf[0]+'b1;
        nmm_bf[0] = tmm_bf[0];
    end
    else begin 
        emm_bf[0] = em_bf[0];
        nmm_bf[0] = {tmm_bf[0][14:0],1'b0};
    end
    
     if(tmm_bf[1][15]) begin 
        emm_bf[1] = em_bf[1]+'b1;
        nmm_bf[1] = tmm_bf[1];
    end
    else begin 
        emm_bf[1] = em_bf[1];
        nmm_bf[1] = {tmm_bf[1][14:0],1'b0};
    end
    
    if(tmm_bf[2][15]) begin 
        emm_bf[2] = em_bf[2]+'b1;
        nmm_bf[2] = tmm_bf[2];
    end
    else begin 
        emm_bf[2] = em_bf[2];
        nmm_bf[2] = {tmm_bf[2][14:0],1'b0};
    end
    
    data_o = {nmm_bf[2],nmm_bf[1],nmm_bf[1]};
    e_m_o = {emm_bf[2],emm_bf[1],emm_bf[0]};
    
    end// case 00

    2'b01: begin 
    
        if(tmm_hp[0][21]) begin 
            emm_hp[0] = em_hp[0]+'b1;
            nmm_hp[0] = tmm_hp[0];
        end
        else begin 
            emm_hp[0] = em_hp[0];
            nmm_hp[0] = {tmm_hp[0][20:0],1'b0};
        end
        
        if(tmm_hp[1][21]) begin 
            emm_hp[1] = em_hp[1]+'b1;
            nmm_hp[1] = tmm_hp[1];
        end
        else begin 
            emm_hp[1] = em_hp[1];
            nmm_hp[1] = {tmm_hp[1][20:0],1'b0};
        end
        
        data_o = {nmm_hp[1],nmm_hp[0]};
        e_m_o = {emm_hp[1],emm_hp[0]};
    
    
    
    end// case 01
    2'b10: begin 
        if(tmm_hp[0][21]) begin 
            emm_bf[0] = em_bf[0]+'b1;
            nmm_hp[0] = tmm_hp[0];
        end
        else begin 
            emm_bf[0] = em_bf[0];
            nmm_hp[0] = {tmm_hp[0][20:0],1'b0};
        end
        
        if(tmm_hp[1][21]) begin 
            emm_bf[1] = em_bf[1]+'b1;
            nmm_hp[1] = tmm_hp[1];
        end
        else begin 
            emm_bf[1] = em_bf[1];
            nmm_hp[1] = {tmm_hp[1][20:0],1'b0};
        end
        
        data_o = {nmm_hp[1],nmm_hp[0]};
        e_m_o = {emm_bf[1],emm_bf[0]};
        
        
        
        
        end// case 10
    
    2'b11: begin 
    if(tmm_sp[47]) begin 
         emm_sp = em_sp+'b1;
         nmm_sp = tmm_sp;
     end
     else begin 
         emm_sp = em_sp;
         nmm_sp = {tmm_sp[46:0],1'b0};
     end
     data_o = nmm_sp;
     e_m_o = emm_sp;
 
    end// case 11

    
    
    
    endcase
    end // always
    
    
    
    
endmodule
//+++++++++++++++++++++++++++++++++++++++++++++++++//
// Mode --> 00: BF16, 01: HP.10:TF, 11:SP///
//------------------------------------------------=//

module round(
    input [71:0] data,
    //input [26:0] exp,
    input [1:0] mo,
    output reg [26:0] r_data
    //output reg [26:0] exp_out
);
// normalization after rounding I will do outside I will send k1,k2,k3 and then it can generate the rounding ok 

// // these are for exponents 
// logic [8:0] t_e [2:0]; 
// logic [5:0] hp_e [1:0]; // these two are used for when the mode is half precision
// assign t_e[0]  = exp[8:0]; // this is only used when the mode is sp 
// assign t_e[1]  = exp[9:17];
// assign t_e[2]  = exp[18:26];
// assign hp_e[0] = exp[5:0]; 
// assign hp_e[1] = exp[11:6];

 
logic k[2:0];
logic g_s; // guard bit 
logic p_s; // pre guard bit 
logic r_s; //round bit
logic s_s; // sticky bit

//logic k_b[2:0]; signals for bfloat
logic g_b[2:0]; // guard bit 
logic p_b[2:0]; // pre guard bit 
logic r_b[2:0]; //round bit
logic s_b[2:0]; // sticky bit

//logic k_h[1:0];
logic g_h[1:0]; // guard bit 
logic p_h[1:0]; // pre guard bit 
logic r_h[1:0]; //round bit
logic s_h[1:0]; // sticky bit


logic [23:0] bf_sig [2:0];
logic [32:0] hp_sig [1:0]; // this will be used for tfloat and hp16
logic [71:0] sp_sig;

// rounding register
logic [23:0] rr_sp;
logic [7:0] rr_bf [2:0];
logic [10:0] rr_hp [1:0];

logic [24:0] rro_sp;
logic [8:0] rro_bf [2:0];
logic [11:0] rro_hp [1:0];

/// for single precision mode 
assign sp_sig    = data;
// for half precision and tfloat 
assign hp_sig[0] = data[32:0];
assign hp_sig[1] = data[65:33];
// for bfloat as it has 3 operands to round up 
assign bf_sig[0] = data[23:0];
assign bf_sig[1] = data[47:24];
assign bf_sig[2] = data[71:48];

// assign



// now assigning the mantissa to the round regs
assign rr_sp = sp_sig[71:48]; // since signle precision will have 23 bit mantissa
// three bfloats 
assign rr_bf[0] = bf_sig[0][23:16];
assign rr_bf[1] = bf_sig[1][23:16];
assign rr_bf[2] = bf_sig[2][23:16];

// now for tfloat and hp 
assign rr_hp[0] = hp_sig[0][32:22];
assign rr_hp[1] = hp_sig[1][32:22];

// assigning the values of k,g,r,p,s for all the modes 
// single precision mode 
assign g_s = sp_sig[47];
assign p_s = sp_sig[48];
assign r_s = sp_sig[46];
assign s_s = |sp_sig[45:0];
// bfloat mode 
assign g_b[0] = bf_sig[0][15];
assign g_b[1] = bf_sig[1][15];
assign g_b[2] = bf_sig[2][15];

assign p_b[0] = bf_sig[0][16];
assign p_b[1] = bf_sig[1][16];
assign p_b[2] = bf_sig[2][16];

assign r_b[0] = bf_sig[0][14];
assign r_b[1] = bf_sig[1][14];
assign r_b[2] = bf_sig[2][14];

assign s_b[0] = |bf_sig[0][13:0];
assign s_b[1] = |bf_sig[1][13:0];
assign s_b[2] = |bf_sig[2][13:0];
// half precision and tfloat mode 
assign g_h[0] = hp_sig[0][21];
assign g_h[1] = hp_sig[1][21];

assign p_h[0] = hp_sig[0][22];
assign p_h[1] = hp_sig[1][22];

assign r_h[0] = hp_sig[0][20];
assign r_h[1] = hp_sig[1][20];

assign s_h[0] = |hp_sig[0][19:0];
assign s_h[1] = |hp_sig[1][19:0];









always@(*) begin
    case(mo)
    
    2'b00: begin //bf16
        k[0] = g_b[0]&(p_b[0] |r_b[0]| s_b[0]);
        k[1] = g_b[1]&(p_b[1] |r_b[1]| s_b[1]);
        k[2] = g_b[2]&(p_b[2] |r_b[2]| s_b[2]);

        rro_bf[0] = rr_bf[0] +k[0];
        rro_bf[1] = rr_bf[1] +k[1];
        rro_bf[2] = rr_bf[2] +k[2];

        r_data = {rro_bf[2],rro_bf[1],rro_bf[0]};




    end

    2'b01: begin   //hp
        k[0] = g_h[0]&(p_h[0] |r_h[0]| s_h[0]);
        k[1] = g_h[1]&(p_h[1] |r_h[1]| s_h[1]);

        rro_hp[0] = rr_hp[0] + k[0];
        rro_hp[1] = rr_hp[1] + k[1];

        r_data = {3'b0,rro_hp[1],rro_hp[0]};

        

    end

    2'b10: begin //tf
        k[0] = g_h[0]&(p_h[0] |r_h[0]| s_h[0]);
        k[1] = g_h[1]&(p_h[1] |r_h[1]| s_h[1]);

        rro_hp[0] = rr_hp[0] + k[0];
        rro_hp[1] = rr_hp[1] + k[1];

        r_data = {3'b0,rro_hp[1],rro_hp[0]};
        
        
    end

    2'b11: begin //sp
        k[0] = g_s &(p_s | r_s | s_s);
        rro_sp = rr_sp + k[0];
        r_data = {2'b0,rro_sp};


    end

  
    endcase

end

endmodule

module outprocess(
    input [22:0] fm, // final mantissa 
    input [23:0] fe, // final exponent
    input [2:0] fs, // final sign 
    input [2:0] ov1, // overflow due to multiplication 
    input [2:0] ov2, // overflow due to addition 
    input [2:0] uf,
    input [1:0] mode,
    output [2:0] over,
    output [2:0] under,
    output  reg [47:0] final_out
);

logic [7:0] fe8b[2:0];
logic [4:0] fe5b[1:0];
logic [22:0] fm_sp;
logic [6:0] fm_bf[2:0];
logic [9:0] fm_hp [1:0];

// outputs 
logic [15:0] out_bf [2:0];
logic [31:0] out_sp ;
logic [18:0] out_tf[1:0];
logic [15:0] out_hp[1:0];

genvar i;
generate 
    for (i=0;i<3;i=i+1) begin 
        assign fe8b[i] = fe[8*i+:8];
        assign fm_bf[i] = fm[7*i+:7];


    end

endgenerate
generate 
    for(i=0;i<2;i=i+1) begin 

        assign fe5b[i] = fe[5*i+:5];
        assign fm_hp[i] = fm[10*i+:10];

    end


endgenerate 
assign fm_sp = fm;

assign over = ov1|ov2;
assign under = uf;

// assigning the outputs 
assign out_bf[0] = {fs[0],fe8b[0],fm_bf[0]};
assign out_bf[1] = {fs[1],fe8b[1],fm_bf[1]};
assign out_bf[2] = {fs[2],fe8b[2],fm_bf[2]};

assign out_hp[0] = {fs[0],fe5b[0],fm_hp[0]};
assign out_hp[1] = {fs[1],fe5b[1],fm_hp[1]};

assign out_tf[0] = {fs[0],fe8b[0],fm_hp[0]};
assign out_tf[1] = {fs[1],fe8b[1],fm_hp[1]};

assign out_sp = {fs[0],fe8b[0],fm_sp};

always @(*) begin 

    case(mode)

    2'b00: final_out = {out_bf[2],out_bf[1],out_bf[0]};
    2'b01: final_out = {16'b0,out_hp[1],out_hp[0]};
    2'b10: final_out = {10'b0,out_tf[1],out_tf[0]};
    2'b11: final_out = {16'b0,out_sp};
        
    endcase 


end 

endmodule


//+++++++++++++++++++++++++++++++++++++++++++++++++//
// Mode --> 00: BF16, 01: HP.10:TF, 11:SP///
//------------------------------------------------=//

module expo_add ( 
    input [23:0] e_a,
    input [23:0] e_b,
    input [1:0] mode, 
    input [2:0] s_a,
    input [2:0] s_b,
    output[2:0] s_m,
    output reg [26:0] e_out
   
   
    );

    assign s_m = s_a ^s_b;

wire [7:0] exa [2:0];
wire [7:0] exb [2:0];
wire [8:0] sum [2:0];
//reg  over[2:0]; 
reg [8:0] iexp [2:0]; // intermediate exponent
//reg [7:0] fexp [2:0];

genvar i; 
generate 
for (i=0;i<3;i=i+1)
assign exa[i] =e_a[8*i+:8];
endgenerate
generate 
for (i=0;i<3;i=i+1)
assign exb[i] = e_b[8*i+:8];
endgenerate

generate 

for(i=0;i<3;i=i+1)
bit8_add u(.a(exa[i]),.b(exb[i]),.sum(sum[i]));

endgenerate

generate 

for (i=0;i<3;i=i+1) 
biasub v(.data(sum[i]),.mode(mode),.exp(iexp[i]));
endgenerate

assign e_out = {iexp[2],iexp[1],iexp[0]};  

endmodule
module bit8_add( 
input [7:0] a,
input [7:0] b,
output [8:0] sum
);

assign sum = a+b;
endmodule
module biasub ( input [8:0] data,
input [1:0] mode,
output  [8:0] exp );

wire [8:0] BIAS;

assign BIAS = (mode == 2'b01)? 9'd15:9'd127;

assign exp = (data>BIAS)? (data-BIAS):9'b0;
endmodule 
//+++++++++++++++++++++++++++++++++++++++++++++++++//
// Mode --> 00: BF16, 01: HP.10:TF, 11:SP///
//------------------------------------------------=//

module align (
    input [23:0] exc, // exponent of c 
    input [26:0] exm, // exponent after multiplication 
    input [47:0] mm, // multiplication output 
    input [23:0] mc, // third input output 
    input [2:0] s_c, // sign  of c 
    input [2:0] s_m, // sign after multiplication 
    input [1:0] mode,
    output reg[71:0] a,
    output reg[71:0] b,
    output reg[23:0] fe, // final exponent
    output reg[2:0] fs, // final sign 
    output reg[2:0] over // overflow 
    //output reg[2:0] uf // underflow  
);
logic [7:0] expc8b [2:0];
logic [4:0] expc5b [1:0];

logic [8:0] expm9b [2:0];
logic [5:0] expm6b [1:0];
logic ov[2:0];
logic u[2:0]; // to detect underflow 

// input sign 
logic sign_c [2:0];
logic sign_m [2:0];
genvar i;


generate 
    for ( i=0;i<3;i=i+1) begin 
    
        assign sign_c[i] = s_c[i];
        assign sign_m[i] = s_m[i];
        end
        
endgenerate



// multiplied significand
logic [71:0] mm_sp;
logic [23:0] mm_bf [2:0];
logic [32:0] mm_hp [1:0];

logic [7:0] shamt [2:0];

assign  mm_sp = {mm,{24{1'b0}}};
assign mm_bf[0] = {mm[15:0],{8{1'b0}}};
assign mm_bf[1] = {mm[31:16],{8{1'b0}}};
assign mm_bf[2] = {mm[47:32],{8{1'b0}}};

assign mm_hp[0] = {mm[21:0],{11{1'b0}}};
assign mm_hp[1] = {mm[43:22],{11{1'b0}}};
// extended multiplied significand 

logic [71:0] mme_sp;
logic [23:0] mme_bf [2:0];
logic [32:0] mme_hp [1:0];

// third significand c
logic [71:0] mc_sp;
logic [23:0] mc_bf [2:0];
logic [32:0] mc_hp [1:0];

assign mc_sp = {mc,{48{1'b0}}};
assign mc_bf[0] = {mc[7:0],{16{1'b0}}};
assign mc_bf[1] = {mc[15:8],{16{1'b0}}};
assign mc_bf[2] = {mc[23:16],{16{1'b0}}};

assign mc_hp[0] = {mc[10:0],{22{1'b0}}};
assign mc_hp[1] = {mc[22:12],{22{1'b0}}};

// extended mantissa for third c 
logic [71:0] mce_sp;
logic [23:0] mce_bf [2:0];
logic [32:0] mce_hp [1:0]; 

// comparator input 
logic [7:0] cin1 [2:0];
logic [7:0] cin2 [2:0];

generate 
    for (i=0;i<3;i=i+1) 
    assign expc8b[i] = exc[8*i+:8];

endgenerate 

assign expc5b[0] = exc[4:0];
assign expc5b[1] = exc[12:8];

generate 
    for (i=0;i<3;i=i+1) 
    assign expm9b[i] = exm[9*i+:9];

endgenerate 
generate 
    for (i=0;i<2;i=i+1) 
    assign expm6b[i] = exm[6*i+:6];

endgenerate

// assigning values of exponent of c 
assign cin1[0] = (mode ==2'b01) ? {{3{1'b0}},expc5b[0]}:expc8b[0];
assign cin1[1] = (mode ==2'b01) ? {{3{1'b0}},expc5b[1]}:expc8b[1];
assign cin1[2] = expc8b[2];

// assigning values of exponent of multiplier 
assign cin2[0] = (mode ==2'b01) ? {{3{1'b0}},expm6b[0][4:0]}:expm9b[0][7:0];
assign cin2[1] = (mode ==2'b01) ? {{3{1'b0}},expm6b[1][4:0]}:expm9b[1][7:0];
assign cin2[2] = expm9b[2][7:0];

// gt lt and eq symbol 

logic gt [2:0];
logic lt [2:0];
//logic eq [2:0];






// instantiating comparator modules
compa u0(.a(cin1[0]),.b(cin2[0]),.gt(gt[0]),.lt(lt[0]));
compa u1(.a(cin1[1]),.b(cin2[1]),.gt(gt[1]),.lt(lt[1]));
compa u2(.a(cin1[2]),.b(cin2[2]),.gt(gt[2]),.lt(lt[2]));


always @(*) begin

    
    if (mode==2'b01) begin 

        ov[0]= (expm6b[0][5] ==1)? 1'b1:1'b0;
        ov[1]= (expm6b[1][5] ==1)? 1'b1:1'b0;
        ov[2]= 1'b0;


    end
    else  begin 
        ov[0]= (expm9b[0][8] ==1)? 1'b1:1'b0;
        ov[1]= (expm9b[1][8] ==1)? 1'b1:1'b0;
        ov[2]= (expm9b[2][8] ==1)? 1'b1:1'b0;
        
    end

    
end
// for assigning underflow values
always @(*) begin

    
    if (mode==2'b01) begin 

        u[0]= (expm6b[0] ==0)? 1'b1:1'b0;
        u[1]= (expm6b[1] ==0)? 1'b1:1'b0;
        u[2]= 1'b0;


    end
    else  begin 
        u[0]= (expm9b[0] ==0)? 1'b1:1'b0;
        u[1]= (expm9b[1] ==0)? 1'b1:1'b0;
        u[2]= (expm9b[2] ==0)? 1'b1:1'b0;
        
    end
    


end
assign over = {ov[2],ov[1],ov[0]};
//assign uf   = {u[2],u[1],u[0]};

/// exponent processing block 
always @(*) begin

    if(mode == 2'b01) begin // this case only have 5 bit exponent
        fe[23:16] = 8'b00000000;
        if(ov[0]) fe[7:0]= 8'b00011111;
        else if (u[0]) fe[7:0] = 8'b00000000;
        else begin
            if(gt[0]) fe[7:0] = {{3{1'b0}},expc5b[0]};
            else if(lt[0]) fe[7:0] = {{3{1'b0}},expm6b[0][4:0]};
            else fe[7:0] = {{3{1'b0}},expc5b[0]};


        end

        if(ov[1]) fe[15:8]= 8'b00011111;
        else if (u[0]) fe[15:8] = 8'b00000000;
        else begin
            if(gt[1]) fe[15:8] = {{3{1'b0}},expc5b[1]};
            else if(lt[1]) fe[15:8] = {{3{1'b0}},expm6b[1][4:0]};
            else fe[15:8] = {{3{1'b0}},expc5b[1]};


        end
        
    end
   

    else begin
        if(ov[0]) fe[7:0]= 8'b11111111;
        else if (u[0]) fe[7:0] = 8'b00000000;
        else begin
            if(gt[0]) fe[7:0] = expc8b[0];
            else if(lt[0]) fe[7:0] = expm9b[0][7:0];
            else fe[7:0] = expc8b[0];


        end

        if(ov[1]) fe[15:8]= 8'b11111111;
        else if (u[0]) fe[15:8] = 8'b00000000;
        else begin
            if(gt[1]) fe[15:8] = expc8b[1];
            else if(lt[1]) fe[15:8] = expm9b[1][7:0];
            else fe[15:8] = expc8b[1];


        end

        if(ov[2]) fe[23:16]= 8'b11111111;
        else if (u[2]) fe[23:16] = 8'b00000000;
        else begin
            if(gt[2]) fe[23:16] = expc8b[2];
            else if(lt[2]) fe[23:16] = expm9b[2][7:0];
            else fe[23:16] = expc8b[2];


        end

    end





end


always @* begin

    
   // else begin 

        case(mode)
        
        2'b00: begin // bf
            if(ov[0]) begin 
                a[23:0] =24'b0;
                b[23:0] =24'b0;
                fs[0] = sign_m[0]; // since overflow is only caused by multiplication
                
              

            end
            else if(u[0]) begin 
            a[23:0] =mc_bf[0]; // since due to underflow the multiplied result is 0 
            b[23:0] =24'b0;
            fs[0] = sign_c[0];
            
            
            end
            else begin 
            if(gt[0]) begin // implies that exp of c is greater than exp of multiplication
                shamt[0] = expc8b[0]-expm9b[0][7:0];
                mce_bf[0] = mc_bf[0];
                mme_bf[0] = mm_bf[0] >> shamt[0];
                a[23:0] = mce_bf[0];
                b[23:0] = mme_bf[0];
                fs[0] =sign_c[0];


            end
            else if(lt[0]) begin // implies that exp of  multiplication is greater than c 
                shamt[0] = expm9b[0][7:0]-expc8b[0];
                mme_bf[0] =mm_bf[0];
                mce_bf[0] = mc_bf[0] >> shamt[0];
                a[23:0] = mme_bf[0];
                b[23:0] = mce_bf[0];
                fs[0] =sign_m[0];

            end
            else begin // implies that exp of c is greater than exp of multiplication
                
                mme_bf[0] =mm_bf[0];
                mce_bf[0] = mc_bf[0];
                a[23:0] = (mm_bf[0]>mc_bf[0]) ?mme_bf[0]: mce_bf[0];
                b[23:0] = (mm_bf[0]>mc_bf[0]) ?mce_bf[0]: mme_bf[0];
                fs[0] =(mm_bf[0]>mc_bf[0]) ? sign_m[0] : sign_c[0];

            end
        end
        if(ov[1]) begin 
            a[47:24] =24'b0;
            b[47:24] =24'b0;
            fs[1] = sign_m[1];

        end
        else if (u[1]) begin 
        a[47:24] =mc_bf[1];
        b[47:24] =24'b0;
        fs[1] = sign_c[1];
        
        
        end
        else begin 

            if(gt[1]) begin // implies that exp of c is greater than exp of multiplication
                shamt[1] = expc8b[1]-expm9b[1][7:0];
                mce_bf[1] = mc_bf[1];
                mme_bf[1] = mm_bf[1] >> shamt[1];
                a[47:24] = mce_bf[1];
                b[47:24] = mme_bf[1];
                fs[1] =sign_c[1];

            end
            else if(lt[1]) begin // implies that exp of c is greater than exp of multiplication
                shamt[1] = expm9b[1][7:0]-expc8b[1];
                mme_bf[1] = mm_bf[1];
                mce_bf[1] = mc_bf[1] >> shamt[1];
                a[47:24] = mme_bf[1];
                b[47:24] = mce_bf[1];
                fs[1] =sign_m[1];
            end
            else begin // implies that exp of c is greater than exp of multiplication
                
                mme_bf[1] =mm_bf[1];
                mce_bf[1] = mc_bf[1];
                a[47:24] = (mm_bf[1]>mc_bf[1]) ?mme_bf[1]: mce_bf[1];
                b[47:24] = (mm_bf[1]>mc_bf[1]) ?mce_bf[1]: mme_bf[1];
                fs[1] =(mm_bf[1]>mc_bf[1]) ? sign_m[1] : sign_c[1];

            end
        end
        if(ov[2]) begin 
            a[71:48] =24'b0;
            b[71:48] =24'b0;
            fs[2] = sign_m[2];

        end
        else if (u[2]) begin
        a[71:48] =mc_bf[2];
        b[71:48] =24'b0;
        fs[2] = sign_c[2];
        
        
        end
        else begin 

            if(gt[2]) begin // implies that exp of c is greater than exp of multiplication
                shamt[2] = expc8b[2]-expm9b[2][7:0];
                mce_bf[2] = mc_bf[2];
                mme_bf[2] = mm_bf[2] >> shamt[2];
                a[71:48] = mce_bf[2];
                b[71:48] = mme_bf[2];
                fs[2] =sign_c[2];

            end
            else if(lt[2]) begin // implies that exp of c is greater than exp of multiplication
                shamt[2] = expm9b[2][7:0]-expc8b[2];
                mme_bf[2] =mm_bf[2];
                mce_bf[2] = mc_bf[2] >> shamt[2];
                a[71:48] = mme_bf[2];
                b[71:48] = mce_bf[2];
                fs[2] =sign_m[2];

            end
            else begin // implies that exp of c is greater than exp of multiplication
                
                mme_bf[2] =mm_bf[2];
                mce_bf[2] = mc_bf[2];
                a[71:48] = (mm_bf[2]>mc_bf[2]) ?mme_bf[2]: mce_bf[2];
                b[71:48] = (mm_bf[2]>mc_bf[2]) ?mce_bf[2]: mme_bf[2];
                fs[2] =(mm_bf[2]>mc_bf[2]) ? sign_m[2] : sign_c[2];

            end
            
        end
    end
        2'b01: begin // hp 
        a[71:66] = 'b0;
        b[71:66] = 'b0;
         fs[2] = 1'b0;
            if(ov[0]) begin 
                a[32:0] =33'b0;
                b[32:0] =33'b0;
                fs[0] = sign_m[0]; // since underflow and overflow is only caused by multiplication

    
            end
            else if (u[0]) begin 
                a[32:0] =mc_hp[0];
                b[32:0] =33'b0;
                fs[0] = sign_c[0];
            
            end
            else begin 
            if(gt[0]) begin // implies that exp of c is greater than exp of multiplication
                shamt[0] = expc5b[0]-expm6b[0][4:0];
                mce_hp[0] = mc_hp[0];
                mme_hp[0] = mm_hp[0] >> shamt[0];
                a[32:0] = mce_hp[0];
                b[32:0] = mme_hp[0];
                fs[0] =sign_c[0];

            end
            else if(lt[0]) begin // implies that exp of c is greater than exp of multiplication
                shamt[0] = expm6b[0][4:0]-expc5b[0];
                mce_hp[0] = mc_hp[0]>>shamt[0];
                mme_hp[0] = mm_hp[0];
                a[32:0] = mme_hp[0];
                b[32:0] = mce_hp[0];
                fs[0] =sign_m[0];

            end
            else begin // implies that exp of c is greater than exp of multiplication
                
                mce_hp[0] = mc_hp[0];
                mme_hp[0] = mm_hp[0];
                a[32:0] = (mm_hp[0]>mc_hp[0]) ?mme_hp[0]:mce_hp[0];
                b[32:0] =(mm_hp[0]>mc_hp[0]) ? mce_hp[0]:mme_hp[0];
                fs[0] =(mm_hp[0]>mc_hp[0]) ? sign_m[0] : sign_c[0];

            end
        end
        if(ov[1]) begin 
            a[65:33] =33'b0;
            b[65:33] =33'b0;
            fs[1] = sign_m[1];
            

        end
        else if (u[1]) begin
            a[65:33] =mc_hp[1];
            b[65:33] =33'b0;
            fs[1] = sign_c[1];
        
        
        end
        else begin 

            if(gt[1]) begin // implies that exp of c is greater than exp of multiplication
                shamt[1] = expc5b[1]-expm6b[1][4:0];
                mce_hp[1] = mc_hp[1];
                mme_hp[1] = mm_hp[1] >> shamt[1];
                a[65:33] = mce_hp[1];
                b[65:33] = mme_hp[1];
                fs[1] =sign_c[1];

            end
            else if(lt[1]) begin // implies that exp of c is greater than exp of multiplication
                shamt[1] = expm6b[1][4:0]-expc5b[1];
                mce_hp[1] = mc_hp[1]>>shamt[1];
                mme_hp[1] = mm_hp[1];
                a[65:33] = mme_hp[1];
                b[65:33] = mce_hp[1];
                fs[1] =sign_m[1];

            end
            else begin // implies that exp of c is greater than exp of multiplication
                
                mce_hp[1] = mc_hp[1];
                mme_hp[1] = mm_hp[1];
                a[65:33] = (mm_hp[1]>mc_hp[1]) ?mme_hp[1]:mce_hp[1];
                b[65:33] = (mm_hp[1]>mc_hp[1]) ? mce_hp[1]:mme_hp[1];
                fs[1] =(mm_hp[1]>mc_hp[1]) ? sign_m[1] : sign_c[1];

            end
        end
    end
        
    
            2'b10: begin // hp 
            fs[2] = 1'b0;
            a[71:66] = 'b0;
            b[71:66] = 'b0;
            if(ov[0]) begin 
                a[32:0] =33'b0;
                b[32:0] =33'b0;
                fs[0] = sign_m[0]; // since underflow and overflow is only caused by multiplication

    
            end
            else if (u[0]) begin 
                a[32:0] =mc_hp[0];
                b[32:0] =33'b0;
                fs[0] = sign_c[0];
            
            end
                else begin 
                if(gt[0]) begin // implies that exp of c is greater than exp of multiplication
                    shamt[0] = expc8b[0]-expm9b[0][7:0];
                    mce_hp[0] = mc_hp[0];
                    mme_hp[0] = mm_hp[0] >> shamt[0];
                    a[32:0] = mce_hp[0];
                    b[32:0] = mme_hp[0];
                    fs[0] = sign_c[0];
    
                end
                else if(lt[0]) begin // implies that exp of c is greater than exp of multiplication
                    shamt[0] = expm9b[0][7:0]-expc8b[0];
                    mce_hp[0] = mc_hp[0]>>shamt[0];
                    mme_hp[0] = mm_hp[0];
                    a[32:0] = mme_hp[0];
                    b[32:0] = mce_hp[0];
                    fs[0] = sign_m[0];
    
                end
                else begin // implies that exp of c is greater than exp of multiplication
                    
                    mce_hp[0] = mc_hp[0];
                    mme_hp[0] = mm_hp[0];
                    a[32:0] = (mm_hp[0]>mc_hp[0]) ?mme_hp[0]:mce_hp[0];
                    b[32:0] =(mm_hp[0]>mc_hp[0]) ? mce_hp[0]:mme_hp[0];
                    fs[0] =(mm_hp[0]>mc_hp[0]) ? sign_m[0] : sign_c[0];
    
                end
            end
            if(ov[1]) begin 
                a[65:33] =33'b0;
                b[65:33] =33'b0;
                fs[1] = sign_m[1];
                
    
            end
            else if (u[1]) begin
                a[65:33] =mc_hp[1];
                b[65:33] =33'b0;
                fs[1] = sign_c[1];
            
            
            end
            else begin 
    
                if(gt[1]) begin // implies that exp of c is greater than exp of multiplication
                    shamt[1] = expc8b[1]-expm9b[1][7:0];
                    mce_hp[1] = mc_hp[1];
                    mme_hp[1] = mm_hp[1] >> shamt[1];
                    a[65:33] = mce_hp[1];
                    b[65:33] = mme_hp[1];
                    fs[1] = sign_c[1];
    
                end
                else if(lt[1]) begin // implies that exp of c is greater than exp of multiplication
                    shamt[1] = expm9b[1][7:0]-expc8b[1];
                    mce_hp[1] = mc_hp[1]>>shamt[1];
                    mme_hp[1] = mm_hp[1];
                    a[65:33] = mme_hp[1];
                    b[65:33] = mce_hp[1];
                    fs[1] = sign_m[1];
    
                end
                else begin // implies that exp of c is greater than exp of multiplication
                    
                    mce_hp[1] = mc_hp[1];
                    mme_hp[1] = mm_hp[1];
                    a[65:33] = (mm_hp[1]>mc_hp[1]) ?mme_hp[1]:mce_hp[1];
                    b[65:33] = (mm_hp[1]>mc_hp[1]) ? mce_hp[1]:mme_hp[1];
                    fs[1] =(mm_hp[1]>mc_hp[1]) ? sign_m[0] : sign_c[0];
    
                end
                end
            end

                2'b11: begin 
                fs[2] = 1'b0;
                fs[1] = 1'b0;
                    if(ov[0]) begin 
                        a[71:0] =72'b0;
                        b[71:0] =72'b0;
                        fs[0] = sign_m[0]; // since underflow and overflow is only caused by multiplication

            
                    end
                    else if (u[0]) begin 
                         a[71:0] =mc_sp;
                         b[71:0] =72'b0;
                         fs[0] = sign_c[0];
                    
                    
                    end
                    else begin 
                    if(gt[0]) begin // implies that exp of c is greater than exp of multiplication
                        shamt[0] = expc8b[0]-expm9b[0][7:0];
                        mce_sp = mc_sp;
                        mme_sp = mm_sp >> shamt[0];
                        a= mce_sp;
                        b= mme_sp;
                        fs[0] = sign_c[0];
        
                    end
                    else if(lt[0]) begin // implies that exp of c is greater than exp of multiplication
                        shamt[0] = expm9b[0][7:0]-expc8b[0];
                        mce_sp = mc_sp>>shamt[0];
                        mme_sp = mm_sp;
                        a= mme_sp;
                        b= mce_sp;
                        fs[0] = sign_m[0];
        
                    end
                    else begin // implies that exp of c is greater than exp of multiplication
                        
                        mce_sp = mc_sp;
                        mme_sp = mm_sp;
                        a= (mm_sp>mc_sp)?mme_sp:mce_sp;
                        b= (mm_sp>mc_sp)?mce_sp:mme_sp;
                        fs[0] = (mm_sp>mc_sp)?sign_m[0]: sign_c[0];
        
                    end
                end
                    
                end

            

        endcase 

    end

endmodule
module data_sel(
    input [71:0] ndaa,
    input [71:0] ndas,
    input [26:0] neaa,
    input [26:0] neas,
    input [1:0]  mode,
    input [2:0]  sign_i,
    output reg [71:0] round_data,
    output reg [26:0] fexp
);

logic [71:0] ndaa_sp;
logic [23:0] ndaa_bf[2:0];
logic [32:0] ndaa_hp[1:0];
logic [71:0] ndas_sp;
logic [23:0] ndas_bf[2:0];
logic [32:0] ndas_hp[1:0];

logic [8:0] neaa_8b[2:0];
logic [5:0] neaa_5b[1:0];

logic [8:0] neas_8b[2:0];
logic [5:0] neas_5b[1:0];

assign ndaa_sp = ndaa;
assign ndaa_bf[0] = ndaa[23:0];
assign ndaa_bf[1] = ndaa[47:24];
assign ndaa_bf[2] = ndaa[71:48];
assign ndaa_hp[0] = ndaa[32:0];
assign ndaa_hp[1] = ndaa[65:33];

assign ndas_sp = ndas;
assign ndas_bf[0] = ndas[23:0];
assign ndas_bf[1] = ndas[47:24];
assign ndas_bf[2] = ndas[71:48];
assign ndas_hp[0] = ndas[32:0];
assign ndas_hp[1] = ndas[65:33];

assign neaa_8b[0] = neaa[8:0];
assign neaa_8b[1] = neaa[17:9];
assign neaa_8b[2] = neaa[26:18];
assign neaa_5b[0] = neaa[5:0];
assign neaa_5b[1] = neaa[11:6];

assign neas_8b[0] = neas[8:0];
assign neas_8b[1] = neas[17:9];
assign neas_8b[2] = neas[26:18];
assign neas_5b[0] = neas[5:0];
assign neas_5b[1] = neas[11:6];

// final data 

logic [71:0] fd_sp;
logic [23:0] fd_bf[2:0];
logic [32:0] fd_hp[1:0];


logic [8:0] fe_8b[2:0];
logic [5:0] fe_5b[1:0];

assign fd_sp    = (sign_i[0])? ndas_sp: ndaa_sp;
assign fd_bf[0] = (sign_i[0])? ndas_bf[0]: ndaa_bf[0];
assign fd_bf[1] = (sign_i[1])? ndas_bf[1]: ndaa_bf[1];
assign fd_bf[2] = (sign_i[2])? ndas_bf[2]: ndaa_bf[2];

assign fd_hp[0] = (sign_i[0])? ndas_hp[0]: ndaa_hp[0];
assign fd_hp[1] = (sign_i[1])? ndas_hp[1]: ndaa_hp[1];

assign fe_8b[0] = (sign_i[0])? neas_8b[0]: neaa_8b[0];
assign fe_8b[1] = (sign_i[1])? neas_8b[1]: neaa_8b[1];
assign fe_8b[2] = (sign_i[2])? neas_8b[2]: neaa_8b[2];

assign fe_5b[0] = (sign_i[0])? neas_5b[0]: neaa_5b[0];
assign fe_5b[1] = (sign_i[1])? neas_5b[1]: neaa_5b[1];





always @(*) begin 

    case(mode) 
    2'b00: begin 
          fexp       = {fe_8b[2],fe_8b[1],fe_8b[0]};
          round_data = {fd_bf[2],fd_bf[1],fd_bf[0]};

    end

    2'b01: begin  // hp
        fexp       = {15'b0,fe_5b[1],fe_5b[0]};
        round_data = {6'b0,fd_hp[1],fd_hp[0]};


    end

    2'b10: begin 
        fexp       = {9'b0,fe_8b[1],fe_8b[0]};
        round_data = {6'b0,fd_hp[1],fd_hp[0]};

    end

    2'b11: begin 
        fexp       = {18'b0,fe_8b[0]};
        round_data =  fd_sp;

    end

    endcase


end



endmodule



module compa( input [7:0] a,
              input [7:0] b,
              output gt,
              output lt
              //output eq

    );
    

    logic g[1:0];
    logic l[1:0];
    logic e[1:0];
    logic [3:0] ain[1:0];
    logic [3:0] bin[1:0];
    
    assign ain[0] = a[3:0];
    assign ain[1] = a[7:4];
    
    assign bin[0] = b[3:0];
    assign bin[1] = b[7:4];
    
    comp4b c1(.a(ain[1]),.b(bin[1]),.gt(g[1]),.lt(l[1]),.eq(e[1])); // 4 bit msb
    
    comp4b c2(.a(ain[0]),.b(bin[0]),.gt(g[0]),.lt(l[0]),.eq(e[0])); // 4 bit lsb
    
    //assign eq = e[1]&e[0];
    assign gt = g[1] | (e[1]&g[0]);
    assign lt = l[1] | (e[1]&l[0]);
    
endmodule
module comp4b ( input [3:0] a,
              input [3:0] b,
              output gt,
              output lt,
              output eq
              );
              
              assign eq = (a[3]~^b[3])&(a[2]~^b[2])&(a[1]~^b[1])&(a[0]~^b[0]);
              assign gt = a[3]&(~b[3]) | (a[3]~^b[3])&(a[2]&(~b[2])) | (a[3]~^b[3])&(a[2]~^b[2])&(a[1]&(~b[1])) |(a[3]~^b[3])&(a[2]~^b[2])&(a[1]~^b[1])&(a[0]&(~b[0]));
              assign lt = b[3]&(~a[3]) | (a[3]~^b[3])&(b[2]&(~a[2])) | (a[3]~^b[3])&(a[2]~^b[2])&(b[1]&(~a[1])) |(a[3]~^b[3])&(a[2]~^b[2])&(a[1]~^b[1])&(b[0]&(~a[0]));
              
endmodule



module adder (
                input [71:0] a_in,
                input [71:0] b_in,
                input [1:0] mode,
                input [2:0]sub,
                output reg [74:0] add_data,
                output reg [71:0] sub_data
);

logic [23:0] a [2:0];
logic [23:0] b [2:0];
logic [32:0] a_hp [1:0];
logic [32:0] b_hp [1:0];

logic c [3:0];
logic c_h[1:0];
logic cin[1:0];

assign a[0] = a_in[23:0];
assign a[1] = a_in[47:24];
assign a[2] = a_in[71:48];

assign b[0] = b_in[23:0];
assign b[1] = b_in[47:24];
assign b[2] = b_in[71:48];

assign a_hp[0] = a_in[32:0];
assign a_hp[1] = a_in[65:33];

//logic [23:0] a_bar [2:0];
logic [23:0] b_bar [2:0];
//logic [32:0] a_hpbar [1:0];
logic [32:0] b_hpbar [1:0];

//assign a_bar[0] = ~a[0];
//assign a_bar[1] = ~a[1];
//assign a_bar[2] = ~a[2];




assign b_hp[0] = b_in[32:0];
assign b_hp[1] = b_in[65:33];

assign b_hpbar[0] = ~b_hp[0];
assign b_hpbar[1] = ~b_hp[1];

assign b_bar[0] = ~b[0];
assign b_bar[1] = ~b[1];
assign b_bar[2] = ~b[2];

logic [23:0] in1 [2:0];
logic [23:0] in2 [2:0];

logic [32:0] in1_hp [1:0];
logic [32:0] in2_hp [1:0];

assign in1[0] = a[0];
assign in1[1] = a[1];
assign in1[2] = a[2];

assign in2[0] = (sub[0])? b_bar[0]:b[0];
assign in2[1] = (mode ==2'b11)?((sub[0])?b_bar[1]:b[1]):(sub[1])? b_bar[1]:b[1];
assign in2[2] = (mode ==2'b11)?((sub[0])?b_bar[2]:b[2]):(sub[2])? b_bar[2]:b[2];

assign in1_hp[0] = a_hp[0];
assign in1_hp[1] = a_hp[1];
assign in2_hp[0] = (sub[0])? b_hpbar[0]:b_hp[0];
assign in2_hp[1] = (sub[1])? b_hpbar[1]:b_hp[1];

assign c[0]  = (sub[0])? 1'b1:1'b0;
assign c_h[0] = (sub[0])? 1'b1:1'b0; // for 33 bit adder since there in no carry propagation in that 
assign c_h[1] = (sub[1])? 1'b1:1'b0;

assign cin[0] = (mode ==2'b11)? c[1]:(sub[1])?1'b1:1'b0;
assign cin[1] = (mode ==2'b11)? c[2]:(sub[2])?1'b1:1'b0;



/// variables for addition
//logic [71:0] sum_sp;
logic [33:0] sum_hp[1:0];
logic [23:0] sum_bf[2:0];



/////////////////////////////////////////////////// modules for perfoming addition and subtraction ///////////
add24 i0(.a(in1[0]),.b(in2[0]),.cin(c[0]),.sum(sum_bf[0]),.cout(c[1]));
add24 i1(.a(in1[1]),.b(in2[1]),.cin(cin[0]),.sum(sum_bf[1]),.cout(c[2]));
add24 i2(.a(in1[2]),.b(in2[2]),.cin(cin[1]),.sum(sum_bf[2]),.cout(c[3]));

add33 u0(.a(in1_hp[0]),.b(in2_hp[0]),.cin(c_h[0]),.sum(sum_hp[0]));
add33 u1(.a(in1_hp[1]),.b(in2_hp[1]),.cin(c_h[1]),.sum(sum_hp[1]));





always @* begin 

case(mode)

2'b00: add_data = {c[3],sum_bf[2],c[2],sum_bf[1],c[1],sum_bf[0]};
2'b01: add_data = {{7{1'b0}},sum_hp[1],sum_hp[0]};
2'b10: add_data = {{7{1'b0}},sum_hp[1],sum_hp[0]};

2'b11: add_data = {{2{1'b0}},c[3],sum_bf[2],sum_bf[1],sum_bf[0]};
default : add_data = 'b0;
//add_data = {co[23],so[23],so[22],so[21],so[20],so[19],so[18],so[17],so[15],so[14],so[13],so[12],so[11],so[23],so[10],so[9],so[8],so[7],so[6],so[5],so[4],so[3],so[2],so[1],so[0]};

endcase
end

// for updating sub_data 

always @* begin 

case(mode)

2'b00: sub_data = {sum_bf[2],sum_bf[1],sum_bf[0]};
2'b01: sub_data = {{6{1'b0}},sum_hp[1][32:0],sum_hp[0][32:0]}; // ignoring the carry of the last bit 
2'b10: sub_data = {{6{1'b0}},sum_hp[1][32:0],sum_hp[0][32:0]};

2'b11: sub_data = {sum_bf[2],sum_bf[1],sum_bf[0]};
default : sub_data = 'b0;
//add_data = {co[23],so[23],so[22],so[21],so[20],so[19],so[18],so[17],so[15],so[14],so[13],so[12],so[11],so[23],so[10],so[9],so[8],so[7],so[6],so[5],so[4],so[3],so[2],so[1],so[0]};

endcase
end
endmodule
module add24(
                input [23:0] a,
                input [23:0] b,
                input cin,
                output [23:0] sum,
                output cout

    );
   
    assign {cout,sum} = (a+b+cin);
   
endmodule
module add33( 
                   input [32:0] a,
                   input [32:0] b,
                   input cin,
                   output [33:0] sum
  );
   assign sum = (a+b+cin);
   
endmodule

  


