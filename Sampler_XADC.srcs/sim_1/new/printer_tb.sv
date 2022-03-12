module printer_tb();

// PARAMETERS 
parameter N_CH = 2;  // Number of channels (XADC)
parameter N_T = 32;  // Number of bits from TIME MEASURING
parameter N_P = 12;  // Number of bits for peak detection
parameter T = 20;


// #################################
// RESET  -> ACTIVE LOW DEFINITION
// #################################
logic  reset;               // Wire combinational 
logic clk;
logic tx;
logic [29:0] count_clk;

// Signal declaration 
logic [N_T-1:0] time_ms;                   // TIME ms
logic signed [N_P-1:0] A [N_CH-1:0];       // Sampled channels (wire bus array)
logic Visualize_pulse;


// *************************************
// TIME MEASUREMENT
// *************************************
Module_Time_Measurement Time_Measurement
(
    .clk(clk),
    .reset(reset),
    .out(time_ms)
);


// *****************************************
//      PULSE GENERATOR FOR PRINTER
// *****************************************
Pulse_generator PULSE_GEN_10Hz
(
    .clk(clk),
    .reset(reset), 
    .period(30'd1000),
    .pulse_out(Visualize_pulse)
);


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
    .reset(reset),
    .time_event(time_ms),        // Time of the event
    .A_peak_event(A),            // Peak values array of the event
    .DAQ_pulse(Visualize_pulse), // Output pulse to send data to memory or uart
    .tx(tx)
);



initial begin
     count_clk = 0;
     reset = 0;
     #(2*T);
     reset = 1;
     #(2*T);
     reset = 0;
end

always begin 
    clk = 1;
    count_clk = count_clk + 1;
    #(T/2);
    clk = 0;
    #(T/2);
end

initial begin
    A[0] = 0;
    A[1] = 0;
end

always begin 
    #(4*T);
    A[0] = A[0] - 1;
    A[1] = A[1] + 1;
end




endmodule
