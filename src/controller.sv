/*
 * Copyright (c) 2025 Embelon
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module controller 
#(
    parameter ADDRESS_BITS = 13,
    parameter UNIT_COUNTS_US = 10,
    parameter CLK_MHZ = 8,
    parameter DELAY_BITS = 16,
    parameter PWM_BITS = 8
)
(
    input   bit  clock_in,      // clock

    input   bit  reset_in,      // resets internal counter (synchronous)

    input   bit  start_in,      // starts working when high (synchroous)
    output  bit  busy_out,      // still working when high
    output  bit  fail_out,      // failure when high

    // memory interface
    output  bit [ADDRESS_BITS-1:0] mem_address_out,
    input   bit [7:0] mem_data_in,
    
    // PWM generator interface
    output  bit pwm_enable_out,
    output  bit pwm_forced_out,
    output  bit pwm_wr_strobe_out,
    output  bit [PWM_BITS-1:0] pwm_value_out,
    input   bit pwm_wr_ack_in,

    // delay interface
    output  bit delay_enable_out,
    output  reg delay_start_strobe_out,
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
reg [7:0] header_r [HEADER_BYTES-1:0];

// individual components of header
wire [7:0] frequency;
wire [7:0] chirps_num;
wire [3:0] pair_num;
wire [2:0] index_bits_num;

assign frequency = header_r[HEADER_FREQUENCY_INDEX];
assign chirps_num = header_r[HEADER_CHIRPS_INDEX];
assign pair_num = header_r[HEADER_PAIRNUM_COMPRESSION_INDEX][7:4];
assign index_bits_num = header_r[HEADER_PAIRNUM_COMPRESSION_INDEX][2:0];


localparam TIMING_BYTES = 4;

localparam MAX_INDEX_BITS = 3;

typedef enum {
    S_RESET, 
    S_IDLE, 
    S_READ_HEADER, 
    S_READ_INDEX, 
    S_READ_CARRIER_ON_TIME, 
    S_CARRIER_ON, 
    S_READ_CARRIER_OFF_TIME, 
    S_CARRIER_OFF, 
    S_PREPARE_NEXT_CYCLE,
    S_FAIL
} e_state;
e_state state_r;


// stores header address or chirps pairs array starting address
reg [ADDRESS_BITS-1:0] header_chirps_address_r;
// stores index address -> it's byte address of index + additional bits (index is 2 or 3 bit wide)
reg [ADDRESS_BITS+MAX_INDEX_BITS-1:0] index_extended_bit_address_r;

wire [MAX_INDEX_BITS-1:0] index_bit_group_offset;
assign index_bit_group_offset = index_extended_bit_address_r[MAX_INDEX_BITS-1:0];

wire [ADDRESS_BITS-1:0] index_byte_address;
assign index_byte_address = index_extended_bit_address_r[ADDRESS_BITS-1:MAX_INDEX_BITS];

reg [7:0] index_byte_n0_r;
reg [7:0] index_byte_n1_r;

wire [MAX_INDEX_BITS-1:0] chirp_pair_index;
wire read_next_index_byte;
wire [MAX_INDEX_BITS-1:0] chirp_delta;
// getting index of current delay pair
always @(*) begin
    case (index_bits_num) 
        4: begin
            case (index_bit_group_offset[MAX_INDEX_BITS-1]) 
                0:  begin chirp_pair_index <= index_byte_n0_r[7:4]; read_next_index_byte = 0; end
                1:  begin chirp_pair_index <= index_byte_n0_r[3:0]; read_next_index_byte = 1; end
            endcase
            chirp_delta <= 3'b100;
        end
        3: begin
            case (index_bit_group_offset[MAX_INDEX_BITS-1:0])
                0:  begin chirp_pair_index <= index_byte_n0_r[7:5]; read_next_index_byte = 0; end
                1:  begin chirp_pair_index <= index_byte_n0_r[4:2]; read_next_index_byte = 1; end
                2:  begin chirp_pair_index <= {index_byte_n0_r[1:0], index_byte_n1_r[7]}; read_next_index_byte = 0; end
                3:  begin chirp_pair_index <= index_byte_n0_r[6:4]; read_next_index_byte = 0; end
                4:  begin chirp_pair_index <= index_byte_n0_r[3:1]; read_next_index_byte = 1; end
                5:  begin chirp_pair_index <= {index_byte_n0_r[0], index_byte_n1_r[7:6]}; read_next_index_byte = 0; end
                6:  begin chirp_pair_index <= index_byte_n0_r[5:3]; read_next_index_byte = 0; end
                7:  begin chirp_pair_index <= index_byte_n0_r[2:0]; read_next_index_byte = 0; end
            endcase
            chirp_delta <= 3'b001;
        end
        2: begin
            case (index_bit_group_offset[MAX_INDEX_BITS-1:1]) 
                0:  begin chirp_pair_index <= index_byte_n0_r[7:6]; read_next_index_byte = 0; end
                1:  begin chirp_pair_index <= index_byte_n0_r[5:4]; read_next_index_byte = 0; end
                2:  begin chirp_pair_index <= index_byte_n0_r[3:2]; read_next_index_byte = 0; end
                3:  begin chirp_pair_index <= index_byte_n0_r[1:0]; read_next_index_byte = 1; end
            endcase
            chirp_delta <= 3'b010;
        end
        default: begin
            // TODO: failure!
        end
    endcase
end

// wire [HEADER_BYTES-1:0] header_byte_offset;
// assign header_byte_offset = header_chirps_address_r[HEADER_BYTES-1:0];

// TODO: add constants
reg [3:0] byte_counter_r;
reg [7:0] chirps_counter_r;

// this is 16 bit delay / time for carrier on or off, depending on state
reg [DELAY_BITS-1:0] delay_on_off_r;

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
                index_extended_bit_address_r <= 0;
                index_byte_n0_r <= 0;
                index_byte_n1_r <= 0;
                byte_counter_r <= 0;
                chirps_counter_r <= 0;
                delay_on_off_r <= 0;
                delay_start_strobe_out <= 0;
                state_r <= S_IDLE;
            end
            S_IDLE: begin
                if (start_in) begin
                    state_r <= S_READ_HEADER;
                    byte_counter_r <= HEADER_BYTES - 1;
                end
            end
            S_READ_HEADER: begin
                header_r[byte_counter_r] <= mem_data_in;
                if (byte_counter_r == 0) begin
                    if ((header_r[2] | header_r[1]) == 8'h00) begin
                        state_r <= S_RESET;
                    end else begin
                        index_extended_bit_address_r <= {header_chirps_address_r + 1 + {pair_num, 2'b00}, 3'b000};
                        chirps_counter_r <= chirps_num - 1;
                        header_chirps_address_r = header_chirps_address_r + 1;
                        state_r <= S_READ_INDEX;
                    end
                end else begin
                    header_chirps_address_r = header_chirps_address_r + 1;
                    byte_counter_r = byte_counter_r - 1;
                end
            end
            S_READ_INDEX: begin

                if (0) begin
                    index_byte_n0_r <= index_byte_n1_r;
                end else begin
                    index_byte_n0_r <= mem_data_in;
                    chirps_counter_r <= chirps_counter_r - 1;
                    byte_counter_r <= 0;
                    state_r <= S_READ_CARRIER_ON_TIME;
                end
                
                // TODO:  
            end
            S_READ_CARRIER_ON_TIME: begin
                if (byte_counter_r == 0) begin
                    delay_on_off_r[7:0] <= mem_data_in;
                end else begin
                    // byte_counter_r == 1
                    delay_on_off_r[15:8] <= mem_data_in;
                    delay_start_strobe_out <= 1;
                    state_r <= S_CARRIER_ON;
                end
                byte_counter_r <= byte_counter_r + 1;
            end
            S_CARRIER_ON: begin
                if (delay_start_strobe_out & delay_busy_in) begin
                    delay_start_strobe_out <= 0;
                end
                if (!delay_start_strobe_out & !delay_busy_in) begin
                    state_r <= S_READ_CARRIER_OFF_TIME;
                end
            end
            S_READ_CARRIER_OFF_TIME: begin
                if (byte_counter_r == 2) begin
                    delay_on_off_r[7:0] <= mem_data_in;
                end else begin
                    delay_on_off_r[15:8] <= mem_data_in;
                    delay_start_strobe_out <= 1;
                    state_r <= S_CARRIER_OFF;
                end
                byte_counter_r <= byte_counter_r + 1;
            end
            S_CARRIER_OFF: begin
                if (delay_start_strobe_out & delay_busy_in) begin
                    delay_start_strobe_out <= 0;
                end
                if (!delay_start_strobe_out & !delay_busy_in) begin
                    state_r <= S_PREPARE_NEXT_CYCLE;
                end
            end
            S_PREPARE_NEXT_CYCLE: begin
                if (chirps_counter_r == 0) begin
                    header_chirps_address_r <= index_byte_address;      // TODO: check if not off-by-one
                    byte_counter_r <= HEADER_BYTES - 1;
                    state_r <= S_READ_HEADER;
                end else begin
                    chirps_counter_r <= chirps_counter_r - 1;
                    index_extended_bit_address_r <= index_extended_bit_address_r + chirp_delta;
                    state_r <= S_READ_INDEX;
                end
            end
            S_FAIL: begin
                if (start_in) begin
                    // TODO: add some delay here before going to RESET and IDLE
                    state_r <= S_RESET;
                end
            end
        endcase
    end
end

assign mem_address_out = (state_r == S_READ_INDEX) ? index_byte_address : (header_chirps_address_r + {chirp_pair_index, 2'b00});

assign fail_out = (state_r == S_FAIL);

assign busy_out = (state_r != S_IDLE);

assign delay_enable_out = (state_r == S_CARRIER_ON) || (state_r == S_CARRIER_OFF);
assign delay_value_out = delay_on_off_r;

assign pwm_enable_out = (frequency != 0) && (state_r == S_CARRIER_ON);
assign pwm_forced_out = (frequency == 0) && (state_r == S_CARRIER_ON);
assign pwm_value_out = frequency;
assign pwm_wr_strobe_out = (state_r == S_READ_INDEX);

endmodule
