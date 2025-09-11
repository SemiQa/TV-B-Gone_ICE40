/*
 * Copyright (c) 2025 SemiQa
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module ctc_generator 
#(
    parameter WIDTH = 8
)
(
    input   bit  clock_in,      // clock

    input   bit  reset_in,      // resets counter and output when driven high (synchronous)
    input   bit  enable_in,     // CTC generated when high
    input   bit  forced_in,     // output state to be forced when not enabled

    input   bit  [WIDTH-1:0] compare_value_in,   // CTC half-period in counts
    input   bit  update_comp_value_in,           // write enable, active high (synchronous)

    output  bit  ctc_out        // CTC output
);

reg [WIDTH-1:0] counter_r;
reg [WIDTH-1:0] ocr_r;

reg out;

always @(posedge clock_in) begin
    if (reset_in) begin
        counter_r <= 0;
        ocr_r <= 0;
        out <= 0;
    end else if (enable_in) begin
        if (counter_r == ocr_r) begin
            out <= ~out;
            counter_r <= 0;
        end else begin
            counter_r <= counter_r + 1;
        end
    end else if (update_comp_value_in) begin
        ocr_r <= compare_value_in;
        counter_r <= 0;
    end
end

assign ctc_out = enable_in ? out : forced_in;

endmodule
