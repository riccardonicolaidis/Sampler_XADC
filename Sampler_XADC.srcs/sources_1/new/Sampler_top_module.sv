module Sampler_top_module
(
    input  logic clk,
    input  logic reset_high,
    input  logic [8:0] adc_a_p, adc_a_n,  // 6 analog channels
    input  logic vp_in, vn_in,
    output logic [3:0] led,
    output logic tx
);

// PARAMETERS 
parameter N_CH = 2;  // Number of channels (XADC)
parameter N_T = 32;  // Number of bits from TIME MEASURING
parameter N_P = 12;  // Number of bits for peak detection



// #################################
// RESET  -> ACTIVE LOW DEFINITION
// #################################
logic  reset_low;               // Wire combinational 
assign reset_low = ~reset_high; // Active low reset


// Signal declaration 
wire [N_T-1:0] time_ms;                   // TIME ms
wire  signed [N_P-1:0] A [N_CH-1:0];       // Sampled channels (wire bus array)
logic signed [N_P-1:0] A_unipolar [N_CH-1:0];       // Sampled channels (wire bus array)
wire A_pulse [N_CH-1:0];                  // Sample pulses   (wire array)
wire Visualize_pulse;


// *************************************
// TIME MEASUREMENT
// *************************************
Module_Time_Measurement Time_Measurement
(
    .clk(clk),
    .reset(reset_low),
    .out(time_ms)
);


// **************************************
//  XADC WRAPPING CIRCUIT 
// **************************************

XADC_module 
#(
    .N_CH(N_CH),   // Number of channels 
    .N_P(N_P)      // Number of bits 12
)
XADC_WRAPPING_CIRCUIT
(
    .clk(clk),         // clock 
    .reset(reset_low), // reset low 

    .adc_a_p(adc_a_p), // input analog  
    .adc_a_n(adc_a_n), // input analog
    .vp_in(vp_in),
    .vn_in(vn_in),
    .A(A),             // A Digitalized 12-bit OUT
    .A_pulse(A_pulse)  // A ready pulse 
);


// *****************************************
//      PULSE GENERATOR FOR PRINTER
// *****************************************
Pulse_generator PULSE_GEN_10Hz
(
    .clk(clk),
    .reset(reset_low), 
    .period(30'd10_000_000),
    .pulse_out(Visualize_pulse)
);

genvar i;
generate
    for(i=0; i<= (N_CH-1); i=i+1) begin
        assign A_unipolar[i] = { (!A[i][N_P-1]) , A[i][(N_P-2):0]};
    end
endgenerate 



Printer_uart
#(
    .N_T(N_T),
    .N_P(N_P),
    .N_CH(N_CH),
    .ADDR_WIDTH(8)
)
UART_DISPLAY
(
    .clk(clk),
    .reset(reset_low),
    .time_event(time_ms),        // Time of the event
    .A_peak_event(A_unipolar),            // Peak values array of the event
    .DAQ_pulse(Visualize_pulse), // Output pulse to send data to memory or uart
    .tx(tx),
    .control_state(led)
);






endmodule
