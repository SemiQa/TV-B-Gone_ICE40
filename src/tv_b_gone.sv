/*
 * Copyright (c) 2025 Embelon
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tv_b_gone (
    input   bit  clock_in,      // clock

    input   bit  reset_in,      // resets internals (synchronous)

    input   bit  start_in,     // starts working when high (synchroous)

    output  bit  busy_out,      // still working when high
    output  bit  fail_out,      // failure when high

    output  bit  pwm_out
);

    localparam PWM_WIDTH = 8;
    localparam DELAY_WIDTH = 16;

	wire [12:0] rom_address;
	wire [7:0] rom_data;

	tv_codes_rom rom (
    	.address(rom_address),
    	.data(rom_data),
    	.address_overflow()
	);

    wire pwm_enable;
	wire pwm_forced_out;
    wire pwm_wr_strobe;
    wire [PWM_WIDTH-1:0] pwm_value;
    wire pwm_ack;

	pwm_generator 
    #(
        .WIDTH(PWM_WIDTH)
    ) pwm (
		.clock_in(clock_in),      					// clock

		.reset_in(reset_in),      					// resets counter and output when driven high (synchronous)
		.enable_in(pwm_enable),     				// PWM generated when high
		.forced_in(pwm_forced_out),					// output state to be forced when not enabled

		.compare_value_in(pwm_value),   			// PWM period in counts
		.update_comp_value_in(pwm_wr_strobe),      	// write enable, active high (synchronous)

		.pwm_out(pwm_out)        					// PWM output
	);

    wire delay_enable;
    wire delay_wr_strobe;
    wire [DELAY_WIDTH-1:0] delay_value;
    wire delay_busy;

	delay_timer 
    #(
        .WIDTH(DELAY_WIDTH)
    )timer (
        .clock_in(clock_in),      // clock

        .reset_in(reset_in),      // resets internal counter (synchronous)
        .enable_in(delay_enable),     // working when high

        .delay_in(delay_value),   // delay in number of units
        .update_delay_in(delay_wr_strobe),        // write enable, active high (synchronous)

        .busy_out(delay_busy)       // delay still not reached if high
	);

// TODO: add debouncing for button, if button triggers sequence
	controller tvbgone_ctrl(
		.clock_in(clock_in),      	// clock

		.reset_in(reset_in),      	// resets internal counter (synchronous)

		.start_in(start_in),      	// starts working when low (synchroous)
        .busy_out(busy_out),
        .fail_out(fail_out),

		// memory interface
		.mem_address_out(rom_address),
		.mem_data_in(rom_data),
		
		// PWM generator interface
		.pwm_enable_out(pwm_enable),
		.pwm_forced_out(pwm_forced_out),
		.pwm_wr_strobe_out(pwm_wr_strobe),
		.pwm_value_out(pwm_value),
		.pwm_wr_ack_in(pwm_ack),

		// delay interface
		.delay_enable_out(delay_enable),
		.delay_start_strobe_out(delay_wr_strobe),
		.delay_value_out(delay_value),
		.delay_busy_in(delay_busy)
	);


endmodule