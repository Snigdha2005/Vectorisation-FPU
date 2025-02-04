// ** This will perform the functionality of a*b+c ** // 
`timescale 1ns/1ps

module mac #(parameter E_WIDTH=8, parameter M_WIDTH=7, parameter I_WIDTH= M_WIDTH +E_WIDTH +1)
	( 
	  input clk,
	  input [I_WIDTH-1:0] ai,bi,ci,
	  output logic  [I_WIDTH-1:0]  out );

    // Defining special signals for special cases 
	
     localparam NAN={1'b0,{E_WIDTH{1'b1}},1'b1,{(M_WIDTH-1){1'b0}}}; // NAN REPRESENTATIOIN IS CHOOSEN TO BE 1ST BIT OF MANTISSA IS 1
     localparam P_INFI={1'b0,{E_WIDTH{1'b1}},{(M_WIDTH){1'b0}}}; //  (+)VE INFINITY
     localparam N_INFI={1'b1,{E_WIDTH{1'b1}},{(M_WIDTH){1'b0}}}; // -VE INFINITY
     localparam P_ZERO={I_WIDTH{1'b0}};
     localparam N_ZERO = {1'b1,{I_WIDTH-1{1'b0}}};
     localparam e_comp={E_WIDTH{1'b1}};
     localparam BIAS = {E_WIDTH-1{1'b1}};
     localparam OVER=2*BIAS;
     //--------------------------------------------------------------------------------------------------------------------
    // input register
    
    logic [I_WIDTH-1:0] a,b,c;
    logic  [I_WIDTH-1:0]  out_w ;
    always @(posedge clk) begin 
    
    a   <= ai;
    b   <= bi;
    c   <= ci;
    out <= out_w;
    
    
    
    end
    // ------------------------------------------------------------------------------------------------------------------


   	logic s_a ,s_b,s_c; //sign
   	logic [E_WIDTH-1:0] e_a,e_b,e_c; //exponent
	logic [M_WIDTH-1:0] m_a,m_b,m_c; //matissa of input 
    logic [M_WIDTH:0] t_m_a,t_m_b; // temporary mantissa for multiplier
    	// -------------------values for the special cases---------------------------------------------------------;;


    logic isNaNA,isNaNB,isNaNC;
    logic isPInfA,isPInfB,isPInfC;
    logic isNInfA,isNInfB,isNInfC;
    logic isSubA,isSubB,isSubC;
    
	
	
    




    // assigninig the values to this signal 
    
    assign s_a = a[I_WIDTH-1];
    assign e_a = a[I_WIDTH-2:M_WIDTH];
    assign m_a = a[M_WIDTH-1:0];
    assign s_b = b[I_WIDTH-1];
    assign e_b = b[I_WIDTH-2:M_WIDTH];
    assign m_b = b[M_WIDTH-1:0];  
    assign s_c = c[I_WIDTH-1];
    assign e_c = c[I_WIDTH-2:M_WIDTH];
    assign m_c = c[M_WIDTH-1:0];  
                                   
    assign isNaNA = ((e_a== e_comp) && (m_a!=0))? 1'b1:1'b0;
    assign isNaNB = ((e_b== e_comp) && (m_b!=0))? 1'b1:1'b0;
    assign isNaNC = ((e_c== e_comp) && (m_c!=0))? 1'b1:1'b0;
    assign isPInfA = (a == P_INFI)? 1'b1:1'b0 ; 
    assign isPInfB = (b == P_INFI)? 1'b1:1'b0 ; 
    assign isPInfC = (c == P_INFI)? 1'b1:1'b0 ; 
    assign isNInfA = (a== N_INFI)? 1'b1:1'b0;
    assign isNInfB = (b== N_INFI)? 1'b1:1'b0;
    assign isNInfC = (c== N_INFI)? 1'b1:1'b0;
    
    assign isSubA = (e_a==0)? 1'b1:1'b0;
    assign isSubB = (e_b==0)? 1'b1:1'b0;
    assign isSubC = (e_c==0)? 1'b1:1'b0;
    
    logic [3*M_WIDTH+2:0] t_m_c; // this is to make mantissa of c and accomodate right shift 
	// preappending 1 to mantissa and appending 0's to the lsb  to accomodate shift                                        
	 
	assign t_m_a = (isSubA)? ({(M_WIDTH+1){1'b0}}):{1'b1,m_a};
	assign t_m_b = (isSubB)? ({(M_WIDTH+1){1'b0}}):{1'b1,m_b};
	assign t_m_c = (isSubC)? ({(3*M_WIDTH +3){1'b0}}):({1'b1,m_c,{(2*M_WIDTH+2){1'b0}}});

	// first stage input registers
    logic s_a_r ,s_b_r,s_c_r; //sign
    logic [E_WIDTH-1:0] e_a_r,e_b_r,e_c_r; //exponent
    //logic [M_WIDTH-1:0] m_a_r,m_b_r,m_c_r; //matissa of input 
    logic [M_WIDTH:0] t_m_a_r,t_m_b_r;
    logic [3*M_WIDTH+2:0] t_m_c_r; 

	logic isNaNA_r,isNaNB_r,isNaNC_r;
    logic isPInfA_r,isPInfB_r,isPInfC_r;
    logic isNInfA_r,isNInfB_r,isNInfC_r;
	logic isSubA_r,isSubB_r;
	
    logic [(2*M_WIDTH)+1:0] t_m_p;
    (*DONT_TOUCH="YES"*)logic[I_WIDTH-1:0] out_s,out_n; //special case output and normal case output 
    

   
   (*DONT_TOUCH="YES"*)logic [M_WIDTH-1:0] f_m;//final mantissa 
   //logic [E_WIDTH-1:0] f_e; // final exponnt
   logic f_s; // final sign for multiplication and final sign
   logic s_m;
   logic [E_WIDTH-1:0] shamt_l;//shiftamount left 
   
   
   
   logic [E_WIDTH:0] t_e;// temporary exponent 
   logic [E_WIDTH:0] e_m;      // exponent of multiplication
logic k,l,g,r,s; // for rounding logic
(*DONT_TOUCH="YES"*)logic spec,spec_r1,spec_r2,spec_r3;
logic g_m1,g_m2; // intermedite temp logic resisters to differenciate between cases 
logic [M_WIDTH :0] r_r,r_rs,r_rd; // rounding logic resister
logic [E_WIDTH:0] e_m_i;
	
	always @ (posedge clk) begin 
		s_a_r     <= s_a;
		s_b_r     <= s_b;
		s_c_r     <= s_c;
		e_a_r     <= e_a;
		e_b_r     <= e_b;
		e_c_r     <= e_c;
		t_m_a_r   <= t_m_a;
		t_m_b_r   <= t_m_b;
		t_m_c_r   <= t_m_c;
		isNaNA_r  <= isNaNA;
		isNaNB_r  <= isNaNB;
		isNaNC_r  <= isNaNC;
		isPInfA_r <= isPInfA;
		isPInfB_r <= isPInfB;
		isPInfC_r <= isPInfC;
		isNInfA_r <= isNInfA;
		isNInfB_r <= isNInfB;
		isNInfC_r <= isNInfC;
		isSubA_r  <= isSubA;
		isSubB_r  <= isSubB;
		//isSubC_r  <= isSubC;
		
	end

//	//multiplication 
//	dsp_macro_0 DSP (
//      .A(t_m_a_r),  // input wire [2 : 0] A
//      .B(t_m_b_r),  // input wire [2 : 0] B
//      .P(t_m_p)  // output wire [5 : 0] P
//    );
	always @(*) 
	 t_m_p = t_m_a_r * t_m_b_r; // calculating the mantissa product 
	
	always @* begin
	 s_m = s_a_r^s_b_r; // sign determination of mantissa
	 
	end

	always @* begin 
	 e_m = e_a_r + e_b_r;
	 e_m_i = ((e_m)>BIAS)? ((e_m)-BIAS):'b0;
	 
	 end
	 
	 always @* begin 
                 // -----------------------special cases----------------------
     
     if (isNaNA_r | isNaNB_r | isNaNC_r  ) begin spec=1'b1;out_s=NAN; end
     else if (isPInfA_r & isNInfB_r ) begin spec=1'b1; out_s = NAN; end
     else if (isNInfA_r & isPInfB_r) begin spec =1'b1;out_s = NAN; end
     else if (isPInfA_r & isPInfB_r && isNInfC_r) begin spec =1'b1; out_s = NAN; end
     else if (isNInfA_r & isNInfB_r && isNInfC_r) begin spec =1'b1; out_s = NAN; end
     else if (isPInfA_r | isPInfB_r ||isPInfC_r) begin spec =1'b1; out_s = P_INFI ;end
     else if (isNInfA_r|isNInfB_r||isNInfC_r) begin spec =1'b1; out_s = N_INFI ; end
     else if (isSubA_r | isSubB_r)  begin spec = 1'b1; out_s = c; end  // multiplication of subnormal is 0 and 0+ c = c

     else  begin spec =1'b0; out_s= 0;end
     
     
     
     end
	
	
	// input to second stage ;
	logic [(2*M_WIDTH)+1:0] t_m_p_r1;
	logic [3*M_WIDTH+2:0] t_m_c_r1; 
	logic s_c_r1,s_m_r1; //sign of c and sign of multiplied significand
	logic [E_WIDTH-1:0] e_c_r1; 
	(*DONT_TOUCH="YES"*)logic [E_WIDTH-1:0] shamt_rt; //shift amount by which smaller mantissa should be shifted it is taken large enough to store the shftamount 
	(*DONT_TOUCH="YES"*)logic [E_WIDTH:0] e_m_r1, e_m_i2;  
	logic isNaNA_r1,isNaNB_r1,isNaNC_r1;
    logic isPInfA_r1,isPInfB_r1,isPInfC_r1;
    logic isNInfA_r1,isNInfB_r1,isNInfC_r1;
	logic isSubA_r1,isSubB_r1;

	logic [3*M_WIDTH+2:0] t_m_c_i; 
	
    logic [3*M_WIDTH+2:0] t_m_m; // this is to make the multiplied mantissa shift 
    logic [3*M_WIDTH+3:0] t_m_s;
    logic [3*M_WIDTH +2:0] t_m_d; // holding temp mantissa sum or difference 
 
    //logic mgt,mgt_r2;
	always @ (posedge clk) begin 

		s_c_r1      <= s_c_r;;
		e_c_r1      <= e_c_r;
		e_m_r1     <= e_m_i;
		s_m_r1     <= s_m;
		t_m_c_r1   <= t_m_c_r;
		t_m_p_r1   <= t_m_p;
		spec_r1     <= spec;
		
	end
    
    always @* g_m1 = (e_m_r1 > e_c_r1)? 1'b1:1'b0;
    always @* g_m2 = (e_c_r1==e_m_r1) ? 1'b1: 1'b0; 
	always @(*) begin 

		
		 if (e_m_r1>0 ) begin 
		   if (t_m_p_r1[2*M_WIDTH+1]) begin 
			   e_m_i2 = e_m_r1+'b1;
			   //t_m_p_r1 = t_m_p_r1>>1;
			   t_m_m = {t_m_p_r1,{(M_WIDTH+1){1'b0}}};
			   //t_m_m = t_m_m >>1;

		   
			end
			 else begin
			  t_m_m = {t_m_p_r1[2*M_WIDTH:0],{(M_WIDTH +2){1'b0}}};
			  e_m_i2 = e_m_r1;
			     
			  end
		end
		else begin 
		   t_m_m =0;
		   e_m_i2 = e_m_r1;
		   
		 end// means underflow is occuring after multiplication
		


			
		 if (g_m1&&(~g_m2) ) begin 
		    //g_m1 =1'b1; g_m2=1'b0;// greater magnitude 1 
			shamt_rt = e_m_i2-e_c_r1;
			t_e = e_m_i2;
			f_s = s_m_r1; // assigning sign of multiplication result
			t_m_c_i =(shamt_rt>2*M_WIDTH+2) ? 'b0:(t_m_c_r1 >> shamt_rt);  
			t_m_m = t_m_m;


		 end
		 else if ((~g_m1)&&g_m2) begin
			shamt_rt = 'b0;
			t_e = e_c_r1;
			f_s = (t_m_m>t_m_c_r1)? s_m_r1:s_c_r1;
		    t_m_c_i = t_m_c_r1;
		    t_m_m = t_m_m;
		    
		  

		 end
		 else begin 
		  

			shamt_rt = e_c_r1-e_m_i2;
			t_e = e_c_r1;
			f_s = s_c_r1;
			t_m_m = (shamt_rt>M_WIDTH+1)? 'b0: (t_m_m >> shamt_rt);
			t_m_c_i = t_m_c_r1;
			
		 end



   
end

// input to third stage 
logic [3*M_WIDTH+2:0] t_m_c_r2; 
logic [3*M_WIDTH+2:0] t_m_m_r2; 
logic f_sr2;
logic [E_WIDTH:0] t_er2; 
logic gt_r2; // if e_m > e_c
logic et_r2; // if e_m == e_c
logic s_c_r2,s_m_r2; //sign of c and sign of multiplied significand

always @ (posedge clk) begin 

	t_m_c_r2   <= t_m_c_i;
	t_m_m_r2   <= t_m_m;
	f_sr2      <= f_s;
	t_er2      <= t_e;
	gt_r2	   <= g_m1;
	et_r2	   <= g_m2;
	s_m_r2	   <= s_m_r1;
	s_c_r2	   <= s_c_r1;  
	spec_r2     <= spec_r1;
	//mgt_r2     <= mgt;
	
end

logic [E_WIDTH:0] t_ei,t_ei_s,t_ei_d; 
logic g_s,r_s,s_s,l_s,k_s; // rounding signals for sum;
logic g_d,r_d,s_d,l_d,k_d; // rounding signals for difference 


    
   always @(*) begin
   t_m_s = t_m_c_r2 + t_m_m_r2;
   
     if (t_m_s[3*M_WIDTH +3]) begin // condition for overfloaw while addtion
         t_ei_s = t_er2+1;
         g_s = t_m_s[2*M_WIDTH +2];
         r_s= t_m_s[2*M_WIDTH +1];
         s_s= |t_m_s[2*M_WIDTH :0]; // declare this 
         l_s= t_m_s[2*M_WIDTH +3];
         k_s = g_s&(l_s|r_s|s_s);
         r_rs = t_m_s[3*M_WIDTH +2:2*M_WIDTH +3]; // rounding logic register 24 bit declare this 

     end
     else begin 
         t_ei_s = t_er2;
         g_s = t_m_s[2*M_WIDTH +1];
         r_s= t_m_s[2*M_WIDTH ];
         s_s= |t_m_s[2*M_WIDTH -1:0]; 
         l_s= t_m_s[2*M_WIDTH +2]; // l is pre guard bit
         k_s = g_s&(l_s|r_s|s_s);
         r_rs = t_m_s[3*M_WIDTH +1:2*M_WIDTH +2];

       end
   end
   
   // substraction 
   always @(*) begin
   shamt_l = 'b0; //flag = 'b0;
   t_ei_d = t_er2;;
   if(gt_r2&&(~et_r2) ) t_m_d = t_m_m_r2 - t_m_c_r2;
   else if((~gt_r2)&& et_r2) begin t_m_d = (t_m_m_r2>t_m_c_r2)? (t_m_m_r2 - t_m_c_r2): (t_m_c_r2 - t_m_m_r2); end  
   else t_m_d = t_m_c_r2 - t_m_m_r2;
 
    for (integer i = (3*M_WIDTH+2); i >= 0; i = i - 1) begin
                       if (t_m_d[i]) begin
                       break;
                       end
                       else shamt_l = shamt_l + 1;
                 end



    t_m_d = t_m_d << shamt_l;

    t_ei_d = (t_ei_d>shamt_l)? (t_ei_d - shamt_l): 0; //decreasing the value of exponent by no. of leading zeroes
    g_d = t_m_d[2*M_WIDTH +1];
    r_d= t_m_d[2*M_WIDTH];
    s_d= |t_m_d[2*M_WIDTH -1:0]; // declare this 
    l_d= t_m_d[2*M_WIDTH +2];
    k_d = g_d&(r_d|s_d|l_d);
    r_rd = t_m_d[3*M_WIDTH +1:2*M_WIDTH +2];
        

    end
    
    
   
   
   
   
   
 
   

   // input to fourth stage 
   logic k_r3;
   logic [M_WIDTH :0] rr_r3;
   logic [E_WIDTH:0] t_er3;
   logic f_sr3;
   
   logic k_dr3,k_sr3;
   logic [M_WIDTH :0] rr_sr3,rr_dr3;
   logic [E_WIDTH:0] t_ei_dr3,t_ei_sr3;
   logic s_m_r3,s_c_r3;
   

   always @ (posedge clk) begin 

	//t_m_c_r2   <= t_m_c_i;
	//t_m_m_r2   <= t_m_m;
	f_sr3      <= f_sr2;
	//t_er3      <= t_ei;
	t_ei_dr3   <= t_ei_d;
	t_ei_sr3   <= t_ei_s;
	s_m_r3     <= s_m_r2;
	s_c_r3     <= s_c_r2;
	
	
	//k_r3	   <= k;
	//rr_r3	   <= r_r;
	spec_r3     <= spec_r2;
	k_dr3      <= k_d;
	k_sr3      <= k_s;
	rr_sr3    <= r_rs;
	rr_dr3    <= r_rd;
	
end
(*DONT_TOUCH="YES"*)logic [M_WIDTH :0] rr_f;
(*DONT_TOUCH="YES"*)logic [E_WIDTH:0] t_ef;

	

always @(*)
begin

	 if (s_m_r3 ~^s_c_r3) begin 

	rr_r3 = rr_sr3;
	k_r3 = k_sr3;
	t_er3 = t_ei_sr3;

	end

	else begin 

	rr_r3 = rr_dr3;
	k_r3 = k_dr3;
	t_er3 = t_ei_dr3;



	end


    rr_f = rr_r3 + k_r3; 
    if (rr_f[M_WIDTH]) begin 
      f_m= rr_f[ M_WIDTH :1];
      t_ef = t_er3+1'b1;   
    end
     else begin t_ef = t_er3; f_m = rr_f[M_WIDTH-1:0]; end

    if (t_ef >OVER) begin out_n=(f_sr3)? N_INFI:P_INFI; end //overflow 
    //else if (t_ef>OVER)  out_n=(f_s)? N_INFI:P_INFI; //overflow condition
      
    else if(t_ef<'b1) begin 
      out_n=(f_sr3)?N_ZERO:P_ZERO; 
      end //underflow condition
    else begin
        //f_e =t_ef[E_WIDTH-1:0];
       out_n = {f_sr3,t_ef[E_WIDTH-1:0],f_m};
    end    
	
	  out_w = (spec_r3)? out_s: out_n;
	 
end




endmodule
	
		 

		 
