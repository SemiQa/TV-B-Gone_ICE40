/*
 * Copyright (c) 2025 SemiQa
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module btn_debouncer 
#(
    parameter PERIOD_MS = 10,
    parameter CLK_MHZ = 8
)
(
    input   bit  clock_in,      // clock

    input   bit  reset_in,      // resets internal counter (synchronous)

    input   bit  btn_in,

    output  bit  btn_out
);

localparam COUNT_PER_PERIOD = CLK_MHZ * PERIOD_MS * 1000;
localparam COUNTER_WIDTH = $clog2(COUNT_PER_PERIOD);

reg [COUNTER_WIDTH-1:0] counter_r;

wire enable;
reg [2:0] probe_r;

always @(posedge clock_in) begin
    if (reset_in) begin
        counter_r <= COUNT_PER_PERIOD - 1;
        probe_r <= 0;
    end else begin
        if (counter_r == 0) begin
            counter_r <= COUNT_PER_PERIOD - 1;
        end else begin
            counter_r <= counter_r - 1;
        end
        if (enable) begin
            probe_r[2:0] <= {probe_r[1:0], btn_in};            
        end
    end
end

assign enable = (counter_r == 0);

assign btn_out = !probe_r[2] & probe_r[1] & probe_r[0];

endmodule
