module adc_demux
#(
parameter N_P = 12
)
(
    input logic clk,
    input logic reset, 
    input logic [4:0] channel,
    input logic [15:0] adc_data,
    input logic rdy,
    input logic [4:0] identifier_ch,

    output logic [N_P-1:0] adc_data_demux,
    output logic data_flag
);

// Signal declaration 
logic [N_P-1:0] adc_data_demux_reg; // Register containing the demuxed data
logic data_flag_reg;                // Update frequency reg
logic rdy_old;                      // Old value of rdy to be sensitive to posedges

// Finite State Machine 
// Body 
always_ff @( posedge clk, posedge reset) begin
    if (reset) begin
        adc_data_demux_reg <= 0;
        data_flag_reg      <= 1'b0;
        rdy_old            <= 1'b0;
    end else if(data_flag) begin
        data_flag_reg <= 1'b0;
    end else if(!rdy_old && rdy) begin
        if(channel == identifier_ch) begin
            adc_data_demux_reg <= adc_data[15 -: N_P];
            data_flag_reg      <= 1'b1;
        end
    end
    rdy_old <= rdy;
end

// Combinational logic for output
assign data_flag      = data_flag_reg;
assign adc_data_demux = adc_data_demux_reg;

endmodule
