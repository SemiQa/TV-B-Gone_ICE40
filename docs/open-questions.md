# Open Questions, Actions and Missing Artifacts

Working tracker for everything the documentation needs but does not yet have.
Nothing in here is a guess: items are either answered, or explicitly open.

Last updated: 2026-08-17

**ID scheme**

| Prefix | Meaning |
| --- | --- |
| `Q-nn` | Open question — needs an answer before the affected text can be written |
| `A-nn` | Action — work to be done, answer already known |
| `M-nn` | Missing artifact — a file, measurement, image or dataset we need |
| `C-nn` | Code observation — something found while reading the RTL, to confirm or fix |

**Status values:** `open`, `answered`, `in progress`, `done`, `deferred`,
`won't do`.

---

## 1. Summary

| Bucket | Open / in progress | Answered / done | Deferred |
| --- | --- | --- | --- |
| Questions | — | 9 | — |
| Actions | 5 | 7 | 4 |
| Missing artifacts | 4 | 2 | — |
| Code observations | 12 | 1 | — |

**Blocking the documentation right now:** nothing. M-03 was answered with a
wiring spec (2026-10-18) and M-01 was resolved by rewriting the converter as
`tools/gen_rom.py`. The current to-do list is in [start-here.md](start-here.md).

**Parked until the cocotb testbench exists:** A-14 (add the synchronous-read ROM
alongside the async one, so the table can reach EBR), A-11 (address-width
parameterisation for the full code set) and A-02 (NA `SIZE` tightening). All are
RTL changes that should be verified rather than reasoned about.

---

## 2. Open questions

> All questions are answered except Q-01, which is parked on one clarification
> rather than blocking anything.

### Q-01 — Core clock: 8 MHz or 4 MHz? · **parked, needs one clarification**

**Reported as verified: 8 MHz.** All documentation and RTL comments now state
8 MHz on that basis, and the ROM compare values only make sense there — `0x67` =
103 gives 38.46 kHz at 8 MHz, against 19.2 kHz at 4 MHz.

**One reading still disagrees.** In `pico_ice.sv:33-42`, `div3_r` cycles 0 → 2 →
1 → 0, so `clk_8M` toggles once every three 24 MHz cycles. That is 8 M *toggles*
per second; a full period needs two toggles, which makes the waveform 4 MHz.

Both cannot be true, and the difference is a factor of two on every duration and
carrier frequency in the project.

**The one question that settles it:** was the measurement taken on the **carrier**
(≈38 kHz on a scope, which implies an 8 MHz core clock and means the divider
reading above is wrong somewhere), or on **`clk_8M` itself**?

- If the carrier: the divider analysis here is wrong and should be deleted, not
  left as a standing doubt.
- If the clock pin: the arithmetic above has something missing, worth finding
  before anyone regenerates a ROM against it.

Nothing is blocked meanwhile — every affected page states "8 MHz" plainly. What
waits is closing this entry, ADR-015, and A-05.

---

## 3. Answered questions

Kept for the record, since the answers drove ADRs.

| ID | Question | Answer | Became |
| --- | --- | --- | --- |
| Q-02 | How should the combined ROM's 14-bit address width be handled? | Intent was one region per build at 13 bits. Add a third build variant for the full set and let the address width follow `$clog2(ROM_SIZE)`, so selecting a table is the only decision. Implementation parked until after the testbench. | ADR-016, A-11 |
| Q-03 | How are the `.mif` files generated? | A Python script converts the upstream world code tables; the linearisation happens there. | ADR-010, M-01 |
| Q-04 | How detailed should the AVR comparison be? | Simple comparison. | ADR-007 |
| Q-05 | Does the ROM map to EBR or to logic? | **To logic — now measured, not inferred.** The EU build uses 3664 SB_LUT4 and **zero** `SB_RAM40_4K`. yosys logs `MEMORY_MAP ... converting memories to logic`, turning `rom_array` into an 8191-mux read tree over constant data, which ABC minimises into LUTs. It fits (69 % of 5280 LUTs) and meets timing. See M-02 for the figures. | ADR-018, A-14 |
| Q-06 | What are the unmatched PCF entries? | Leftovers from debugging and other projects; remove the unused ones. | ADR-009, A-03 |
| Q-07 | Should the docs cover simulation? | Not yet — a cocotb testbench comes after the documentation and gets documented then. | ADR-008 |
| Q-08 | How is the IR LED wired? | Two anti-phase outputs, of which exactly one is used; they exist so any driver arrangement (NPN, PNP, buffer, or direct) can pick a convenient polarity. | ADR-006, D34 |
| Q-09 | Diagram tooling and language? | **Mermaid and WaveDrom.** Both verified working; WaveDrom's `reg` mode also covers bit-field and byte-layout figures, shrinking the hand-authored set to roughly D34 alone. English. | ADR-002, A-16 |
| Q-10 | Why three ROM variants? | Targeted builds, and to fit a small ASIC later. `SIZE` is rounded up so the stop sequence cannot be clipped. | ADR-004, ADR-005 |

---

## 4. Actions

### A-01 — Write the documentation set · **in progress**

Per the phase plan in [documentation-plan.md](documentation-plan.md) §7. Phases
1–3 can start now; phases 4–6 wait on M-02/M-03/M-04.

### A-02 — Tighten the NA ROM `SIZE` from 5320 to 5316 · **deferred** · small

`na_tv_codes_rom.mif` holds 5314 bytes with the `00 00 00` terminator at offsets
5311–5313. `SIZE = 5316` keeps the even-number property and the 13-bit address
width while shrinking the uninitialised tail from 6 bytes to 2. Also worth
reviewing the EU value (`4740` against 4739 actual bytes — 1 byte of tail).

Do this **after** the cocotb testbench exists so the change can be verified
rather than assumed. Per ADR-005.

### A-03 — Clean the PCF · **done** (2026-09-17)

Done. `pico-ice/pico-ice.pcf` now holds nine `set_io` lines, every one matching a
real port: `clk_ext`, the three board LEDs, `button_in`, `loop_forever_in`,
`ir_led_out`, `ir_ledn_out`, `active_led_out`, `fail_led_out`. The `uart_*` and
`trace_*` leftovers are gone.

`clk_ext` is deliberately kept although the design runs from the internal
oscillator, so the pin stays available as an alternative clock source (C-04).

### A-04 — Commit the ROM converter script · **done** (2026-10-18)

The original could not be recovered, so it was rewritten as
[`tools/gen_rom.py`](../tools/gen_rom.py) and documented in `tools/README.md` and
`rom-format.md` "Generating a table". See M-01.

### A-05 — Reconcile the clock comment and parameters with the measurement · **open**

Depends on Q-01. If the effective clock is not 8 MHz: fix the divider or the
comment at `pico_ice.sv:34`, rename `clk_8M`, and correct the `CLK_MHZ`
defaults. If it is 8 MHz, just correct the comment's wording so it is not
misleading.

### A-06 — Fix stale comments in the RTL · **done**

Found while reading:

- `tv_b_gone.sv:95` — "starts working when low"; the signal is active **high**
  (`controller.sv:19` and `pico_ice.sv:69`, which does the inversion).
- `tv_b_gone.sv:13` and `controller.sv:19` — "synchroous" typo, twice.
- `pico_ice.sv:34` — the divider comment, per A-05.
- `controller.sv:140` — a `// TODO: add constants` left on the counter
  declarations.

Worth doing before the documentation quotes these lines.

### A-07 — Update the README status section when the testbench lands · **open**

Per ADR-008. The README will state "no automated tests yet"; that sentence and
the documentation map both change when `docs/verification.md` is added.

### A-08 — Record toolchain versions · **done**

`docs/build-and-program.md` names Yosys 0.68+58 (git edbc62a44), the version that
produced the committed results. The OSS CAD Suite release number itself is not in
the log; the yosys version identifies it well enough for a reader comparing
numbers.

### A-09 — Decide the `docs/` planning-file endgame · **open** · low priority

`documentation-plan.md`, `adr.md` and `open-questions.md` are working files.
`adr.md` is worth keeping permanently. The other two should either be trimmed to
a short maintenance note or moved out of `docs/` once the documentation is
complete, so readers are not handed a planning document as if it were
documentation.

### A-10 — Add a `docs/` index or table of contents · **deferred**

Only worth doing if `docs/` grows past ~12 pages; the README's documentation map
covers it until then.

### A-11 — Parameterise the ROM size and address width in `tv_b_gone` · **deferred** · after testbench

Implements ADR-016, enabling a third build variant that carries the full code
set. **Deliberately parked until the cocotb testbench exists**, so the change can
be verified rather than reasoned about, and until Q-05 confirms the combined
table is feasible at all.

Audit of what has to change — the complete list, verified by grep over `src/`
and `pico-ice/`:

| File | Line | Current | Needed |
| --- | --- | --- | --- |
| `tv_b_gone.sv` | 37 | `wire [12:0] rom_address;` | `wire [ROM_ADDRESS_BITS-1:0]` |
| `tv_b_gone.sv` | 42 | `tv_codes_rom rom (` — no overrides, so `SIZE`/`INIT_FILE` defaults bake the EU table in at the instance | pass `ROM_SIZE`, `ROM_INIT_FILE` |
| `tv_b_gone.sv` | 90 | `controller tvbgone_ctrl (` — no overrides, so `ADDRESS_BITS` defaults to 13 | pass `ROM_ADDRESS_BITS` (and see C-10) |
| `pico_ice.sv` | 64 | `tv_b_gone tv_gone (` — no overrides | only if the region is to be chosen at board level rather than by `tv_b_gone`'s default |

Confirmed to need **no** change, because they already scale:

- `controller` — every address register and both offset constructions are
  parameterised. `{(ADDRESS_BITS-1-6){1'b0}}` yields 13 bits at
  `ADDRESS_BITS=14` and is zero-extended into the 14-bit addition; correct at
  both widths (see C-05).
- `tv_codes_rom` — `localparam ADDRESS_BITS = $clog2(SIZE)` derives itself.
- `ctc_generator`, `delay_timer`, `btn_debouncer` — no address involvement.

Sizes to use, following the ADR-005 rounding policy: EU `4740`, NA `5316`
(per A-02), full set `8272` (even, multiple of 16, `$clog2` = 14).

### A-12 — Commit the ROM walker script · **done**

Committed as [`tools/walk_rom.py`](../tools/walk_rom.py), with
[`tools/README.md`](../tools/README.md) documenting it. Replays a `.mif` using
the FSM's exact fetch rules (the `index_bit_delta` special case, the 3-bit phase
table, the "final chirp does not fetch" rule,
`next_pos = last_index_byte + 1`) and reports record count, terminator position,
highest address touched, distinct carrier values, and any reachable `S_FAIL`
condition. Exits non-zero on a problem, so it is usable as a CI check.

Serves two purposes: an independent check that the generator (A-04) and the RTL
agree on the fetch pattern, and the **reference model** for the cocotb scoreboard
— `walk()` plus `envelope()` yield `(ocr, on_units, off_units)` per chirp, which
is exactly the expected DUT output (ADR-008).

Deliberately takes the clock rate as an argument in `carrier_hz()` rather than
hard-coding one, per ADR-015 / Q-01.

### A-13 — Release two regional bitstreams, with provenance · **done** (2026-09-17)

Per ADR-017, one released bitstream per region so people without the toolchain
can flash the board:

| File | Code table | Depends on |
| --- | --- | --- |
| `bitstreams/pico-ice-eu.bin` | `rom/eu_tv_codes_rom.mif` | released |
| `bitstreams/pico-ice-na.bin` | `rom/na_tv_codes_rom.mif` | released; A-02 would change it |

**Two releases, not three.** The combined table is dropped from the release set
because it does not fit as logic.

The reasoning behind that was initially wrong and is worth recording correctly.
Scaling the EU build's 3664 LUTs by bytes gives about 0.77 LUTs per byte and
predicts 6400 for the combined table — but the NA build disproves that model. NA
holds 580 more bytes than EU and costs only 178 more LUTs, a marginal rate of
0.31 per byte, because **both tables produce the same 8191-node decode tree** and
only the data contents differ.

The cost tracks the tree, not the byte count: 3664/8191 = 0.45 LUTs per node for
EU, 3842/8191 = 0.47 for NA. The combined table needs 14 address bits, so a
16383-node tree — roughly 7400 LUTs on that ratio, against 5280 available. The
conclusion is unchanged and the margin is larger than the byte-scaling estimate
suggested.

A combined build becomes possible only alongside A-14: with a registered read the
table moves into EBR, where 17 of 30 blocks would hold it. Until then A-11 has no
release depending on it.

The async/LUT build **does** fit for a single region — 69 % of the device for EU —
so the EU and NA releases can be built from the RTL as it stands.

Both binaries are in `bitstreams/` as `pico-ice-eu.bin` and `pico-ice-na.bin`,
104 090 bytes each, built 2026-09-17. The provenance table in
`bitstreams/README.md` is filled with the code table, board, clock, toolchain
version, utilisation and timing for each.

One column is still blank: the **source commit** each was built from. The
repository is not a git checkout here, so it cannot be filled automatically. Worth
adding when the project is next committed, since without it a stale binary cannot
be told from a current one.

Released ahead of the cocotb verification rather than after it, so the note in
`bitstreams/README.md` warns that releases can lag the RTL.

**Prerequisite Makefile work.** Producing three variants needs per-variant
targets that pass `ROM_SIZE` / `ROM_INIT_FILE` through to `tv_b_gone`, which only
becomes possible once A-11 lands. Currently `pico-ice/Makefile` builds exactly one
configuration, from the `tv_codes_rom` defaults.

**Staleness is the real risk**, and three files triple the exposure. Rebuilding
them has to be part of any RTL change. Worth a CI job that rebuilds and diffs
them, if this project ever gets CI.

---

## 5. Missing artifacts

### A-14 — Add a synchronous-read ROM alongside the async one · **deferred** · after testbench · high value

Implements ADR-018 as amended by ADR-019: **both** styles, selectable, rather than
replacing the async read. The async version is kept because it is the better
starting point for ASIC hardening — a combinational mask-programmed array becomes
logic and wires with no flip-flops in the read path — and because it is the simpler
FSM to read first. The sync version is the practical FPGA default and reaches EBR.

Scope:

- **new** `src/tv_codes_rom_sync.sv` — registered read: address captured on the
  clock edge, data the next cycle; `address_overflow` and the zero-forcing mux move
  to the registered side. Gains a clock port.
- **rename** `src/tv_codes_rom.sv` → `tv_codes_rom_async.sv`, behaviour unchanged,
  so the two sit side by side and the diff is legible. (Keeping the two as separate
  files rather than one `generate` is deliberate — that diff is figure D30.)
- `controller.sv` — a `ROM_READ_LATENCY` parameter (0 or 1) inserting one wait
  cycle in `S_READ_HEADER`, `S_READ_INDEX`, `S_READ_CARRIER_ON_TIME` and
  `S_READ_CARRIER_OFF_TIME`.
- `tv_b_gone.sv` — select the module, pass the matching latency, connect the clock
  in the sync case.
- `pico-ice/Makefile` — per-style build targets.

Expected result for the sync variant: 10 EBRs for EU, 11 for NA, 17 for the
combined table, of 30 available. Timing cost about five clock cycles per chirp,
under 0.1 % of a chirp period, falling in the gaps between bursts rather than
inside them.

**Do this before A-11 and A-13.** The combined table is only viable in the sync
flavour, so A-11's scope depends on it, and any bitstream released earlier would be
a release of the LUT-mapped build.

> [!IMPORTANT]
> This change alters the FSM's cycle-level timing. The cocotb testbench must check
> the **emitted envelope** against `tools/walk_rom.py`, not exact cycle counts. An
> envelope test then validates *both* implementations unmodified — and in doing so
> proves they are functionally equivalent, which is the whole point.

### A-15 — Comment the non-obvious parts of the RTL · **done**

Per ADR-020: comments only where something is genuinely hard to read, explaining
the local mechanism and cross-referencing the docs by name rather than restating
them. No comments on self-evident code.

Done after phases 1–2, so the sites came from what the documentation actually
needed a paragraph or a figure to explain. 56 comment lines added across seven
files, verified to change no logic by stripping comments from before and after and
diffing.

Sites commented:

| File | Site | Why it is not obvious |
| --- | --- | --- |
| `controller.sv:43-47` | reversed `header_r` load order | `byte_counter_r` counts down, so file byte 0 lands in `header_r[2]` |
| `controller.sv:104` | `index_bit_delta` is 1 for 3-bit | makes the offset an 8-phase counter, not a bit offset (C-07) |
| `controller.sv:93-101` | `read_next_index_byte` | evaluated on the pre-increment offset |
| `controller.sv:110-122` | 3-bit phase case table | the rolling 3-byte window |
| `controller.sv:200` | `index_vector_r` shift | carries 2 bits across the byte boundary; 10 bits is exactly enough |
| `controller.sv:192, 286` | `{(ADDRESS_BITS-1-6){1'b0}}` | reads as off-by-one but is correct (C-05) |
| `controller.sv:261` | next record = last index byte + 1 | the implicit record boundary |
| `controller.sv:223, 247` | `|delay_on_off_r == 0` shortcut | without it a zero delay would hang, since `busy` never rises |
| `ctc_generator.sv:42` | `ocr_r` loads only while disabled | why the controller strobes it in `S_READ_INDEX` |
| `btn_debouncer.sv:49` | `!probe_r[2] & probe_r[1] & probe_r[0]` | one-cycle pulse on a confirmed edge, not a level |

Also fixed the stale comments listed in A-06: the "starts working when low" on an
active-high port, both `synchroous` typos, and `pico_ice.sv`'s divider comment,
which now describes what the counter does without asserting an output frequency
while Q-01 is open.

The `// TODO: add constants` in `controller.sv` was **left in place** — it is an
unactioned reminder about naming the magic numbers, not a stale comment, and
removing it without doing the work would lose it.

### A-16 — Diagram render script · **done**

[`tools/render_diagrams.py`](../tools/render_diagrams.py) renders
`docs/diagrams/src/*.json` to committed SVGs in `docs/diagrams/`, injecting the
white background rect that keeps figures visible on GitHub's dark theme. Three
modes: default (render stale only, by mtime), `--force`, and `--check` for CI.
Documented in [`../docs/diagrams/README.md`](diagrams/README.md) and
[`../tools/README.md`](../tools/README.md).

Verified working end to end on figure D02, including the Windows `npx.cmd`
path, skip-when-unchanged, and `--check`.

Seven authoring constraints found while doing it, all recorded in
`docs/diagrams/README.md` so the next figure does not rediscover them:

- **Use `l`/`h`, not `0`/`1`, for levels.** `0`/`1` slant their transitions into
  diagonal ramps; `l`/`h` draw straight vertical edges.
- **Extend with `.`, never repeat the level character.** `"hhhh"` draws a notch at
  each repeat that looks like a glitch; `"h..."` is clean.
- **Gate clock bursts with `p`, not `n`.** An `n` slot is low-then-high, so a burst
  ends high, and WaveDrom omits the falling edge at a clock-to-level boundary —
  the burst looks like it is missing an edge. A `p` slot is high-then-low, so the
  burst ends on the low rail and both sides render.
- **Give every pulse at least two slots.** One-slot pulses read as Dirac spikes.
- **Match trace lengths across groups**, or the figure has a ragged right edge that
  reads as a rendering fault.
- **Group labels render as rotated text** down the left edge and collide past about
  six characters. One short word only.
- **`head`/`foot` text is not wrapped or measured** against the image width, so a
  long line is silently clipped. Provenance and unit conversions belong in the
  markdown caption.

### C-12 — The 4-bit index path is never exercised by shipped data · **open** · test coverage

`index_bits_num == 4` is supported by `controller.sv` and is deliberate headroom
for future tables ([ADR-021](adr.md#adr-021--leave-headroom-in-the-header-bit-fields)),
not dead code. But no record in any of the three shipped tables uses it — the
counts are 2 bits in 62 EU / 35 NA records and 3 bits in 76 EU / 102 NA, with 4
bits nowhere.

The path is therefore correct by construction rather than by evidence. The cocotb
testbench should carry a synthetic record using 4-bit indices, since nothing in the
shipped data would catch a defect there. `tools/walk_rom.py` already implements the
4-bit case, so it can generate the expected output for such a record.

The same applies less sharply to `pairs_num` above 8, which the field allows up to
15 but no shipped record reaches.

### M-01 — The Python ROM converter script · **resolved by rewrite** (2026-10-18)

The original is lost. `tools/gen_rom.py` replaces it: it converts upstream
`firmware/WORLDcodes.c` at commit `7fc4877` (SHA-256 pinned, downloaded, never
committed — owner's rule) and reproduces `eu_tv_codes_rom.mif`,
`na_tv_codes_rom.mif` and `tv_codes_rom.mif` byte for byte. `F_CPU` = 8 MHz from
the upstream Makefile; `--clock-hz` recomputes the compare values for another
clock. Facts found on the way: the three tables are the three upstream Makefile
builds (`EU_CODE=1`, `NA_CODE=1`, default both); several EU entries use NA
definitions that upstream puts inside `#ifdef NA_CODES`, so upstream's own
EU-only build would not resolve them, and the generator reads definitions from
the whole file; `codes[]` holds exactly the bytes the controller fetches for all
270 codes.

### M-02 — Synthesis and timing results · **delivered** (2026-09-17)

Received for **both regional builds**, archived per region:
`pico-ice/eu/` and `pico-ice/na/`, each holding `pico-ice.log` (yosys),
`pico-ice.json` (netlist), `pico-ice.asc` (placed design) and `pico-ice.rpt`
(icetime). Bitstreams are in `bitstreams/`, 104 090 bytes each.

**Toolchain:** Yosys 0.68+58 (git edbc62a44). Zero warnings.

**Utilisation** — final netlist, module `pico_ice`:

| Cell | Count |
| --- | --- |
| Cell | EU | NA |
| --- | --- | --- |
| `SB_LUT4` | 3664 | 3842 |
| `SB_CARRY` | 127 | 126 |
| Flip-flops (all `SB_DFF*` variants) | 181 | 181 |
| `SB_HFOSC` | 1 | 1 |
| `SB_RAM40_4K` | **0** | **0** |

69 % of the UP5K's 5280 LUT4s for EU, 73 % for NA, so both LUT-mapped builds
**fit**. Everything outside the code table is identical between them, one carry
cell apart.
The four leaf modules account for only 88 LUTs between them (`delay_timer` 41,
`btn_debouncer` 24, `ctc_generator` 23); the code table dominates the rest.
A per-module split is not recoverable from this netlist, because ABC names each
LUT after the register it feeds rather than its source module.

**Why it is logic.** yosys states the conversion outright:

```
Mapping memory 	v_gone.rom.rom_array in module \pico_ice:
  created 4740 $dff cells and 0 static cells of width 8.
  read interface: 0 $dff and 8191 $mux cells.
```

8191 is a full binary mux tree over 13 address bits. The 4740 x 8 registers hold
constant data and fold away, leaving the mux tree, which ABC minimises into the
3664 LUTs.

**Timing** — icetime, conservative (`max_span_hack` enabled):

| | |
| --- | --- |
| | EU | NA |
| --- | --- | --- |
| Critical path | 69.59 ns | 70.36 ns |
| Implied maximum | 14.37 MHz | 14.21 MHz |
| Path endpoint | `delay_on_off_r`, through the code-table logic | same |

Against the 8 MHz core clock (125 ns) that passes with roughly 1.8x margin, and
the real margin is larger since the estimate is conservative. The critical path
running through the table is the combinational read showing up in timing.

**Still absent, and no longer worth chasing:** the nextpnr utilisation block
(`Info: Device utilisation ...`). The Makefile does not redirect nextpnr's output,
so it went to the console. It would give the authoritative `ICESTORM_LC` count,
but the yosys cell counts and the `.asc` cover the same ground. Capturing it needs
`nextpnr-ice40 ... 2> pnr.log` whenever the Makefile is next touched.

### M-03 — Schematic or wiring sketch for the IR LED and buttons · **done** (2026-10-18)

Answered with a wiring spec from the owner; drawn as D34a and D34b in
`hardware.md`, reviewed and accepted the same day. The original request follows.

D34 needs real part values to be useful rather than decorative: series resistor
value, transistor type, LED part, and how `button_in` / `loop_forever_in` are
pulled. A photo of your actual wiring would be enough.

### M-04 — Upstream AVR data-structure layout · **open** · blocks phase 5

D17 compares the original `PROGMEM` layout with the linear format. The original
struct definition must be read from the upstream repository
(`adafruit/TV-B-Gone-kit`, `firmware/`) rather than recalled.

**Either:** grant web access so it can be fetched and quoted accurately, **or**
paste the relevant struct and table declarations here.

### M-05 — Carrier frequency measurement / recording · **open** · resolves Q-01

You have recordings that show a correct carrier and will re-check the frequency.
What the documentation needs: the measured carrier frequency for a known code,
and ideally a scope or logic-analyser capture usable as figure P02.

### M-06 — Board photo or demo capture · **open** · nice to have

Figure P01 for the README. A photo of the Pico-ICE with the IR LED attached, or
a short GIF of the status LED during a run.

---

## 6. Code observations

Found while reading the RTL for the documentation. **None of these are known
bugs** — they are things the documentation would have to either explain or
quietly paper over, so it is better to decide about each one deliberately.

### C-01 — `clk_8M` divider ratio · **open** · see Q-01

`pico_ice.sv:33-42`. The central question. Highest-impact item in this file.

### C-02 — Blocking assignment inside a clocked block · **open** · style

`pico_ice.sv:37` uses `clk_8M = !clk_8M` (blocking) inside
`always @(posedge clk_24M)`. It synthesises to the intended flip-flop here, but
mixing blocking assignment into sequential logic is the classic source of
simulation/synthesis mismatch, and it will matter once there is a cocotb
testbench. `<=` would be the conventional choice. Also `div3_r` has no reset and
relies on power-up state.

### C-03 — Global clock buffer commented out · **open**

`pico_ice.sv:44-50`. The `SB_GB` instantiation is commented out, so the derived
core clock is distributed on general routing rather than a global clock network.
For a design this small it evidently works; it is worth either restoring or
documenting as a deliberate choice, since "why is my clock not on a global
buffer" is a genuinely instructive topic for the target audience.

### C-04 — `clk_ext` declared but unused · **open** · cosmetic

`pico_ice.sv:8` declares `clk_ext` (PCF pin 35, the 12 MHz clock from the RP2040)
but the design uses the internal oscillator. Either remove it or add a comment
saying it is available as an alternative clock source. `docs/hardware.md` needs
to say which is used, since the pin being constrained implies otherwise.

### C-05 — Address offset vector width reads as off-by-one · **open** · readability

`controller.sv:192` and `controller.sv:286` build offsets as
`{ {(ADDRESS_BITS-1-6){1'b0}}, ..., 2'b00 }`, which is `ADDRESS_BITS-1` bits
wide, not `ADDRESS_BITS`. It is correct — the value is zero-extended in the
addition, and only 6 bits of magnitude are ever needed since `pairs_num ≤ 15` so
`pairs_num << 2 ≤ 60` — but it looks like a mistake to anyone reading it, which
is a problem in a project meant to serve as a teaching example. A short comment
would fix it. Also relevant to Q-02.

### C-06 — Unmatched PCF constraints · **moot** (2026-09-17)

What does nextpnr currently do with `set_io` for a port that does not exist —
warn or error? Needs confirming from a real build log, and is worth a sentence
in the build documentation either way.

### C-07 — `index_bit_offset_r` is a phase counter, not a bit offset · **open** · documentation only

`controller.sv:104` forces `index_bit_delta` to 1 when `index_bits_num == 3`, so
in the 3-bit case the register counts phases 0–7 over a 3-byte window rather
than bit positions. The name actively misleads. Not worth renaming, but D14 and
`docs/rom-format.md` must call it out explicitly or every reader will lose ten
minutes here.

### C-08 — Timing constraint mismatch · **answered, harmless**

`Makefile:8` passes `--freq 10` to nextpnr and `Makefile:11` passes `-c 12` to
`icetime`; neither matches the 8 MHz core clock.

Measured outcome: the design reaches 14.37 MHz, so nextpnr's 10 MHz target is met
and exceeded, and `icetime`'s 12 ns constraint is only reported against, never
enforced. Both numbers are harmless, and `docs/build-and-program.md` says so
rather than presenting them as deliberate.

Tidying them to 8 MHz would still be worth doing whenever the Makefile is next
touched.

### C-09 — `loop_forever_in` is neither debounced nor synchronised · **open** · by design?

`tv_b_gone.sv:96` routes the pin straight to the controller, where it is sampled
as a level in `S_IDLE` (`controller.sv:170`). Unlike `start_in` it gets no
debouncer and no synchroniser. For a static mode switch that is defensible —
a glitch only causes an extra playback — but it is a metastability path worth one
sentence in `docs/modules.md`, especially in a design used as a learning example
where "always synchronise your asynchronous inputs" is a lesson worth teaching.

### C-10 — `CTC_WIDTH` / `DELAY_WIDTH` are not passed to the controller · **open**

`tv_b_gone.sv:34-35` declares `CTC_WIDTH = 8` and `DELAY_WIDTH = 16` and passes
them to `ctc_generator` and `delay_timer`, but **not** to `controller`, whose own
`CTC_BITS` / `DELAY_BITS` parameters (`controller.sv:11-12`) default to 16 and 8
independently. They currently agree by coincidence, not by construction: change
`CTC_WIDTH` in `tv_b_gone` and the controller's carrier value port would no
longer match the generator's.

Same class of error-proneness that ADR-016 exists to remove, so fix it in the
same pass as A-11.

### C-11 — `S_CHECK_HEADER` accepts four illegal `index_bits_num` values · **open**

Found while writing `tools/walk_rom.py` against the RTL. `S_CHECK_HEADER`
(`controller.sv:188`) validates the header with
`(index_bit_delta != 0) && (chirps_num != 0) && (pairs_num != 0)`. Because
`index_bit_delta` is `1` for the value 3 and otherwise the value itself
(`controller.sv:104`), the only `index_bits_num` this rejects is **0**. Values
1, 5, 6 and 7 pass the check but are not decoded correctly by the index mux
(`controller.sv:136-138`):

| `index_bits_num` | Passes `S_CHECK_HEADER` | Index mux behaviour |
| --- | --- | --- |
| 0 | no — `S_FAIL` | — |
| 1 | **yes** | always returns index 0 |
| 2, 3, 4 | yes | correct |
| 5 | **yes** | always returns index 0 |
| 6 | **yes** | decoded as 2-bit, but `read_next_index_byte` never fires, so it re-reads one byte indefinitely |
| 7 | **yes** | decoded as 3-bit, same non-fetching problem |

Severity is low: the field is entirely generator-controlled, and all 503 records
in the three shipped tables use only 2 and 3 — verified by `tools/walk_rom.py`,
which flags these values separately from genuine `S_FAIL` conditions. So this is
not a live bug.

Deliberately **not** described in `docs/rom-format.md`, per ADR-022: a reference
page for a working system should not carry a catalogue of its own defects. This
entry is the record.

Same class as C-13 below: a guard that reads like validation but only covers part
of what it appears to.

It matters for two reasons anyway. The documentation describes
`S_CHECK_HEADER` as a sanity check, and should be honest that it is a partial
one. And a project offered as a teaching example is a poor place to leave a
validation gap unremarked. Tightening the guard to
`(index_bits_num >= 2) && (index_bits_num <= 4)` costs almost nothing.

### C-13 — `S_CHECK_INDEX` validates only the first chirp after each fetch · **open**

Found while drawing the control-flow figure for `controller-fsm.md`.
`S_CHECK_INDEX` is reachable only from `S_READ_INDEX`
([`controller.sv:199-210`](../src/controller.sv#L199-L210)). Chirps whose index
comes from an index byte that is **already loaded** reach
`S_READ_CARRIER_ON_TIME` directly from `S_PREPARE_NEXT_CYCLE`
([`controller.sv:270-272`](../src/controller.sv#L270-L272)) and are never range
checked.

So the `chirp_pair_index < pairs_num` guard covers one chirp per index fetch:

| `index_bits_num` | Fetches per N chirps | Chirps validated |
| --- | --- | --- |
| 2 | 1 per 4 | 1 in 4 |
| 3 | 3 per 8 | 3 in 8 |
| 4 | 1 per 2 | 1 in 2 |

An unchecked out-of-range index would read past the end of the pair table into
whatever bytes follow, producing a wrong duration rather than `S_FAIL`.

Not a live bug: the field is generator-controlled, and `tools/walk_rom.py` confirms
every index in all 503 shipped records is inside its record's pair table.

**Suggested fix — one line.** Send the non-fetching path through `S_CHECK_INDEX`
as well. At [`controller.sv:271`](../src/controller.sv#L271), inside
`S_PREPARE_NEXT_CYCLE`:

```systemverilog
                    if (read_next_index_byte) begin
                        index_byte_address_r <= index_byte_address_r + 1;
                        state_r <= S_READ_INDEX;
                    end else begin
-                       state_r <= S_READ_CARRIER_ON_TIME;
+                       state_r <= S_CHECK_INDEX;
                    end
```

The fetch path already runs `S_READ_INDEX → S_CHECK_INDEX → S_READ_CARRIER_ON_TIME`,
so afterwards both paths are validated by the same state and no new logic is added.

Three things make this safe, all checked against the current RTL:

- `index_bit_offset_r` is updated on the edge *leaving* `S_PREPARE_NEXT_CYCLE`
  ([`controller.sv:266`](../src/controller.sv#L266)), so `S_CHECK_INDEX` evaluates
  the index for the chirp about to be emitted.
- `byte_counter_r` is already 0 on entry, because it wrapped from 3 in
  `S_READ_CARRIER_OFF_TIME`. `S_CHECK_INDEX` does not touch it, and
  `S_READ_CARRIER_ON_TIME` needs it to start at 0.
- `S_CHECK_INDEX` drives no ROM address and asserts no output beyond `busy`, so
  inserting it changes nothing but timing.

Cost is one clock per chirp: per-chirp overhead goes from about 6–7 cycles to
about 7–8, still under a microsecond at 8 MHz against chirps of tens of
microseconds upward.

Worth doing in the same pass as C-11, and covering in the cocotb testbench with a
record whose *second* index is deliberately out of range — the shipped data cannot
exercise this path.

---

## 7. Verified facts

Recorded here so they are not re-derived later. All checked against the shipped
files in this working copy.

**ROM record format** — `header (3 B) · pair table (pairs_num × 4 B) · packed
index bytes`, records back to back, `00 00 00` header terminates the table.

Header: byte 0 = carrier compare value, byte 1 = `chirps_num`, byte 2 =
`{pairs_num[7:4], unused[3], index_bits_num[2:0]}`. The FSM loads them into
`header_r[2]`, `[1]`, `[0]` respectively, because `byte_counter_r` counts down.

Pair table entry: two little-endian 16-bit values, on-time then off-time, in
10 µs units.

**Decode examples**, verified byte-for-byte against `eu_tv_codes_rom.mif`:

| Header | freq (OCR) | chirps | pairs | idx bits | pair bytes | index bytes |
| --- | --- | --- | --- | --- | --- | --- |
| `6f 28 73` | 0x6f = 111 | 40 | 7 | 3 | 28 | 15 |
| `83 1f 73` | 0x83 = 131 | 31 | 7 | 3 | 28 | 12 |
| `77 1a 42` | 0x77 = 119 | 26 | 4 | 2 | 16 | 7 |

The index-byte counts confirm the fetch rule: a byte is fetched on entry and
then whenever `read_next_index_byte` is true for the chirp just completed, and
the final chirp never triggers a fetch. This is why the count is not simply
`ceil(chirps × bits / 8)`.

**File sizes** — `eu_tv_codes_rom.mif` 4739 B (terminator at 4736–4738),
`na_tv_codes_rom.mif` 5314 B (terminator at 5311–5313),
`tv_codes_rom.mif` 8269 B. Declared `SIZE` defaults: EU 4740, NA 5320.

**Full-ROM walk results** — produced by replaying each file with the FSM's exact
fetch rules (see A-12). Every chain lands precisely on its terminator with zero
bytes left over, no index exceeds its record's `pairs_num`, and no `S_FAIL`
condition is reachable in any of the 503 records:

| File | Bytes | Records | Terminator | Bytes after | Highest addr | Address bits | `S_FAIL` reachable |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `eu_tv_codes_rom.mif` | 4739 | 138 | 4736–4738 | 0 | 4738 | 13 | no |
| `na_tv_codes_rom.mif` | 5314 | 137 | 5311–5313 | 0 | 5313 | 13 | no |
| `tv_codes_rom.mif` | 8269 | 228 | 8266–8268 | 0 | 8268 | **14** | no |

Two consequences worth keeping:

1. The combined file holds **228 records, not 275** (= 138 + 137). It is
   upstream's two-region build: NA codes 0–114 followed by EU codes 0–112, each
   list's tail being `#ifndef` the other region. (Recorded earlier as a
   "deduplicated union"; that was wrong — five codes appear twice. Corrected
   2026-10-18.) It contains **no interior all-zero header** — a concatenation of
   the two regional files would have stopped playback at the first terminator.
2. Carrier statistics for the documentation: 11 distinct compare values in EU
   (16 zero-carrier records), 18 in NA (2 zero-carrier), 17 in the combined set
   (13 zero-carrier). The zero-carrier records are the ones that exercise
   `ctc_forced_out`, so they are the natural test cases for that path.

**3-bit index phase table** — verified against `controller.sv:110-122`:

| phase | slice of `index_vector_r` | source bits | fetch after |
| --- | --- | --- | --- |
| 0 | `[7:5]` | byte0[7:5] | no |
| 1 | `[4:2]` | byte0[4:2] | yes |
| 2 | `[9:7]` | byte0[1:0] + byte1[7] | no |
| 3 | `[6:4]` | byte1[6:4] | no |
| 4 | `[3:1]` | byte1[3:1] | yes |
| 5 | `[8:6]` | byte1[0] + byte2[7:6] | no |
| 6 | `[5:3]` | byte2[5:3] | no |
| 7 | `[2:0]` | byte2[2:0] | yes |

10 bits of `index_vector_r` is exactly enough: 8 new bits plus at most 2 carried
over from the previous byte.
