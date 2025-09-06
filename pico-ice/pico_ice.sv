/*
 * Copyright (c) 2025 SemiQa
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none

module pico_ice (
	input clk_ext,

	// Status LEDs
	output led_red,
	output led_green,
    output led_blue,

	// Button triggering sequence playing
	input button_in,
	input loop_forever_in,

	// Project LEDs
	output ir_led_out,
	output ir_ledn_out,
	output active_led_out,	
	output fail_led_out
);

	assign led_red = 1;
	assign led_green = 1;
	assign led_blue = 1;

    wire clk_24M;
    SB_HFOSC #(.CLKHF_DIV("0b01")) inthosc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk_24M));		// 24MHz internal osc.

	reg [1:0] div3_r;
	reg clk_8M = 0;				// 24MHz div 3 = 8MHz
	always @(posedge clk_24M) begin
		if (div3_r == 0) begin
			clk_8M = !clk_8M;
			div3_r <= 3 - 1;
		end else begin
			div3_r <= div3_r - 1;
		end
	end

/*
	wire clk;						// 8MHz buffered clock
	SB_GB ClockBuffer(
		.USER_SIGNAL_TO_GLOBAL_BUFFER(clk_8M_buf),
		.GLOBAL_BUFFER_OUTPUT(clk_8M)
	);
*/

	// ~2.7ms reset pulse (65536 / 24M)
	reg [15:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk_24M) begin
//		if (!resetn) begin
//			reset_cnt <= 0;
//		end else begin
			reset_cnt <= reset_cnt + !resetn;
//		end
	end

	tv_b_gone tv_gone (
		.clock_in (clk_8M),      	// clock

    	.reset_in(!resetn),      	// resets internals (synchronous)

    	.start_in(!button_in),     	// starts working when high (synchroous)
		.loop_forever_in(loop_forever_in),

    	.busy_out(active_led_out), 	// still working when high
    	.fail_out(fail_led_out),   	// failure when high

    	.ctc_out(ir_led_out)		// control for IR LED
	);

	assign ir_ledn_out = !ir_led_out;

endmodule
