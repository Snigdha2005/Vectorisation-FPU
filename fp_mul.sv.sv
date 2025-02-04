`timescale 1ns / 1ps

/// here I_WIDTH -> INPUT WIDTH
// M_WIDTH => MANTISSA WIDTH 
// E_WIDTH => EXPONENT WIDTH 
module fp_mul#(parameter E_WIDTH=8, parameter M_WIDTH=23, parameter I_WIDTH = E_WIDTH + M_WIDTH+ 1 )( input [I_WIDTH-1:0] a,b,
         output reg  [I_WIDTH-1:0]  out );
        

        
        
         
        
        wire s_a ,s_b; //sign
        wire [E_WIDTH-1:0] e_a,e_b; //exponent
	    wire [M_WIDTH-1:0] m_a,m_b; //matissa of input 
        wire [M_WIDTH:0] t_m_a,t_m_b; //temp mantissa with hidden 1 bit 
        reg [(2*M_WIDTH)+1:0] t_m_p; // temp mantissa product
        reg [M_WIDTH-1:0] f_m;//final mantissa
        reg [E_WIDTH-1:0] f_e;// final exponent
	    reg [E_WIDTH:0] t_e;// temporary exponent OF 
        wire f_s; // final sign
	    reg [I_WIDTH-1:0] out_s,out_n; //output in special cases and normal case
	    reg s; //flag for special case detection
		reg [M_WIDTH+1:0] r_m; //temporary round mantissa of 25 bits
	    
	    
	    
	    
	    //reg [E_WIDTH-1:0] a;
// extracting sign mantissa and exponent
        assign s_a = a[I_WIDTH-1];
        assign e_a = a[I_WIDTH-2:M_WIDTH];
        assign m_a = a[M_WIDTH-1:0];
        assign s_b = b[I_WIDTH-1];
        assign e_b = b[I_WIDTH-2:M_WIDTH];
        assign m_b = b[M_WIDTH-1:0];
//determining sign
	    assign f_s = s_a^s_b;
// preappending hidden bit 1 in the mantissa for shifting
        assign t_m_a = {1'b1,m_a};
	    assign t_m_b = {1'b1,m_b};
	    
   // variables for compare of infinity and zero input 
   	    wire [E_WIDTH-1:0] e_comp;
        assign e_comp={E_WIDTH{1'b1}};
     
     // variable for bias 
        wire [E_WIDTH-2:0] BIAS; // this is of size exponent bit size -1
        wire [E_WIDTH-1:0] OVER;
        assign BIAS = {E_WIDTH-1{1'b1}};
        assign OVER=BIAS<<1; // 2*bias is used for overflow condition
     
     // variable for overflow detection
     
     
    
     // VARIABLES FOR COMPARE AND SPECIAL CASES 
        wire [I_WIDTH-1:0] NAN,INFINITY,ZERO;
        assign NAN={1'b0,{E_WIDTH{1'b1}},1'b1,{(M_WIDTH-1){1'b0}}}; // NAN REPRESENTATIOIN IS CHOOSEN TO BE 1ST BIT OF MANTISSA IS 1
        assign INFINITY={f_s,{E_WIDTH{1'b1}},{(M_WIDTH){1'b0}}}; // IT WILL GENERATE (+)VE AND (-)VE INFINITY DEPENDING UPON SIGN
        assign ZERO={I_WIDTH{1'b0}};
     

       
     
	
	// for special inputs in IEEE754
	always@(*)
	begin 
	        if ((e_a == e_comp) && (e_b==e_comp)) begin
			  s=1'b1;
		 	  if((m_a!=0)|(m_b!=0)) out_s=NAN;//checking for NaN input 
			  else begin
                  out_s= (f_s)? NAN:INFINITY;
			  end
             end

            else if ((e_a == e_comp) && (e_b ==0)) begin
			   s=1'b1;
			   out_s=NAN; //output is NaN
		    end
                 //output is zero  
		    else if ((e_a == 0) && (e_b ==e_comp)) begin
			   s=1'b1;
			   out_s=NAN; //output is NaN
      		end
		   else if ((e_a ==0) && (e_b ==0)) begin
               s=1'b1;
			   out_s =ZERO;
           end 
		   else if ((e_a == e_comp) || (e_b ==e_comp)) begin
			 s=1'b1;
			 if(e_a==e_comp) begin 
			 out_s=(m_a!=0)?NAN:INFINITY;
			 end
			 else begin
		 	 out_s = (m_b !=0)?NAN:INFINITY;
			 end
		   end
		   else if((e_a==0)||(e_b==0)) begin
		        s=1'b1;
			   out_s=ZERO; //output is zero 
		   end
		   else begin 
			   s=1'b0;
			   out_s=ZERO;
		   end
    end
    	
    	
	// for the Normal Input 
	always@(*)
	begin  
		t_e =  e_a+e_b;
		t_m_p = t_m_a*t_m_b;
		if (t_m_p[2*M_WIDTH+1])
		begin
			//t_m_p=t_m_p>>1; this will require a aditional resource 
		//	f_m = t_m_p[2*M_WIDTH:M_WIDTH+1]; //shifting the temp mantissa right by one bit and then selecting 23 MSBs 

			t_e= t_e+1'b1; //exponent is increased by 1 as mantissa is shifted right by one bit 
			//end
			//else
			//f_m=t_m_p[2*M_WIDTH-1:M_WIDTH];
			//rounding logic
			if(t_m_p[M_WIDTH]==1'b1) // checking if guard bit is 1
			begin
				if(t_m_p[M_WIDTH-1:0]==0) //round to even 
				begin 
					if(t_m_p[M_WIDTH+1]==0) f_m=t_m_p[2*M_WIDTH:M_WIDTH+1]; //checking previous bit to guard bit 
					else 
					begin
						r_m = t_m_p[2*M_WIDTH+1:M_WIDTH+1] + 1; //for making round to even 
						if(r_m[M_WIDTH+1]) 
						begin
							f_m=r_m[M_WIDTH:1];
							t_e=t_e+1; //again normalizing the result in case of overflow 
						end
						else f_m=r_m[M_WIDTH-1:0];
					
					end

				end
			
				else //round up 
				begin
					r_m = t_m_p[2*M_WIDTH+1:M_WIDTH+1] + 1;
					if(r_m[M_WIDTH+1]) 
						begin
							f_m=r_m[M_WIDTH:1];
							t_e=t_e+1; //again normalizing the result in case of overflow 
						end
						else f_m=r_m[M_WIDTH-1:0];

				end
			end
			else f_m = t_m_p[2*M_WIDTH:M_WIDTH+1]; // guard bit zero then simply truncating the bits
		end
        // condition for no overflow while multiplication
		else
		begin 
			//f_m= t_m_p[2*M_WIDTH-1:M_WIDTH]; //selecting higher Mantisaa bits
			if(t_m_p[M_WIDTH-1]==1'b1) // checking if guard bit is 1. now this is guard bit 
			begin
				if(t_m_p[M_WIDTH-2:0]==0) //round to even 
				begin 
					if(t_m_p[M_WIDTH]==0) f_m=t_m_p[2*M_WIDTH-1:M_WIDTH]; //checking previous bit to guard bit 
					else 
					begin
						r_m = t_m_p[2*M_WIDTH:M_WIDTH] + 1; //for making round to even 
						if(r_m[M_WIDTH+1]) 
						begin
							f_m=r_m[M_WIDTH:1];
							t_e=t_e+1; //again normalizing the result in case of overflow 
						end
						else f_m=r_m[M_WIDTH-1:0];
					
					end

				end
				else //round up 
				begin
					r_m = t_m_p[2*M_WIDTH:M_WIDTH] + 1;
					if(r_m[M_WIDTH+1]) 
						begin
							f_m=r_m[M_WIDTH:1];
							t_e=t_e+1; //again normalizing the result in case of overflow 
						end
						else f_m=r_m[M_WIDTH-1:0];

				end
			end
			else f_m = t_m_p[2*M_WIDTH-1:M_WIDTH]; // guard bit zero then simply truncating the bits selecting 23 bit msb
			
			
		end
		//t_e=t_e-BIAS; //substractiong extra bias which got added due to addition of exponent
		if (t_e<=BIAS) out_n=ZERO; // If t_e will be less than bia then we will get -ve number which will be underflow condition
		else if ((t_e-BIAS)>OVER) out_n = INFINITY;
		else begin
		
		  f_e=t_e-BIAS;
		  out_n={f_s,f_e,f_m};
		
		end
		



	end
	// checking for expont overflow and underflow 
	always @(*)
	begin 
	
	   out=(s)? out_s:out_n;
	
	end
endmodule


