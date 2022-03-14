module printer_tb();

// PARAMETERS 
parameter N_CH = 4;  // Number of channels (XADC)
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

logic [3:0] led;



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


assign A[0] = 12'd10;
assign A[1] = 12'd100;
assign A[2] = 12'd3000;
assign A[3] = 12'd6000;




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
    .tx(tx),
    .control_state(led)
);



initial begin
     count_clk = 0;
     Visualize_pulse = 0;
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

always begin 
Visualize_pulse = 0;
#(20*T);
Visualize_pulse = 1;
#(1*T);
Visualize_pulse = 0;
#(20000*T);
end




endmodule
