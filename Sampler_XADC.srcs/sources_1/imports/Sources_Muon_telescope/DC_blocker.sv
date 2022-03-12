module DC_Blocker 
#(
    parameter width = 12               // width of the input data bus 
)
(	
	input logic clk,                          // clock 
	input logic reset,                        // reset low 
	input logic sampl_freq,                   // update frequency
	input logic signed [width-1:0] data_in,   // data input 
	output logic signed [width-1:0] data_out  // data output 
);

localparam Size_log2 = 10;                        // 1024 samples
logic signed [width+Size_log2-1:0] temp_output;   // temporary output 
logic signed [width+Size_log2-1:0] final_output;  // final output 
logic [29:0] counter;                             // counter for counting samples
logic old_clk_slow;                               // old 100 clock value to be sensitive to posedge or negedge
logic w_clk_slow;                                 // update freq divided by 100 

Module_FrequencyDivider	DIVISORE_FREQUENZA_100Hz
(	
    .clk(sampl_freq),    
    .period(30'd50000),    
    .clk_out(w_clk_slow)
); 

always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        counter      <= 30'd0;
        final_output <= 0;
        temp_output  <= 0;
    end else begin
        if((!old_clk_slow & w_clk_slow)||(old_clk_slow & !w_clk_slow)) begin
            if(counter < 30'd1024) begin
              temp_output <= $signed(temp_output) + $signed({{Size_log2{data_in[width-1]}},data_in});
              counter     <= counter + 30'd1;
            end
            else begin
              counter      <= 30'd0;
              final_output <= temp_output;
              temp_output  <= 0;
            end
        end
    end
    old_clk_slow <= w_clk_slow;
end

// If you want to have an inverted output 
// assign data_out = final_output[width+Size_log2-1:Size_log2] + ~data_in + 14'd1;
assign data_out = $signed(data_in)  - $signed(final_output[width+Size_log2-1 -: width]);


endmodule