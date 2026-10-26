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

	// 12 MHz from the RP2040 on pin 35, multiplied to 48 MHz by the PLL
	wire clk_48M;
	wire pll_locked;
	SB_PLL40_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0000),			// 12 MHz / 1 = 12 MHz at the phase detector
		.DIVF(7'b0111111),		// x 64 = 768 MHz VCO
		.DIVQ(3'b100),			// / 16 = 48 MHz
		.FILTER_RANGE(3'b001)
	) pll (
		.PACKAGEPIN(clk_ext),
		.PLLOUTGLOBAL(clk_48M),
		.LOCK(pll_locked),
		.RESETB(1'b1),
		.BYPASS(1'b0)
	);

	reg [1:0] div3_r;
	reg clk_8M = 0;				// toggles every 3rd 48MHz cycle: 48MHz div 6 = 8MHz
	always @(posedge clk_48M) begin
		if (div3_r == 0) begin
			clk_8M = !clk_8M;
			div3_r <= 3 - 1;
		end else begin
			div3_r <= div3_r - 1;
		end
	end

	// ~1.4ms reset pulse (65536 / 48M), counted from PLL lock
	reg [15:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk_48M) begin
		if (!pll_locked) begin
			reset_cnt <= 0;
		end else begin
			reset_cnt <= reset_cnt + !resetn;
		end
	end

	tv_b_gone tv_gone (
		.clock_in (clk_8M),      	// clock

    	.reset_in(!resetn),      	// resets internals (synchronous)

    	.start_in(button_in),     	// starts working when high (synchroous)
		.loop_forever_in(loop_forever_in),

    	.busy_out(active_led_out), 	// still working when high
    	.fail_out(fail_led_out),   	// failure when high

    	.ctc_out(ir_led_out)		// control for IR LED
	);

	assign ir_ledn_out = !ir_led_out;

endmodule
