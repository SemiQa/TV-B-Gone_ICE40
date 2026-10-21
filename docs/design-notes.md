# Design notes

Short answers to "why is it done that way?", for readers using this project to
learn how RTL gets written rather than only what it does.

- [Why there is no processor](#why-there-is-no-processor)
- [Why the ROM read matters more than it looks](#why-the-rom-read-matters-more-than-it-looks)
- [Why durations are counted in 10 µs units](#why-durations-are-counted-in-10-µs-units)
- [Why the table stores a compare value](#why-the-table-stores-a-compare-value)
- [Why the debouncer produces a pulse](#why-the-debouncer-produces-a-pulse)
- [Why every file disables implicit nets](#why-every-file-disables-implicit-nets)
- [Naming, and types](#naming-and-types)
- [Reading a state machine out of the RTL](#reading-a-state-machine-out-of-the-rtl)

## Why there is no processor

The obvious way to move firmware onto an FPGA is to put a small processor on the
chip and run the firmware on it. That works, and it would be larger and slower
than what is here.

The gadget does one fixed job: walk a table, wait, toggle a pin. It never branches
on anything a person does, never computes anything, and never needs to run
different code tomorrow. A processor buys flexibility this problem does not use,
and charges for it in area — a soft core plus its memory dwarfs twelve states and
three counters.

The trade is that changing the behaviour means changing hardware rather than
recompiling. For a design whose behaviour is fixed by an IR standard, that costs
nothing.

## Why the ROM read matters more than it looks

`tv_codes_rom` reads combinationally: `data` follows `address` within the cycle.
It is the simplest thing to write, it makes the controller simpler too — every
read is one cycle, with no latency to track — and on an FPGA it has a consequence
that is easy to miss.

iCE40 block RAM has a **registered** read port: an address presented now yields
data after the next clock edge. A memory whose read is asynchronous therefore
cannot be block RAM, and synthesis builds it from ordinary logic instead.

The arithmetic is worth doing. The European table is 4739 bytes, or 37 912 bits.
A UP5K has 5280 four-input LUTs, each holding 16 bits of configuration — 84 480
bits in total, before any is spent on address decoding or on the rest of the
design. As block RAM the same table needs about ten of the device's thirty EBRs.

Registering the read would cost one wait cycle per access. A chirp involves
roughly five reads, so about five extra clocks against a chirp lasting hundreds of
microseconds — under a tenth of a percent, and those clocks fall in the gaps
between bursts rather than inside them.

The asynchronous form is not simply worse. Hardened into an ASIC the same
description becomes a combinational array — logic and wires, no flip-flops in the
read path — which is what a mask-programmed ROM wants to be. The two targets pull
in opposite directions, which is why the choice is worth understanding rather than
copying.

SPRAM, the UP5K's larger memory, is no alternative for a table: it holds far more,
but it cannot be given initial contents at configuration, so there would be
nothing in it at power-up.

## Why durations are counted in 10 µs units

A burst can be 430 µs and the gap between transmissions 83 ms. At 8 MHz those are
3440 and 665 920 clocks — the second needs 20 bits, and every duration in the
table would have to be that wide.

Counting in 10 µs units puts every duration in 16 bits with room to spare, and
halves the size of the pair table. The cost is a prescaler: one small counter,
shared by every delay in the design.

Ten microseconds is also the unit the original AVR firmware used, so the numbers
in the table are unchanged from the source data. Nothing had to be rescaled, and
nothing can be rescaled wrongly.

## Why the table stores a compare value

A code's carrier is around 38 kHz, and the natural way to write that down is
38000. The hardware would then have to divide the clock by that number to get a
period, and dividers are expensive.

The table stores what the counter actually needs — the number to count to — so the
byte goes straight into a register and no arithmetic happens at run time. The
conversion is done once, offline, by the tool that generates the table.

The price is that the table is tied to a clock rate. At 8 MHz a stored 103 means
38.46 kHz; at any other clock it means something else. That makes the code table
and `CLK_MHZ` a matched pair, and it is the first thing to check when moving the
design to different hardware.

## Why the debouncer produces a pulse

A button held down is a level, and the controller starts a run whenever it sees
`start_in` high in its idle state. If `start_in` were simply the button, holding
it would start a run — and the moment that run finished, the machine would return
to idle, see the button still down, and start another.

So the debouncer emits a pulse: high once when a press is confirmed, then low
again even though the button is still held. Its three-sample shift register
detects the *edge* — low, then two consecutive highs — rather than the level.

The pulse lasts one sample period, about 10 ms. Far longer than a clock, so it
cannot be missed; far shorter than a run, so it cannot be seen twice.

## Why every file disables implicit nets

By default, Verilog invents a one-bit wire for any undeclared name. A typo in a
signal name silently becomes a new wire that nothing drives, and the design
synthesises with a hole in it rather than failing to compile.

Every file here starts with a directive that switches that off, so a misspelled
signal is an error. It costs one line per file and removes a class of bug that is
otherwise found on hardware.

## Naming, and types

Ports carry a direction suffix — `clock_in`, `busy_out` — so a signal's role is
readable where it is used, not only where it is declared.

Registers carry `_r`. Seeing `counter_r` in an expression tells you it holds a
value from the previous clock edge, which is what you need when reasoning about
timing.

The types are mixed for reasons more historical than technical. `bit` is a
SystemVerilog two-state type, used here on ports and wires; `reg` is the older
keyword, used for storage. Neither makes something a flip-flop. What decides that
is whether a signal is assigned inside a clocked block — a `reg` assigned in an
`always @(*)` block is combinational logic, which is exactly what
`chirp_pair_3b_index` is.

## Reading a state machine out of the RTL

The controller is written as three separate pieces, and recognising the pattern
makes any similar design readable.

The **clocked block**, `always @(posedge clock_in)`, holds the state register and
every other register. It is the only place `state_r` is assigned, so it alone
decides what happens next.

The **combinational block**, `always @(*)`, computes the ROM address from the
current state. It holds no memory; it is a mux, written as a `case`.

The **continuous assignments** at the end decode outputs directly from the state:
`busy_out` is `state_r != S_IDLE`, and the carrier and timer enables are
comparisons against particular states. Nothing there can add a cycle of delay,
which is why the outputs in the per-state table line up with the states exactly
rather than lagging them.

Read in that order — what state comes next, what address this state drives, what
outputs this state asserts — and the twelve-state `case` stops being a wall of
code.

---

**Previous:** [architecture.md](architecture.md) · **Unfamiliar term?**
[glossary.md](glossary.md)

**Why it is built this way:** [adr.md](adr.md) records the design decisions.
