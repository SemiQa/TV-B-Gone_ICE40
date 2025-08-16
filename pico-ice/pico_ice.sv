`default_nettype none

module pico_ice (
	// Status LEDs
	output led_red,
	output led_green,
    output led_blue,

	// Button triggering sequence playing
	input button_in,

	// Project LEDs
	output ir_led_out,
	output active_led_out,	
	output fail_led_out,

	// Trace outputs
	output trace_7_out,
	output trace_6_out,
	output trace_5_out,
	output trace_4_out,
	output trace_3_out,
	output trace_2_out,
	output trace_1_out,
	output trace_0_out
);

    wire clk_24M;
    SB_HFOSC #(.CLKHF_DIV("0b01")) inthosc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk_24M));		// 24MHz internal osc.

	reg [1:0] div3_r;
	reg clk_8M = 0;				// 24MHz div 3 = 8MHz
	always @(posedge clk_24M) begin
		div3_r <= div3_r - 1;
		if (div3_r == 0) begin
			clk_8M = !clk_8M;
			div3_r <= 3 - 1;
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
		if (!resetn) begin
			reset_cnt <= 0;
		end else begin
			reset_cnt <= reset_cnt + !resetn;
		end
	end

	// TODO: should be finally 4096 + 4096 + 77
	reg [7:0] rom [4095:0];
	initial begin
		$readmemh("../rom/ROM_123_hex.mem", rom, 0, 4095);
	end

	wire [11:0] rom_address;
	wire [7:0] rom_byte;
	always @(*) begin
		rom_byte <= rom[rom_address[11:0]];
	end;

	controller tvbgone_ctrl(
		.clock_in(clk_8M),      	// clock

		.reset_in(!resetn),      	// resets internal counter (synchronous)

		// TODO: add debouncing for button
		.startn_in(button_in),      // starts working when low (synchroous)

		// memory interface
		.data_in(rom_byte),
		.address_out(rom_address),

		.pwm_out(ir_led_out),        // pwm output

		.busy_out(active_led_out),      // still working when high
		.fail_out(fail_led_out)       // failure when high
	);

	wire [7:0] trace_out;
	assign trace_out[7:0] = {trace_7_out, trace_6_out, trace_5_out, trace_4_out, trace_3_out, trace_2_out, trace_1_out, trace_0_out};

endmodule
