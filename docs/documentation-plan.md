# Documentation Plan — TV-B-Gone on ICE40UP5K

Status: **draft for review**
Last updated: 2026-08-17

This file is the working plan for the project documentation. It is a planning
artifact, not user-facing documentation — once the documentation set is written
and stable this file can be trimmed to a short "how to update the docs" note or
removed entirely.

## Where this stands

**Status and the to-do list now live in [start-here.md](start-here.md)**, so there
is one list to keep current. This file keeps the conventions, outlines, figure
specifications and phase plan.

**Before writing any page**, read §2.1 (voice) and run `tools/check_doc_voice.py`
afterwards. Before drawing any figure, read `docs/diagrams/README.md` — it holds
the WaveDrom and Mermaid traps found the hard way.

---

Companion planning files:

- [adr.md](adr.md) — decision records for the design and the documentation
- [open-questions.md](open-questions.md) — open questions, actions, missing artifacts

---

## 1. Goals and audience

### 1.1 Primary audience

Someone with **none to low FPGA/RTL experience** who wants to:

1. understand what the gadget does and see it working, then
2. understand *how* it is built, and
3. use the project as a **worked example** of a small, complete, self-contained
   FPGA design — RTL, ROM data, constraints, build flow and board bring-up.

That audience shapes every decision below. Concretely:

- No jargon without a definition on first use (FSM, CTC, EBR, PnR, LUT,
  synthesis, prescaler, debounce, one-hot, `$readmemh`, …).
- Every non-trivial claim is anchored to a **file and line reference** so the
  reader can jump from prose to RTL and back.
- The reader must be able to stop after the README and still have learned
  something useful.

### 1.2 Secondary audiences

- **Someone porting the core to another board or to an ASIC.** The ASIC intent
  is why the ROM exists in three regional variants — see [adr.md](adr.md) ADR-004.
- **Someone extending the code table** (adding a region, regenerating the ROM).
- **Future us**, six months from now, wondering why the ROM format is linear.

### 1.3 Explicit non-goals

- Not a general IR-protocol reference. We explain only what is needed to follow
  this design.
- Not a Verilog/SystemVerilog tutorial. We explain the constructs *this* project
  uses, where they are non-obvious, and link out for the rest.
- Not a Pico-ICE board manual. We link to the vendor docs.

---

## 2. Language and writing conventions

| Convention | Rule |
| --- | --- |
| Language | English (US spelling) |
| Tone | Plain, direct, second person for instructions ("run `make`"), third person for description |
| Signal names | Inline code: `ctc_enable_out` |
| State names | Inline code, full RTL name: `S_READ_HEADER` |
| Numbers | Hex as `0x6f`, Verilog literals as `8'h6f` when quoting RTL, binary as `0b011` |
| Time units | µs / ms / kHz / MHz, always with the unit |
| File references | Relative markdown links, e.g. `[controller.sv](../src/controller.sv)` |
| Line references | `controller.sv:199-210` in prose, link where the renderer supports it |
| Definitions | First use of a term is **bold** and immediately defined in the same sentence, or in a per-page glossary callout |
| RTL comments | Docs explain the why and the whole; comments explain the local mechanism where it is not obvious, and reference docs by name rather than restating them (ADR-020) |
| Admonitions | GitHub alert syntax (`> [!NOTE]`, `> [!WARNING]`, `> [!TIP]`) |
| Diagram captions | `**Figure D-nn** — caption text.` directly under every figure |
| Unverified facts | State the assumption inline and plainly ("quoted at `f_clk` = 8 MHz"); track the uncertainty in open-questions.md. No warning banners in reference prose. |

### 2.1 Voice: reference pages, not analysis

Per [ADR-022](adr.md#adr-022--separate-reference-rationale-and-defects), each kind
of content has one home: `docs/*.md` says **what it is and how it works**,
`adr.md` says **why**, `open-questions.md` says **what is wrong or missing**.

Reference pages are written for a reader learning a working system. The following
belong elsewhere, and cutting them means *moving* them, not deleting them:

| Avoid in a reference page | Instead |
| --- | --- |
| Process narration — "verified across all 503 records", "three verified examples" | State the fact. The reader assumes it was checked. |
| Internal tracker IDs in prose — `Q-01`, `C-11`, `M-01`, `A-14` | Link an ADR if rationale helps; otherwise nothing. |
| Known defects and gaps | An entry in `open-questions.md`. |
| Analyst voice — "two things stand out", "worth slowing down for", "notice that" | Say the thing directly. |
| Hedging — "this happens to", "it turns out that" | Present tense, declarative. |
| Justifying a design at length | One sentence, in place. |
| ADR citations in prose — `([ADR-013](adr.md#…))` | The short reason, in place. One plain `adr.md` link at the end of the page. |

This is enforced mechanically, because the rule is easy to agree with and easy to
violate while writing — the offending sentence arrives naturally, one step after a
correct one:

```console
$ python tools/check_doc_voice.py
```

It flags the recurring surface forms ("two things follow", "the result is", "notice
that", "not arbitrary", "we verified", bare tracker IDs) with the reason each does
not belong, ignores fenced code, skips the planning files, and exits non-zero.
Run it before calling a page done.

The underlying habit it catches: **stating a fact, then adding one more sentence
that tells the reader what to conclude from it.** If a fact needs a "therefore"
sentence, either the fact is badly stated, the "therefore" belongs in an ADR, or a
figure already showed it and the sentence is redundant.

Two things stay, because the reader needs them:

- **Surprising but real behaviour**, such as the reversed header load order. State
  it as a fact about the implementation, without commentary on how confusing it is.
- **Values resting on an unresolved parameter.** Name the assumption in the same
  sentence; do not add a banner.

---

## 3. File layout

Decision: **README + `docs/` split** (ADR-001). The README is the 15-minute
read; `docs/` holds the deep dives.

```
README.md                        entry point, ~400-500 lines incl. diagrams
tools/
├── README.md                    what each script is for
├── walk_rom.py                  reference decoder / .mif consistency check
├── render_diagrams.py           WaveDrom src/*.json -> committed SVG
└── gen_rom.py                   ROM generator, from upstream at a pinned commit
bitstreams/
├── README.md                    which variant to flash, and provenance
└── pico-ice-{eu,na}.bin         released bitstreams, 104 kB each
tmp/                             scratch space, gitignored
docs/
├── documentation-plan.md        this file (planning)
├── adr.md                       decision records (planning)
├── open-questions.md            open items (planning)
├── ir-primer.md                 how IR remotes work, for beginners
├── architecture.md              block structure, clocking, reset, interfaces
├── rom-format.md                the linear ROM format, full spec
├── controller-fsm.md            the state machine, state by state
├── modules.md                   per-module reference (ports, params, timing)
├── build-and-program.md         toolchain, Makefile, results, flashing
├── hardware.md                  pin map, IR LED drive options, buttons
├── avr-comparison.md            original AVR firmware vs this implementation
├── design-notes.md              "why it is done this way" notes for learners
├── porting.md                   other boards, other ROMs, ASIC notes
├── verification.md              cocotb testbench (deferred — ADR-008)
├── glossary.md                  one-line definitions, linked from everywhere
└── diagrams/
    ├── *.svg                    hand-authored / exported figures (committed)
    ├── README.md             tooling, rendering, authoring tips, figure index
    └── src/*.json            WaveDrom sources (rendered by tools/render_diagrams.py)
```

Mermaid diagrams live **inline** in the markdown files (GitHub renders them, and
they stay editable without any tool). WaveDrom and hand-drawn figures live in
`docs/diagrams/` as committed SVG, with sources in `docs/diagrams/src/`. See
ADR-002.

---

## 4. README.md outline

Target: a newcomer reads it top to bottom in ~15 minutes and comes away knowing
what the thing is, that it works, and roughly how.

| § | Section | Content | Figures |
| --- | --- | --- | --- |
| 1 | Title + one-liner + badges | "TV-B-Gone, reimplemented in SystemVerilog for the Lattice iCE40UP5K." Photo/GIF of the board blinking. | photo slot |
| 2 | What it does | 3 short paragraphs: universal TV power-off remote; replays ~150 power codes back to back; original is an AVR gadget from Adafruit, this is the same idea in hardware. | D01 |
| 3 | Responsible use | Short, factual, up front: only on equipment you own or have permission to use; some jurisdictions/venues care. Links to upstream project. | — |
| 4 | Features at a glance | Bullet list: 3 regional code tables, single-button trigger, loop-forever mode, busy/fail status outputs, no CPU/softcore, no external memory, ~N LUTs (TBD). | — |
| 5 | How it works in one picture | The top-level block diagram plus a 6-line walkthrough. Links into `docs/architecture.md`. | D03 |
| 6 | Quick start | **Two paths, flash-first.** (a) *No toolchain* — clone, wire the IR LED, pick a region and `dfu-util` the matching `bitstreams/pico-ice-{eu,na}.bin`, press the button (ADR-017, A-13). (b) *From source* — OSS CAD Suite, `cd pico-ice && make`, `make prog`. Then: what the LEDs mean, and a troubleshooting table. | D34 (ref) |
| 7 | Repository layout | Annotated tree of `src/`, `rom/`, `pico-ice/`, `docs/`. | D35 |
| 8 | Documentation map | Table of the `docs/` pages with a one-line "read this if…" for each. | — |
| 9 | Status and limitations | What is verified, what is not (carrier frequency measurement pending — Q-01), no testbench yet (Q-07), combined ROM not currently buildable (Q-02). | — |
| 10 | Credits and license | Adafruit TV-B-Gone kit firmware as the source of the code tables and the algorithm; Apache-2.0; SemiQa copyright. | — |

> Rule for the README: **no section may require the reader to already understand
> another section.** Anything that needs build-up goes to `docs/`.

---

## 5. `docs/` page outlines

### 5.1 `ir-primer.md` — How IR remotes work

For readers who have never touched IR. Deliberately short.

1. The problem: sunlight and room lighting are broadband IR noise.
2. The solution: a **carrier** — the LED is switched on and off at ~30–40 kHz,
   and the receiver only listens at that frequency.
3. The **envelope** — the carrier is gated on and off in bursts; the pattern of
   burst and gap lengths encodes the command.
4. What a "code" is: carrier frequency + a list of (on-time, off-time) pairs.
5. Why the same pair values repeat: protocols reuse a small alphabet of
   mark/space durations. **This is the whole reason the ROM format uses a pair
   table plus indices** — forward reference to `rom-format.md`.
6. Why one gadget needs ~150 codes: no universal off command exists.
7. Terms defined inline on first use — carrier, envelope, chirp, code — rather than
   in a callout box, so `glossary.md` stays the single list and nothing drifts.

Figures: **D02**. The planned D16 inset was dropped: D16 carries a *pair index*
row, which needs the pair-table concept the primer has not introduced yet. The
primer shows the same code's first four chirps as a plain duration table and links
forward instead.

### 5.2 `architecture.md` — Block structure

1. Two layers: the portable core `tv_b_gone` and the board wrapper `pico_ice`.
   Why the split matters (retargeting, ASIC).
2. Core block diagram with every inter-module signal named. **D04**
3. Role of each block in one paragraph each, with the "why this block exists"
   angle rather than a port dump (ports live in `modules.md`).
4. The controller's four interfaces (memory, CTC, delay, status) as an
   interface map. **D06**
5. Clocking and reset: `SB_HFOSC` → divider → core clock; the power-on reset
   counter; the commented-out `SB_GB` global buffer and what a global buffer is
   for. **D05**
   > Carries an **Unconfirmed** note for the actual clock frequency (Q-01).
6. ROM addressing: how `mem_address_out` is built differently in each state.
   **D07**
7. Why there is no CPU: contrast with the AVR original — a hardwired FSM plus
   two counters replaces firmware. Forward reference to `avr-comparison.md`.

### 5.3 `rom-format.md` — The linear ROM format

The heart of the documentation, and the part most worth writing carefully.

1. What problem the format solves: the AVR original used pointer-linked structs
   in `PROGMEM`; pointer chasing is awkward in RTL. The linear format lets a
   state machine walk the table with one address register and an adder.
   **D17** (side-by-side with the original layout).
2. Global layout: records back to back, `00 00 00` header terminates. **D08**
3. One record's anatomy: header (3 B) → pair table (`pairs_num` × 4 B) → index
   bytes. **D09**
4. Header fields, bit by bit — including the note that the FSM loads the three
   header bytes into `header_r[2]`, `[1]`, `[0]` in descending order, so the
   array index order looks reversed relative to the file. **D10**
   - byte 0 → `frequency`, the CTC compare value (not a frequency in Hz)
   - byte 1 → `chirps_num`
   - byte 2 → `{pairs_num[7:4], unused[3], index_bits_num[2:0]}`
5. Converting `frequency` to Hz: `f = f_clk / (2 × (OCR + 1))`, worked both ways,
   with a table of the values that actually occur in the shipped ROMs.
6. Pair table entry: two little-endian 16-bit values in 10 µs units. Worked
   example and the resulting µs. **D11**
7. Index packing — three cases, one figure each:
   - 4 bits: two per byte. **D12**
   - 2 bits: four per byte. **D13**
   - 3 bits: the 8-index / 3-byte rolling window, `index_bit_delta` forced to 1,
     the 10-bit `index_vector_r` carrying 2 bits across the byte boundary. This
     is the single hardest thing in the design and gets the most careful figure.
     **D14**, plus **D15** for the shift-register mechanics.
8. How many index bytes a record occupies, and why it is not simply
   `ceil(chirps_num × bits / 8)` — the last chirp does not trigger a fetch, so
   the record end depends on the fetch pattern. Include the three verified
   examples below.
9. Worked end-to-end example: one real record from `eu_tv_codes_rom.mif`
   decoded byte by byte into the emitted waveform. **D16**
10. The three ROM variants, their sizes, and the `SIZE` parameter policy
    (ADR-004, ADR-005).
11. ✅ How the `.mif` files are generated: `tools/gen_rom.py` (rewritten after
    the original was lost), and how to check a generated table with
    [`tools/walk_rom.py`](../tools/walk_rom.py).
12. The partial nature of the `S_CHECK_HEADER` validation (C-11) — stated
    honestly rather than described as a full sanity check.

Verified decoding examples to reuse in the text (checked against the shipped
`eu_tv_codes_rom.mif`):

| Header | freq | chirps | pairs | idx bits | pair bytes | index bytes |
| --- | --- | --- | --- | --- | --- | --- |
| `6f 28 73` | 0x6f = 111 | 40 | 7 | 3 | 28 | 15 |
| `83 1f 73` | 0x83 = 131 | 31 | 7 | 3 | 28 | 12 |
| `77 1a 42` | 0x77 = 119 | 26 | 4 | 2 | 16 | 7 |

### 5.4 `controller-fsm.md` — The state machine

1. Why an FSM: the "firmware without a CPU" framing, for beginners.
2. Full state diagram with every transition condition. **D18**
3. Per-state reference table: what the state reads, what it writes, which
   outputs are asserted, what the ROM address is, exit conditions. **D19**
4. The two nested loops — outer loop over codes, inner loop over chirps — drawn
   as an activity flow so the reader sees the shape before the detail. **D20**
5. One chirp end to end as a sequence diagram across the four blocks. **D21**
6. The delay handshake in detail, including the zero-delay shortcut
   (`|delay_on_off_r == 0`) and the `delay_start_r` / `delay_busy_in`
   two-step. **D22**
7. Termination and error paths: all-zero header → `S_RESET` → `S_IDLE`;
   `S_CHECK_HEADER` and `S_CHECK_INDEX` sanity checks → `S_FAIL`, which is
   terminal until reset. What each failure actually means for the ROM data.
   **D23**
8. `loop_forever_in` behaviour: level-sensitive, sampled in `S_IDLE`, not
   debounced; restarts from address 0 after the terminator.
9. `busy_out` and `fail_out` semantics, including that `busy_out` is high in
   `S_RESET`.

### 5.5 `modules.md` — Module reference

One section per module, all in the same shape so the reader learns the pattern
once:

> **Purpose** (1–2 sentences) → **Parameters** (table: name, default, meaning,
> constraints) → **Ports** (table: name, dir, width, meaning, timing) →
> **Internal structure** (figure) → **Timing** (waveform figure) →
> **Notes and gotchas** → **Source link**

Order: `tv_b_gone` → `controller` (summary, pointing to `controller-fsm.md`) →
`tv_codes_rom` → `ctc_generator` → `delay_timer` → `btn_debouncer` →
`pico_ice`.

Figures: **D25**, **D27**, **D29**, **D30**.

> **Datapath figures D24, D26 and D28 were dropped after piloting one.** For
> modules this small a datapath diagram mostly re-draws the RTL in boxes, and the
> feedback path through a counter does not read as a loop in an auto-laid-out
> graph. The timing diagram carries the whole explanation instead: D25 shows the
> compare-load, the toggle period and the forced output in one picture, and D27
> makes the prescaler-to-unit-counter cascade visible in a way a block diagram
> cannot. Structure that is genuinely non-obvious goes in prose beside the port
> table.

Per-module points that must not be lost:

- `ctc_generator`: toggle-on-compare, so the output period is
  `2 × (OCR + 1)` clocks; `ocr_r` only updates while `enable_in` is low, which
  is why the controller strobes it in `S_READ_INDEX`; `forced_in` provides the
  un-modulated constant-on case when `frequency == 0`.
- `delay_timer`: two-stage countdown (prescaler to a 10 µs unit tick, then the
  16-bit unit counter); `busy_out` is combinational and gated by `enable_in`;
  `delay_r` only loads while not busy.
- `btn_debouncer`: samples every `PERIOD_MS` (10 ms at 8 MHz); the 3-tap shift
  register plus `!probe_r[2] & probe_r[1] & probe_r[0]` goes high on a confirmed
  rising edge and stays high for **one whole sample period**, not one clock —
  `probe_r` only shifts when `enable` fires, and `btn_out` is combinational on it.
  Holding the button does not retrigger: on the next return to `S_IDLE`, `probe_r`
  reads `111` and the output is already low.
- `tv_codes_rom`: **two implementations, presented side by side** (ADR-019, A-14).
  The async version reads combinationally, so the controller sees data in the same
  cycle it drives the address and every read state is one cycle — the simpler FSM,
  and the right starting point for ASIC hardening, where the array becomes logic and
  wires with no flip-flops in the read path. The sync version registers the read,
  which costs one wait cycle per access but is the only way to reach iCE40 EBR.
  Present the *choice*, with the mapping consequence and the target that motivates
  each. This is the most instructive pair in the project: the same intent wants
  different RTL for two targets, and the reason is one sentence in the vendor's
  memory guide.
- `pico_ice`: `clk_ext` (pin 35) is declared but unused because the internal
  oscillator is used instead; the RGB LEDs are tied off.

### 5.6 `build-and-program.md`

1. Toolchain: OSS CAD Suite, one download, what is inside it (yosys,
   nextpnr-ice40, icepack, icetime, verilator, dfu-util). Install notes for
   Linux/macOS/Windows.
2. What each stage does, in beginner terms: synthesis → place & route → timing
   → bitstream → download. **D31**
3. Makefile target graph and how to invoke each one. **D32**
4. `make lint` — verilator lint-only, and why linting SystemVerilog early is
   worth it. Explain the `/* verilator lint_off UNUSEDSIGNAL */` pragma around
   the ROM instance.
5. Selecting the code table: overriding `SIZE` and `INIT_FILE` on
   `tv_codes_rom`, and the address-width consequence (Q-02).
6. Results: resource utilisation and timing. **Placeholder table pending M-02.**
7. Programming over DFU, and what to do when the device does not enumerate.
8. **Prebuilt bitstreams** — the three released variants, their provenance (code
   table, board, toolchain release, source commit), why they are committed while
   every other build product is ignored (ADR-017), how to build a chosen variant
   yourself, and the warning that a release may lag the RTL.
8. Reading the reports: how to find LUT/EBR counts in the yosys log and Fmax in
   the nextpnr/icetime output.

### 5.7 `hardware.md`

1. Pico-ICE pin map as used by this project, with the PCF as the source of
   truth. **D33**
2. `ir_led_out` / `ir_ledn_out`: **two anti-phase outputs, of which you use
   exactly one.** They exist so that whichever external driver you have —
   NPN transistor, PNP transistor, a logic buffer, or the LED driven directly
   from the pin — you can pick the polarity that suits it. **D34** shows the
   variants. (ADR-006)
3. Current limiting and the practical limits of driving an IR LED from an FPGA
   pin; why a driver transistor is the better choice for range.
4. Buttons: `button_in` is active low (`pico_ice.sv` inverts it),
   `loop_forever_in` is active high and level-sensitive.
5. Status LEDs: `active_led_out` = busy, `fail_led_out` = fail.
6. Wiring diagram / schematic. **Pending M-03.**

### 5.8 `avr-comparison.md`

Scope: **simple comparison** (ADR-007) — enough for a reader to understand what
changed and why, not an exhaustive diff.

1. What the original is: Adafruit TV-B-Gone kit firmware, C on an AVR.
2. Side-by-side table: code table storage, carrier generation, timing,
   sequencing, region selection, "loop forever".
3. Data layout comparison figure. **D17**
4. The three substantive changes:
   - pointer-linked `PROGMEM` structs → one flat byte stream (the
     "linearization")
   - AVR hardware timer in CTC mode → `ctc_generator`
   - `delay_ten_us()` busy loop → `delay_timer`
5. What deliberately did **not** change: the code tables themselves, the
   carrier compare values, the pair/index compression idea.
6. Attribution and licensing of the derived data.

### 5.9 `design-notes.md` — Notes for learners

Short, self-contained notes, each answering a "why is it like that?" question:

1. Why a hardwired FSM rather than a soft CPU.
2. **Async or sync ROM read — the same intent, two different targets.** The most
   instructive note in the set. Walks the chain for FPGA: EBR read ports are always
   registered → yosys will not map an async read to block RAM → LUT RAM is never
   used for ROMs → the table becomes plain logic. Then the numbers: 37,920 bits
   against 5280 LUT4s, versus 10 of 30 EBRs once the read is registered. Then the
   other direction: on an ASIC the async array is *preferable*, hardening into logic
   and wires with no flip-flops in the read path. Includes the distinction that
   caused the confusion here — `$readmemh` decides whether *initial contents* are
   possible, not which primitive gets chosen — and why SPRAM, despite being 1 Mbit,
   cannot hold the table at all: no initialisation path. (ADR-018, ADR-019)
3. Why timing is done in 10 µs units instead of clock cycles.
4. Why the carrier compare value is stored, not the frequency in Hz.
5. Why the debouncer emits a pulse, not a level.
6. Why `default_nettype none` is at the top of every file.
7. `bit` vs `logic` vs `reg` in this codebase, and the `_r` / `_in` / `_out`
   naming convention.
8. Why parameters (`WIDTH`, `CLK_MHZ`, `SIZE`) instead of hard-coded numbers,
   and where that discipline is not yet complete (C-05).
9. Reading a state machine from RTL: how the `always @(posedge)` case block, the
   separate combinational address mux, and the `assign` output block map onto
   the state diagram.

### 5.10 `porting.md`

1. Retargeting the board: what lives in `pico_ice.sv` vs `tv_b_gone.sv`, what a
   new wrapper must provide (clock, reset, one button, one output pin).
2. Changing the clock frequency: the `CLK_MHZ` parameters, and that the ROM
   `frequency` bytes are clock-dependent so the ROM must be regenerated for a
   different clock.
3. Changing the code table: the three variants, the `SIZE`/`INIT_FILE`
   parameters, the 13-bit address limit (Q-02).
4. iCE40 memory options and why the code table goes in EBR: EBR is 4 kbit blocks,
   flexible width, **initialisable**; SPRAM is far larger (4 × 256 kbit) but fixed
   16-bit, single-port and **cannot be initialised at all**, so it is unusable for
   a ROM without shipping the data elsewhere and writing a loader. Both cited to
   the Lattice technical notes. (ADR-018)
5. ASIC notes: why the regional split exists, ROM size as the dominant area
   term, and what would need to change (memory macro instead of `$readmemh`,
   external reset, no `SB_HFOSC`).

### 5.11 `glossary.md`

One-line definitions, alphabetical, linked from first use across all pages:
bitstream, carrier, chirp, CTC, debounce, duty cycle, EBR, envelope, FSM, LUT,
mark, MIF, PnR, PROGMEM, prescaler, space, synthesis, `$readmemh`.

### 5.12 `verification.md` — deferred

Written after the cocotb testbench exists (ADR-008). Reserved outline:
test strategy, per-module unit tests, ROM-format golden vectors, full-code
end-to-end decode check, how to run, CI. Figure **D36**.

---

## 6. Diagram inventory

38 figures proposed. **P0** = required for the documentation to make sense,
**P1** = strongly recommended, **P2** = nice to have / cut first.

Tooling per ADR-002: `mermaid` inline in markdown, `wavedrom` as committed SVG
with JSON source, `svg` hand-authored and committed, `table` = a formatted
markdown table doing a diagram's job, `photo` = user-supplied image.

| ID | Title | Type | Page | Prio |
| --- | --- | --- | --- | --- |
| **D01** | Concept and data flow | mermaid | README | P0 |
| **D02** | IR signalling: carrier and envelope | wavedrom | ir-primer | P0 |
| **D03** | Top-level system block diagram | mermaid | README | P0 |
| **D04** | Core block diagram with named signals | mermaid | architecture | P0 |
| **D05** | Clock and reset generation | mermaid + wavedrom | architecture | P1 |
| **D06** | Controller interface map | mermaid | architecture | P1 |
| **D07** | ROM address mux composition | svg | architecture | P1 |
| **D08** | ROM global memory map | svg | rom-format | P0 |
| **D09** | Single record anatomy | svg | rom-format | P0 |
| **D10** | Header byte bit fields | svg | rom-format | P0 |
| **D11** | Pair table entry | svg | rom-format | P1 |
| **D12** | Index packing, 4-bit case | svg | rom-format | P0 |
| **D13** | Index packing, 2-bit case | svg | rom-format | P0 |
| **D14** | Index packing, 3-bit case (8-phase window) | svg | rom-format | P0 |
| **D15** | `index_vector_r` shift mechanics | svg | rom-format | P1 |
| **D16** | Worked example: record → waveform | table + wavedrom | rom-format | P0 |
| **D17** | AVR layout vs linear layout | svg | avr-comparison | P1 |
| **D18** | Controller FSM state diagram | mermaid | controller-fsm | P0 |
| **D19** | Per-state action table | table | controller-fsm | P0 |
| **D20** | Nested-loop activity flow | mermaid | controller-fsm | P1 |
| **D21** | One chirp, sequence diagram | mermaid | controller-fsm | P0 |
| **D22** | Delay handshake timing | wavedrom | controller-fsm | P1 |
| **D23** | Termination and failure paths | mermaid | controller-fsm | P2 |
| ~~D24~~ | ~~`ctc_generator` datapath~~ | — | — | **dropped** |
| **D25** | `ctc_generator` timing | wavedrom | modules | P1 |
| ~~D26~~ | ~~`delay_timer` datapath~~ | — | — | **dropped** |
| **D27** | `delay_timer` timing | wavedrom | modules | P1 |
| ~~D28~~ | ~~`btn_debouncer` datapath~~ | — | — | **dropped** |
| **D29** | `btn_debouncer` timing | wavedrom | modules | P1 |
| **D30** | `tv_codes_rom` read path — async vs sync, two panels | svg | modules | **P1** |
| **D31** | Build/tool flow with artifacts | mermaid | build-and-program | P0 |
| **D32** | Makefile target graph | mermaid | build-and-program | P2 |
| **D33** | Pico-ICE pin map | svg + table | hardware | P1 |
| **D34** | IR LED drive options | svg | hardware | P0 |
| **D35** | Source file / instantiation graph | mermaid | README | P2 |
| **D36** | Cocotb testbench structure | mermaid | verification | deferred |
| **P01** | Board photo / IR-LED-blinking GIF | photo | README | P1 |
| **P02** | Scope or logic-analyser capture of the carrier | photo | ir-primer | P1 |

### 6.1 Diagram specifications

Enough detail here that each figure can be drawn later without re-deriving it.

---

**D01 — Concept and data flow** · mermaid `flowchart LR` · README

Five boxes left to right: `Button press` → `iCE40UP5K` → `IR LED` → `(air)` →
`TV`. The FPGA box is a subgraph containing four stacked mini-boxes labelled in
plain language, not RTL names: *code table* → *sequencer* → *timer* →
*carrier generator*. A dashed feedback edge from the sequencer back to the code
table labelled "next code". Caption states the headline number: ~150 codes
replayed in sequence.

*Purpose:* orient the reader in 10 seconds, before any terminology.

---

**D02 — IR signalling: carrier and envelope** · wavedrom · ir-primer

Three stacked tracks over the same time axis:

1. `envelope` — logical bursts: on 430 µs, off 470 µs, on 430 µs, off 910 µs
   (real values from the `6f 28 73` record).
2. `carrier` — a 35.7 kHz square wave, drawn continuous.
3. `IR LED` — the AND of the two, i.e. what the LED actually does.

Annotations: one carrier period labelled `2 × (OCR+1)` clocks; one burst
labelled "on-time, from the pair table"; one gap labelled "off-time".
A zoom bracket showing that a single 430 µs burst contains ~15 carrier cycles.

*Purpose:* the single most important concept for a beginner. Everything else in
the design is machinery to produce this picture.

---

**D03 — Top-level system block diagram** · mermaid `flowchart` + subgraphs · README

Outer subgraph `pico_ice` (board wrapper) containing:
- `SB_HFOSC` → `clock divider` → core clock (frequency annotated, with an
  Unconfirmed marker per Q-01)
- `reset counter (16-bit)` → `reset_in`
- inverters on `button_in` and on `ir_led_out` → `ir_ledn_out`
- RGB LEDs tied off (shown greyed, to explain why they are dark)

Inner subgraph `tv_b_gone` shown as a single box with its five ports, expanded
in D04. Physical pins annotated on the boundary with their PCF numbers.

*Purpose:* separate "board glue" from "the actual design" — a distinction
beginners routinely miss.

---

**D04 — Core block diagram with named signals** · mermaid `flowchart` · architecture

The reference map for the whole document. Five nodes: `btn_debouncer`,
`tv_codes_rom`, `controller`, `ctc_generator`, `delay_timer`. Every edge
labelled with the real signal name and width:

- `start_in` → debouncer → `start_debounced` → controller
- controller `mem_address_out[12:0]` → ROM; ROM `data[7:0]` → controller
  `mem_data_in`
- controller → CTC: `ctc_enable_out`, `ctc_forced_out`, `ctc_wr_strobe_out`,
  `ctc_value_out[7:0]`
- controller → delay: `delay_enable_out`, `delay_start_strobe_out`,
  `delay_value_out[15:0]`; delay → controller `delay_busy_in`
- controller → outputs `busy_out`, `fail_out`; CTC → `ctc_out`
- `loop_forever_in` straight to the controller (annotate: not debounced)

Colour/shape convention introduced here and reused in every later figure:
storage = cylinder, sequencer = hexagon, counters = rectangle, glue = rounded.

---

**D05 — Clock and reset generation** · mermaid + small wavedrom inset · architecture

Mermaid part: `SB_HFOSC (CLKHF_DIV=0b01)` → 24 MHz → `÷N toggle divider` → core
clock → all four synchronous blocks; separately `reset_cnt[15:0]` → `&reset_cnt`
→ `resetn` → inverted → `reset_in`. The commented-out `SB_GB` drawn dashed with
a note on what a global clock buffer does and why you normally want one.

WaveDrom inset: `clk_24M`, `div_r`, core clock, showing the toggle cadence, and
`reset_cnt` / `resetn` showing the ~2.7 ms release.

> Carries an **Unconfirmed** banner: the divider ratio and the resulting core
> frequency must be reconciled with the hardware recording (Q-01). The figure is
> drawn parameterised on N until that is settled.

---

**D06 — Controller interface map** · mermaid · architecture

The controller in the middle, four labelled interface groups radiating out:
*Control/status* (`start_in`, `loop_forever_in`, `busy_out`, `fail_out`),
*Memory* (address out, data in), *Carrier* (4 signals), *Timing* (3 out, 1 in).
Each group boxed and annotated with its direction and handshake style
(combinational address, single-cycle strobe, level enable, busy handshake).

*Purpose:* teach the idea that a module is a set of interfaces, not a flat pin
list.

---

**D07 — ROM address mux composition** · svg · architecture

A 4-way mux driven by `state_r`, showing each input as a bit-field construction:

- `S_READ_HEADER` / `S_CHECK_HEADER` → `header_chirps_address_r`
- `S_READ_INDEX` → `index_byte_address_r`
- `S_READ_CARRIER_ON_TIME` / `S_READ_CARRIER_OFF_TIME` →
  `header_chirps_address_r + {6'b0, chirp_pair_index[3:0], byte_counter_r[1:0]}`
  drawn as a bit-lane picture so `index × 4 + byte` is visually obvious
- default → 0

Side note explaining that `pairs_num << 2` is the pair-table size, which is how
`index_byte_address_r` is computed in `S_CHECK_HEADER`.

---

**D08 — ROM global memory map** · svg · rom-format

A tall column, address 0 at top. Records as coloured blocks, each labelled with
its real header bytes from `eu_tv_codes_rom.mif` and its byte span. Show record
0, record 1, record 2, an ellipsis, the last record, then the `00 00 00`
terminator, then the rounded-up `SIZE` boundary with the padding gap hatched and
annotated "uninitialised — never read". A right-hand ruler gives the three
variants' sizes side by side (EU 4739 B, NA 5314 B, combined 8269 B) against the
13-bit address ceiling of 8192 B, which makes the Q-02 problem visible.

---

**D09 — Single record anatomy** · svg · rom-format

One record exploded horizontally, using the real record `6f 28 73`:

```
+----+----+----+  +----------------------------+  +--------------------+
| 6f | 28 | 73 |  | 7 pairs × 4 B = 28 bytes   |  | 15 index bytes     |
+----+----+----+  +----------------------------+  +--------------------+
 freq chirps pairs/bits   on_lo on_hi off_lo off_hi   packed 3-bit indices
```

with byte offsets, and arrows showing which header field determines the size of
each following region. A second row shows the next record starting immediately
after, to make "linear" concrete.

---

**D10 — Header byte bit fields** · svg · rom-format

Three 8-bit boxes with numbered bit lanes.

- Byte 0 `frequency` — annotated "CTC compare value (OCR), not Hz", with the
  conversion formula and `0x6f → 35.7 kHz @ 8 MHz` worked beside it.
- Byte 1 `chirps_num` — annotated "number of on/off bursts, 1…255".
- Byte 2 — lanes `[7:4] pairs_num`, `[3] unused`, `[2:0] index_bits_num`, with
  the only legal values of `index_bits_num` (2, 3, 4) called out and the
  `S_CHECK_HEADER` rejection rule shown.

A sidebar shows the load order: file byte 0 → `header_r[2]`, byte 1 →
`header_r[1]`, byte 2 → `header_r[0]`, because `byte_counter_r` counts down from
`HEADER_BYTES-1`. This trips up everyone reading the RTL and needs to be
explicit.

---

**D11 — Pair table entry** · svg · rom-format

One 4-byte entry with the two little-endian 16-bit assemblies drawn as arrows
from byte lanes into a 16-bit value, then the unit conversion
`value × 10 µs`. Uses real bytes `2b 00 2f 00` → on 43 units = 430 µs,
off 47 units = 470 µs. A small note on the special case `value == 0` and how the
FSM short-circuits it.

---

**D12 — Index packing, 4-bit case** · svg · rom-format

One byte, two nibbles, labelled index 0 (bits 7:4) and index 1 (bits 3:0), with
`index_bit_offset_r` values 0 and 4 beneath, and the fetch-next-byte trigger
marked after offset 4. Uses real index bytes from a `…4` record.

---

**D13 — Index packing, 2-bit case** · svg · rom-format

One byte, four 2-bit fields, indices 0–3, `index_bit_offset_r` = 0, 2, 4, 6,
fetch trigger after 6. Uses `1a 56 a6 …` from the verified `77 1a 42` record,
decoded to actual index values.

---

**D14 — Index packing, 3-bit case** · svg · rom-format · *the important one*

Three consecutive bytes drawn as one 24-bit lane with 8 three-bit index fields
straddling the byte boundaries. Beneath, a table with one row per phase 0–7:

| phase | slice of `index_vector_r` | source bits | fetch next byte after? |
| --- | --- | --- | --- |
| 0 | `[7:5]` | byte0[7:5] | no |
| 1 | `[4:2]` | byte0[4:2] | **yes** |
| 2 | `[9:7]` | byte0[1:0] + byte1[7] | no |
| 3 | `[6:4]` | byte1[6:4] | no |
| 4 | `[3:1]` | byte1[3:1] | **yes** |
| 5 | `[8:6]` | byte1[0] + byte2[7:6] | no |
| 6 | `[5:3]` | byte2[5:3] | no |
| 7 | `[2:0]` | byte2[2:0] | **yes** |

Callout: `index_bit_delta` is forced to 1 for the 3-bit case, so
`index_bit_offset_r` is not a bit offset at all but an 8-phase counter — this
is the one place where a variable name actively misleads, and the doc should say
so.

---

**D15 — `index_vector_r` shift mechanics** · svg · rom-format

The 10-bit register drawn across three successive `S_READ_INDEX` events:
`index_vector_r <= {index_vector_r[1:0], mem_data_in}`. Shows the two carried
bits moving from `[1:0]` to `[9:8]` and the new byte landing in `[7:0]`, with
colour-coded provenance. Explains why 10 bits is exactly enough: 8 new bits plus
at most 2 leftover.

---

**D16 — Worked example: record → waveform** · table + wavedrom · rom-format

Take the first EU record (`6f 28 73`) and do the whole job in one figure:

1. Hex dump of the full 46-byte record, colour-coded by region.
2. Decoded header.
3. Pair table decoded to µs.
4. First 8 indices decoded from the packed bytes, per D14's phase table.
5. WaveDrom envelope of the first ~8 chirps with each burst labelled by the pair
   index that produced it.

*Purpose:* the "aha" figure. Anyone who follows this one figure understands the
entire data path.

---

**D17 — AVR layout vs linear layout** · svg · avr-comparison

Two panels. Left: the original — a `code_t` struct with a pointer to a
`timer_pairs` array and a pointer to a bit-packed index array, drawn with the
pointer arrows that make it awkward for RTL. Right: the same information as one
flat byte stream where every region's location is computed by an adder. Below,
a two-row comparison of what the reader hardware needs: *pointer dereference*
vs *address register + adder*.

> Depends on M-04: the exact upstream struct layout must be read from the
> Adafruit repo before this figure is drawn, not reconstructed from memory.

---

**D18 — Controller FSM state diagram** · mermaid `stateDiagram-v2` · controller-fsm

All 12 states with every transition and its guard condition:

`S_RESET` → `S_IDLE` (unconditional, after clearing all registers) ·
`S_IDLE` → `S_READ_HEADER` [`start_in | loop_forever_in`] ·
`S_READ_HEADER` → itself [`byte_counter_r != 0`] → `S_CHECK_HEADER` ·
`S_CHECK_HEADER` → `S_RESET` [header all zero — end of table] ·
`S_CHECK_HEADER` → `S_READ_INDEX` [valid header] ·
`S_CHECK_HEADER` → `S_FAIL` [otherwise] ·
`S_READ_INDEX` → `S_CHECK_INDEX` ·
`S_CHECK_INDEX` → `S_READ_CARRIER_ON_TIME` [`chirp_pair_index < pairs_num`] ·
`S_CHECK_INDEX` → `S_FAIL` [otherwise] ·
`S_READ_CARRIER_ON_TIME` → itself → `S_CARRIER_ON` ·
`S_CARRIER_ON` → `S_READ_CARRIER_OFF_TIME` [delay elapsed or zero] ·
`S_READ_CARRIER_OFF_TIME` → itself → `S_CARRIER_OFF` ·
`S_CARRIER_OFF` → `S_PREPARE_NEXT_CYCLE` ·
`S_PREPARE_NEXT_CYCLE` → `S_READ_HEADER` [last chirp] ·
`S_PREPARE_NEXT_CYCLE` → `S_READ_INDEX` [`read_next_index_byte`] ·
`S_PREPARE_NEXT_CYCLE` → `S_READ_CARRIER_ON_TIME` [otherwise] ·
`S_FAIL` → terminal

Visual grouping: the four *read* states shaded as "ROM access", the two
*carrier* states as "emit", the two *check* states as "validate". Reset arrow
from anywhere shown once, as a note, rather than 12 arrows.

---

**D19 — Per-state action table** · markdown table · controller-fsm

Columns: State · ROM address driven · Registers written · `ctc_enable` ·
`ctc_forced` · `ctc_wr_strobe` · `delay_enable` · `busy` · `fail` · Cycles ·
Exit condition. One row per state. This is the table a reader consults while
reading the RTL, and it makes the output `assign` block at
`controller.sv:291-302` self-evident.

---

**D20 — Nested-loop activity flow** · mermaid `flowchart TD` · controller-fsm

The algorithm as pseudo-control-flow, deliberately *not* as an FSM: outer loop
"for each record until terminator", inner loop "for each chirp", innermost
"emit burst, emit gap". Shows where the index fetch happens relative to the
inner loop. Serves readers who think in software.

---

**D21 — One chirp, sequence diagram** · mermaid `sequenceDiagram` · controller-fsm

Four participants: `controller`, `tv_codes_rom`, `delay_timer`,
`ctc_generator`. Messages for one complete chirp: address for on-time low byte →
data; address for high byte → data; `delay_start_strobe` + value;
`ctc_enable` asserted; `delay_busy` high … low; `ctc_enable` deasserted; then
the same for the off-time. Cycle counts annotated on the left margin.

---

**D22 — Delay handshake timing** · wavedrom · controller-fsm

Two scenarios side by side.

*Normal:* `clk`, `state_r`, `delay_on_off_r`, `delay_start_r`,
`delay_enable_out`, `delay_busy_in`, `ctc_enable_out`. Shows the load, the
strobe being dropped once `busy` is seen, the wait, and the exit when `busy`
falls.

*Zero delay:* the `|delay_on_off_r == 0` shortcut, where the state exits
immediately because `busy_out` would never rise. Explain why this special case
must exist — a beginner will not spot it.

---

**D23 — Termination and failure paths** · mermaid · controller-fsm

A reduced FSM view showing only the exits: terminator → `S_RESET` → `S_IDLE`
(and straight back out if `loop_forever_in` is still high), plus the two
`S_FAIL` entries with the specific ROM-data defect each one detects
(`index_bits_num` illegal / `chirps_num == 0` / `pairs_num == 0`; and an index
pointing past the pair table). Note that `S_FAIL` is terminal and latches
`fail_out`.

---

**D24 — `ctc_generator` datapath** · svg · modules

`counter_r` and `ocr_r` registers, the `==` comparator, the `out` toggle
flip-flop, and the output mux `enable_in ? out : forced_in`. The
`update_comp_value_in` path into `ocr_r` shown gated by `!enable_in`, with a
callout that this is why the controller writes the OCR in `S_READ_INDEX`.
Comparison note: this is the same behaviour as an AVR timer in CTC mode, hence
the name.

---

**D25 — `ctc_generator` timing** · wavedrom · modules

`clk`, `enable_in`, `update_comp_value_in`, `compare_value_in`, `counter_r`,
`out`, `ctc_out`, `forced_in`. Uses a small OCR (3) so the toggling is visible.
Three phases: OCR load while disabled → enabled, showing period
`2 × (OCR+1)` → disabled with `forced_in` high, showing the constant-on
un-modulated case used when `frequency == 0`.

---

**D26 — `delay_timer` datapath** · svg · modules

Two cascaded counters: `unit_counter_r` (width `$clog2(CLK_MHZ × UNIT_COUNTS_US)`)
generating a 10 µs tick, feeding the decrement of `delay_r[15:0]`. The
combinational `busy_out = (delay_r != 0) && enable_in`, and the load path from
`delay_in` gated by `!busy_out`. Annotate the parameter arithmetic
`COUNTS_PER_UNIT = CLK_MHZ × UNIT_COUNTS_US` and what it becomes at the actual
clock rate (pending Q-01).

---

**D27 — `delay_timer` timing** · wavedrom · modules

Two zoom levels on one page: fine (individual clocks, `unit_counter_r` rolling
over, one `delay_r` decrement) and coarse (the whole delay, `busy_out` high
throughout, falling on the last unit). Uses a small `COUNTS_PER_UNIT` for
legibility with the real value stated in the caption.

---

**D28 — `btn_debouncer` datapath** · svg · modules

`counter_r` free-running down-counter → `enable` pulse every `PERIOD_MS` →
3-tap shift register `probe_r` → the edge-detect gate
`!probe_r[2] & probe_r[1] & probe_r[0]`. Annotate the real numbers
(`PERIOD_MS = 10`, `COUNT_PER_PERIOD = CLK_MHZ × 10000`).

---

**D29 — `btn_debouncer` timing** · wavedrom · modules

`btn_in` with realistic contact bounce, the `enable` sample ticks, `probe_r`
contents, and `btn_out` as a single one-cycle pulse well after the bouncing has
settled. A second trace shows a bounce burst shorter than one sample period
being ignored entirely. Caption gives the latency cost (up to ~3 sample
periods ≈ 30 ms).

---

**D30 — `tv_codes_rom` read path: async vs sync** · svg · modules

Two panels side by side, because the difference *is* the lesson (ADR-019).

*Left, async:* `rom_array` initialised by `$readmemh(INIT_FILE)`, a combinational
read straight to `data`, the `address_overflow` comparator and the zero-forcing
mux. No clock. Annotated: maps to plain LUT logic on iCE40; hardens to logic and
wires with no flip-flops on an ASIC; every controller read state is one cycle.

*Right, sync:* the same array with the address captured in a register, data
appearing the following cycle, and the overflow/zero-forcing logic moved to the
registered side. Annotated: maps to EBR (10 blocks for EU, 11 for NA, 17 for the
combined table, of 30); costs one wait cycle per read.

Beneath both, the rule that decides it, quoted: EBR reads are always registered,
so an asynchronous read can only become LUT logic. Plus a note that `$readmemh`
governs whether initial contents are *possible*, not which primitive is chosen —
the distinction that makes this whole figure necessary. And that SPRAM, despite
being 1 Mbit, cannot hold the table at all because it has no initialisation path.

`ADDRESS_BITS` shown in both as a `localparam` derived from `$clog2(SIZE)`.

---

**D31 — Build/tool flow with artifacts** · mermaid `flowchart LR` · build-and-program

Nodes for inputs (six `.sv` files, one `.mif`, one `.pcf`), tools
(`yosys` → `nextpnr-ice40` → `icetime` / `icepack` → `dfu-util`), and artifacts
(`pico-ice.json`, `pico-ice.log`, `pico-ice.asc`, `pico-ice.rpt`,
`pico-ice.bin`). Each tool annotated with the one-line question it answers:
"what gates?", "where do they go?", "is it fast enough?", "what bytes do I
send?", "how do I send them?". The `verilator` lint path shown as a side branch.

---

**D32 — Makefile target graph** · mermaid · build-and-program

Literal dependency graph of the five targets in `pico-ice/Makefile`
(`pico-ice.json`, `.asc`, `.bin`, `prog`, `lint`, `clean`), so a reader who has
never used `make` can see why typing `make prog` runs four tools.

---

**D33 — Pico-ICE pin map** · svg + table · hardware

The SG48 package drawn as a simple rectangle with the pins this project uses
marked and labelled with both the PCF signal name and the pin number: `clk_ext`
35 (unused), LEDs 39/40/41, `button_in` 10, `loop_forever_in` 11, `ir_led_out`
3, `ir_ledn_out` 6, `active_led_out` 4, `fail_led_out` 48. Unused/leftover PCF
entries shown separately and greyed, pending the PCF cleanup (A-03).

---

**D34 — IR LED drive options** · svg · hardware

Four small schematics on one figure, making the key point that **only one of the
two anti-phase outputs is used** and which one depends on your driver:

1. **Direct drive** from `ir_led_out` through a series resistor — simplest,
   lowest range, limited by pin current.
2. **NPN** low-side switch driven from `ir_led_out` (active high).
3. **PNP** high-side switch driven from `ir_ledn_out` (active low).
4. **Logic buffer / FET driver**, either polarity — pick whichever output makes
   the buffer non-inverting overall.

Each variant annotated with which pin to use and which to leave unconnected.
Caption states the design intent explicitly (ADR-006).

---

**D35 — Source file / instantiation graph** · mermaid · README

Two overlaid relationships: the instantiation hierarchy
(`pico_ice` → `tv_b_gone` → five leaves) and the compile order from the
Makefile prerequisite list. Also shows which `.mif` feeds `tv_codes_rom`.
Doubles as the "repository layout" figure.

---

**D36 — Cocotb testbench structure** · mermaid · verification · *deferred*

Reserved. DUT, cocotb coroutines, the reference ROM decoder in Python, the
scoreboard comparing emitted envelope against the decoded expectation.
To be drawn once the testbench exists (ADR-008).

---

## 7. Work plan

Phases are ordered so that nothing blocks on an open question that has not been
answered yet. Items marked ⚠ have a dependency in
[open-questions.md](open-questions.md).

| Phase | Work | Depends on |
| --- | --- | --- |
| **0** | These three planning files, reviewed and agreed | — |
| **0.5** | ✅ Diagram pipeline: `tools/render_diagrams.py`, `docs/diagrams/`, and D02 rendered end to end as the pilot figure (A-16) | — |
| **1** | ✅ Complete — `rom-format.md` (D10, D12, D13, D14, D15, D16; D08/D09/D11 as ASCII blocks), `ir-primer.md` (D02), `glossary.md` (32 entries) | — |
| **2** | ✅ `controller-fsm.md` (D18, D19, D20, D21, D22; D23 folded into D18). ✅ `modules.md` (D25, D27, D29) | ⚠ Q-01 for absolute times; write parameterised on `f_clk` and fill numbers later |
| **2.5** | ✅ A-15 — 56 comment lines added at the sites phases 1–2 showed were hard, plus the A-06 stale-comment fixes. Logic verified unchanged. | phases 1–2 |
| **3** | ✅ `architecture.md` (D04, D05; D06 folded into D04, D07 written as a formula), `design-notes.md` | — |
| **4** | `hardware.md` (D33, D34) | ⚠ M-03 schematic |
| **5** | ✅ `avr-comparison.md` (D17 as an ASCII layout pair). Upstream struct fetched and quoted. | — |
| **6** | ✅ `porting.md`, ✅ `build-and-program.md` (D31; D32 folded into it as a target table). Results from the EU build are quoted. | — |
| **7** | `README.md` (D01, D03, D35) — written **last**, so it can summarise settled material | phases 1–6 |
| **8** | Photos/captures P01, P02; fill in every Unconfirmed marker | ⚠ M-05, M-06 |
| **9** | `verification.md` (D36) after the cocotb work | ADR-008 |
| **10** | RTL follow-ups deliberately parked behind verification, in order: **A-14** (add the sync-read ROM alongside the async one, ADR-018/ADR-019 — do this first), A-11 (address-width parameterisation for the full code set, ADR-016), A-02 (NA `SIZE` tightening), C-10 (width pass-through), C-11 (header guard) — then per-style and per-variant Makefile targets | phase 9 |
| **11** | Revise the docs for the two ROM styles: `modules.md` (D30 becomes two panels), `design-notes.md` note 2, `rom-format.md` §10, `porting.md` §3-4 and `build-and-program.md` §5, plus the build matrix of style × code table | phase 10 |
| **12** | A-13 — build and release the two regional bitstreams, fill the provenance table in `bitstreams/README.md`, and drop the "not yet provided" warning from it and from the README quick start | phase 11 |

Rationale for writing the README last: it is a summary, and summarising material
that does not exist yet is how documentation drifts from reality.

## 8. Review checklist

Before the documentation set is declared done:

- [ ] Every figure has an ID, a caption, and is referenced from prose at least once
- [ ] Every RTL claim carries a file (and where useful, line) reference
- [ ] Every term in `glossary.md` is linked from its first use
- [ ] No `TODO`, no unmarked guess; every uncertainty is an `Unconfirmed` note with an open-questions ID
- [ ] The three verified ROM decode examples in §5.3 still match the shipped `.mif` files
- [ ] `README.md` reads standalone, with no forward dependency on `docs/`
- [ ] Diagram sources for every non-mermaid figure are committed under `docs/diagrams/src/`
- [ ] All links resolve (relative paths, correct case — matters on Linux)
- [ ] Attribution to the upstream Adafruit project is present in README and `avr-comparison.md`
- [ ] The committed bitstream is current, and its provenance is stated (ADR-017, A-13)
