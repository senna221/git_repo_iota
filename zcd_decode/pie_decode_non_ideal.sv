// Code your design here
module seq_det0101 (pulse,in_valid,sclk_3mhz,reset_n,sequence_detected);
  input reg pulse;
  input reg in_valid;
  input sclk_3mhz;
  input reset_n;
  output reg sequence_detected;
  
  parameter [3:0] SEQ = 4'b0101; 
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

  
  //Sequence detector FSM
  always @(*) begin 
    sequence_detected = 0;
    case(cur_state) 
      S0: if(pulse == SEQ[3]) next_state = S1; else next_state = S0;
      S1: if(pulse == SEQ[2]) next_state = S2; else next_state = S0;
      S2: if(pulse == SEQ[1]) next_state = S3; else next_state = S0;
      S3: if(pulse == SEQ[0]) begin 
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



module pulse_interval_decode_non_ideal (zcd_pulse,sclk_3mhz,reset_n,zero_clock_count,one_clock_count,zero_detect,one_detect);
input reg zcd_pulse;
input sclk_3mhz;
input reset_n;
output wire [4:0] zero_clock_count;
output wire [4:0] one_clock_count;
output wire one_detect;
output wire zero_detect;


reg zcd_pulse_ff1;
reg zcd_pulse_ff2;
reg zcd_pulse_ff3;
reg zcd_pulse_sync;
wire zcd_pulse_toggle_sync;

reg [4:0] zero_clock_count_interm;
reg [4:0] pulse_hi_count_interm;

wire [1:0] pulse_interval_decode;
wire decode_now;
wire zcd_prev;

//Combinational, so it can happen in same cycle

  
//Decode goes high only when there are more than 1 low cycles(because Rx clk is 2*Tx clk)
assign decode_now = (zero_clock_count_interm == 2);
  
assign pulse_interval_decode = (pulse_hi_count_interm > 8 && pulse_hi_count_interm < 13 && decode_now) ? 2'd1:
    (pulse_hi_count_interm > 2 && pulse_hi_count_interm < 7 && decode_now) ? 2'd0: 2'dx;
  
assign zero_detect = (zero_clock_count_interm > 1);
assign one_detect = (pulse_hi_count_interm > 0 && ~zero_detect);
  

   `define toggle_sync 

`ifdef toggle_sync

  reg zcd_pulse_ff1_b,zcd_pulse_ff1_b2,zcd_pulse_ff2_b;
  reg zcd_pulse_ff1_b_interm, zcd_pulse_ff1_b2_interm;
  
  reg zcd_pulse_sync_b;
  
  
  ///Pos edge DFF Sync
  always @(posedge sclk_3mhz) begin
    if(!reset_n) begin
      zcd_pulse_ff1_b <= 0;
      zcd_pulse_ff1_b_interm <= 0;
    end else begin 
      {zcd_pulse_ff1_b,zcd_pulse_ff1_b_interm} <= {zcd_pulse_ff1_b_interm,zcd_pulse};
    end
  end
  
  //Negedge DFF Sync
  
  always @(negedge sclk_3mhz) begin
    if(!reset_n) begin
      zcd_pulse_ff1_b2 <= 0;
      zcd_pulse_ff1_b2_interm <= 0;
    end else begin 
      {zcd_pulse_ff1_b2,zcd_pulse_ff1_b2_interm} <= {zcd_pulse_ff1_b2_interm,zcd_pulse};
    end
  end
  
  reg zcd_pulse_sync_b_dly;
  
  //Dual Edge triggered Flop
  always @(posedge sclk_3mhz or negedge sclk_3mhz) begin
        zcd_pulse_sync_b <= zcd_pulse_ff1_b | zcd_pulse_ff1_b2;
        zcd_pulse_sync_b_dly <= zcd_pulse_sync_b;
    end
  
`endif
  

  reg [4:0] pulse_hi_count_interm_dly, zero_clock_count_interm_dly;
  wire overlap;
  
  assign overlap = (zero_clock_count_interm == zero_clock_count_interm_dly);
  
 
  reg [4:0] small_count, wrap_count; 
  wire [4:0] hi_pulse_stop_count;
  
  assign hi_pulse_stop_count = (overlap == 1 && (pulse_hi_count_interm < pulse_hi_count_interm_dly))? pulse_hi_count_interm_dly: 
    (overlap == 1)? hi_pulse_stop_count : 0;
  
  //Wrap Counter to deal with overlapping pulses
  always @(posedge sclk_3mhz) begin
    if(overlap) begin
      small_count <= small_count+1;
      if(small_count == 5'd1) begin 
        wrap_count <= wrap_count + 1;
        small_count <= 0;
      end
    end else begin
      small_count <= 0;
      wrap_count <= 0;
    end
  end
  
  
  
  always @(posedge sclk_3mhz) begin
    if(!reset_n) begin
        zero_clock_count_interm <= 5'd0;
        pulse_hi_count_interm <= 5'd0;
    end else begin
      pulse_hi_count_interm_dly <= pulse_hi_count_interm;
      zero_clock_count_interm_dly <= zero_clock_count_interm; 
        //Dual Flip Flop Sync(behav)
        //{zcd_pulse_sync,zcd_pulse_ff1} <= {zcd_pulse_ff1,zcd_pulse};
      if(zcd_pulse_sync_b) begin
        if(!(overlap)) begin
        	pulse_hi_count_interm <= pulse_hi_count_interm + 1;
        end else begin
          if(hi_pulse_stop_count == 0)
            	pulse_hi_count_interm <= wrap_count + 2;
          else 
              pulse_hi_count_interm <= wrap_count + hi_pulse_stop_count;
          end
        zero_clock_count_interm <= 5'd0;
        end else begin
        // Pulse Hi Counter Resets only if more than 1 zero pulse clock edges to accnt for Sync(Rx:tx = 2:1) 
          if(zero_clock_count_interm == 2) begin
             pulse_hi_count_interm <= 5'd0;
          end  
            zero_clock_count_interm <= zero_clock_count_interm + 1;
        end    
    end 
end


reg seq_detect;
  
  seq_det0101  #(.SEQ(4'd0101)) seq1 (.pulse(pulse_interval_decode[0]),.in_valid(decode_now),.sclk_3mhz(sclk_3mhz),.reset_n(reset_n),.sequence_detected(seq_detect));
    

  


endmodule