# Architecture and Documentation Decision Records

This file collects the decisions behind the project and its documentation, in
[ADR](https://adr.github.io/) style: each record states the context, the
decision, and the consequences, so that a later reader does not have to
reverse-engineer intent from the code.

Two kinds of record are mixed here, and each is tagged:

- **`[DOC]`** — decisions about the documentation itself.
- **`[DESIGN]`** — decisions about the RTL, the data format, or the hardware.
  Several of these were made before this file existed and are **recorded
  retroactively**; where the original reasoning was reconstructed rather than
  stated, the record says so and is tagged **needs confirmation**.

Statuses used: `Accepted`, `Proposed`, `Deferred`, `Superseded`.

| # | Title | Kind | Status |
| --- | --- | --- | --- |
| [ADR-001](#adr-001--split-documentation-into-a-readme-plus-a-docs-directory) | README + `docs/` split | DOC | Accepted |
| [ADR-002](#adr-002--diagram-tooling-mermaid-inline-wavedrom-and-svg-committed) | Diagram tooling | DOC | Accepted |
| [ADR-003](#adr-003--linearise-the-code-table-instead-of-porting-the-pointer-linked-avr-layout) | Linear ROM format | DESIGN | Accepted (retroactive) |
| [ADR-004](#adr-004--ship-three-regional-code-table-variants) | Three ROM variants | DESIGN | Accepted |
| [ADR-005](#adr-005--round-the-rom-size-parameter-up-past-the-terminator) | ROM `SIZE` rounding policy | DESIGN | Accepted |
| [ADR-006](#adr-006--expose-two-anti-phase-ir-outputs-and-use-only-one) | Two anti-phase IR outputs | DESIGN | Accepted |
| [ADR-007](#adr-007--keep-the-avr-comparison-simple) | Scope of the AVR comparison | DOC | Accepted |
| [ADR-008](#adr-008--defer-verification-documentation-until-the-cocotb-testbench-exists) | Defer verification docs | DOC | Accepted |
| [ADR-009](#adr-009--clean-unused-signals-out-of-the-pcf) | Clean up the PCF | DESIGN | Accepted |
| [ADR-010](#adr-010--generate-the-mif-files-with-an-offline-python-converter) | Offline Python ROM generator | DESIGN | Accepted (retroactive) |
| [ADR-011](#adr-011--keep-the-board-wrapper-separate-from-the-portable-core) | Board wrapper / core split | DESIGN | Accepted (retroactive) |
| [ADR-012](#adr-012--asynchronous-rom-read) | Asynchronous ROM read | DESIGN | Accepted (retroactive), extended by ADR-018/ADR-019 |
| [ADR-013](#adr-013--store-the-carrier-compare-value-not-the-frequency) | Store OCR, not Hz | DESIGN | Accepted (retroactive) |
| [ADR-014](#adr-014--time-in-10-µs-units-rather-than-clock-cycles) | 10 µs timing unit | DESIGN | Accepted (retroactive) |
| [ADR-015](#adr-015--document-the-clock-frequency-only-once-it-is-measured) | Clock frequency pending measurement | DOC | Deferred |
| [ADR-016](#adr-016--derive-the-rom-address-width-from-the-selected-table-size) | ROM address width derived from `SIZE` | DESIGN | Accepted, implementation deferred |
| [ADR-017](#adr-017--commit-the-bitstream-so-the-board-can-be-flashed-without-a-toolchain) | Commit the bitstream | DOC | Accepted |
| [ADR-018](#adr-018--register-the-rom-read-port-so-the-code-table-maps-to-ebr) | Registered ROM read, for EBR | DESIGN | **Proposed — parked** |
| [ADR-019](#adr-019--ship-both-rom-styles-async-for-asic-sync-for-fpga) | Both ROM styles, selectable | DESIGN | **Proposed — parked** |
| [ADR-020](#adr-020--comment-only-what-is-not-obvious-in-the-rtl) | RTL comment policy | DOC | Accepted |
| [ADR-021](#adr-021--leave-headroom-in-the-header-bit-fields) | Headroom in the header fields | DESIGN | Accepted |
| [ADR-022](#adr-022--separate-reference-rationale-and-defects) | Reference / rationale / defects split | DOC | Accepted |

---

## ADR-001 — Split documentation into a README plus a `docs/` directory

**Kind:** DOC · **Status:** Accepted · **Date:** 2026-08-17

### Context

The project has to serve two reading modes at once: a newcomer who wants to know
what the gadget is and see it run, and a learner who wants the full mechanism
including the ROM bit-packing and the state machine. Putting all of that in one
README produces a file nobody finishes reading.

### Decision

`README.md` is the entry point and stays at roughly 400–500 lines including
figures: what it is, quick start, one architecture picture, and a map of the
deep dives. Everything else goes into topic pages under `docs/`.

### Consequences

- The README stays readable and can be skimmed on a phone.
- Cross-linking discipline becomes mandatory; a broken relative link is now a
  real defect (added to the review checklist).
- Duplication risk: the same fact can drift between README and a `docs/` page.
  Mitigation — the README states conclusions only and always links to the page
  that owns the detail.
- The README is written **last**, so it summarises material that already exists.

---

## ADR-002 — Diagram tooling: Mermaid inline, WaveDrom and SVG committed

**Kind:** DOC · **Status:** **Accepted** · **Confirmed:** 2026-08-17 (Q-09)

### Context

The documentation needs block diagrams, state machines, sequence diagrams,
timing waveforms, and byte-layout figures. Constraints: it must render on
GitHub without a build step, it must stay editable years later, and it must not
require anyone to install a proprietary drawing tool.

### Options considered

| Option | Renders on GitHub | Editable | Good for |
| --- | --- | --- | --- |
| Mermaid in fenced blocks | yes, natively | yes, it is text | blocks, FSMs, sequences, flows |
| WaveDrom | no | yes, JSON source | digital timing waveforms |
| Hand-authored SVG | yes, as an image | awkward but possible | bit fields, memory maps |
| ASCII art | yes | yes | tiny inline sketches |
| Exported PNG from a GUI tool | yes | no — source is lost | nothing here |

### Decision

- **Mermaid**, inline in the markdown, for block diagrams, state machines,
  sequence diagrams, flowcharts and dependency graphs. No separate `.mmd` files:
  keeping the source in the page is what makes it stay up to date.
- **WaveDrom** for every timing waveform. The JSON source is committed under
  `docs/diagrams/src/`, and the exported SVG under `docs/diagrams/` is what the
  markdown embeds, because GitHub will not render WaveDrom itself.
- **Hand-authored SVG**, committed, for bit-field and memory-map figures where
  precise byte lanes matter and no text-based tool does a good job.
- **ASCII art** only for sketches small enough to sit inside a sentence's worth
  of context.
- **No PNG** for anything generated, so that every figure remains editable.
  Photos and scope captures are the exception.

### Confirmed toolchain

Verified working in this repository on 2026-08-17:

- **Mermaid** — rendered natively by GitHub from fenced ```` ```mermaid ```` blocks.
  No tooling needed.
- **WaveDrom** — `npx -y wavedrom-cli --input X.json --svg X.svg`. Node and npm are
  present; `wavedrom-cli` is fetched on demand by `npx`, so nothing is added to the
  repository. Both diagram modes tested:
  - `signal` — timing waveforms (D02, D22, D25, D27, D29)
  - **`reg` — bit-field and byte-layout diagrams.** This was not in the original
    plan and it covers most of what had been assigned to hand-authored SVG: header
    bit fields (D10), pair-table entries (D11), index packing (D12–D14, using
    multiple lanes for the 3-byte rolling window), and the address-mux bit lanes
    (D07). Output is small — under 2 KB — and text-sourced.

### Consequences

- The residual hand-authored set shrinks to roughly one figure: D34, the IR LED
  drive variants, which is circuit schematics that neither tool expresses.
  Candidate alternative is ASCII art in a code block, which for four small
  transistor circuits is legible and maximally maintainable. Datapath figures
  (D24, D26, D28) and structural comparisons (D17, D33) can be Mermaid — plainer
  than a drawn schematic, but text-sourced and good enough.
- Two files per WaveDrom diagram to keep in sync (JSON source + exported SVG).
  Mitigated by a render script rather than by discipline — see A-16.
- **Dark mode is a confirmed trap, not a theoretical one.** `wavedrom-cli` output
  uses `stroke:#000` with no page-background rect, so on GitHub's dark theme the
  waveform would be black on near-black. Every exported SVG therefore needs a white
  background rect injected. The render script does this; hand-authored SVG must do
  it explicitly.
- Mermaid's layout is automatic, so complex diagrams (D04, D18) may need node
  ordering tweaks to be legible.
- `npx` needs network access on first use, so the render step is not fully offline.
  Acceptable, since the exported SVGs are committed and a reader never re-renders.

---

## ADR-003 — Linearise the code table instead of porting the pointer-linked AVR layout

**Kind:** DESIGN · **Status:** Accepted (recorded retroactively)

### Context

The upstream Adafruit firmware stores each TV code as a C struct in `PROGMEM`
containing a carrier value, counts, and **pointers** to a separate durations
array and a separate bit-packed index array. In C on an AVR that is free —
you dereference a pointer. In RTL there is no dereference: a pointer is another
memory read, and a variable-length structure means the address of every region
has to be computed.

### Decision

Flatten the whole table into a single linear byte stream where each record is

```
header (3 B) · pair table (pairs_num × 4 B) · packed index bytes
```

and records follow one another with no padding, terminated by an all-zero
header. Every region's address is then `base + constant` or
`base + (field << 2)`, computable with one adder.

### Consequences

- The controller needs exactly two address registers
  (`header_chirps_address_r`, `index_byte_address_r`) and an adder, no pointer
  indirection and no second memory port.
- All four read states are single-cycle.
- The format is **generated offline** and is not human-authored, so a converter
  script is now a required build-time artifact (ADR-010).
- The record boundary is implicit: the next record starts one byte after the
  last index byte *that was fetched*. The generator and the RTL therefore have
  to agree exactly on the fetch pattern, including the rule that the final chirp
  does not trigger a fetch. This is the format's sharpest edge and is called out
  in `docs/rom-format.md`.
- Deviating from upstream means the two projects' data files are no longer
  interchangeable, which is the price of the simplification.

---

## ADR-004 — Ship three regional code-table variants

**Kind:** DESIGN · **Status:** Accepted

### Context

The full code table is 8269 bytes. The original gadget has a region switch
(North America / Europe). ROM is the dominant area term in this design, and
there is an intent to fit the core into a small ASIC, where several kilobytes of
ROM is a significant cost.

### Decision

Ship three `.mif` files and select one at build time via the `tv_codes_rom`
parameters:

| File | Bytes | Contents |
| --- | --- | --- |
| `rom/tv_codes_rom.mif` | 8269 | all codes |
| `rom/eu_tv_codes_rom.mif` | 4739 | Europe |
| `rom/na_tv_codes_rom.mif` | 5314 | North America |

The default in `src/tv_codes_rom.sv` is the EU table.

### Consequences

- A build targets one region; there is no runtime region switch, unlike the
  original. That is a deliberate trade of flexibility for area.
- Roughly a 40 % ROM reduction versus the combined table.
- **The combined table does not currently fit the address path.** 8269 bytes
  needs 14 address bits, but `tv_b_gone.sv` hard-codes `wire [12:0] rom_address`
  and `controller` defaults `ADDRESS_BITS = 13` (8192). Resolved in principle by
  ADR-016 — a third build variant with the width derived from the table size —
  with implementation deferred to A-11. Until then, only the EU and NA tables are
  buildable.
- Three data files to regenerate whenever the converter changes.

---

## ADR-005 — Round the ROM `SIZE` parameter up past the terminator

**Kind:** DESIGN · **Status:** Accepted

### Context

`SIZE` sets the depth of `rom_array` and, through `$clog2(SIZE)`, the address
width. The actual data lengths are awkward numbers (4739, 5314, 8269), and the
FSM relies on reaching the all-zero terminator record to stop.

### Decision

Round `SIZE` up to a slightly larger, even value rather than matching the file
length exactly, so that there is no possibility of the array being shorter than
the data and the terminator being clipped. Current values: `4740` for EU,
`5320` for NA.

### Consequences

- A few array entries past the terminator are never written by `$readmemh` and
  are therefore `X` in simulation. They are never read, because the FSM stops at
  the terminator — but if a future change ever walked past it, `X` would
  propagate rather than producing a clean failure.
- The padding is free in terms of address width here: `$clog2(4740)` and
  `$clog2(5320)` are both 13, the same as the exact sizes.
- Agreed refinement (A-05): tighten `5320` → `5316` for NA, which keeps the
  even-number property and the 13-bit address width while shrinking the
  uninitialised tail from 6 bytes to 2. Low risk, to be verified in simulation
  once the testbench exists.
- Worth considering later: have the converter emit an explicit padded tail so
  there are no uninitialised entries at all, at the cost of a slightly larger
  `.mif`.

---

## ADR-006 — Expose two anti-phase IR outputs and use only one

**Kind:** DESIGN · **Status:** Accepted

### Context

The IR LED can be driven in several ways depending on what parts the builder
has: straight off an FPGA pin through a resistor, through an NPN low-side
switch, through a PNP high-side switch, or through a logic buffer or FET
driver. Those want opposite polarities.

### Decision

The wrapper drives two pins, `ir_led_out` and `ir_ledn_out = !ir_led_out`. The
builder connects **exactly one** of them — whichever polarity suits the external
circuit — and leaves the other unconnected.

### Consequences

- One bitstream works with NPN, PNP, buffered and unbuffered drive.
- Costs one extra pin, which this package has to spare.
- This is easy to misread as a differential or bridge drive that doubles the
  voltage across the LED. It is **not**. The documentation must state the
  single-output rule explicitly, and D34 exists specifically to prevent that
  misreading.

---

## ADR-007 — Keep the AVR comparison simple

**Kind:** DOC · **Status:** Accepted

### Context

The project is derived from the Adafruit AVR firmware, and readers arriving from
that project will want to know what changed. A full line-by-line comparison
would be a large document with little teaching value, and it would rot as
upstream changes.

### Decision

`docs/avr-comparison.md` stays a **simple** comparison: a feature/mechanism
table, one data-layout figure (D17), and the three substantive changes
(linearised table, `ctc_generator` in place of the AVR timer, `delay_timer` in
place of the delay loop). No source-level diff.

### Consequences

- Cheap to write and cheap to keep accurate.
- A reader who wants the exact upstream detail is sent to the upstream
  repository rather than served a possibly stale copy.
- The upstream data-structure layout still has to be read from the real source
  before D17 is drawn, not recalled (M-04).

---

## ADR-008 — Defer verification documentation until the cocotb testbench exists

**Kind:** DOC · **Status:** Deferred

### Context

The repository currently has no testbench. A cocotb testbench is planned as the
next piece of work after the documentation.

### Decision

Do not write `docs/verification.md` speculatively. The documentation set ships
with an honest "no automated tests yet" statement in the README status section,
and `verification.md` plus figure D36 are added once the testbench is real.

### Consequences

- No fictional test instructions, which is the failure mode being avoided.
- The README's status section must be updated as part of the testbench work —
  noted as A-07 so it does not get forgotten.
- The documentation written now should be testbench-friendly: the per-state
  action table (D19) and the ROM decode examples in `docs/rom-format.md` are
  directly reusable as golden vectors for the cocotb reference model.

---

## ADR-009 — Clean unused signals out of the PCF

**Kind:** DESIGN · **Status:** Accepted

### Context

`pico-ice/pico-ice.pcf` contains `set_io` constraints for signals that do not
exist as ports on `pico_ice`: `uart_rx`, `uart_tx`, and `trace_0_out` through
`trace_12_out`. These are leftovers from debugging this project and from other
projects that shared the constraint file.

### Decision

Remove the constraints that have no matching port, keeping only the pins the
design actually uses. If trace pins are wanted again later they are re-added
together with the ports that drive them.

### Consequences

- The PCF becomes readable as documentation of the real interface, which is what
  D33 depends on.
- Any tool warning or error about unmatched constraints goes away (see C-06 —
  worth capturing what the toolchain currently says before the cleanup, since
  that behaviour is itself worth a sentence in `docs/build-and-program.md`).
- Slight loss of convenience if debug traces are needed again; mitigated by
  documenting in `docs/porting.md` how to add a trace port and constraint.

---

## ADR-010 — Generate the `.mif` files with an offline Python converter

**Kind:** DESIGN · **Status:** Accepted (recorded retroactively)

### Context

The linear format (ADR-003) is not something anyone would hand-write, and the
source data is the upstream `WORLD_IR_CODES` tables in C.

### Decision

A Python script converts the upstream C tables into the linear `.mif` files,
performing the linearisation at generation time. The `.mif` files are committed
so that a build needs only the FPGA toolchain.

### Consequences

- The RTL stays simple; all the awkward layout work happens once, offline.
- The original script was lost (M-01). It was **rebuilt on 2026-10-18 as
  `tools/gen_rom.py`**, which downloads upstream `WORLDcodes.c` at a pinned commit
  (SHA-256 checked, no copy committed), reproduces all three `.mif` files byte for
  byte, takes the index-byte count from `walk_rom.py`'s fetch rule, and walks its
  own output before writing it.

---

## ADR-011 — Keep the board wrapper separate from the portable core

**Kind:** DESIGN · **Status:** Accepted (recorded retroactively)

### Context

The design has to run on a specific board (Pico-ICE, iCE40UP5K, SG48) but is
also intended to be portable and eventually to target an ASIC.

### Decision

Two layers. `src/tv_b_gone.sv` is the portable core: clock, reset, start,
loop-forever, busy, fail, carrier out — no vendor primitives. `pico-ice/pico_ice.sv`
is the board wrapper and is the only file containing vendor primitives
(`SB_HFOSC`, and the commented-out `SB_GB`), pin-level polarity inversion, the
power-on reset generator, and the LED tie-offs.

### Consequences

- Retargeting means writing one new wrapper, not editing the design.
- The ASIC path is unblocked, since the core contains nothing iCE40-specific.
- Directory layout follows the split: board files live under `pico-ice/`, which
  is also where the Makefile and PCF live.
- The core still carries clock-rate assumptions in parameters (`CLK_MHZ`), so
  "portable" means "portable with parameter changes", not frequency-agnostic.
  `docs/porting.md` has to say that plainly.

---

## ADR-012 — Asynchronous ROM read

**Kind:** DESIGN · **Status:** Accepted (recorded retroactively), extended by
[ADR-018](#adr-018--register-the-rom-read-port-so-the-code-table-maps-to-ebr) and
[ADR-019](#adr-019--ship-both-rom-styles-async-for-asic-sync-for-fpga)

> [!NOTE]
> The open consequence below has since been resolved: an asynchronous read cannot
> reach iCE40 block RAM, so on FPGA the code table is lowered to plain LUT logic.
> This decision is **not** reversed — the async read is kept as the ASIC-oriented
> implementation, and a synchronous variant is added alongside it for FPGA use.

### Context

The controller reads a ROM byte in each of four states. A registered
(synchronous) read would add a cycle of latency per read and require either
wait states or a pipelined address.

### Decision

`tv_codes_rom` reads combinationally: `assign data = rom_array[address]`. The
controller drives the address from a combinational mux on `state_r` and captures
the data on the same clock edge that leaves the state, so every read state is
one cycle.

### Consequences

- The FSM is simple: no wait states, no read pipeline, no data-valid signal.
- Read timing is on the critical path (address mux → memory → capture flop), so
  this decision interacts directly with achievable Fmax.
- **Implementation consequence, now resolved against this decision.** On iCE40,
  block RAM (EBR) has a registered read port, and yosys will not map an
  asynchronous read to it. The code table is therefore lowered to plain LUT
  logic, which for several kilobytes is not what this design wants on a UP5K.
  Superseded by ADR-018.

---

## ADR-013 — Store the carrier compare value, not the frequency

**Kind:** DESIGN · **Status:** Accepted (recorded retroactively)

### Context

Each code needs a carrier frequency, typically in the 30–40 kHz range. Storing
it in Hz would require a divide at runtime to get a counter compare value.

### Decision

The ROM stores the **compare value** (the AVR `OCR` equivalent) in one byte.
`ctc_generator` toggles its output when the counter reaches it, so the carrier
period is `2 × (compare + 1)` clock cycles and the frequency is
`f_clk / (2 × (compare + 1))`.

### Consequences

- No divider in hardware; the value goes straight into `ocr_r`.
- One byte per code instead of two.
- **The ROM data is clock-rate specific.** Change the core clock and every
  compare value in every `.mif` is wrong. This has to be stated prominently in
  `docs/porting.md` and in `docs/rom-format.md`, and it is why Q-01 matters:
  the documented Hz values depend entirely on the true core frequency.
- Frequency resolution is quantised by the counter, and the achievable step size
  depends on the clock; worth a short note for readers wondering why the values
  are not round numbers.
- The value `0` is overloaded to mean "no carrier": the controller then asserts
  `ctc_forced_out` and the LED is driven constantly on for the burst duration.

---

## ADR-014 — Time in 10 µs units rather than clock cycles

**Kind:** DESIGN · **Status:** Accepted (recorded retroactively)

### Context

Burst and gap durations run from tens of microseconds to tens of milliseconds.
Stored in clock cycles at a few MHz, the longest gaps would not fit in 16 bits.

### Decision

`delay_timer` prescales the clock to a 10 µs tick
(`COUNTS_PER_UNIT = CLK_MHZ × UNIT_COUNTS_US`) and counts a 16-bit number of
those units. The ROM stores durations in 10 µs units. This mirrors the
upstream firmware's `delay_ten_us()` primitive, which keeps the data
values identical to the original.

### Consequences

- 16 bits covers up to 655.35 ms, comfortably more than any gap in the table.
- Two bytes per duration instead of four.
- Timing resolution is 10 µs, which is far finer than IR protocols need.
- The prescaler divisor depends on `CLK_MHZ`, so it is a parameter, and it has
  to be correct — another reason Q-01 is a blocking question for any absolute
  timing number printed in the documentation.
- Keeping the same unit as upstream means the converter script does no time
  arithmetic, only re-layout.

---

## ADR-015 — Document the clock frequency only once it is measured

**Kind:** DOC · **Status:** Deferred

### Context

`pico_ice.sv` derives the core clock from the 24 MHz `SB_HFOSC` output with a
toggle divider, names the result `clk_8M`, and comments it as "24MHz div 3 =
8MHz". The `CLK_MHZ = 8` parameter defaults in `delay_timer` and
`btn_debouncer` agree with that name, and the ROM compare values only land on
standard IR carrier frequencies at 8 MHz. Reading the divider as written,
however, the toggle occurs every third 24 MHz cycle, which produces a 4 MHz
square wave. The two readings cannot both be right, and the resolution changes
every absolute time and frequency figure in the documentation. Hardware
recordings exist that show a correct carrier; they have not yet been re-checked.

### Decision

Do not pick a number. Write all affected documentation parameterised on
`f_clk`, with an explicit `Unconfirmed` marker at each point where an absolute
value would normally appear, and fill the numbers in once the recording is
reviewed and the actual carrier frequency is known (Q-01, M-05).

### Consequences

- No incorrect numbers get published, and no reader is misled into
  regenerating a ROM against the wrong clock.
- Phases 1–3 of the writing plan can proceed now; only the numeric fills wait.
- Affected figures and text: D02, D05, D25, D26, D27, D29, the frequency table
  in `docs/rom-format.md`, and the `CLK_MHZ` discussion in `docs/porting.md`.
- If the measurement shows the effective clock is not 8 MHz, this stops being a
  documentation matter and becomes an RTL fix plus a comment correction, at
  which point a new ADR supersedes this one.

---

## ADR-016 — Derive the ROM address width from the selected table size

**Kind:** DESIGN · **Status:** Accepted, implementation deferred (A-11) · **Date:** 2026-08-17

### Context

ADR-004 ships three code tables. The original intent was one region per build,
which fits in 13 address bits — and both regional tables do: the highest address
touched is 4738 (EU) and 5313 (NA). The combined table needs 14 bits, since its
highest address is 8268.

Today `tv_b_gone` has no parameters at all. It hard-codes
`wire [12:0] rom_address` at line 37 and instantiates both `tv_codes_rom` and
`controller` with no parameter overrides, so the EU table and the 13-bit width
are baked in at three separate points in one file. Selecting a different table
therefore means editing three places *and* knowing that the width must move in
lockstep with the file choice — precisely the error-prone coupling worth removing
before a third variant exists.

### Decision

Add a third build variant for the full code set, and make the address width a
**derived** quantity rather than a value anyone maintains by hand:

```systemverilog
module tv_b_gone #(
    parameter  ROM_SIZE         = 4740,                         // EU 4740, NA 5316, all 8272
    parameter  ROM_INIT_FILE    = "../rom/eu_tv_codes_rom.mif",
    localparam ROM_ADDRESS_BITS = $clog2(ROM_SIZE)              // 13 or 14, automatically
) ( ... );
```

`ROM_ADDRESS_BITS` feeds the `rom_address` wire and the controller's
`ADDRESS_BITS`, and `ROM_SIZE` / `ROM_INIT_FILE` feed `tv_codes_rom`. Selecting a
table then becomes one parameter pair, with the width following on its own.

The same pass also passes `CTC_WIDTH` and `DELAY_WIDTH` through to the
controller, which today match its independent defaults only by coincidence
(C-10).

This uses the `localparam`-in-the-parameter-port-list form that
`tv_codes_rom.sv:13` already relies on, so the construct is proven with this
toolchain.

### Alternatives considered

1. **Widen everything to 14 bits unconditionally.** Simple, but pays an address
   bit in the regional builds that ADR-004 exists to keep small, and works
   against the ASIC intent.
2. **Document the combined table as unbuildable.** Rejected — the data is
   already committed and valid.

### Consequences

- One decision per build, and no hand-maintained width to get wrong. Regional
  builds keep their 13-bit path unchanged.
- Nothing below `tv_b_gone` needs to change. Verified by grep over `src/` and
  `pico-ice/`: `controller` is fully parameterised on `ADDRESS_BITS` (including
  the `{(ADDRESS_BITS-1-6){1'b0}}` offset constructions, which yield 13 bits at
  `ADDRESS_BITS=14` and zero-extend correctly into the 14-bit addition),
  `tv_codes_rom` derives its own width from `SIZE`, and the three remaining leaf
  modules never see an address.
- `pico_ice.sv` becomes an optional fourth touch point, if the region should be
  chosen at board level rather than by `tv_b_gone`'s default.
- **The combined table's data was verified before committing to this.** Replaying
  all three files with the FSM's exact fetch rules shows every chain landing
  precisely on its terminator with no bytes left over, no index exceeding its
  record's `pairs_num`, and no reachable `S_FAIL` across all 503 records. The
  combined file holds 228 records rather than 275. It is upstream's two-region
  build (`make` with both `NA_CODES` and `EU_CODES`): NA codes 0–114 then EU codes
  0–112, the rest of each list being guarded by `#ifndef` of the other region.
  It is not a de-duplicated union (corrected 2026-10-18); five codes occur in
  both lists and appear twice. It has one terminator, at the end. Details in `open-questions.md` §7.
- **Feasibility still depends on Q-05.** The combined table nearly doubles the
  memory, 4740 → 8272 bytes (66,176 bits). Mapped to EBR at 512×8 that is roughly
  17 of the UP5K's 30 block RAMs, against about 10 for EU — workable. Mapped to
  logic, as an asynchronous read may well be, neither table fits comfortably and
  the combined one certainly will not. The synthesis log (M-02) settles this, and
  there is no point implementing A-11 before it does.
- **Implementation deferred until the cocotb testbench exists** (ADR-008). The
  change is small but touches the address path in every read state, so it is
  cheaper to verify than to argue about — and the walker script from A-12 gives
  the testbench a reference model that can prove the 14-bit build plays all 228
  records. This matches the deferral already applied to A-02 for the same reason.

---

## ADR-017 — Commit the bitstream so the board can be flashed without a toolchain

**Kind:** DOC · **Status:** Accepted · **Date:** 2026-08-17

### Context

The primary audience includes people with little or no FPGA experience. Between
them and a working gadget sits an OSS CAD Suite install — a large download and a
real barrier for someone who just wants to see the thing work before deciding
whether to study it. Everything else needed to flash the board (`dfu-util`) is
small and commonly available.

The other build products — the yosys netlist, the placed design, the timing
report, the logs — are pure intermediates with no value to a reader.

### Decision

Commit released bitstreams in a dedicated `bitstreams/` directory, **one per
region** — `pico-ice-eu.bin` and `pico-ice-na.bin` — so a reader can pick their
region without building anything. The combined table is not released, because it
does not fit the device as logic; see the consequences below. Gitignore every other build
product, including the transient `pico-ice/pico-ice.bin` that a local `make`
leaves behind. The README quick start then offers two paths: flash a release, or
build from source.

Releases live apart from build output deliberately. A released artifact and a
scratch build have different lifecycles, and sharing a path would mean either
ignoring the releases too or committing whatever a local build happened to leave
in the tree.

### Consequences

- Someone can go from clone to working hardware with one `dfu-util` command.
- **The bitstream can go stale.** Nothing enforces that it matches the RTL, and a
  stale binary is worse than none, because it fails in ways that do not
  correspond to the source anyone is reading. Mitigations: state its provenance
  next to it (A-13), and treat rebuilding it as part of any RTL change — this
  applies directly to the deferred A-11 and A-02 work.
- **A committed binary needs provenance.** Which code table it contains (EU by
  default, per ADR-004), which board and package, and which toolchain release
  built it. Without that the artifact is not trustworthy. A-13 covers it.
- Neither region is privileged, since both are released. That is the reason for
  two files rather than one: with a single bitstream, whichever table the
  default parameters selected would silently become *the* build, and everyone
  else would discover it by flashing and finding their TV unaffected.
- **Two releases, not three.** The combined table was dropped once M-02 showed
  that the cost of the table tracks its address decode tree rather than its byte
  count: the EU and NA builds both produce an 8191-node tree and cost 3664 and
  3842 LUTs, about 0.46 per node. The combined table needs 14 address bits and so
  a 16383-node tree, roughly 7400 LUTs against the 5280 available. A combined
  release becomes possible only with the registered read of ADR-018, which moves
  the table into EBR.
- The netlist is ignored by exact path (`pico-ice/pico-ice.json`) rather than by
  `*.json`, so editor and tooling configs added later are unaffected.
- Two artifacts to keep current instead of one, which doubles the staleness
  exposure. The provenance table in `bitstreams/README.md` is what makes a stale
  file detectable.
- No bitstreams are committed yet — see A-13. They are deliberately deferred
  until after the RTL changes and verification, so the first release is of a
  verified design rather than of whatever happened to build today.

---

## ADR-018 — Register the ROM read port so the code table maps to EBR

**Kind:** DESIGN · **Status:** **Proposed — parked, revisit after verification** · **Date:** 2026-08-17
**Extends:** ADR-012

> [!NOTE]
> The **finding** below is verified fact: an asynchronous read cannot reach iCE40
> block RAM. The **response** to it is deliberately left open until after the
> testbench, and nothing has been decided about which style the project defaults
> to. Do not treat this as settled.

### Context

The code table must live in block RAM (EBR). Several kilobytes of ROM realised as
logic is the wrong answer on a UP5K: the EU table alone is 4740 × 8 = 37,920
bits, against 5280 LUT4s ≈ 84,480 configuration bits for the whole device before
any address decode. Design intent has always been EBR.

`tv_codes_rom.sv:28` currently reads combinationally
(`assign data = rom_array[address]`), which was recorded as ADR-012 for the
simplicity it buys the FSM: every read state is a single cycle, with no wait
states, no read pipeline and no data-valid signal.

Checking the toolchain documentation shows that combination cannot deliver EBR:

- **EBR reads are always registered.** Lattice FPGA-TN-02002 (Memory Usage Guide
  for iCE40 Devices): "By default, all EBR read operations are synchronized to the
  rising edge of RCLK... After the clock edge, the EBR contents located at the
  specified address (RADDR) appear on the RDATA output port."
- **Yosys will not map an async read to block RAM.** Memory kind selection: "If
  any read port is asynchronous, only LUT RAM (or FF RAM) can be used"; block RAM
  "supports only synchronous reads".
- **LUT RAM is not used for ROMs either.** "Will never be used for ROMs (lowering
  to plain LUTs is always better)."

So the present RTL lowers the table to plain LUT logic. `$readmemh` is not the
deciding factor — it governs whether initial contents are *possible*, not which
primitive is chosen. The two are independent, and conflating them is what left
ADR-012's consequence open.

**SPRAM is not an alternative.** The UP5K's 1 Mbit of single-port RAM is much
larger, but Lattice FPGA-TN-02022 (iCE40 SPRAM Usage Guide) confirms it has no
initialisation path: SPRAM cannot be initialised by device configuration, so
`$readmemh` cannot reach it. Using it for the code table would require shipping
the data somewhere else and writing a loader — all cost, no benefit, since the
table fits in EBR comfortably.

### Decision

Provide a **registered read** variant: the address is captured on the clock edge
and data appears the following cycle. The controller gains one wait cycle per ROM
read, in `S_READ_HEADER`, `S_READ_INDEX`, `S_READ_CARRIER_ON_TIME` and
`S_READ_CARRIER_OFF_TIME`.

> [!NOTE]
> **Amended by [ADR-019](#adr-019--ship-both-rom-styles-async-for-asic-sync-for-fpga).**
> This decision originally said *replace* the asynchronous read. It does not — the
> asynchronous version is kept as a second, selectable implementation, because it
> is the better starting point for ASIC hardening. The analysis in this record
> stands unchanged; only "replace" becomes "add alongside".

### Consequences

- The code table maps to EBR, at 512×8 per block: **10 EBRs for EU, 11 for NA, 17
  for the combined table**, against 30 available. All three variants fit
  comfortably, which also removes the last doubt over ADR-016's full-code-set
  variant.
- LUT usage drops to whatever the FSM and counters actually need.
- **Timing cost is negligible.** Roughly five ROM reads per chirp, so about five
  extra clock cycles — on the order of 625 ns at 8 MHz against chirp periods of
  roughly 1 ms, i.e. under 0.1 %. The added cycles fall in the read states, which
  sit *between* bursts rather than inside them, so they slightly lengthen a gap
  and never distort a carrier burst. IR receivers tolerate percent-level timing
  error, so this is free in practice.
- The FSM becomes slightly longer but not structurally different; multi-cycle read
  states already exist, since `S_READ_HEADER` loops on `byte_counter_r`.
- `address_overflow` and the zero-forcing output mux need to move to the
  registered side, or be registered alongside the data.
- ADR-012's stated benefit — single-cycle reads — is genuinely lost. That was a
  real simplification, and the trade is being made deliberately: correct resource
  mapping matters more than one cycle of FSM latency.
- **Sequencing.** Implementation is deferred to A-14, after the cocotb testbench
  exists. This makes an argument for how that testbench should be written: check
  the **emitted envelope**, using `tools/walk_rom.py` as the reference model,
  rather than exact cycle counts. An envelope-based testbench survives this change
  unmodified and therefore actually validates it; a cycle-accurate one would
  simply break and have to be rewritten.
- Until this lands, `docs/modules.md` and `docs/design-notes.md` must describe the
  async read as the current state, with its FPGA mapping consequence stated
  (see ADR-019 for how both styles are then presented).

---

## ADR-019 — Ship both ROM styles: async for ASIC, sync for FPGA

**Kind:** DESIGN · **Status:** **Proposed — parked, revisit after verification** · **Date:** 2026-08-17
**Amends:** ADR-018

### Context

ADR-018 established that an asynchronous read cannot reach iCE40 block RAM, and
concluded that the read should be registered. That conclusion was too narrow: it
treated the asynchronous version as a defect to remove, when the two styles suit
two different targets.

- **On an FPGA**, the registered read is clearly better. The table lands in EBR —
  10 blocks for EU, 11 for NA, 17 for the combined set, of 30 — instead of being
  lowered to plain LUT logic that a UP5K can barely hold, if at all.
- **On an ASIC**, the asynchronous read is the better starting point. A
  combinational mask-programmed array hardens into logic and wires with no
  flip-flops in the read path, which is what a synthesis flow can optimise
  aggressively. Registering the read would add storage the ASIC does not want.

The two are also complementary as teaching material. The async version has the
simpler FSM — every read is one cycle, no latency to reason about — which makes it
the better thing to read *first*. The sync version then introduces read latency
and wait states, which is a concept every FPGA engineer needs and which this
project can demonstrate on something small enough to follow.

### Decision

Ship both as selectable implementations rather than replacing one with the other:

| Module | Read | Clock port | Maps to | Target |
| --- | --- | --- | --- | --- |
| `tv_codes_rom_async` | combinational | no | plain LUT logic | ASIC hardening; simplest FSM |
| `tv_codes_rom_sync` | registered | yes | EBR | FPGA; the practical default |

`controller` gains a `ROM_READ_LATENCY` parameter (0 or 1) that inserts the wait
cycle in the four read states. `tv_b_gone` selects the module and passes the
matching latency.

Preferred structure: **two modules plus one controller parameter**, rather than one
module with a `generate` around the read path. Two files that can be diffed
side by side are the point — that diff *is* the teaching artifact, and it is
exactly what figure D30 should show.

### Consequences

- Build variants become a matrix of ROM style × code table:

  | | EU (4740 B) | NA (5316 B) | Combined (8272 B) |
  | --- | --- | --- | --- |
  | async / LUT | yes | yes | **no** — too large for LUT logic |
  | sync / EBR | yes | yes | yes |

  So the combined table exists only in the sync flavour, which narrows A-11's
  scope and A-13's release list.
- **Whether the async EU/NA builds fit a UP5K at all is still unknown** (M-02).
  37,920 bits against 5280 LUT4s is marginal on arithmetic alone. If they do not
  fit, the async variant becomes ASIC-only and the docs must say so plainly rather
  than offering a build that cannot be built.
- Documentation gains rather than loses: `docs/modules.md` presents both with the
  diff, `docs/design-notes.md` gets a genuinely instructive note on why the same
  RTL intent wants different code for two targets, and `docs/porting.md` §4 has a
  concrete ASIC example instead of general advice.
- **The envelope-based cocotb testbench validates both without modification**, and
  in doing so proves the two implementations are functionally equivalent. That is
  a strong argument for the envelope-based approach and a good demonstration of
  why testing behaviour beats testing cycles.
- Costs: two modules to keep in step, a latency parameter threaded through the
  controller, and more build variants to release and document. Acceptable, since
  the second module is a near-copy and the parameter touches four states.
- The ASIC rationale is now recorded rather than folklore. Without it, someone
  would eventually "clean up" the async version as dead code.

---

## ADR-020 — Comment only what is not obvious in the RTL

**Kind:** DOC · **Status:** Accepted · **Date:** 2026-08-17

### Context

The project is meant to be read. Readers arrive two ways — through the
documentation, or by opening a `.sv` file directly — and the second group gets
nothing from `docs/`. Several parts of this design are genuinely hard to read
cold: the reversed header load order, the 3-bit index phase counter, the offset
vector widths, the zero-delay shortcut.

The failure mode to avoid is commenting everything, which buries the few comments
that matter and creates a second copy of the documentation that drifts out of
step with the first.

### Decision

Add comments only where something is **not straightforward**, and split the
labour by scope:

- **Comments explain the local mechanism** — what this line or block does that a
  competent reader would not guess, in one or two lines. Cross-reference the docs
  by name (`see docs/rom-format.md, 3-bit index packing`) rather than restating
  them.
- **Documentation explains the why and the whole** — rationale, structure,
  diagrams, worked examples.

No comments on self-evident code. No block comments restating a signal name.

Harvest the list of what to comment **from the act of writing the documentation**:
anything that needed a paragraph or a figure to explain is, by definition, not
obvious, and its location in the RTL deserves a pointer.

### Consequences

- Readers who open the RTL directly get help at the four or five points where they
  will actually stall.
- Drift risk is real but bounded, because comments stay local and mechanical while
  anything explanatory lives in one place.
- Sequencing: the comment pass comes **after** phases 1–2 of the documentation, not
  before. Writing `rom-format.md` and `controller-fsm.md` is what reveals which
  parts are hard — guessing at that in advance produces comments on the wrong
  lines. Tracked as A-15.
- The same pass fixes the stale and incorrect comments already catalogued in A-06.
  Leaving a wrong comment in place is worse than having none, and a project offered
  as a teaching example cannot afford either.
- Candidate sites, from reading the RTL so far: the reversed `header_r` load order,
  `index_bit_delta` being 1 for the 3-bit case, `index_bit_offset_r` as a phase
  counter, the `index_vector_r` two-bit carry, `read_next_index_byte`, the
  `{(ADDRESS_BITS-1-6){1'b0}}` widths, `next record = last index byte + 1`, the
  `|delay_on_off_r == 0` shortcut, `ocr_r` updating only while disabled, and the
  debouncer's edge-detect expression.

---

## ADR-021 — Leave headroom in the header bit fields

**Kind:** DESIGN · **Status:** Accepted · **Date:** 2026-08-18

### Context

Header byte 2 packs two fields into eight bits. The shipped code tables only ever
use `index_bits_num` of 2 and 3, and `pairs_num` values from 2 to 8. Both fields
could have been narrower.

### Decision

Allocate 3 bits to `index_bits_num` (supporting 2, 3 and 4) and 4 bits to
`pairs_num` (supporting up to 15), deliberately wider than the current data
requires, as headroom for future code tables.

### Consequences

- A future table can use 4-bit indices, or up to 15 distinct duration pairs,
  without a format change, a ROM regeneration for existing records, or an RTL
  change.
- The cost is nil in practice. The fields share a byte that would otherwise be
  padded, so no storage is added, and the decode logic is a mux whose width is set
  by the field, not by the values that happen to occur.
- The 4-bit index path in `controller.sv` is therefore **supported but not
  exercised by any shipped record**. It is correct by construction rather than by
  test, so it deserves an explicit case in the cocotb testbench.
- Documentation describes 4-bit indices as a supported option, not as an oddity —
  they are reserved capability, not dead code.

---

## ADR-022 — Separate reference, rationale and defects

**Kind:** DOC · **Status:** Accepted · **Date:** 2026-08-18

### Context

The first draft of `rom-format.md` mixed three kinds of writing: how the format
works, why it was designed that way, and what is imperfect about the current
implementation. The result read as an analysis report rather than documentation —
process narration ("verified across all 503 records"), internal tracker IDs in
prose, and a section cataloguing a validation gap in the middle of a reference
page.

The target reader has none-to-middling FPGA experience and wants to understand a
working system. Defect discussion spends their attention on our problems instead
of their understanding, and undermines confidence in a design that does in fact
work.

### Decision

Each kind of content has one home:

| Where | Answers | Written for |
| --- | --- | --- |
| `docs/*.md` | what it is, how it works, how to use it | the reader |
| `docs/adr.md` | why it was decided this way | someone changing the design |
| `docs/open-questions.md` | what is wrong, missing or unverified | us |

Reference pages state facts in the present tense. They do not narrate how a fact
was established, cite internal tracker IDs, hedge, or discuss known defects.

**Rationale a reader needs is written in place, in a clause or a sentence — not
delegated to an ADR citation.** `ADR-013` is an internal document number, no more
meaningful to a reader learning the format than `C-11` is; sending them to another
file to find out why a field exists is worse than spending eight words on it. In
practice the in-place explanation was already present in every case, and the
citation beside it added nothing.

Each page carries **one** plain link to `adr.md` at the end, for the reader who
wants the full reasoning and for anyone about to change the design. Deep links to
individual records belong in planning files, where the audience is us.

Two things are **not** covered by this and stay in reference pages, because the
reader needs them to use the system correctly:

- Behaviour that is surprising but real, such as the reversed header load order.
  State it plainly as a fact about the implementation, without commentary about how
  confusing it is.
- Values that depend on an unresolved parameter. State the assumption explicitly
  ("quoted at f_clk = 8 MHz") rather than adding a warning banner.

### Consequences

- Nothing is lost when it is cut from a page — it moves to the file that owns it,
  and that move is part of the edit, not a follow-up.
- Reference pages get shorter and more confident.
- `open-questions.md` becomes the single place to look before changing the RTL,
  which is what it was for.
- Applies to every page in the plan, and to the RTL comment pass (ADR-020): the
  same split governs what belongs in a comment versus a tracker entry.
