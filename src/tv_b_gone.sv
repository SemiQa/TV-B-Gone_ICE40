/*
 * Copyright (c) 2025 SemiQa
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tv_b_gone (
    input   bit  clock_in,      	// clock

    input   bit  reset_in,      	// resets internals (synchronous)

    input   bit  start_in,     		// starts working when high (synchroous)
	input	bit  loop_forever_in,

    output  bit  busy_out,      	// still working when high
    output  bit  fail_out,      	// failure when high

    output  bit  ctc_out			// IR LED driving
);

	wire start_debounced;

	btn_debouncer btn_dbc (
        .clock_in(clock_in),      				// clock

        .reset_in(reset_in),      				// resets internal counter (synchronous)

		.btn_in(start_in),

		.btn_out(start_debounced)
	);

    localparam CTC_WIDTH = 8;
    localparam DELAY_WIDTH = 16;

	wire [12:0] rom_address;
	wire [7:0] rom_data;
	/* verilator lint_off UNUSEDSIGNAL */
	wire address_overflow;

	tv_codes_rom rom (
    	.address(rom_address),
    	.data(rom_data),
    	.address_overflow(address_overflow)
	);
	/* verilator lint_on UNUSEDSIGNAL */

    wire ctc_enable;
	wire ctc_forced_out;
    wire ctc_wr_strobe;
    wire [CTC_WIDTH-1:0] ctc_value;

	ctc_generator 
    #(
        .WIDTH(CTC_WIDTH)
    ) ctc (
		.clock_in(clock_in),      					// clock

		.reset_in(reset_in),      					// resets counter and output when driven high (synchronous)
		.enable_in(ctc_enable),     				// CTC generated when high
		.forced_in(ctc_forced_out),					// output state to be forced when not enabled

		.compare_value_in(ctc_value),   			// CTC half-period in counts
		.update_comp_value_in(ctc_wr_strobe),      	// write enable, active high (synchronous)

		.ctc_out(ctc_out)        					// CTC output
	);

    wire delay_enable;
    wire delay_wr_strobe;
    wire [DELAY_WIDTH-1:0] delay_value;
    wire delay_busy;

	delay_timer 
    #(
        .WIDTH(DELAY_WIDTH)
    ) timer (
        .clock_in(clock_in),      				// clock

        .reset_in(reset_in),      				// resets internal counter (synchronous)
        .enable_in(delay_enable),     			// working when high

        .delay_in(delay_value),   				// delay in number of units
        .update_delay_in(delay_wr_strobe),      // write enable, active high (synchronous)

        .busy_out(delay_busy)       			// delay still not reached if high
	);

	controller tvbgone_ctrl (
		.clock_in(clock_in),      			// clock

		.reset_in(reset_in),      			// resets internal counter (synchronous)

		.start_in(start_debounced), 		// starts working when low (synchroous)
		.loop_forever_in(loop_forever_in),
        .busy_out(busy_out),
        .fail_out(fail_out),

		// memory interface
		.mem_address_out(rom_address),
		.mem_data_in(rom_data),
		
		// CTC generator interface
		.ctc_enable_out(ctc_enable),
		.ctc_forced_out(ctc_forced_out),
		.ctc_wr_strobe_out(ctc_wr_strobe),
		.ctc_value_out(ctc_value),

		// delay interface
		.delay_enable_out(delay_enable),
		.delay_start_strobe_out(delay_wr_strobe),
		.delay_value_out(delay_value),
		.delay_busy_in(delay_busy)
	);


endmodule
