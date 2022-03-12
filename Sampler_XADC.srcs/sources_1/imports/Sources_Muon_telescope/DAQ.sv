module DAQ
#(parameter N_CH = 6,
            N_T  = 32,
            N_P  = 12,
            N_A  = 20
)
(
    input logic clk,                           // Clock 
    input logic reset,                         // Reset
    input logic [N_T-1:0] time_ms,             // Time continuously flowing 
    input logic [N_P-1:0] A_peak [N_CH-1:0],   // Peak values array
    input logic [N_A-1:0] A_area [N_CH-1:0],   // Area value array
    input logic peak_ready [N_CH-1:0],         // peak ready flag   (posedge)
    input logic area_ready [N_CH-1:0],         // area ready flag   (posedge)
    input logic coincidence_flag,              // coincidence flag  (posedge)
    
    output logic [N_T-1:0] time_event,                // Time of the event
    output logic [N_P-1:0] A_peak_event [N_CH-1:0],   // Peak values array of the event
    output logic [N_A-1:0] A_area_event [N_CH-1:0],   // Area value array of the event
    output logic DAQ_pulse                            // Output pulse to send data to memory or uart
    );
    
/*************************************************************
   Prima di creare il modulo DAQ voglio andare a definire
   In che modo vado ad immagazzinare i dati 
   Questo mi serve per definire la larghezza e la profondit� 
   del blocco RAM che devo usare per immagazzinare i dati    
**************************************************************/

localparam N_TOTAL = N_T + (N_A + N_P)*N_CH;


// Signal declarations   
logic [N_TOTAL-1:0] data_concat;            // For data concatenation 
logic coincidence_flag_old;                 // register to store the old coincidence flag
logic [N_CH-1:0] wb_peak_ready_monostable;  // Wire bus for the monostabled signal array
logic [N_CH-1:0] wb_area_ready_monostable;  // Wire bus for the monostabled signal array
logic peak_ready_monostable [N_CH-1:0];     // peak ready flag   (posedge)
logic area_ready_monostable [N_CH-1:0];     // area ready flag   (posedge)
logic all_area_ready;                       // Reduction operator AND &
logic all_peak_ready;                       // Reduction operator AND &
logic all_data_ready;                       // AND between the reduction operators
logic time_acquired;                        // Flag stating that the time has been acquired
logic [N_T:0] time_reg;                     // Register to store time 
logic DAQ_pulse_reg;                        // DAQ_pulse for data sending 
logic clear_pulse;                          // clear_pulse for latches

// Type definition for the finite state machine 
typedef enum {IDLE, WAITING_STORE, SEND_PULSE, RESET } acquisition_state;
acquisition_state state_reg;
// Monostable instantiation to build a signal for the finite state machine 

// Instantiation of an array of monostables 
    // Monostable for peak
    Monostable_rise_only MONOSTABLES_PEAK[N_CH-1:0](
    .clk(clk),
    .reset(reset),
    .clear(clear_pulse),
    .trigger_pulse(peak_ready),
    .handshake(peak_ready_monostable)
    );
    // monostable for area
    Monostable_rise_only MONOSTABLES_AREA[N_CH-1:0](
    .clk(clk),
    .reset(reset),
    .clear(clear_pulse),
    .trigger_pulse(area_ready),
    .handshake(area_ready_monostable)
    );
    // Now we need to implement the reduction operators
    genvar i;
    generate
        for(i = 0; i <= (N_CH-1); i = i + 1 ) begin
            assign wb_peak_ready_monostable[i] = peak_ready_monostable[i];
            assign wb_area_ready_monostable[i] = area_ready_monostable[i];
        end
    endgenerate

    assign all_area_ready = &wb_area_ready_monostable;
    assign all_peak_ready = &wb_peak_ready_monostable;
    assign all_data_ready = all_area_ready & all_peak_ready;



// Instantiation of LATCHES to preserve the data from changing

Buffers_reg_LATCH
#(.width(N_P))
LATCHES_PEAK [N_CH-1:0]
(
    .clk(clk),                   // Clock
    .reset(reset||clear_pulse),               // Reset
    .wb_signal_in(A_peak),       // Signal incoming 
    .update_flag(peak_ready),    // Update signal (posedge)
    .output_latch(A_peak_event)  // Output of the buffer (TO OUTPUT)
);

Buffers_reg_LATCH
#(.width(N_A))
LATCHES_AREA [N_CH-1:0]
(
    .clk(clk),                   // Clock
    .reset(reset||clear_pulse),               // Reset
    .wb_signal_in(A_area),       // Signal incoming 
    .update_flag(area_ready),    // Update signal (posedge)
    .output_latch(A_area_event)  // Output of the buffer (TO OUTPUT)
);



// Sequential acquisition with registers 

always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        state_reg <= IDLE;
    end
    else begin
        case(state_reg)
            IDLE: begin
                DAQ_pulse <= 1'b0;
                clear_pulse <= 1'b0;
                if(coincidence_flag & (!coincidence_flag_old))
                    state_reg <= WAITING_STORE;
            end
            WAITING_STORE: begin
                if(!time_acquired) begin
                    time_reg <= time_ms;
                    time_acquired <= 1'b1;
                end
                if(time_acquired & all_data_ready) begin
                    DAQ_pulse_reg <= 1'b1;
                    state_reg <= SEND_PULSE;
                end
            end
            SEND_PULSE: begin 
                state_reg <= RESET;
            end
            RESET: begin 
                state_reg <= IDLE;
                clear_pulse <= 1'b1;
                time_acquired <= 1'b0;
            end
            default: 
                state_reg <= IDLE;
        endcase
        coincidence_flag_old <= coincidence_flag;
    end
end


// Combinational logic for output 
assign time_event = time_reg;


/****************************************************
 Now I need to properly manage the ready signals
 A counter should count the positive edges from the peak_ready
 and the Area_ready signals. 

    Example
 -> @ posedge peak_ready[0]
        -> counter_peak = counter_peak + 1
 -> if counter_peak == number of channels 
        -> acquire data since all of them are ready

****************************************************/
    
    
endmodule
