module Buffers_reg_LATCH
#(parameter width = 12)
(
    input logic clk,                        // Clock
    input logic reset,                      // Reset
    input logic [width-1:0] wb_signal_in,   // Signal incoming 
    input logic update_flag,                // Update signal (posedge)
    output logic [width-1:0] output_latch   // Output of the buffer
);


// Signal declaration 

logic update_flag_old;
logic [width-1:0] output_latch_reg;

// Sequential logic circuit 

always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        output_latch_reg <= 0;
        update_flag_old <= 1'b0;
    end else begin 
        if(update_flag & (!update_flag_old)) begin
            output_latch_reg <= wb_signal_in;
        end
        update_flag_old <= update_flag;
    end
end







// Combinational logic for output 
assign output_latch = output_latch_reg;


endmodule
