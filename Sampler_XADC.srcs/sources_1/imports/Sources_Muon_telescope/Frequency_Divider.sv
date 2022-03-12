module	Module_FrequencyDivider
(	
input  logic        clk,  
input  logic [29:0] period, 
input  logic        reset,   
output logic        clk_out
);

// Signal declaration 
logic [29:0] counter;
logic clk_out_reg;

// body
always_ff @(posedge clk, posedge reset) begin
	if(reset) begin 
		clk_out_reg <= 1'b0;
		counter     <= 30'd0;
	end else if (counter >= (period - 30'd1)) begin
		counter <= 30'd0;
		clk_out_reg <= ~clk_out_reg;
	end else
		counter <= counter + 30'd1;
end

// Combinatorial part for the output 
assign clk_out = clk_out_reg;
endmodule
