/*
 * Copyright (c) 2025 Embelon
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module controller 
#(
    parameter ADDRESS_BITS = 14,
    parameter UNIT_COUNTS_US = 10,
    parameter CLK_MHZ = 8
)
(
    input   bit  clock_in,      // clock

    input   bit  reset_in,      // resets internal counter (synchronous)
    input   bit  startn_in,     // starts working when high (synchroous)

    // memory interface
    input   bit [7:0] data_in,
    output  bit [ADDRESS_BITS-1:0] address_out,

    output  bit pwm_out,        // pwm output

    output  bit  busy_out,      // still working when high
    output  bit  fail_out       // failure when high
);

localparam HEADER_BYTES = 3;
localparam HEADER_FREQUENCY_INDEX = 2;
localparam HEADER_CHIRPS_INDEX = 1;
localparam HEADER_COMPRESSION_INDEX = 0;
localparam TIMING_BYTES = 2;

typedef enum {S_RESET, S_IDLE, S_FAIL, S_READ_HEADER, S_READ_INDEX, S_READ_CARRIER_ON, S_CARRIER_ON, S_READ_CARRIER_OFF, S_CARRIER_OFF} e_state;
e_state state_r;

// header array
reg [7:0] header_r [HEADER_BYTES-1:0];

// individual components of header
wire [7:0] frequency;
wire [7:0] chirps_num;
wire [4:0] delays_num;
wire [4:0] words_num;
wire [2:0] index_bits_num;

assign frequency = header_r[HEADER_FREQUENCY_INDEX];
assign chirps_num = header_r[HEADER_CHIRPS_INDEX];
assign words_num = header_r[HEADER_COMPRESSION_INDEX][7:3];
assign index_bits_num = header_r[HEADER_COMPRESSION_INDEX][2:0];
/*
// function to reset header array
function automatic reset_header;
inout bit[7:0] array [HEADER_BYTES-1:0];
integer i;
begin
    for (i = 0; i < HEADER_BYTES; i = i + 1) begin
        array[i][7:0] = 8'h00;
    end  
end
endfunction
*/
reg [1:0] byte_counter_r;

// general address (header & chirp indexes)
reg [ADDRESS_BITS-1:0] gen_address_r;

// delay table address (on and off timings)
reg [ADDRESS_BITS-1:0] timing_address_r;

reg [7:0] index_byte_r;
reg [2:0] index_offset_r;
reg [1:0] index_rem_bits_r;

wire [2:0] delay_index;
reg [15:0] delay_on_off_r;

// getting index of current delay pair
always @(*) begin
    case (index_bits_num) 
        4: begin
            case (index_offset_r) 
                0:  begin delay_index <= index_byte_r[7:4]; end
                4:  begin delay_index <= index_byte_r[3:0]; end
            endcase
        end
        3: begin
            case (index_offset_r)
                0:  begin delay_index <= index_byte_r[7:5]; end
                1:  begin delay_index <= index_byte_r[6:4]; end
                2:  begin delay_index <= index_byte_r[5:3]; end
                3:  begin delay_index <= index_byte_r[4:2]; end
                4:  begin delay_index <= index_byte_r[3:1]; end
                5:  begin delay_index <= index_byte_r[2:0]; end
                6:  begin delay_index <= {index_rem_bits_r[0], index_byte_r[6:5]}; end
                7:  begin delay_index <= {index_rem_bits_r[1:0], index_byte_r[5]}; end
            endcase
        end
        2: begin
            case (index_offset_r) 
                0:  begin delay_index <= index_byte_r[7:6]; end
                2:  begin delay_index <= index_byte_r[5:4]; end
                4:  begin delay_index <= index_byte_r[3:2]; end
                6:  begin delay_index <= index_byte_r[1:0]; end
            endcase
        end
    endcase
end

wire enable_pwm_out;
wire update_pwm_value;

pwm_generator pwm(
    .clock_in(clock_in),            // clock

    .reset_in(reset_in),            // resets counter and output when driven high (synchronous)
    .enable_in(enable_pwm_out),     // PWM generated when high

    .compare_value_in(frequency),   // PWM period in counts
    .update_comp_value_in(update_pwm_value),          // write enable, active high (synchronous)

    .pwm_out(pwm_out)               // PWM output
);

wire enable_delay;
wire update_delay_value;
wire delay_active;

delay_timer timer(
    .clock_in(clock_in),            // clock

    .reset_in(reset_in),            // resets internal counter (synchronous)
    .enable_in(enable_delay),       // working when high

    .delay_in(delay_on_off_r),              // delay in number of units
    .update_delay_in(update_delay_value),   // write enable, active high (synchronous)

    .busy_out(delay_active)         // delay still not reached if high
);

always @(posedge clock_in) begin
    if (reset_in) begin
        state_r <= S_RESET;
        gen_address_r <= 0;
        timing_address_r <= 0;
        byte_counter_r <= HEADER_BYTES - 1;
        index_byte_r <= 0;
        // reset_header(header_r);
    end else begin
        case (state_r)
            S_RESET: begin
                state_r <= S_IDLE;
                gen_address_r <= 0;
                timing_address_r <= 0;
                byte_counter_r <= HEADER_BYTES - 1;
                index_byte_r <= 0;
                // reset_header(header_r);
            end
            S_IDLE: begin
                if (!startn_in) begin
                    state_r <= S_READ_HEADER;
                    gen_address_r <= 0;
                    timing_address_r <= 0;
                    byte_counter_r <= HEADER_BYTES - 1;
                    index_byte_r <= 0;
                    // reset_header(header_r);
                end
            end
            S_FAIL: begin
                if (!startn_in || reset_in) begin
                    // TODO: add some delay here
                    state_r <= S_IDLE;
                end
            end
            S_READ_HEADER: begin
                header_r[gen_address_r] <= data_in;
                if (byte_counter_r == 0) begin
                    byte_counter_r <= 0;
                    // first delay value
                    timing_address_r <= gen_address_r + 1;
                    // first byte with indexes
                    gen_address_r <= gen_address_r + 1 + {2'b00, data_in[7:3], 0};
                    index_offset_r <= 0;
                    state_r <= S_READ_INDEX;
                end else begin
                    byte_counter_r = byte_counter_r - 1;
                    gen_address_r <= gen_address_r + 1;
                end
            end
            S_READ_INDEX: begin
                index_byte_r <= data_in;
                byte_counter_r <= TIMING_BYTES - 1;
                // TODO:  
            end
            S_READ_CARRIER_ON: begin
                if (byte_counter_r == 0) begin
                    // TODO: check byte order
                    delay_on_off_r[7:0] <= data_in;
                    state_r <= S_CARRIER_ON;
                end else begin
                    // TODO: check byte order
                    delay_on_off_r[15:8] <= data_in;
                    byte_counter_r <= byte_counter_r - 1;
                end
            end
            S_CARRIER_ON: begin
                if (!delay_active) begin
                    byte_counter_r <= TIMING_BYTES - 1;
                    state_r <= S_READ_CARRIER_OFF;
                end
            end
            S_READ_CARRIER_OFF: begin
                if (byte_counter_r == 0) begin
                    delay_on_off_r[7:0] <= data_in;
                    state_r <= S_CARRIER_OFF;
                end else begin
                    delay_on_off_r[15:8] <= data_in;
                    byte_counter_r <= byte_counter_r - 1;
                end
            end
            S_CARRIER_OFF: begin
                if (!delay_active) begin
                    state_r <= S_READ_INDEX;
                    // TODO: advance index bits
                    index_offset_r <= index_offset_r + 3;  
                end
            end
        endcase
    end
end

always @(*) begin
    if (state_r == S_READ_CARRIER_ON) begin
        address_out <= timing_address_r + {delay_index, 0, byte_counter_r[0]};
    end else if (state_r == S_CARRIER_OFF) begin
        address_out <= timing_address_r + {delay_index, 1, byte_counter_r[0]};
    end else begin
        address_out <= gen_address_r;
    end
end

assign update_pwm_value = (state_r == S_READ_CARRIER_ON) && (byte_counter_r == 0);
assign enable_pwm_out = (state_r == S_CARRIER_ON) && (frequency != 0);

assign update_delay_value = ((state_r == S_READ_CARRIER_ON) || (state_r == S_READ_CARRIER_OFF)) 
                            && (byte_counter_r == 0);
assign enable_delay = (state_r == S_CARRIER_ON) || (state_r == S_CARRIER_OFF);

assign busy_out = (state_r != S_IDLE);

assign fail_out = (state_r == S_FAIL);

endmodule
