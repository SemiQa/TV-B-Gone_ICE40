/*
 * Copyright (c) 2025 SemiQa
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tv_codes_rom
#(
    parameter SIZE = 256,
    parameter DATA_WIDTH = 8,
    parameter INIT_FILE = "../rom/eu_tv_test_rom.mif",
    localparam ADDRESS_BITS = $clog2(SIZE)
)
(
    input bit [ADDRESS_BITS-1:0] address,
    output bit [DATA_WIDTH-1:0] data,
    output bit address_overflow
);

bit [DATA_WIDTH-1:0] rom [0:SIZE-1];

initial begin
    $readmemh(INIT_FILE, rom);
end

assign address_overflow = (address >= SIZE);
assign data = !address_overflow ? rom[address] : {DATA_WIDTH{1'b0}};

endmodule
