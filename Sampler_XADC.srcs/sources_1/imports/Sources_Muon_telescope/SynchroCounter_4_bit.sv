module	Module_SynchroCounter_4_bit
(
input logic clk,
input logic clk_ref,
input logic reset,
input logic [3:0] limit,
output logic [3:0] out,
output logic carry
);

// Signal declaration 
logic [3:0]	out_reg;
logic carry_reg;
logic clk_ref_old;

// body 
always_ff @(posedge clk, posedge reset) begin
	if (reset) begin
		out_reg     <= 0;
		carry_reg   <= 0;
		clk_ref_old <= 0;
	end else if (!clk_ref_old & clk_ref) begin
		if (out_reg >= (limit - 4'b0001)) begin
			out_reg   <= 0;
			carry_reg <= 1;
		end else if (out_reg == 0) begin
			out_reg   <= 1;
			carry_reg <= 0;
		end else
			out_reg <= out_reg + 1;
	end
	clk_ref_old <= clk_ref;
end

// Combinatorial circuit for the output 
assign out = out_reg;
assign carry = carry_reg;

endmodule


