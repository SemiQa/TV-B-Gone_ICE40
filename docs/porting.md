# Porting

What is tied to this board, what is tied to this clock, and what has to change to
run the design somewhere else.

- [What is portable](#what-is-portable)
- [Writing a new board wrapper](#writing-a-new-board-wrapper)
- [Changing the clock](#changing-the-clock)
- [Changing the code table](#changing-the-code-table)
- [Memory on the iCE40](#memory-on-the-ice40)
- [Toward an ASIC](#toward-an-asic)

## What is portable

Every vendor primitive, pin name and board polarity in the project sits in
`pico-ice/pico_ice.sv`. The core below it — `tv_b_gone` and the five modules it
instantiates — contains none.

That puts the boundary at seven ports:

| Port | Dir | What the wrapper supplies |
| --- | --- | --- |
| `clock_in` | in | A free-running clock. |
| `reset_in` | in | High for long enough after power-up for the clock to settle. |
| `start_in` | in | Active high. Debouncing happens inside the core. |
| `loop_forever_in` | in | Active high level, sampled when idle. |
| `busy_out` | out | Drive an LED, or leave unconnected. |
| `fail_out` | out | Drive an LED, or leave unconnected. |
| `ctc_out` | out | Drives the IR LED, directly or through a driver. |

Two things cross that boundary without appearing in the port list: the `CLK_MHZ`
parameters, and the code table's dependence on the same clock. Both are covered
below.

## Writing a new board wrapper

A replacement for `pico_ice.sv` needs to do four things.

**Provide a clock.** The existing wrapper uses the iCE40's `SB_HFOSC` at 24 MHz
and divides it down. Any source works — an external oscillator, a PLL, a
divided system clock.

**Provide a reset.** The existing wrapper counts a 16-bit register up to
all-ones and releases reset after 65536 clocks. That counter starts from zero
because the FPGA bitstream initialises it. A target that does not guarantee that
power-up value needs its reset from elsewhere.

**Match the polarities.** The Pico-ICE button pulls low when pressed, so the
wrapper passes `!button_in`. A board with an active-high button passes the signal
straight through.

**Route the output.** `ctc_out` is a plain logic output. The existing wrapper also
emits its inverse on a second pin so either polarity of LED driver can be used;
a new wrapper can emit one, both, or neither.

## Changing the clock

Two parameters carry the clock rate into the design:

| Module | Parameter | Used for |
| --- | --- | --- |
| `delay_timer` | `CLK_MHZ` | Clocks per 10 µs unit: `CLK_MHZ × UNIT_COUNTS_US` |
| `btn_debouncer` | `CLK_MHZ` | Clocks per sample: `CLK_MHZ × PERIOD_MS × 1000` |

Both default to 8. Setting them correctly keeps burst durations and the button
sampling rate right at a new frequency.

**The code table is the harder half.** Header byte 0 of every record holds a
counter compare value, not a frequency in Hz, and the carrier that results is

```
carrier Hz = f_clk / (2 × (frequency + 1))
```

At 8 MHz a stored 103 gives 38.5 kHz. At 12 MHz the same byte gives 57.7 kHz, and
a receiver tuned to 38 kHz responds to it weakly or not at all. Running at a
different clock means regenerating the tables with compare values computed for it.

[`tools/gen_rom.py`](../tools/gen_rom.py) regenerates them from the upstream
code tables for any clock:

```console
$ python tools/gen_rom.py --clock-hz 12000000 --out-dir tmp/
```

A compare value that no longer fits a byte stops it with an error.

Keeping the existing 8 MHz core clock and dividing a faster board clock down to it
avoids the whole question.

## Changing the code table

`tv_codes_rom` takes the table as parameters:

| File | Bytes | `SIZE` | Address bits |
| --- | --- | --- | --- |
| `rom/eu_tv_codes_rom.mif` | 4739 | 4740 | 13 |
| `rom/na_tv_codes_rom.mif` | 5314 | 5320 | 13 |
| `rom/tv_codes_rom.mif` | 8269 | 8272 | 14 |

Set `INIT_FILE` and `SIZE` together, with `SIZE` at or above the file length.
`ADDRESS_BITS` follows from `$clog2(SIZE)`.

Both regional tables fit 13 address bits. The combined table crosses into 14, and
`tv_b_gone` currently declares its ROM address as a fixed 13-bit wire, so building
the combined table means widening that and passing the width down to `controller`.

Any regenerated table can be checked against the controller's own rules before it
is built:

```console
$ python tools/walk_rom.py rom/my_table.mif
```

## Memory on the iCE40

The UP5K offers two kinds of memory, and the choice is already made by how the ROM
is read rather than by any parameter.

| | EBR | SPRAM |
| --- | --- | --- |
| Size | 4 kbit per block, 30 blocks | 256 kbit per block, 4 blocks |
| Width | configurable, 512 × 8 among them | fixed 16 bits |
| Initial contents | loaded from the bitstream | **none** |
| Read port | synchronous | synchronous |

`tv_codes_rom` reads combinationally. Block RAM on this family has a registered
read port, and yosys maps only synchronous reads into it — a combinational read
becomes ordinary LUT logic instead. Registering the read moves the table into EBR
at roughly 10 blocks for the EU table, 11 for NA and 17 for the combined one, out
of 30, and costs one wait cycle per ROM access.

SPRAM is far larger but takes no initial contents at all, so it cannot hold a code
table without separate storage and a loader to copy it in.

## Toward an ASIC

The core is already free of vendor primitives, so the wrapper is the only file
that has to go. Four things need attention beyond that.

**The table.** `$readmemh` fills an array at elaboration, which suits an FPGA
bitstream. An ASIC flow needs the same data as a ROM macro, or synthesised into
logic.

**The reset.** The wrapper's counter relies on registers powering up at zero. A
flow that does not guarantee power-up state needs an external reset.

**The clock.** `SB_HFOSC` is an iCE40 primitive. An ASIC needs an external clock
or an on-chip oscillator of its own.

**The read style.** A combinational ROM read, which costs area on this FPGA,
hardens into logic and wiring with no flip-flops in the read path — closer to what
a mask-programmed array wants.

Area is dominated by the table, which is why the code set ships split by region:
building the EU or NA table alone rather than the combined one removes roughly
40 % of it.

The core has been fabricated this way on Tiny Tapeout SKY 25a, with the European
table, in two versions:

| Project | ROM | Source |
| --- | --- | --- |
| [TV-B-Gone-EU](https://tinytapeout.com/chips/ttsky25a/tt_um_tv_b_gone) | synthesised as written | [SemiQa/ttsky25a-tv-b-gone-eu](https://github.com/SemiQa/ttsky25a-tv-b-gone-eu) |
| [TV-B-Gone-EU, ROM macro variant](https://tinytapeout.com/chips/ttsky25a/tt_um_tv_b_gone_rom) | optimised ROM | [smunaut/ttsky25a-tv-b-gone-eu](https://github.com/smunaut/ttsky25a-tv-b-gone-eu) |

Both take an 8 MHz clock from the demo board's RP2040, and drive their status
outputs active low, as `ACTIVE_LED_N` and `FAILURE_LED_N`. The [IR
PMOD](https://github.com/flummer/tt-ir-pmod) in [hardware.md](hardware.md) was
designed for these chips, which is why its status LEDs light on a low level.

---

**Previous:** [avr-comparison.md](avr-comparison.md) · **Unfamiliar term?**
[glossary.md](glossary.md)

**Why it is built this way:** [adr.md](adr.md) records the design decisions.
