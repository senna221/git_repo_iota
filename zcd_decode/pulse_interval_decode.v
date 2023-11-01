module seq_det0101 (pulse,in_valid,sclk_3mhz,reset_n,sequence_detected);
  input reg pulse;
  input reg in_valid;
  input sclk_3mhz;
  input reset_n;
  output reg sequence_detected;
  
  //State Encoding
  localparam S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11 ;
  
  reg [2:0] cur_state, next_state;
  
  
  //state register
  always @(posedge sclk_3mhz)
    if(!reset_n) begin 
      cur_state <= S0;
    end else if(in_valid) begin 
      cur_state <= next_state;
    end

  always @(*) begin 
    sequence_detected = 0;
    case(cur_state) 
      S0: if(pulse == 0) next_state = S1; else next_state = S0;
      S1: if(pulse == 1) next_state = S2; else next_state = S0;
      S2: if(pulse == 0) next_state = S3; else next_state = S0;
      S3: if(pulse == 1) begin 
        		next_state = S0;
                sequence_detected = 1;
          end else begin
                next_state = S0;
                sequence_detected = 0;
          end
      default: next_state = S0;
    endcase
  end 
  
endmodule


module pulse_interval_decode (zcd_pulse,sclk_3mhz,reset_n,zero_clock_count,one_clock_count,zero_flag,one_flag);
input reg zcd_pulse;
input sclk_3mhz;
input reset_n;
output wire [4:0] zero_clock_count;
output wire [4:0] one_clock_count;

output reg one_flag;
output reg zero_flag;

reg zcd_pulse_ff1;
reg zcd_pulse_sync;

reg [4:0] zero_clock_count_interm;
reg [4:0] pulse_hi_count_interm;

wire [4:0] zero_clock_count_store;
wire [4:0] one_clock_count_store;
  
wire [1:0] pulse_interval_decode;
wire decode_now;

 //Combinational, so it can happen in same cycle
  

  assign zero_clock_count_store = zero_clock_count_interm;
  assign one_clock_count_store = pulse_hi_count_interm;
  
  assign one_clock_count = one_clock_count_store >> 1;
  assign zero_clock_count = zero_clock_count_store >> 1;
  
  //Decode Flag goes high only when there are more than 1 low cycles(because Rx clk is 2*Tx clk)
  
  assign decode_now = (zero_clock_count_interm == 2);
  
  assign pulse_interval_decode = (pulse_hi_count_interm > 8 && pulse_hi_count_interm < 13 && decode_now) ? 2'd1:
    (pulse_hi_count_interm > 2 && pulse_hi_count_interm < 7 && decode_now) ? 2'd0: 2'dx;
  

always @(posedge sclk_3mhz) begin
    if(!reset_n) begin
        zero_clock_count_interm <= 5'd0;
        pulse_hi_count_interm <= 5'd0;
    end else begin
        //DFF(behav)
        {zcd_pulse_sync,zcd_pulse_ff1} <= {zcd_pulse_ff1,zcd_pulse};
      if(pulse_hi_count_interm > 18 && pulse_hi_count_interm < 24) begin
            one_flag <= 1'b1;
          end else begin
            one_flag <= 1'b0;
          end
        if(zcd_pulse_sync) begin
            pulse_hi_count_interm <= pulse_hi_count_interm + 1;
            zero_clock_count_interm <= 5'd0;
            zero_flag <= 1'b0;
        end else begin
            //one_flag <= 1'b0;
          if(zero_clock_count_interm == 2) begin
             pulse_hi_count_interm <= 5'd0;
             one_flag <= 0;
          end  
            zero_clock_count_interm <= zero_clock_count_interm + 1;
            zero_flag <= 1'b1;
        end    
    end 
end


reg seq_detect;
  
  seq_det0101 seq1 (.pulse(pulse_interval_decode[0]),.in_valid(decode_now),.sclk_3mhz(sclk_3mhz),.reset_n(reset_n),.sequence_detected(seq_detect));
    

  


endmodule