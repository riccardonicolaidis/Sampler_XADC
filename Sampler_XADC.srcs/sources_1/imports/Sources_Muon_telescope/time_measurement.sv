module Module_Time_Measurement (
input logic clk,
input logic reset,
output  logic [31:0] out
);

// FILI PER IL CRONOMETRO
logic  w_1e3Hz;
logic  w_1e2Hz;
logic  w_1e1Hz;
logic  w_1e0Hz;
logic  w_1m1Hz;
logic  w_1m2Hz;
logic  w_1m3Hz;
logic  w_1m4Hz;


Module_FrequencyDivider	DIVISORE_1000Hz(	
    .clk(clk), 
	.reset(reset),
    .period(30'd50000), 
    .clk_out(w_1e3Hz)
);  
Module_SynchroCounter_4_bit  COUNTER_1e3Hz(	
	.clk(clk),
	.clk_ref(w_1e3Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[3:0]),
	.carry(w_1e2Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1e2Hz(	
	.clk(clk),
	.clk_ref(w_1e2Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[7:4]),
	.carry(w_1e1Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1e1Hz(	
	.clk(clk),
	.clk_ref(w_1e1Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[11:8]),
	.carry(w_1e0Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1e0Hz(	
	.clk(clk),
	.clk_ref(w_1e0Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[15:12]),
	.carry(w_1m1Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1m1Hz(	
	.clk(clk),
	.clk_ref(w_1m1Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[19:16]),
	.carry(w_1m2Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1m2Hz(	
	.clk(clk),
	.clk_ref(w_1m2Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[23:20]),
	.carry(w_1m3Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1m3Hz(	
	.clk(clk),
	.clk_ref(w_1m3Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[27:24]),
	.carry(w_1m4Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1m4Hz(	
	.clk(clk),
	.clk_ref(w_1m4Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[31:28]),
	.carry()
);

endmodule