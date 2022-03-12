module Monostable_rise_only(

    input clk,
    input reset,
    input clear,
    input trigger_pulse,

    output handshake
    );

// Signal declaration
logic trigger_pulse_old;
logic handshake_reg;
logic clear_old;

// Body 
always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        trigger_pulse_old <= 1'b0;
        handshake_reg <= 1'b0;
        clear_old <= 1'b0;
    end else begin
        if (trigger_pulse & (!trigger_pulse_old))
            handshake_reg <= 1'b1;
        else if(clear & (!clear_old))
            handshake_reg <= 1'b0;
            
        trigger_pulse_old <= trigger_pulse;
        clear_old <= clear;
    end
end


// Combinational output
assign handshake = handshake_reg;

endmodule
