`timescale 1ns / 1ps
module fp_add_sub #(parameter E_WIDTH=8, parameter M_WIDTH=23, parameter I_WIDTH= M_WIDTH +E_WIDTH +1)( input [I_WIDTH-1:0] a,b,
         output reg  [I_WIDTH-1:0]  out );
         
   // parameter I_WIDTH= M_WIDTH +E_WIDTH +1;

   	wire s_a ,s_b; //sign
   	wire [E_WIDTH-1:0] e_a,e_b; //exponent
	wire [M_WIDTH-1:0] m_a,m_b; //matissa of input 
    reg [(2*M_WIDTH)+1:0] t_m_a,t_m_b; //temp mantissa with hidden 1 bit 
	reg [E_WIDTH-1:0] shamt; //shift amount by which smaller mantissa should be shifted it is taken large enough to store the shftamount 
	// shamt<= mantissa width it is approximately equal to log2(m_width)
	
	//reg [(2*M_WIDTH)+1:0] s_m_a,s_m_b; //shifted mantissa bit 
	reg [(2*M_WIDTH)+2:0] t_m_s; //temp mantissa sum 49 bits for sp
	reg [(2*M_WIDTH)+1:0] t_m_d; // temp mantissa diff 48 bits for sp
	reg [M_WIDTH-1:0] f_m;//final mantissa 
	reg [E_WIDTH-1:0] f_e; // final exponnt
	reg f_s; // final sign
	reg [E_WIDTH-1:0] shamt_l;//shiftamount left 
	reg s;// flag for special case 
	reg[I_WIDTH-1:0] out_s,out_n; //special case output and normal case output 
	reg [M_WIDTH+1:0] r_m; //temporary round mantissa of 25 bits
	reg [E_WIDTH:0] t_e;// temporary exponent 
	


         
         
	


// extracting sign mantissa and exponent
    assign s_a = a[I_WIDTH-1];
    assign e_a = a[I_WIDTH-2:M_WIDTH];
    assign m_a = a[M_WIDTH-1:0];
    assign s_b = b[I_WIDTH-1];
    assign e_b = b[I_WIDTH-2:M_WIDTH];
    assign m_b = b[M_WIDTH-1:0];

// preappending hidden bit 1 in the mantissa for shifting

	
	//compare variable to compare for special cases
     wire [E_WIDTH-1:0] e_comp;
     assign e_comp={E_WIDTH{1'b1}};
     
     // variable for bias 
     wire [E_WIDTH-2:0] BIAS; // this is of size exponent bit size -1
     wire [E_WIDTH-1:0] OVER;
     assign BIAS = {E_WIDTH-1{1'b1}};
     assign OVER=BIAS<<1; // 2*bias is used for overflow condition
	
	// special case signals
	 wire [I_WIDTH-1:0] NAN,P_INFI,N_INFI,P_ZERO,N_ZERO;
     assign NAN={1'b0,{E_WIDTH{1'b1}},1'b1,{(M_WIDTH-1){1'b0}}}; // NAN REPRESENTATIOIN IS CHOOSEN TO BE 1ST BIT OF MANTISSA IS 1
     assign P_INFI={1'b0,{E_WIDTH{1'b1}},{(M_WIDTH){1'b0}}}; //  (+)VE INFINITY
     assign N_INFI={1'b1,{E_WIDTH{1'b1}},{(M_WIDTH){1'b0}}}; // -VE INFINITY
     assign P_ZERO={I_WIDTH{1'b0}};
     assign N_ZERO = {1'b1,{I_WIDTH-1{1'b0}}};
     

	always @(*)
	begin
		
		 if ((e_a == e_comp) && (e_b==e_comp)) begin 
		    s=1'b1;
		 	if((m_a!=0)||(m_b!=0)) out_s=NAN;//checking for NaN input 
			else begin
		 	out_s = (s_a!=s_b) ? NAN:((s_a)?N_INFI:P_INFI); // if sign of both are not same than NAN otherwise +or - infinity depends upon sign
			end
		 end
	 	else if  ((e_a == e_comp) || (e_b==e_comp)) begin  
	 	    s=1'b1;
			if(e_a==e_comp) begin 
			out_s=(m_a!=0)? NAN: ((s_a)?N_INFI:P_INFI);
			end
			else begin
		 	out_s = (m_b !=0)? NAN :((s_b)?N_INFI:P_INFI);
			end
		end
		else if ((e_a == 0) && (e_b ==0)) begin 
		s=1'b1;
		out_s = (s_a&s_b)?N_ZERO:P_ZERO;
		end

		else if ((e_a == 0) || (e_b ==0)) begin 
		    s=1'b1;
			out_s = (e_a==0)? b:a;
		end
		else 
		 begin 
		  s=1'b0;
		  out_s=P_ZERO;
		 end
	end
		 
		 
		
//---------------------------------FOR NORMAL CASES---------------------------------------------------------//
 always@(*)
 begin
    shamt_l=0;
	t_m_a = {1'b1,m_a,{(M_WIDTH+1){1'b0}}};
	t_m_b = {1'b1,m_b,{(M_WIDTH+1){1'b0}}};
	if (e_a > e_b)
	 begin 
			shamt = e_a - e_b;
			//s_m_b= (shamt >8'd23)? 23'd0:t_m_b>>shamt;
			if (shamt>M_WIDTH+1)  out_n=a;
			   
			else 
             begin
                 
			     t_e = e_a;
			     f_s = s_a;
                 t_m_b= t_m_b>>shamt;

	 if(s_a == s_b)
	 begin
		       		 t_m_s = t_m_a+t_m_b;
                     // rounding logic 
                        if(t_m_s[2*M_WIDTH+2]) //checking for overflow
                        begin 
			    t_e=t_e+1;
                            if(t_m_s[M_WIDTH+1]) begin //checking for guard bit 
				if(t_m_s[M_WIDTH:0]==0) begin
					if (t_m_s[M_WIDTH+2]) f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2]+1'b1;
					else f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2];

				end
			        else f_m =  t_m_s[2*M_WIDTH+1:M_WIDTH+2]+1'b1;
			   end
			   else f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2]; //  truncating the bits if GB is zero


			  end  
			 else begin 
		
                            if(t_m_s[M_WIDTH]) begin //checking for guard bit 
				if(t_m_s[M_WIDTH-1:0]==0) begin
					if (t_m_s[M_WIDTH+1])begin
							r_m = t_m_s[2*M_WIDTH+1:M_WIDTH+1]+1'b1;
							if(r_m[M_WIDTH+1])begin
								f_m= r_m[M_WIDTH:1];
								t_e= t_e+1'b1;
							end
							else f_m = r_m[M_WIDTH-1:0];
							 
					end
					else f_m = t_m_s[2*M_WIDTH:M_WIDTH+1];

				end
			        else begin //round up
							r_m = t_m_s[2*M_WIDTH+1:M_WIDTH+1]+1'b1;
							if(r_m[M_WIDTH+1])begin
								f_m= r_m[M_WIDTH:1];
								t_e= t_e+1'b1;
							end
							else f_m = r_m[M_WIDTH-1:0];



				end


			    end
			    else f_m =  t_m_s[2*M_WIDTH:M_WIDTH+1];  // truncating the bit if GB is 0
				



			    end
             end
//--------------------------------------------------------------------------------------------------------------------------------------------------


                     

	     else begin 
			 t_m_d = t_m_a - t_m_b;
				//leading zero detector 
			 for (int i = (2*M_WIDTH+1); i >= 0; i = i - 1) begin
                                if (t_m_d[i]) begin
                                break;
                                end
                                else shamt_l = shamt_l + 1;
                          end
			t_m_d =t_m_d << shamt_l;
			t_e = (t_e>shamt_l)? (t_e - shamt_l): 0; //decreasing the value of exponent by no. of leading zeroes			
                     
                    
                
			
                        // rounding logic for difference
                        if(t_m_d[M_WIDTH]) 
                        begin 
                            if(t_m_d[M_WIDTH-1:0]==0) begin // round to even 
                            if(t_m_d[M_WIDTH+1])  f_m = t_m_d[2*M_WIDTH:M_WIDTH+1]+1'b1;
                            else f_m = t_m_d[2*M_WIDTH:M_WIDTH+1];
			    end
			else f_m =  t_m_d[2*M_WIDTH:M_WIDTH+1]+1'b1;

                        end
                        else f_m =  t_m_d[2*M_WIDTH:M_WIDTH+1];  // truncating the bit if GB is 0

               end
//------------------------------------------------------------------------------------------------
		
		
		// arranging output and checking for overflow 
		      if (t_e>OVER) 
	          out_n=(f_s)? N_INFI:P_INFI; //overflow condition
              else if(t_e<1) 
              out_n=(f_s)?N_ZERO:P_ZERO; //underflow condition
              else begin
		f_e =t_e;
                out_n = {f_s,f_e,f_m};
	      end
              
          end
		end
		
	 	else if (e_b > e_a) 
	 	begin
			shamt = e_b- e_a;
		    
			if(shamt>M_WIDTH+1)  out_n=b;
			else begin 
			
			 //s_m_a= t_m_a>>shamt;
			 
			 t_e = e_b;
			 f_s = s_b;
             t_m_a = t_m_a>>shamt;

if(s_a == s_b)
	 begin
		       		 t_m_s = t_m_a+t_m_b;
                     // rounding logic 
                        if(t_m_s[2*M_WIDTH+2]) //checking for overflow
                        begin 
			    t_e=t_e+1;
                            if(t_m_s[M_WIDTH+1]) begin //checking for guard bit 
				if(t_m_s[M_WIDTH:0]==0) begin
					if (t_m_s[M_WIDTH+2]) f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2]+1'b1;
					else f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2];

				end
			        else f_m =  t_m_s[2*M_WIDTH+1:M_WIDTH+2]+1'b1;
			   end
			   else f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2]; //  truncating the bits if GB is zero


			  end  
			 else begin 
		
                            if(t_m_s[M_WIDTH]) begin //checking for guard bit 
				if(t_m_s[M_WIDTH-1:0]==0) begin
					if (t_m_s[M_WIDTH+1])begin
							r_m = t_m_s[2*M_WIDTH+1:M_WIDTH+1]+1'b1;
							if(r_m[M_WIDTH+1])begin
								f_m= r_m[M_WIDTH:1];
								t_e= t_e+1'b1;
							end
							else f_m = r_m[M_WIDTH-1:0];
							 
					end
					else f_m = t_m_s[2*M_WIDTH:M_WIDTH+1];

				end
			        else begin //round up
							r_m = t_m_s[2*M_WIDTH+1:M_WIDTH+1]+1'b1;
							if(r_m[M_WIDTH+1])begin
								f_m= r_m[M_WIDTH:1];
								t_e= t_e+1'b1;
							end
							else f_m = r_m[M_WIDTH-1:0];



				end


			    end
			    else f_m =  t_m_s[2*M_WIDTH:M_WIDTH+1];  // truncating the bit if GB is 0
				



			    end
             end
//--------------------------------------------------------------------------------------------------------------------------------------------------


                     

	     else begin 
			 t_m_d = t_m_b - t_m_a;
				//leading zero detector 
			 for (int i = (2*M_WIDTH+1); i >= 0; i = i - 1) begin
                                if (t_m_d[i]) begin
                                break;
                                end
                                else shamt_l = shamt_l + 1;
                          end
			t_m_d =t_m_d << shamt_l;
			t_e = (t_e>shamt_l)? (t_e - shamt_l): 0; //decreasing the value of exponent by no. of leading zeroes			
                     
                    
                
			
                        // rounding logic for difference
                        if(t_m_d[M_WIDTH]) 
                        begin 
                            if(t_m_d[M_WIDTH-1:0]==0) begin // round to even 
                            if(t_m_d[M_WIDTH+1]) f_m = t_m_d[2*M_WIDTH:M_WIDTH+1]+1'b1;
                            else f_m = t_m_d[2*M_WIDTH:M_WIDTH+1];
			    end
			else f_m =  t_m_d[2*M_WIDTH:M_WIDTH+1]+1'b1;

                        end
                        else f_m =  t_m_d[2*M_WIDTH:M_WIDTH+1];  // truncating the bit if GB is 0

               end
//------------------------------------------------------------------------------------------------
           
           	if (t_e>OVER) 
	         out_n=(f_s)? N_INFI:P_INFI; //overflow condition
            else if(t_e<1) 
               out_n=(f_s)?N_ZERO:P_ZERO; //underflow condition
              else begin
		f_e =t_e;
                out_n = {f_s,f_e,f_m};
	      end
      
         end


	 end
	else begin
			t_e = e_a;
			f_s = (t_m_a>t_m_b)? s_a:s_b;
if(s_a == s_b)
	 begin
		       		 t_m_s = t_m_a+t_m_b;
                     // rounding logic 
                        if(t_m_s[2*M_WIDTH+2]) //checking for overflow
                        begin 
			    t_e=t_e+1;
                            if(t_m_s[M_WIDTH+1]) begin //checking for guard bit 
				if(t_m_s[M_WIDTH:0]==0) begin
					if (t_m_s[M_WIDTH+2]) f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2]+1'b1;
					else f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2];

				end
			        else f_m =  t_m_s[2*M_WIDTH+1:M_WIDTH+2]+1'b1;
			   end
			   else f_m = t_m_s[2*M_WIDTH+1:M_WIDTH+2]; //  truncating the bits if GB is zero


			   end 
			 else begin 
		
                            if(t_m_s[M_WIDTH]) begin //checking for guard bit 
				if(t_m_s[M_WIDTH-1:0]==0) begin
					if (t_m_s[M_WIDTH+1])begin
							r_m = t_m_s[2*M_WIDTH+1:M_WIDTH+1]+1'b1;
							if(r_m[M_WIDTH+1])begin
								f_m= r_m[M_WIDTH:1];
								t_e= t_e+1'b1;
							end
							else f_m = r_m[M_WIDTH-1:0];
							 
					end
					else f_m = t_m_s[2*M_WIDTH:M_WIDTH+1];

				end
			        else begin //round up
							r_m = t_m_s[2*M_WIDTH+1:M_WIDTH+1]+1'b1;
							if(r_m[M_WIDTH+1])begin
								f_m= r_m[M_WIDTH:1];
								t_e= t_e+1'b1;
							end
							else f_m = r_m[M_WIDTH-1:0];



				end


			    end
			    else f_m =  t_m_s[2*M_WIDTH:M_WIDTH+1];  // truncating the bit if GB is 0
				



			    end
             end
//--------------------------------------------------------------------------------------------------------------------------------------------------


                     

	     else begin 
			 t_m_d = (t_m_a>t_m_b)? (t_m_a - t_m_b) :(t_m_b -t_m_a);
				//leading zero detector 
			 for (int i = (2*M_WIDTH+1); i >= 0; i = i - 1) begin
                                if (t_m_d[i]) begin
                                break;
                                end
                                else shamt_l = shamt_l + 1;
                          end
			t_m_d =t_m_d << shamt_l;
			t_e = (t_e>shamt_l)? (t_e - shamt_l): 0; //decreasing the value of exponent by no. of leading zeroes			
                     
                    
                
			
                        // rounding logic for difference
                        if(t_m_d[M_WIDTH]) 
                        begin 
                            if(t_m_d[M_WIDTH-1:0]==0) begin // round to even 
                            if(t_m_d[M_WIDTH+1]) f_m = t_m_d[2*M_WIDTH:M_WIDTH+1]+1'b1;
                            else f_m = t_m_d[2*M_WIDTH:M_WIDTH+1];
			    end
			else f_m =  t_m_d[2*M_WIDTH:M_WIDTH+1]+1'b1;

                        end
                        else f_m =  t_m_d[2*M_WIDTH:M_WIDTH+1];  // truncating the bit if GB is 0

               end
//------------------------------------------------------------------------------------------------
	 		 if (t_e>OVER) 
	         out_n=(f_s)? N_INFI:P_INFI; //overflow condition
            else if(t_e<1) 
               out_n=(f_s)?N_ZERO:P_ZERO; //underflow condition
           else begin
		f_e =t_e;
                out_n = {f_s,f_e,f_m};
	      end
       
	
	 end
	 //  arranging result and checking for overflow 

	end
	

	always@(*)
	begin 
        out=s?out_s:out_n;
	end

endmodule

