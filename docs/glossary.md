# Glossary

Terms used across this documentation, with the meaning they carry *here*. Several
are ordinary words in hardware or infrared work that this project uses in a
specific way; those say so.

The list grows as pages are added.

| Term | Meaning |
| --- | --- |
| **AGC** | Automatic gain control. Circuitry in an IR receiver that adapts to signal strength. The long leading burst of a code exists to give it time to settle. |
| **bitstream** | The configuration data loaded into an FPGA to make it behave as the design describes. Produced by `icepack`, loaded over DFU. Held in `bitstreams/` as `.bin`. |
| **burst** | A period during which the IR LED is driven with the carrier. Also called a *mark*. |
| **carrier** | The rapid on/off switching of the IR LED, between 30 and 60 kHz and most often near 38 kHz, that lets a receiver pick the signal out of ambient infrared. See [ir-primer.md](ir-primer.md). |
| **chirp** | One on-burst plus the gap that follows it. A code is a list of chirps; the header field `chirps_num` counts them. |
| **code** | One complete command for one television: a carrier value plus its list of chirps. Stored as one *record*. |
| **compare value** | The number the carrier counter counts up to before toggling its output. The ROM stores this rather than a frequency, so no divider is needed in hardware. Called `frequency` in the header and `ocr_r` in the RTL. |
| **CTC** | Clear Timer on Compare, an AVR timer mode in which a counter resets on reaching a compare value. `ctc_generator` is named after it and behaves the same way. |
| **debounce** | Filtering the contact bounce of a mechanical switch, so one press produces one event. Done by `btn_debouncer`. |
| **DFU** | Device Firmware Upgrade, the USB protocol used to load a bitstream onto the board. |
| **EBR** | Embedded Block RAM, the iCE40's dedicated memory blocks: 4 kbit each, 30 on the UP5K, loadable with initial contents from the bitstream. Its read port is synchronous. |
| **envelope** | The pattern of carrier on and off periods that encodes a command. What a receiver hands its decoder once the carrier is stripped off. |
| **FSM** | Finite state machine: logic that holds a state and moves between states on defined conditions. The controller is one. |
| **gap** | A period during which the IR LED is off. Also called a *space*. |
| **iCE40 UP5K** | The Lattice FPGA this project targets. 5280 4-input LUTs, 30 EBRs, four SPRAM blocks. |
| **index** | A packed 2-, 3- or 4-bit number selecting which pair-table entry a chirp uses. See [rom-format.md](rom-format.md). |
| **leader** | The long opening burst of a code, sent before any data so the receiver's AGC can settle. |
| **LUT** | Look-up table, the basic logic element of an FPGA. An iCE40 LUT has four inputs and 16 bits of configuration, so it can implement any 4-input function. |
| **mark** | See *burst*. |
| **MIF** | Memory initialisation file. In this project a `.mif` is plain whitespace-separated hex bytes, one per ROM address, read by `$readmemh`. |
| **pair table** | The per-record list of distinct on/off duration pairs a code uses. Chirps refer to its entries by index rather than repeating durations. |
| **PCF** | Physical constraints file: maps the top-level port names of a design onto numbered pins of the package. |
| **place and route** | The stage that assigns each cell of a synthesised netlist to a physical location on the chip and connects them. Done by `nextpnr-ice40`. |
| **prescaler** | A counter that divides a fast clock down to a slower tick. `delay_timer` uses one to produce a 10 µs tick from the core clock. |
| **$readmemh** | A SystemVerilog system task that fills a memory array from a text file of hexadecimal values. How the code table gets into the ROM. |
| **record** | The stored form of one code: a 3-byte header, a pair table, and packed index bytes, laid out end to end. |
| **RTL** | Register transfer level: describing hardware as registers and the logic between them, rather than as gates. The style of the `.sv` files here. |
| **space** | See *gap*. |
| **SPRAM** | Single-port RAM on the UP5K: four blocks of 256 kbit, 16 bits wide. Much larger than EBR, but it cannot be given initial contents, so it cannot hold a ROM. |
| **synthesis** | The stage that translates RTL into a netlist of primitives the target device actually has. Done by `yosys`. |
| **terminator** | The all-zero header that ends a code table. Reaching it stops playback. |
| **unit, 10 µs** | The unit in which the pair table stores durations. A value of 43 means 430 µs. |
