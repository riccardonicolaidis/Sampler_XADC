//*********************************************************************
// Xilinx xadc interface:
//  * xadc in sequence mode
//  * DRP interface is connected to atomtically read
//    out the pres-designated channels
//  * the readout is stored into corresponding register
//*********************************************************************
// arty board configuration
//  * vp/vn channel
//  * 13 aux channels:
//      * 6 single-ended channels
//      * 3 differential channels
//      * 4 on-board voltage/current channels
//  * the design enables all 16 aux channels and 
//    * 16 aux reading in a register file
//    * vp/temp/vcc in three registers 
// *********************************************************************
//  * channel mapping (arty signal: aux)
//    * single-ended channels (max=3V via voltage divider)
//      * a0: 4
//      * a1: 5
//      * a2: 6
//      * a3: 7
//      * a4: 15
//      * a5: 0
//    * differential channels  (max=1V)
//      * a6/a7: 12 (diff)
//      * a8/a9: 13 (diff)
//      * a10/a11: 14 (diff)
//    * on-board v-i channel
//      * iv0 (core current): 10 (max=1V)
//          * shunt register = 10m ohm; amp gain = 50 
//          * 1A(0.5V
//      * iv1 (unregulated voltage): 2 (max=16V via volatge divider)
//          * voltage of external power jack (usually not connected) 
//      * iv2 (5V power supply voltage): 1 (max=5.99V via voltage divider) 
//      * iv3 (5V power supply current): 9 
//          * shunt register = 5m ohm; amp gain = 50 
//          * 1A(0.25V
//    * software driver must do the conversion  
//*********************************************************************
//  * channel mapping (aux: arty signal)
//    * 0:a5   1:iv2  2:iv1    3:n/a  4:a0     5:a1     6:a2       7:a3
//    * 8:n/a  9:iv3  10:iv0  11:n/a 12:a6/a7 13:a8/a9 14:a10/a11 15:a4   
//*********************************************************************
//*********************************************************************
//  * xadc internal reg address space (5 bits) 
//    * 0xxxx: internal measurements and vp/vn
//    * 1xxxx: 16 aux analog readings    
//*********************************************************************

// ADDRESS DEFINITIONS 
/**********************************************************************
ORA DEVO DEFINIRE GLI INDIRIZZI DADDR PER ANDARE A LEGGERE 
I VALORI DELLE MISURE FATTE DALLO XADX 

         _________________________________________________________
        |  # 	|  PIN       | DADDR   |      Channel ADC	      |
        |-------|------------|---------|--------------------------|
        |  1.   | V_P / v_N  |    03h  |   DEDICATED DIFFERENTIAL |
        |  2.   | A0         |    14h  |   Channel 4              |
        |  3.   | A1		 |    15h  |   Channel 5              |
        |  4.   | A2         |    16h  |   Channel 6              |
        |  5.   | A3         |    17h  |   Channel 7              |
        |  6.   | A4         |    1Fh  |   Channel 15             |
        |  7.   | A5	    m|    10h  |   Channel 0              |
        |  8.   | A6+  / A7- |    1Ch  |   Channel 12             |
        |  9.   | A8+  / A9- |    1Dh  |   Channel 13             |
        |  10.  | A10+ / A11-|    1Eh  |   Channel 14             |
        |_______|____________|_________|__________________________|

************************************************************************/
module XADC_module
#( 
    parameter N_CH = 6,
              N_P = 12
)
(
    input  logic clk,
    input  logic reset,
    input  logic [8:0] adc_a_p, adc_a_n,         // 9 analog channels
    input  logic vp_in, vn_in,
    output logic signed [N_P-1:0] A [N_CH-1:0],  // A      Digitalized 12-bit OUT
    output logic A_pulse [N_CH-1:0]              // A ready pulse 
    );

// SIGNAL DECLARATION 
   logic [4:0] channel;
   logic [6:0] daddr_in;
   logic eoc;
   logic rdy;
   logic [15:0] adc_data;


xadc_wiz_0 xadc_unit (
      .dclk_in(clk),         // input logic dclk_in
      .reset_in(reset),      // input logic reset_in
      .di_in(16'h0000),      // input logic [15 : 0] di_in
      .daddr_in(daddr_in),   // input logic [6 : 0] daddr_in
      .den_in(eoc),          // input logic den_in
      .dwe_in(1'b0),         // input logic dwe_in
      .drdy_out(rdy),        // output logic drdy_out
      .do_out(adc_data),     // output logic [15 : 0] do_out
      .channel_out(channel), // output logic [4 : 0] channel_out
      .eoc_out(eoc),         // output logic eoc_out
      .alarm_out(),          // output logic alarm_out
      .eos_out(),            // output logic eos_out
      .busy_out(),           // output logic busy_out
      .ot_out(),
      .user_temp_alarm_out(),
      .vp_in(vp_in), 
      .vn_in(vn_in), 
      .vauxp0(adc_a_p[5]), // A5
      .vauxn0(adc_a_n[5]), // A5
      .vauxp1(1'b0), 
      .vauxn1(1'b0),
      .vauxp2(1'b0), 
      .vauxn2(1'b0),
      .vauxp3(1'b0), 
      .vauxn3(1'b0),
      .vauxp4(adc_a_p[0]), // A0 single ended
      .vauxn4(adc_a_n[0]), // A0 gnd
      .vauxp5(adc_a_p[1]), // A1 single ended
      .vauxn5(adc_a_n[1]), // A1 gnd
      .vauxp6(adc_a_p[2]), // A2 single ended
      .vauxn6(adc_a_n[2]), // A2 gnd
      .vauxp7(adc_a_p[3]), // A3 single ended
      .vauxn7(adc_a_n[3]), // A3 gnd
      .vauxp8(1'b0), 
      .vauxn9(1'b0),
      .vauxp10(1'b0), 
      .vauxn10(1'b0),
      .vauxp11(1'b0), 
      .vauxn11(1'b0),
      .vauxp12(adc_a_p[6]), // A6 diff +
      .vauxn12(adc_a_n[6]), // A7 diff -
      .vauxp13(adc_a_p[7]), // A8 diff +
      .vauxn13(adc_a_n[7]), // A9 diff -
      .vauxp14(adc_a_p[8]), // A10 diff +
      .vauxn14(adc_a_n[8]), // A11 diff -
      .vauxp15(adc_a_p[4]), // A4 single ended
      .vauxn15(adc_a_n[4])  // A4 gnd
   );


// form xadc DRP address 
assign daddr_in = {2'b00, channel};
// Instantiation of REGISTERS MODULES FOR DEMULTIPLEXING
//
// CHANNEL USED:
// - 6 single ended
// - 3 differential
// - 9 in total

logic [4:0] identifier_ch [8:0];      // IDENTIFIERS FOR ALL 9 CHANNELS USED

assign identifier_ch[0] = 5'b10100; 
assign identifier_ch[1] = 5'b10101;
assign identifier_ch[2] = 5'b10110;
assign identifier_ch[3] = 5'b10111;
assign identifier_ch[4] = 5'b11111;
assign identifier_ch[5] = 5'b10000;
assign identifier_ch[6] = 5'b11100;
assign identifier_ch[7] = 5'b11101;
assign identifier_ch[8] = 5'b11110;



// ARRAY OF DEMULTIPLEXERS TO BUILD UP THE PARALLEL PIPELINE FOR DSP
genvar i;
generate
    for(i=0; i<=(N_CH-1);i=i+1) begin : Demux_generation
        adc_demux 
        #(
            .N_P(N_P)                   // # of bits of the ADC 12
        )
            A_demux           // ARRAY 
        (
            .clk(clk),                  // clk
            .reset(reset),              // reset low
            .channel(channel),          // channel 5 bits from XADC (to be compared with the id)
            .adc_data(adc_data),        // adc data bus from the xadc (to be acquired)
            .rdy(rdy),                  // ready signal 
            .identifier_ch(identifier_ch[i][4:0]),    // identifier of the demultiplexed channel 
            .adc_data_demux(A[i][(N_P-1):0]),         // data bus array containing the demultiplexed lines 
            .data_flag(A_pulse[i])         // demultiplexed pulses lines (sampling frequencies)
        );
    end
endgenerate
    
endmodule
