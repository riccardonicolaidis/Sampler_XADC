module Printer_uart
#(
    parameter N_T = 32,
              N_P = 12,
              N_A = 20,
              N_CH = 6,
              ADDR_WIDTH = 4
)
(
    input logic clk,
    input logic reset,
    input logic [N_T-1:0] time_event,                       // Time of the event
    input logic signed [N_P-1:0] A_peak_event [N_CH-1:0],   // Peak values array of the event
    input logic DAQ_pulse,                                  // Output pulse to send data to memory or uart
    output logic tx,
    output logic [3:0] control_state
);

// Registri che servono per le conversioni da binario a BCD
// Parametri
localparam N_BIT_IN_PEAK    = N_P; 
localparam N_DIGIT_OUT_PEAK = 5  ;


// Signal declarations
// Important ASCII CODES
wire  [7:0] wb_SPACE_ASCII;
wire  [7:0] wb_DOT_ASCII;
wire  [7:0] wb_NEW_LINE;
assign wb_SPACE_ASCII = 8'd32;
assign wb_DOT_ASCII   = 8'd46;
assign wb_NEW_LINE    = 8'd10;

// Max values of counters

/*
wire [7:0] max_counter_channel;
wire [7:0] max_counter_digit;

assign max_counter_channel = 8'd1;
assign max_counter_digit   = 8'd4;
*/

// Regs necessay for the monitoring of the FIFO buffers
wire empty_fifo;

// Wires to connect the output of fifo buffers
wire [N_T-1:0] time_event_fifo;                // Time of the event
wire [N_P-1:0] A_peak_event_fifo [N_CH-1:0];   // Peak values array of the event

// Segnali che pilotano il fifo_controller 
logic read_pulse_reg;               // reg

// Contatore per inviare i byte correttamente
logic [7:0] counter_digit;      // Conta le cifre reg
logic [7:0] counter_channel;    // Conta i canali reg

// Registro che contiene i dati da inviare 1 BYTE
logic [7:0]     Printer;         // Registro reg
logic           Print_pulse;     // Segnale  reg

// Registri
logic start_conversion_peak;  // reg
wire  BCD_peak_ready;  // wire
logic [N_P-1:0] Converter_peak;  // reg
wire  [4*(N_DIGIT_OUT_PEAK)-1:0] BCD_peak; // wire bus
logic [4*(N_DIGIT_OUT_PEAK)-1:0] A_peak_event_BCD [N_CH-1:0];   // Peak values array of the event BCD

logic [N_T-1:0] time_event_reg;                // REG MODIFICABILE
logic [N_P-1:0] A_peak_event_reg [N_CH-1:0];   // REG MODIFICABILE 


// Stato di controllo 
logic [3:0] CONTROL_STATE;



// FIFO TIME DATA
fifo_generator_time FIFO_TIME 
(
  .clk(clk),              // input wire clk
  .srst(reset),           // input wire srst
  .din(time_event),       // input wire [11 : 0] din
  .wr_en(DAQ_pulse),      // input wire wr_en
  .rd_en(read_pulse_reg), // input wire rd_en
  .dout(time_event_fifo), // output wire [11 : 0] dout
  .full(),                // output wire full
  .empty(empty_fifo)      // output wire empty
);


// FIFO PEAK DATA
genvar i;
generate
    for(i=0; i<=(N_CH-1);i=i+1) begin : fifo_peak_generation
        fifo_generator_0 FIFO_PEAK
        (
            .clk(clk),                            // input wire clk
            .srst(reset),                         // input wire srst
            .din(A_peak_event[i][N_P-1:0]),       // input wire [11 : 0] din
            .wr_en(DAQ_pulse),                    // input wire wr_en
            .rd_en(read_pulse_reg),               // input wire rd_en
            .dout(A_peak_event_fifo[i][N_P-1:0]), // output wire [11 : 0] dout
            .full(),                              // output wire full
            .empty()                              // output wire empty
        );
    end
endgenerate


// Now I need to define the states of the FSMs
// 1) Send time 
// 2) Binary to BCD peak
// 3) Send peak
// 4) repeat for all peaks
// 5) Repeat for all areas
// 6) Read <= 1'b1;
// 7) read <= 1'b0;

typedef enum {IDLE,
              SEND_TIME,
              FILL_REGS, 
              BCD_PEAK, 
              SEND_PEAK,
              FINAL_STATE} state_FSM;

state_FSM state_reg;



// Finite state machine
always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        state_reg            <= IDLE;
        Printer              <= 0;
        Print_pulse          <= 0;
        time_event_reg       <= 0;                // Time of the event
        read_pulse_reg       <= 0;            // reg
        counter_digit        <= 0;      // Conta le cifre reg
        counter_channel      <= 0;    // Conta i canali regstart_conversion_peak;  // reg
        Converter_peak       <= 0;  // reg
    end
    else begin
        case (state_reg) 
            IDLE : begin
                if(!empty_fifo) begin
                    state_reg             <= FILL_REGS;
                    counter_digit         <= 8'd9;
                    CONTROL_STATE         <= 4'd0;
                end else begin 
                    counter_channel       <= 0;
                    time_event_reg        <= 0;
                    read_pulse_reg        <= 0;
                    counter_digit         <= 8'd0;
                    start_conversion_peak <= 1'b0;
                    CONTROL_STATE         <= 4'd1;
                end
            end
            FILL_REGS : begin
                time_event_reg   <= time_event_fifo;
                A_peak_event_reg <= A_peak_event_fifo;
                read_pulse_reg   <= 1'b1;
                state_reg        <= SEND_TIME;
                CONTROL_STATE    <= 4'd2;
            end
            SEND_TIME : begin
                if(read_pulse_reg) begin
                    read_pulse_reg <= 1'b0;
                end 
                if( (counter_digit >= 8'd2) & (!Print_pulse) ) begin
                                  Printer        <= {4'b0011,time_event_reg[(N_T-1) -: 4]};
                                  time_event_reg <= (time_event_reg << 4);
                                  Print_pulse    <= 1'b1;
                                  counter_digit  <= counter_digit - 8'd1;
                                  CONTROL_STATE  <= 4'd3;
                end else if ((counter_digit == 8'd1) & (!Print_pulse) ) begin
                                  Printer       <= wb_SPACE_ASCII;
                                  Print_pulse   <= 1'b1;
                                  counter_digit <= counter_digit - 8'd1;
                                  CONTROL_STATE <= 4'd4;
                end else if((counter_digit == 8'd0) & (!Print_pulse)) begin
                                  state_reg             <= BCD_PEAK;
                                  Print_pulse           <= 1'b0;
                                  counter_channel       <= 0;
                                  Converter_peak        <= 0;
                                  start_conversion_peak <= 1'b0;
                                  CONTROL_STATE         <= 4'd5;
                end
                if (Print_pulse) begin
                    Print_pulse <= 1'b0;
                end
            end
            BCD_PEAK : begin
                if (counter_channel <= (N_CH - 1)) begin
                    if(!start_conversion_peak) begin
                        Converter_peak        <= A_peak_event_reg[counter_channel];
                        start_conversion_peak <= 1'b1;
                        CONTROL_STATE         <= 4'd6;
                    end else if(start_conversion_peak & BCD_peak_ready) begin
                        A_peak_event_BCD[counter_channel] <= BCD_peak;
                        start_conversion_peak             <= 1'b0;
                        counter_channel                   <= counter_channel + 1;
                        CONTROL_STATE                     <= 4'd7;
                    end
                end else begin
                    state_reg       <= SEND_PEAK;
                    counter_channel <= 0;
                    counter_digit   <= 0;
                    Print_pulse     <= 1'b0;
                    CONTROL_STATE   <= 4'd8;
                end
            end 
            SEND_PEAK : begin
                if(Print_pulse) begin
                    Print_pulse <= 1'b0;
                end
                if (counter_channel <= (N_CH - 1) ) begin
                    if(counter_digit <= (N_DIGIT_OUT_PEAK - 1) ) begin 
                        if(!Print_pulse) begin 
                            Printer                           <= {4'b0011, A_peak_event_BCD[counter_channel][(4*(N_DIGIT_OUT_PEAK)-1) -: 4 ]};
                            A_peak_event_BCD[counter_channel] <= ( A_peak_event_BCD[counter_channel] << 4);
                            Print_pulse                       <= 1'b1;
                            counter_digit                     <= counter_digit + 1;
                            CONTROL_STATE                     <= 4'd9;
                        end
                    end else begin
                        if(!Print_pulse) begin 
                            Printer         <= wb_SPACE_ASCII;
                            Print_pulse     <= 1'b1;
                            counter_channel <= counter_channel + 1;
                            counter_digit   <= 0;
                            CONTROL_STATE   <= 4'd10;
                        end
                    end
                end else begin
                    if(!Print_pulse) begin 
                        Printer               <= wb_NEW_LINE;
                        Print_pulse           <= 1'b1;
                        state_reg             <= FINAL_STATE;
                        counter_digit         <= 0;
                        counter_channel       <= 0;
                        start_conversion_peak <= 1'b0;
                        CONTROL_STATE         <= 4'd11;
                    end
                end
            end
            FINAL_STATE : begin
                state_reg             <= IDLE;
                Print_pulse           <= 1'b0;
                start_conversion_peak <= 1'b0;
                counter_channel       <= 0;
                counter_digit         <= 0;
                CONTROL_STATE         <= 4'd12;
            end
            default: begin 
                state_reg <= IDLE;
            end
        endcase
    end
end



// ******************************
//      BCD MODULES 
// ******************************

Binary_to_BCD 
#(
      .INPUT_WIDTH(N_BIT_IN_PEAK),
      .DECIMAL_DIGITS(N_DIGIT_OUT_PEAK)
)
BINARY_BCD_PEAK
(
   .i_Clock(clk),
   .i_Binary(Converter_peak),
   .i_Start(start_conversion_peak),
   .o_BCD(BCD_peak),
   .o_DV(BCD_peak_ready)
);



// Modulo uart per invio dei dati
uart
#(
    .DBIT(8),      // # data bits
    .SB_TICK(16),  // # 16 ticks for 1 stop bit
    .FIFO_W(5)     // # addr bits of FIFO
)
UART_MODULE
(
    .clk(clk), 
    .reset(reset),
    .rd_uart(1'b0), 
    .wr_uart(Print_pulse),
    .rx(1'b1),
    .w_data(Printer),
    .dvsr(11'd650),
    .tx_full(),
    .rx_empty(), 
    .tx(tx),
    .r_data()
);




assign control_state = CONTROL_STATE;

endmodule
