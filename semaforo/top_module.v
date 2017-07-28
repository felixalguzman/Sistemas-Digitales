`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:49:02 07/18/2017 
// Design Name: 
// Module Name:    top_module 
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


module top_module(
	input [3:0] btn, 
	input mclk, 
	input [3:0] sw,
	input [5:4] sw2,
	output[6:0] Led,
	input [7:7] sw7
 );
	 
	wire hz1_enable;
	wire [3:0] value;
	wire start_timer;
	wire expired;
	wire wr_reset;
	wire wr;
	wire interval;
	 
	fsm dut1(.clock(hz1_enable), .reset_sync(sw7), .sensor_sync(btn[1]), .wr(wr), .prog_sync(btn[3]), .expired(expired), .Leds(Led), .wr_reset(wr_reset), .interval(interval), .start_timer(start_timer));
	 
	divider dut2(.clock(mclk), .reset_sync(sw7), .hz1_enable(hz1_enable));
	 
	time_parameters dut3(.clock(hz1_enable), .reset_sync(sw7), .time_value(sw), .time_parameter_selector(sw2), .prog_sync(btn[3]), .interval(interval), .value(value));
	 
	timer dut4(.hz1_enable(hz1_enable), .reset_sync(sw7), .value(value), .start_timer(start_timer), .expired(expired));

	walk_register dut5(.clock(hz1_enable), .reset_sync(sw7), .wr_sync(btn[2]), .wr_reset(wr_reset), .wr(wr));
endmodule
