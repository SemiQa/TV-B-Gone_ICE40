/*
 * Copyright (c) 2025 SemiQa
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tv_codes_rom
#(
    parameter SIZE = 4740,      // EU -> 4740, NA -> 5320
    parameter DATA_WIDTH = 8,
    parameter INIT_FILE = "../rom/eu_tv_codes_rom.mif",
    localparam ADDRESS_BITS = $clog2(SIZE)
)
(
    input bit [ADDRESS_BITS-1:0] address,
    output bit [DATA_WIDTH-1:0] data,
    output bit address_overflow
);

bit [DATA_WIDTH-1:0] rom_array [0:SIZE-1];

initial begin
    $readmemh(INIT_FILE, rom_array);
end

// Combinational read: data follows address within the same cycle, with no
// enable and no latency, which is what makes every read state in the controller
// a single cycle. Addresses past the end return zero rather than X.
assign address_overflow = (address >= SIZE);
assign data = !address_overflow ? rom_array[address] : {DATA_WIDTH{1'b0}};

endmodule
