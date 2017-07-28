`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:16:39 07/18/2017 
// Design Name: 
// Module Name:    semaforo 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fsm(
	input clock, reset_sync, sensor_sync, wr, prog_sync, expired,
  	output reg [6:0] Leds, 
	output reg wr_reset, 
	output reg [1:0] interval, 
	output reg start_timer
);
	
	parameter 
		s0 = 3'b000, //GM
		s1 = 3'b001, //GM#2
		s2 = 3'b010, //YM
		s3 = 3'b011, //GS
		s4 = 3'b100, //YS
		s5 = 3'b101, //Walk
		s6 = 3'b110, //Ext1
		s7 = 3'b111; //Ext2
		
	parameter 
		BASE = 0, 
		EXT = 1, 
		YELLOW = 2;
	
	reg [3:0] state = s0;
	
	always @(posedge clock) 
	begin 
		 if(reset_sync || prog_sync) 
		 begin 
			state <= 0;
		 end 
		 else 
		 begin 
		 if(expired) 
		 begin 		 
		 case(state)			 
			 s0: 
			 begin 
			 if(sensor_sync) 
				state <= s6; 
			 else 
				state <= s1; 
			 end 
			 
			 s1:
				state <= s2;
			 
			 s2: 
			 begin 
			 if(wr) 
			 begin 
				state <= s5; 
			 end 
			 else 
				state <= s3; 
			 end 
			 
			 s3: 
			 begin 
			 if(sensor_sync) 
				state <= s7; 
			 else 
				state <= s4; 
			 end 
			 
			 s4: 
				state <= s0;  
				 
			 s5: 
				state <= s3; 
				
			 s6: 
				state <= s2; 
				
			 s7: 
				state <= s4;
		endcase 
	 end 		 
	 end
	end 
	
	always @(state)
	begin 	
		case(state) 
			s0: 
			begin 
				interval = BASE; 
				Leds = 7'b0100001;
			end 
			
			s1:
			begin 
				interval = BASE; 
				Leds = 7'b0100001; 
			end 
			
			s2:
			begin 
				interval = YELLOW; 
				Leds = 7'b0100010;
			end 
			
			s3: 
			begin 
				interval = BASE; 
				Leds = 7'b0001100;
			end 
			
			s4:
			begin 
				interval = YELLOW; 
				Leds = 7'b0010100; 
			end 
			
			s5:
			begin 
				interval = EXT; 
				Leds = 7'b1100100;
			end 
			
			s6: 
			begin 
				interval = EXT; 
				Leds = 7'b0100001; 
			end 
			
			s7:
			begin 
				interval = EXT; 
				Leds = 7'b0001100;
			end
		endcase 
	end
	
	always @(*)
		begin		
		if(expired)
		begin
			start_timer = 0;
		end
		else
		begin
			start_timer = 1;
		end
		
		if(state == s5)
		begin
			wr_reset = 1;
		end
		else
		begin
			wr_reset = 0;
		end
	end
endmodule // fsm

module divider(
	input clock, reset_sync,
	output reg hz1_enable = 1'b0
);

	reg [24:0] counter;
	
	always @(posedge reset_sync or posedge clock)
	begin
		if(reset_sync == 1'b1) begin
			hz1_enable <= 0;
			counter <= 0;
		end
		else
		begin
			counter <= counter + 1;
			if(counter == 25_000_000)
			begin
				counter <= 0;
				hz1_enable <= ~hz1_enable;
			end
		end		
	end
endmodule // divider

module time_parameters(
	input clock, reset_sync, prog_sync,
	input [1:0] time_parameter_selector,
	input [3:0] time_value,
	input [1:0] interval,
	output reg [3:0] value
); 

	parameter t_BASE = 4'b0110; 
	parameter t_EXT = 4'b0011; 
	parameter t_YEL = 4'b0010; 

	parameter BASE = 0; 
	parameter EXTEND = 1; 
	parameter YELLOW = 2;
 
	reg [3:0] timeBase = t_BASE; 
	reg [3:0] timeExt = t_EXT; 
	reg [3:0] timeYel = t_YEL; 
 
	always @ (posedge clock) 
	begin
		if(reset_sync) 
		begin
		 timeBase <= t_BASE; 
		 timeExt <= t_EXT; 
		 timeYel <= t_YEL; 
		end
		else if(prog_sync) 
		begin 
		 case(time_parameter_selector) 
			 BASE: 
				timeBase <= time_value; 
			 EXTEND: 
				timeExt <= time_value;
			 YELLOW: 
				timeYel <= time_value; 
		 endcase 
		end
	end
 
	always @ (interval) 
	begin 
	case(interval)
	 BASE: 
		value = timeBase;
	 EXTEND: 
			value = timeExt;
	 YELLOW: 
		value = timeYel; 
	 default: 
		value = value; 
	 endcase 
	end 
endmodule // time_parameters

module timer(
	input hz1_enable, reset_sync, 
	input [3:0] value, 
	input start_timer,
	output reg expired = 1'b0
);

	reg [3:0] counter;
	
	always @(posedge hz1_enable or posedge reset_sync)
	begin
		if(reset_sync == 1'b1) begin
			expired <= 1'b0;
			counter <= 4'b0000;
		end
		else
		begin
			if(start_timer)
			begin				
				if(counter <= value)
				begin
					counter <= counter + 1;
					expired <= 1'b0;
				end
				else
				begin
					counter <= 4'b0000;
					expired <= 1'b1;
				end
			end
			else
			begin
				counter <= 4'b0000;
				expired <= 1'b0;
			end
		end
	end
endmodule // timer

module walk_register(
	input clock, reset_sync, wr_sync, wr_reset,
	output reg wr = 0
);

	always @(posedge clock) 
	  begin
		if(reset_sync) 
			wr <= 0; 
		else 
		begin 
		if(wr_reset) 
			wr <= 0; 
		else if(wr_sync)
			wr <= 1; 
		else 
			wr <= wr; 
		end 
	  end
endmodule // walk_register