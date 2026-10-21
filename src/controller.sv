/*
 * Copyright (c) 2025 SemiQa
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module controller 
#(
    parameter ADDRESS_BITS = 13,
    parameter DELAY_BITS = 16,
    parameter CTC_BITS = 8
)
(
    input   bit  clock_in,          // clock

    input   bit  reset_in,          // resets internal counter (synchronous)

    input   bit  start_in,          // starts working when high (synchronous)
    input   bit  loop_forever_in,   // loops forever sending codes, when high

    output  bit  busy_out,          // still working when high
    output  bit  fail_out,          // failure detected when high

    // memory interface
    output  bit [ADDRESS_BITS-1:0] mem_address_out,
    input   bit [7:0] mem_data_in,
    
    // CTC generator interface
    output  bit ctc_enable_out,
    output  bit ctc_forced_out,
    output  bit ctc_wr_strobe_out,
    output  bit [CTC_BITS-1:0] ctc_value_out,

    // delay interface
    output  bit delay_enable_out,
    output  bit delay_start_strobe_out,
    output  bit [DELAY_BITS-1:0] delay_value_out,
    input   bit delay_busy_in
);

localparam HEADER_BYTES = 3;
// for simplification header bytes are read into the header_r registers in opposite order (2 -> 1 -> 0)
// following indexes take that into account
localparam HEADER_FREQUENCY_INDEX = 2;
localparam HEADER_CHIRPS_INDEX = 1;
localparam HEADER_PAIRNUM_COMPRESSION_INDEX = 0;

// header array
reg [7:0] header_r [0:HEADER_BYTES-1];

// individual components of header
wire [7:0] frequency;
wire [7:0] chirps_num;
wire [3:0] pairs_num;
wire [2:0] index_bits_num;

assign frequency = header_r[HEADER_FREQUENCY_INDEX];
assign chirps_num = header_r[HEADER_CHIRPS_INDEX];
assign pairs_num = header_r[HEADER_PAIRNUM_COMPRESSION_INDEX][7:4];
assign index_bits_num = header_r[HEADER_PAIRNUM_COMPRESSION_INDEX][2:0];

localparam MAX_INDEX_BITS = 3;
localparam INDEX_VECTOR_BITS = MAX_INDEX_BITS + 8 - 1;

typedef enum {
    S_RESET, 
    S_IDLE, 
    S_READ_HEADER, 
    S_CHECK_HEADER,
    S_READ_INDEX,
    S_CHECK_INDEX,
    S_READ_CARRIER_ON_TIME, 
    S_CARRIER_ON, 
    S_READ_CARRIER_OFF_TIME, 
    S_CARRIER_OFF, 
    S_PREPARE_NEXT_CYCLE,
    S_FAIL
} e_state;
e_state state_r;

// stores header bytes current address or chirps pairs array starting address, depending on state
reg [ADDRESS_BITS-1:0] header_chirps_address_r;

// index byte address
reg [ADDRESS_BITS-1:0] index_byte_address_r;
// index bit address (index is packed, using only 2,3,4 bits)
reg [MAX_INDEX_BITS-1:0] index_bit_offset_r;

reg [INDEX_VECTOR_BITS-1:0] index_vector_r;

// True when the chirp just emitted used up the index bits held in
// index_vector_r, so the next one needs a fresh byte. Evaluated on the offset
// *before* it advances. See docs/rom-format.md, "Where a record ends".
wire read_next_index_byte;
assign read_next_index_byte = 
    ((index_bits_num == 4) 
        && (index_bit_offset_r[MAX_INDEX_BITS-1]))
    || ((index_bits_num == 2) 
        && (index_bit_offset_r[MAX_INDEX_BITS-1:1] == 3))
    || ((index_bits_num == 3) 
        && ((index_bit_offset_r[MAX_INDEX_BITS-1:0] == 1)
            || (index_bit_offset_r[MAX_INDEX_BITS-1:0] == 4)
            || (index_bit_offset_r[MAX_INDEX_BITS-1:0] == 7)));

// For 3-bit indices the step is 1, not 3: index_bit_offset_r then counts
// phases 0..7 through a repeating 3-byte window rather than bit positions.
// That is what makes the case statement below look arbitrary -- each phase is a
// different slice of the window. See docs/rom-format.md, "3 bits per index".
wire [MAX_INDEX_BITS-1:0] index_bit_delta;
assign index_bit_delta = (index_bits_num == 3) ? (1) : (index_bits_num);

wire [3:0] chirp_pair_4b_index;
assign chirp_pair_4b_index[3:0] = (index_bit_offset_r[MAX_INDEX_BITS-1] == 0) ? index_vector_r[7:4] : index_vector_r[3:0];

// One arm per phase of the 8-index / 3-byte window; phases 2 and 5 straddle a
// byte boundary and reach into the carried bits. Table in docs/rom-format.md.
reg [3:0] chirp_pair_3b_index;
always @(*) begin
    case (index_bit_offset_r[MAX_INDEX_BITS-1:0])
        0:  chirp_pair_3b_index = {1'b0, index_vector_r[7:5]};
        1:  chirp_pair_3b_index = {1'b0, index_vector_r[4:2]};
        2:  chirp_pair_3b_index = {1'b0, index_vector_r[9:7]};
        3:  chirp_pair_3b_index = {1'b0, index_vector_r[6:4]};
        4:  chirp_pair_3b_index = {1'b0, index_vector_r[3:1]};
        5:  chirp_pair_3b_index = {1'b0, index_vector_r[8:6]};
        6:  chirp_pair_3b_index = {1'b0, index_vector_r[5:3]};
        7:  chirp_pair_3b_index = {1'b0, index_vector_r[2:0]};
        default: chirp_pair_3b_index = 4'b0000;
    endcase
end

reg [3:0] chirp_pair_2b_index;
always @(*) begin
    case (index_bit_offset_r[MAX_INDEX_BITS-1:1]) 
        0:  chirp_pair_2b_index = {2'b00, index_vector_r[7:6]};
        1:  chirp_pair_2b_index = {2'b00, index_vector_r[5:4]};
        2:  chirp_pair_2b_index = {2'b00, index_vector_r[3:2]};
        3:  chirp_pair_2b_index = {2'b00, index_vector_r[1:0]};
        default: chirp_pair_2b_index = 4'b0000;
    endcase
end

wire [3:0] chirp_pair_index;
assign chirp_pair_index[3:0] = (index_bits_num[1]) 
                                ? (index_bits_num[0] ? chirp_pair_3b_index : chirp_pair_2b_index) 
                                : ((index_bits_num[2] & !index_bits_num[0]) ? chirp_pair_4b_index : 4'b0000);

// TODO: add constants
// byte_counter_r does three jobs in turn: counts the header bytes down 2->0,
// then indexes the on-time bytes (0,1) and the off-time bytes (2,3) of a
// pair-table entry, where it also supplies the low address bits. Two bits wide,
// so 3+1 wraps to 0 ready for the next chirp with no explicit reset.
reg [1:0] byte_counter_r;
reg [7:0] chirps_counter_r;

// this is 16 bit delay / time for carrier on or off, depending on state
reg [DELAY_BITS-1:0] delay_on_off_r;
// this is strobe / trigger to start the delay
reg delay_start_r;

// state machine
always @(posedge clock_in) begin
    if (reset_in) begin
        state_r <= S_RESET;
    end else begin
        case (state_r)
            S_RESET: begin
                header_r[0] <= 0;
                header_r[1] <= 0;
                header_r[2] <= 0;
                header_chirps_address_r <= 0;
                index_byte_address_r <= 0;
                index_bit_offset_r <= 0;
                index_vector_r <= 0;
                byte_counter_r <= 0;
                chirps_counter_r <= 0;
                delay_on_off_r <= 0;
                delay_start_r <= 0;
                state_r <= S_IDLE;
            end
            S_IDLE: begin
                if (start_in || loop_forever_in) begin
                    state_r <= S_READ_HEADER;
                    byte_counter_r <= HEADER_BYTES - 1;
                end
            end
            S_READ_HEADER: begin
                header_r[byte_counter_r] <= mem_data_in;
                header_chirps_address_r <= header_chirps_address_r + 1;
                if (byte_counter_r == 0) begin
                    state_r <= S_CHECK_HEADER;
                end else begin
                    byte_counter_r <= byte_counter_r - 1;
                end
            end
            S_CHECK_HEADER: begin
                if (!(|header_r[2] | |header_r[1] | |header_r[0])) begin
                    // EOF for TV codes -> go back to reset state
                    state_r <= S_RESET;
                end else if ((index_bit_delta != 0) 
                    && (chirps_num != 0) 
                    && (pairs_num != 0)) begin
                    index_bit_offset_r <= 0;
                    // Index bytes start after the pair table: pairs_num entries
                    // of 4 bytes. The concatenation is pairs_num * 4, zero-extended;
                    // 6 magnitude bits are enough because pairs_num <= 15.
                    index_byte_address_r <= header_chirps_address_r + { {(ADDRESS_BITS-1-6){1'b0}}, pairs_num, 2'b00 };
                    chirps_counter_r <= chirps_num - 1;                  
                    state_r <= S_READ_INDEX;
                end else begin
                    state_r <= S_FAIL;
                end
            end
            S_READ_INDEX: begin
                // Slide the window: keep the (at most 2) bits not yet consumed and
                // append the new byte. 10 bits is exactly 8 new + 2 carried.
                index_vector_r[INDEX_VECTOR_BITS-1:0] <= {index_vector_r[1:0], mem_data_in[7:0]};
                byte_counter_r <= 0;
                state_r <= S_CHECK_INDEX;
            end
            S_CHECK_INDEX: begin
                if (chirp_pair_index < pairs_num) begin
                    state_r <= S_READ_CARRIER_ON_TIME;
                end else begin
                    state_r <= S_FAIL;
                end
            end
            S_READ_CARRIER_ON_TIME: begin
                if (byte_counter_r == 0) begin
                    delay_on_off_r[7:0] <= mem_data_in;
                end else begin
                    // byte_counter_r == 1
                    delay_on_off_r[15:8] <= mem_data_in;
                    delay_start_r <= 1;
                    state_r <= S_CARRIER_ON;
                end
                byte_counter_r <= byte_counter_r + 1;
            end
            S_CARRIER_ON: begin
                // A duration of zero never raises busy, so waiting for the
                // timer here would hang. Skip straight on instead.
                if (|delay_on_off_r == 0) begin
                    delay_start_r <= 0;
                    state_r <= S_READ_CARRIER_OFF_TIME;
                end else begin
                    // Two-phase handshake: hold the strobe until the timer
                    // acknowledges by raising busy, then drop it and wait for busy
                    // to fall. Dropping it earlier risks the load never landing;
                    // holding it reloads the timer the moment it finishes.
                    if (delay_start_r & delay_busy_in) begin
                        delay_start_r <= 0;
                    end
                    if (!delay_start_r & !delay_busy_in) begin
                        state_r <= S_READ_CARRIER_OFF_TIME;
                    end
                end
            end
            S_READ_CARRIER_OFF_TIME: begin
                if (byte_counter_r == 2) begin
                    delay_on_off_r[7:0] <= mem_data_in;
                end else begin
                    // byte_counter_r == 3
                    delay_on_off_r[15:8] <= mem_data_in;
                    delay_start_r <= 1;
                    state_r <= S_CARRIER_OFF;
                end
                byte_counter_r <= byte_counter_r + 1;
            end
            S_CARRIER_OFF: begin
                // A duration of zero never raises busy, so waiting for the
                // timer here would hang. Skip straight on instead.
                if (|delay_on_off_r == 0) begin
                    delay_start_r <= 0;
                    state_r <= S_PREPARE_NEXT_CYCLE;
                end else begin
                    if (delay_start_r & delay_busy_in) begin
                        delay_start_r <= 0;
                    end
                    if (!delay_start_r & !delay_busy_in) begin
                        state_r <= S_PREPARE_NEXT_CYCLE;
                    end
                end
            end
            S_PREPARE_NEXT_CYCLE: begin
                if (chirps_counter_r == 0) begin
                    // A record ends one byte after the last index byte actually
                    // fetched -- there is no length field anywhere.
                    header_chirps_address_r <= index_byte_address_r + 1;
                    byte_counter_r <= HEADER_BYTES - 1;
                    state_r <= S_READ_HEADER;
                end else begin
                    chirps_counter_r <= chirps_counter_r - 1;
                    index_bit_offset_r <= index_bit_offset_r + index_bit_delta;
                    if (read_next_index_byte) begin
                        index_byte_address_r <= index_byte_address_r + 1;
                        state_r <= S_READ_INDEX;
                    end else begin
                        state_r <= S_READ_CARRIER_ON_TIME;
                    end
                end
            end
            S_FAIL: begin
            end
        endcase
    end
end

// combinatorial logic, mux for address out
always @(*) begin
    case (state_r) 
        S_READ_HEADER, S_CHECK_HEADER: begin mem_address_out = header_chirps_address_r; end
        S_READ_INDEX: begin mem_address_out = index_byte_address_r; end
        // pair-table entry i lives at base + 3 + i*4; header_chirps_address_r is
        // already base+3 here, and byte_counter_r supplies the byte within the entry
        S_READ_CARRIER_ON_TIME, S_READ_CARRIER_OFF_TIME: begin mem_address_out = header_chirps_address_r + { {(ADDRESS_BITS-1-6){1'b0}}, chirp_pair_index[3:0], byte_counter_r[1:0]}; end
        default: begin mem_address_out = 0; end
    endcase
end

assign fail_out = (state_r == S_FAIL);

assign busy_out = (state_r != S_IDLE);

assign delay_enable_out = (state_r == S_CARRIER_ON) || (state_r == S_CARRIER_OFF);
assign delay_start_strobe_out = delay_start_r;
assign delay_value_out = delay_on_off_r;

assign ctc_enable_out = (frequency != 0) && (state_r == S_CARRIER_ON);
assign ctc_forced_out = (frequency == 0) && (state_r == S_CARRIER_ON);
assign ctc_value_out = frequency;
assign ctc_wr_strobe_out = (state_r == S_READ_INDEX);

endmodule
