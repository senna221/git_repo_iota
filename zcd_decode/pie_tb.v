
//`include pulse_interval_decode

module PIE_tb();

    reg tx_clk_1_5mhz;
    reg sclk_3mhz;
    reg rst_n;
    reg [4:0] count = 5'd0;
    reg pulse;
  
    wire [4:0] zero_clock_count;
    wire [4:0] one_clock_count;

    wire one_flag;
    wire zero_flag;
  

  pulse_interval_decode dut (.zcd_pulse(pulse),.sclk_3mhz(sclk_3mhz),.reset_n(rst_n),.zero_clock_count(zero_clock_count),.one_clock_count(one_clock_count),.zero_flag(zero_flag),.one_flag(one_flag));


// Clock generation
always #333 tx_clk_1_5mhz = ~tx_clk_1_5mhz;  // 1.5 MHz clock

//System clock  
always #165 sclk_3mhz = ~sclk_3mhz; //3 MHz clock
  


`define test_0101_new
  
`ifdef  test_0101_new
 integer seq_index = 0;
 integer counter = 0;
 logic stop_count; 
  
  // PIE encoded pulse stimulus logic
      always @(posedge tx_clk_1_5mhz) begin
        counter = counter + 1;
        
        case(seq_index)
        0: begin
          if(counter == 8) begin  // 3 cycles of "OFF" time
            counter = 0;
            pulse <= 1;
            #340 pulse <= 0;  // pulse is slightly longer than half the tx_clk_1_5mhz period
             seq_index = seq_index + 1;
          end else if(counter < 5) begin //5 consecutive cycles of "ON pulses"
            pulse <= 1;
            #340 pulse <= 0; 
        end else begin
            pulse <= 0;
        end
        end  
          
        1: begin
        if(counter == 13) begin  
            counter = 0;
            pulse <= 1;
            #340 pulse <= 0;  
             seq_index = seq_index + 1;
        end else if(counter < 10) begin //10 consecutive cycles of "ON pulses"
            pulse <= 1;
            #340 pulse <= 0; 
        end else begin
            pulse <= 0;
        end
        end
        
        2: begin
          if(counter == 8) begin
            counter = 0;
            pulse <= 1;
            #340 pulse <= 0;
             seq_index = seq_index + 1;
          end else if(counter < 5) begin //5 consecutive cycles of "ON pulses"
            pulse <= 1;
            #340 pulse <= 0; 
        end else begin
            pulse <= 0;
        end
        end
          
        3: begin
        if(counter == 13) begin
            counter = 0;
            pulse <= 1;
            #340 pulse <= 0;
             seq_index = 0;
        end else if(counter < 10) begin //10 consecutive cycles of "ON pulses"
            pulse <= 1;
            #340 pulse <= 0; 
        end else begin
            pulse <= 0;
        end
        end 
          
        endcase
    end

  
initial
begin
   
   $dumpfile ("PIE_tb.vcd"); $dumpvars(0, PIE_tb);
    tx_clk_1_5mhz = 0;
    sclk_3mhz  = 0;
    rst_n = 0;
    pulse = 0;
    count = 0;
    #666; // Assert reset for 1 clock cycle of 1.5 MHz
    rst_n = 1;
   #100000 $finish;
  
end

`endif
    

endmodule