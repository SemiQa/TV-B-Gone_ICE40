/*
 * Copyright (c) 2025 SemiQa
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module delay_timer 
#(
    parameter WIDTH = 16,
    parameter UNIT_COUNTS_US = 10,
    parameter CLK_MHZ = 8
)
(
    input   bit  clock_in,      // clock

    input   bit  reset_in,      // resets internal counter (synchronous)
    input   bit  enable_in,     // working when high

    input   bit  [WIDTH-1:0] delay_in,   // delay in number of units
    input   bit  update_delay_in,        // write enable, active high (synchronous)

    output  bit  busy_out       // delay still not reached if high
);

localparam COUNTS_PER_UNIT = CLK_MHZ * UNIT_COUNTS_US;
localparam UNIT_COUNTER_WIDTH = $clog2(COUNTS_PER_UNIT);

reg [WIDTH-1:0] delay_r;
reg [UNIT_COUNTER_WIDTH-1:0] unit_counter_r;

assign busy_out = (delay_r != 0) && enable_in;

always @(posedge clock_in) begin
    if (reset_in) begin
        delay_r <= 0;
        unit_counter_r <= COUNTS_PER_UNIT - 1;
    end else if (busy_out) begin
        if (unit_counter_r != 0) begin
            unit_counter_r <= unit_counter_r - 1;
        end else begin
            if (delay_r != 0) begin
                delay_r <= delay_r - 1;
            end
            unit_counter_r <= COUNTS_PER_UNIT - 1;
        end
    end else if (update_delay_in) begin
        delay_r <= delay_in;
        unit_counter_r <= COUNTS_PER_UNIT - 1;
    end
end

endmodule
