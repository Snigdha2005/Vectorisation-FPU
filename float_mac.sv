// ** This will perform the functionality of a*b+c ** // 
`timescale 1ns/1ps

module mac #(parameter E_WIDTH=5, parameter M_WIDTH=10, parameter I_WIDTH= M_WIDTH +E_WIDTH +1)
	( input [I_WIDTH-1:0] a,b,c,
	  output   [I_WIDTH-1:0]  out );

    // Defining special signals for special cases 
	 wire [I_WIDTH-1:0] NAN,P_INFI,N_INFI,P_ZERO,N_ZERO;
     assign NAN={1'b0,{E_WIDTH{1'b1}},1'b1,{(M_WIDTH-1){1'b0}}}; // NAN REPRESENTATIOIN IS CHOOSEN TO BE 1ST BIT OF MANTISSA IS 1
     assign P_INFI={1'b0,{E_WIDTH{1'b1}},{(M_WIDTH){1'b0}}}; //  (+)VE INFINITY
     assign N_INFI={1'b1,{E_WIDTH{1'b1}},{(M_WIDTH){1'b0}}}; // -VE INFINITY
     assign P_ZERO={I_WIDTH{1'b0}};
     assign N_ZERO = {1'b1,{I_WIDTH-1{1'b0}}};
     //--------------------------------------------------------------------------------------------------------------------

     // values for bias and overflow detection
     wire [E_WIDTH-1:0] e_comp;
     assign e_comp={E_WIDTH{1'b1}};
       
     wire [E_WIDTH-2:0] BIAS; // this is of size exponent bit size -1
     wire [E_WIDTH-1:0] OVER;
     assign BIAS = {E_WIDTH-1{1'b1}};
     assign OVER=BIAS<<1; // 2*bias is used for overflow condition
    // ------------------------------------------------------------------------------------------------------------------


   	wire s_a ,s_b,s_c; //sign
   	wire [E_WIDTH-1:0] e_a,e_b,e_c; //exponent
	wire [M_WIDTH-1:0] m_a,m_b,m_c; //matissa of input 
    wire [M_WIDTH:0] t_m_a,t_m_b; // temporary mantissa for multiplier
    //reg [(2*M_WIDTH)+1:0] t_m_c; //temp mantissa with hidden bit for summantion 
	reg [E_WIDTH-1:0] shamt_r; //shift amount by which smaller mantissa should be shifted it is taken large enough to store the shftamount 
	// shamt<= mantissa width it is approximately equal to log2(m_width)
    wire [(2*M_WIDTH)+1:0] t_m_p;

	//reg [(2*M_WIDTH)+2:0] t_m_s; //temp mantissa sum 49 bits for sp
	//reg [(2*M_WIDTH)+1:0] t_m_d; // temp mantissa diff 48 bits for sp
	reg [M_WIDTH-1:0] f_m;//final mantissa 
	reg [E_WIDTH-1:0] f_e; // final exponnt
	reg f_s; // final sign for multiplication and final sign
	wire s_m;
	reg [E_WIDTH-1:0] shamt_l;//shiftamount left 
	//reg s;// flag for special case 
	reg[I_WIDTH-1:0] out_s,out_n; //special case output and normal case output 
	//reg [M_WIDTH+1:0] r_m; //temporary round mantissa of 25 bits
	reg [E_WIDTH:0] t_e;// temporary exponent 
	reg [E_WIDTH:0] e_m;      // exponent of multiplication
	reg [3*M_WIDTH+2:0] t_m_c; // this is to make mantissa of c and accomodate right shift 
	reg [3*M_WIDTH+2:0] t_m_m; // this is to make the multiplied mantissa shift 
	reg [3*M_WIDTH+3:0] t_m_s;
	reg [3*M_WIDTH +2:0] t_m_d; // holding temp mantissa sum or difference 
	//wire m_s; // sign of multiplication

	reg k,l,g,r,s; // for rounding logic
	reg special_case;
	reg g_m1,g_m2; // intermedite temp registers to differenciate between cases 
	reg [M_WIDTH :0] r_r; // rounding register
	// -------------------values for the special cases---------------------------------------------------------;;


    wire isNaNA,isNaNB,isNaNC;
    wire isPInfA,isPInfB,isPInfC;
    wire isNInfA,isNInfB,isNInfC;
    wire isSubA,isSubB,isSubC;
    // assigninig the values to this signal 
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
    
    assign s_a = a[I_WIDTH-1];
    assign e_a = a[I_WIDTH-2:M_WIDTH];
    assign m_a = a[M_WIDTH-1:0];
    assign s_b = b[I_WIDTH-1];
    assign e_b = b[I_WIDTH-2:M_WIDTH];
    assign m_b = b[M_WIDTH-1:0];  
    assign s_c = c[I_WIDTH-1];
    assign e_c = c[I_WIDTH-2:M_WIDTH];
    assign m_c = c[M_WIDTH-1:0];  
                               
	// preappending 1 to mantissa and appending 0's to the lsb  to accomodate shift                                        
	 
	assign t_m_a = (isSubA)? ({(M_WIDTH+1){1'b0}}):{1'b1,m_a};
	assign t_m_b = (isSubB)? ({(M_WIDTH+1){1'b0}}):{1'b1,m_b};
	//assign t_m_a = {1'b1,m_a};
	//assign t_m_b = {1'b1,m_b};
	//multiplication 
	assign t_m_p = t_m_a*t_m_b; // calculating the mantissa product 
	
	assign s_m = s_a^s_b; // sign determination of mantissa
	

    // -----------------------special cases----------------------

   	always @(*)
	begin
		
		 if (isNaNA || isNaNB || isNaNC  ) begin special_case=1'b1;out_s=NAN; end
		 else if (isPInfA && isNInfB ) begin special_case=1'b1; out_s = NAN; end
		 else if (isNInfA && isPInfB) begin special_case =1'b1;out_s = NAN; end
		 else if (isPInfA && isPInfB && isNInfC) begin special_case =1'b1; out_s = NAN; end
		 else if (isNInfA && isNInfB && isNInfC) begin special_case =1'b1; out_s = NAN; end
		 else if (isPInfA || isPInfB ||isPInfC) begin special_case =1'b1; out_s = P_INFI ;end
		 else if (isNInfA||isNInfB||isNInfC) begin special_case =1'b1; out_s = N_INFI ; end
		 else if (isSubA || isSubB)  begin special_case = 1'b1; out_s = c; end  // multiplication of subnormal is 0 and 0+ c = c
		 /*else if (((e_a+e_b)-BIAS)>OVER) begin
			special_case =1'b1;
			out_s = (s_m)? N_INFI:P_INFI;
			
		 end*/
		 else  begin special_case =1'b0; out_s= 0;end
		 
	end

	always @(*)
	begin
	shamt_l = 0;

	t_m_c = (isSubC)? ({(3*M_WIDTH +3){1'b0}}):({1'b1,m_c,{(2*M_WIDTH+2){1'b0}}});
	//t_m_c = {1'b1,m_c,{(2*M_WIDTH+2){1'b0}}};
	     e_m = e_a+e_b;
	
		 e_m = ((e_m)>BIAS)? ((e_m)-BIAS):0;
		//e_m = (e_m) -BIAS;
		 
		  if (e_m>0 ) begin 
			if (t_m_p[2*M_WIDTH+1]) begin 
				e_m = e_m+1;
				//t_m_p = t_m_p>>1;
				t_m_m = {t_m_p,{(M_WIDTH+1){1'b0}}};
				//t_m_m = t_m_m >>1;

			
		     end
		 	 else begin t_m_m = {t_m_p[2*M_WIDTH:0],{(M_WIDTH +2){1'b0}}}; end
		 end
		 else begin  t_m_m =0; end// means underflow is occuring after multiplication

		 
		 shamt_r = (e_m>e_c) ? (e_m-e_c) : (e_c-e_m);
// now additon and subtraction logic starts here

// --------------------------now alligning the mantissas 

 
 // shifting of mantissas for allignment of the smaller exponent number 

		 if (e_m>e_c ) begin 
		    g_m1 =1'b1; g_m2=1'b0;// greater magnitude 1 
			t_e = e_m;
			f_s = s_m; // assigning sign of multiplication result
			t_m_c =(shamt_r>2*M_WIDTH+2) ? 0:(t_m_c >> shamt_r);  
			//t_m_s = (s_m == s_c)? (t_m_m+t_m_c): (t_m_m-t_m_c);
			//if(s_m==s_c) t_m_s =t_m_m +t_m_c;
			//else begin d7=1; t_m_d = t_m_m-t_m_c; end

		 end
		 else if (e_c>e_m) begin
		  g_m1 =1'b0;
		  g_m2 =1'b1; // greater magnitude
			t_e = e_c;
			f_s = s_c;
			t_m_m = (shamt_r>M_WIDTH+1)? 0: (t_m_m >> shamt_r);
			//(*DONT_TOUCH = "YES"*)t_m_s = (s_m == s_c)? (t_m_m+t_m_c): (t_m_c-t_m_m);
			//if(s_m==s_c) t_m_s =t_m_m +t_m_c;
			//else begin d8=1; t_m_d = t_m_c - t_m_m; end

		 end
		 else begin 
		  
		        g_m1 =1'b0;
		        g_m2 =1'b0;
			t_e = e_c;
			f_s = (t_m_m>t_m_c)? s_m:s_c;
	
		 end
		 // now I got sum and or difference 
		 if (s_m ==s_c) begin 
		  t_m_s = t_m_c + t_m_m;
			if (t_m_s[3*M_WIDTH +3]) begin // condition for overfloaw while addtion
				t_e = t_e+1;
				g = t_m_s[2*M_WIDTH +2];
				r= t_m_s[2*M_WIDTH +1];
				s= |t_m_s[2*M_WIDTH :0]; // declare this 
				l= t_m_s[2*M_WIDTH +3];
				r_r = t_m_s[3*M_WIDTH +2:2*M_WIDTH +3]; // rounding register 24 bit declare this 

			end
		    else begin 
				t_e = t_e;
				g = t_m_s[2*M_WIDTH +1];
				r= t_m_s[2*M_WIDTH ];
				s= |t_m_s[2*M_WIDTH -1:0]; // declare this 
				l= t_m_s[2*M_WIDTH +2]; // l is preguard bit
				r_r = t_m_s[3*M_WIDTH +1:2*M_WIDTH +2];

		      end
		  end
		 else begin 
			//leading zero detector 
			if(g_m1) t_m_d = t_m_m - t_m_c;
			else if(g_m2) t_m_d = t_m_c - t_m_m;
			else begin t_m_d = (t_m_m>t_m_c)? (t_m_m - t_m_c): (t_m_c - t_m_m); end
		  
			 for (integer i = (3*M_WIDTH+2); i >= 0; i = i - 1) begin
                                if (t_m_d[i]) begin
                                break;
                                end
                                else shamt_l = shamt_l + 1;
                          end
			 t_m_d =t_m_d << shamt_l;

			  t_e = (t_e>shamt_l)? (t_e - shamt_l): 0; //decreasing the value of exponent by no. of leading zeroes
			 	g = t_m_d[2*M_WIDTH +1];
				r= t_m_d[2*M_WIDTH];
				s= |t_m_d[2*M_WIDTH -1:0]; // declare this 
				l= t_m_d[2*M_WIDTH +2];
				r_r = t_m_d[3*M_WIDTH +1:2*M_WIDTH +2];

		     end

			// rounding logic 
			 k= g&(l|r|s); 
			 r_r = r_r+k; 
			 if (r_r[M_WIDTH]) begin 
			  f_m= r_r[ M_WIDTH :1];
			  t_e = t_e+1;   
			 end
			 else begin t_e = t_e; f_m = r_r[M_WIDTH-1:0]; end
			// f_m = (r_r[M_WIDTH])? r_r[ M_WIDTH :1]: r_r[M_WIDTH-1:0];
//------------------------------------------------------------------------------------------------------------//
	     if (e_m >OVER) out_n=(s_m)? N_INFI:P_INFI; //overflow due to multiplication
	     else if (t_e>OVER)  out_n=(f_s)? N_INFI:P_INFI; //overflow condition
	           
             else if(t_e<1) 
               out_n=(f_s)?N_ZERO:P_ZERO; //underflow condition
             else begin
		         f_e =t_e;
                out_n = {f_s,f_e,f_m};
	         end	  
	         
	end
	assign out = (special_case )? out_s:out_n;
	

endmodule
	
		 

