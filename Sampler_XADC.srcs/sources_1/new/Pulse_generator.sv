module Pulse_generator
(
    input  logic clk,
    input  logic reset, 
    input  logic [29:0] period,
    output logic pulse_out
);

// Signal declaration
logic clk_out;
logic clk_out_old;
logic pulse_out_reg;


Module_FrequencyDivider DIVIDER
(	
    .clk(clk),  
    .period(period), 
    .reset(reset),
    .clk_out(clk_out)
);


always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin
        pulse_out_reg <= 1'b0;
        clk_out_old   <= 1'b0;
    end else begin
        if((clk_out & (!clk_out_old) ) || ( (!clk_out) & clk_out_old))
            pulse_out_reg <= 1'b1;
        else if (pulse_out_reg)
            pulse_out_reg <= 1'b0;
    end
    clk_out_old <= clk_out;
end


// Combinational logic for output
assign pulse_out = pulse_out_reg;

endmodule
