# Start here — working on this project

For whoever picks the work up next: what the project is doing, how the work is
done, where everything stands, and what is left. Read this before touching
anything. It is a working file, not reader documentation. Readers start at the
[README](../README.md).

Last updated: 2026-10-18

- [What we are doing](#what-we-are-doing)
- [Where things live](#where-things-live)
- [How the work is done](#how-the-work-is-done)
- [Commands](#commands)
- [Where it stands](#where-it-stands)
- [What is left](#what-is-left)
- [Starting a session](#starting-a-session)

## What we are doing

**The project.** TV-B-Gone, the universal TV power-off remote, reimplemented as
RTL for the iCE40UP5K on a Pico-ICE board. The code tables come from the Adafruit
AVR firmware, linearised into a flat byte stream that a state machine can walk
(ADR-003). The core is kept portable because a small ASIC is a later target, and
that is why the code table ships split by region (ADR-004).

**The goal.** Turn a working design into a **teaching example** for readers with
little or no FPGA experience: they should understand what it does, see it work,
and then be able to follow every part of it, from IR basics to bitstream.
Surface quality is part of the deliverable.

**The roadmap**, in order:

1. **Documentation** of the design as it stands — *nearly done*.
2. **A cocotb testbench**, using [`tools/walk_rom.py`](../tools/walk_rom.py) as the
   reference model, comparing the emitted envelope rather than cycle counts
   (ADR-008). Then `docs/verification.md`.
3. **RTL improvements**, held back until the testbench can verify them: the
   registered-read ROM alongside the async one (A-14, ADR-018/019), address-width
   parameterisation (A-11), the guard fixes (C-11, C-13), and the smaller items.
4. **Revise the docs** for those changes, and rebuild the released bitstreams.

## Where things live

Each kind of content has **one** home (ADR-022). Put it there, not anywhere else.

| File | Holds | Audience |
| --- | --- | --- |
| [`../README.md`](../README.md) | The 15-minute overview, quick start, doc map | readers |
| `docs/*.md` (reference pages) | **What it is and how it works** | readers |
| [`adr.md`](adr.md) | **Why**: 22 decision records | readers and maintainers |
| [`open-questions.md`](open-questions.md) | **What is wrong or missing**: the `Q`/`A`/`M`/`C` tracker | maintainers |
| [`documentation-plan.md`](documentation-plan.md) | Audience, conventions (§2), page outlines (§5), figure specs (§6), phase table (§7), review checklist (§8) | maintainers |
| [`diagrams/README.md`](diagrams/README.md) | Diagram tooling, the WaveDrom and Mermaid traps, figure index | maintainers |
| [`../tools/README.md`](../tools/README.md) | What each helper script does | maintainers |
| [`../bitstreams/README.md`](../bitstreams/README.md) | Released bitstreams and their provenance | readers |
| this file | Orientation, working rules, current status, the to-do list | maintainers |

Tracker ID prefixes: `Q` open question, `A` action, `M` missing artifact, `C`
code observation. Figures are `D01`–`D36`, photos `P01`–`P02`, specified in
documentation-plan.md §6.

## How the work is done

These rules came out of the work so far. Most exist because something went wrong
without them.

**Sources and configuration are frozen** during the documentation phase (owner,
2026-10-18). Nothing in `src/` or `pico-ice/` changes; anything that needs such a
change goes to the parked list in [What is left](#what-is-left) §4, with the
documentation fixes that must follow it.

**Never guess a hardware fact.** If a value is not in the RTL, the data or a
measurement the user supplied, it is an open question. Record it in
`open-questions.md` and write the affected text parameterised (on `f_clk`, say).
A plausible invented resistor value is worse than a visible gap.

**Reference voice.** Reference pages state facts in the present tense. No process
narration ("we verified"), no analyst voice ("notice that"), no tracker IDs, no
defect catalogues, and no ADR citations in the prose. A defect goes in
`open-questions.md`, a justification goes in `adr.md`. Full rules in
documentation-plan.md §2.1. `tools/check_doc_voice.py` enforces the recurring
forms. Run it on every page, and on `README.md` explicitly, since it only scans
`docs/` by default.

**Facts come from the source, not from memory.** Counts, sizes, decode examples
and timings are computed: `walk_rom.py` for the tables, the archived reports in
`pico-ice/eu/` and `pico-ice/na/` for utilisation and timing,
`fsm_transitions.py` for the state machine.

**Pilot one, then make many.** For a new kind of figure or page, do one, have it
reviewed, write down the rules it taught, then do the rest. The WaveDrom and
Mermaid rules in `diagrams/README.md` came from this.

**Plan large pages before writing them.** A short outline reviewed first is cheaper
than a rewrite.

**Look at every figure rendered**, in both dark and light themes, before calling
it done. Valid source is not a correct picture. Previews go to `tmp/`, never to
`docs/diagrams/`.

**Show the work in the repo or in the reply.** Results that exist only in tool
output or in the gitignored `tmp/` are invisible to the reviewer.

**Turn a repeated correction into a check.** When the same mistake recurs, add a
rule to a script in `tools/` rather than another paragraph of guidance.

**Scripts:** reusable ones go in `tools/` — Python 3 stdlib only, importable,
non-zero exit on failure, listed in `tools/README.md`. One-offs go in `tmp/`.

**RTL comments** explain only the non-obvious local mechanism and point to the
docs by page name (ADR-020). Any RTL edit must be shown to leave the logic
unchanged: strip the comments from the before and after versions, then diff.

**The README is written last** and summarises settled material only. When a page
changes what the README says (feature list, status, quick start), update both.

## Commands

```console
$ python tools/check_doc_voice.py                  # voice rules, docs/*.md
$ python tools/check_doc_voice.py README.md        # ...and the README
$ python tools/walk_rom.py                         # decode and check every rom/*.mif
$ python tools/gen_rom.py --check                  # rom/*.mif still match upstream?
$ python tools/gen_rom.py                          # regenerate rom/*.mif from upstream
$ python tools/fsm_transitions.py --check docs/controller-fsm.md
$ python tools/render_diagrams.py --check          # any WaveDrom SVG stale?
$ python tools/render_diagrams.py                  # re-render stale WaveDrom SVGs
$ npx -y @mermaid-js/mermaid-cli -i tmp/fig.mmd -o tmp/fig.png -b '#1e1e1e'
$ cd pico-ice && make pico-ice.bin                 # full build (OSS CAD Suite)
```

## Where it stands

As of 2026-10-18.

| Page | State | Figures |
| --- | --- | --- |
| `README.md` | drafted, owner has seen it; update as pages change | D01, D03 (D35 folded into the repository tree) |
| `ir-primer.md` | done | D02 |
| `rom-format.md` | done | D10, D12–D16 (D08, D09, D11 as ASCII) |
| `controller-fsm.md` | done | D18–D22 (D19 is a table, D23 folded into D18) |
| `modules.md` | done | D25, D27, D29 (D24, D26, D28 dropped) |
| `architecture.md` | done | D04, D05 (D06 folded into D04, D07 as a formula) |
| `design-notes.md` | done | — |
| `avr-comparison.md` | done | D17 as ASCII |
| `porting.md` | done | — |
| `build-and-program.md` | done | D31 (D32 folded into a table) |
| `glossary.md` | done, 32 entries | — |
| `hardware.md` | done, reviewed 2026-10-18 | D34a (all discrete, PMOD circuit drawn out, 47 Ω LED resistors), D34b (IR PMOD, inverted status logic noted until the parked pin-map refactor); D33 folded into the pin-map table |
| `verification.md` | not started, after the testbench | D36 |

Also done: `tools/gen_rom.py` (2026-10-18), rebuilding all three `.mif` files byte
for byte from upstream at a pinned commit, which closes M-01 and A-04; the
combined table turned out to be upstream's two-region build, not a de-duplicated
union, and every page now says so. RTL comment pass (A-15, but see the
`pico_ice.sv` item below), both
regional bitstreams released with provenance (A-13), synthesis and timing results
for both builds (M-02), PCF cleaned (A-03), four tools with self-tests.

The one open question, **Q-01** (is the core clock 8 MHz or 4 MHz?), is parked on a
single clarification and blocks nothing: every page states 8 MHz. See
`open-questions.md` Q-01.

## What is left

### 1. Needs input from the project owner

Nothing in this group can be done by inference. Each one is an open question or a
missing artifact.

| # | What | Unblocks |
| --- | --- | --- |
| 1.1 | **Q-01, which device was measured?** The ≈38 kHz carrier was measured. The released Pico-ICE netlists set `SB_HFOSC` to `0b01` (24 MHz) and toggle `clk_8M` once every 3 cycles, which is 4 MHz, and at 4 MHz a compare value of 103 gives 19.2 kHz. Both Tiny Tapeout pages state "Clock: 8000000 Hz" from the RP2040, so a measurement on the TT chip fits; one on the Pico-ICE does not. A one-line fix exists: `CLKHF_DIV("0b00")` (48 MHz) with the same divide-by-6 gives exactly 8 MHz. | Closing Q-01, A-05, ADR-015, C-01 |
| 1.2 | **Carrier capture** (M-05), a scope or logic-analyser screenshot of a known code, **from the Pico-ICE** | Figure P02 in `ir-primer.md`; settles 1.1 |
| 1.3 | **Photo or GIF of the working gadget** (M-06): the Pico-ICE with the IR PMOD or the discrete driver attached, ideally mid-run. A stock board photo from the vendor is not a substitute: it would not show this project, and copying vendor images goes against the link-don't-copy rule; the README already links the vendor docs. | Figure P01 at the top of the README |
| 1.4 | **Commit the documentation work to GitHub.** Everything outside `docs/`, `tmp/` and `tools/` is already on GitHub; this working copy is not a git checkout. To commit: all of `docs/`; all of `tools/` (every script is linked from the docs, and `gen_rom.py` imports `walk_rom.py`; `__pycache__/` is already ignored); three files changed outside those folders (`.gitignore`, `README.md`, `bitstreams/README.md`); and the newly un-ignored `pico-ice/eu/pico-ice.rpt` and `pico-ice/na/pico-ice.rpt`. If the `pico-ice/eu|na/pico-ice.json` netlists were pushed earlier, the new ignore rule does not remove them: `git rm --cached` them. `tmp/` stays out (only `.gitkeep`). Then fill the "source commit" column in `bitstreams/README.md` (A-13). | Published docs; bitstream provenance |

### 2. Can be done now

Documentation and tooling only. Sources and configuration are frozen (see §4).

| # | What |
| --- | --- |
| 2.1 | **`diagrams/README.md` figure index** stops at D16. D22, D25, D27 and D29 are committed SVGs missing from it. |
| 2.2 | **`open-questions.md` hygiene.** "Last updated" is 2026-08-17. The §1 summary counts are stale. M-04 is still marked open and "blocks phase 5", though it was delivered. A-01 still says phases 4–6 wait on M-02/M-04. A-14 and C-12 sit under "5. Missing artifacts". The two M-02 tables have a doubled header row. A-13's "Prerequisite Makefile work" still speaks of three variants. |
| 2.3 | **`adr.md` ADR-017** still ends "No bitstreams are committed yet — see A-13"; they were released on 2026-09-17. |
| 2.4 | **`documentation-plan.md`.** The header still says draft / 2026-08-17. §5.6 still says "Placeholder table pending M-02" and "three released variants", and has two items numbered 8. The phase table leaves phase 12 (A-13) unticked though it is done, and phase 7 should now read "drafted". |
| 2.5 | **Run the review checklist**, documentation-plan.md §8, over the whole set. Every box is still unticked. |
| 2.6 | **Record the 2026-10-18 answers in `open-questions.md`**: M-03 delivered (wiring spec, D34a/b); Q-01 narrowed to "which device" (TT pages state 8 MHz); NA untested, EU tested on Pico-ICE and two TT SKY 25a chips; upstream source pinned to `WORLDcodes.c` @ `7fc4877`, linked not copied (M-01/A-04 and the "deduplicated union" error already corrected in the tracker); build reports: `.rpt` only; DFU answered (CRAM `--alt 1`, flash `--alt 0`); Pico-ICE IR LED resistors 47 Ω (TT demo board supplies 300 mA, 15 Ω fine there); PCF/polarity refactor parked (§4); scope check deferred (§5). |
| 2.7 | **A-09: decide the endgame for the planning files.** Once the docs are complete, `documentation-plan.md` and `open-questions.md` should shrink to maintenance notes or move out of `docs/`, so readers are not handed a plan as documentation. This file would absorb what remains. |

### 3. Parked behind the cocotb testbench

In this order (documentation-plan.md §7, phases 9–12):

1. Testbench, then `verification.md` (D36). Include a synthetic 4-bit-index record
   (C-12) and an out-of-range second index (C-13), since the shipped data
   exercises neither.
2. A-14 registered-read ROM first, then A-11 address width, A-02 NA `SIZE`, C-10
   width pass-through, C-11 and C-13 guards, then per-style and per-region
   Makefile targets.
3. Revise the docs for two ROM styles (phase 11), D30 as two panels.
4. Rebuild and re-release the bitstreams, and update their provenance.

### 4. Parked for a later refactor of sources and configuration

**Owner's decision, 2026-10-18: nothing in `src/`, `pico-ice/` (RTL, PCF,
Makefile) is changed during the documentation phase.** These wait for the
refactor:

1. **Pico-ICE pin map (PCF) for the IR PMOD.** The tt-ir-pmod was made for the Tiny
   Tapeout chips and does not match the Pico-ICE as wired today. Rework the PCF so
   it plugs into a Pico-ICE PMOD socket: `IR_LED_OUT`, `IR_LED_OUT_N`,
   `ACTIVE_LED_N`, `FAILURE_LED_N` on PMOD pins 1–4, GND/3V3 on 5/6. Needs the
   board header position of each FPGA pin (the vendor PCF names them
   `ICE_PMOD0A_IO1` …; the docs show them only as an image).
2. **Status outputs active low** in `pico_ice.sv`, matching the TT chips and the
   PMOD, either by inverting `active_led_out` / `fail_led_out` or by adding
   inverted copies as is done for `ir_ledn_out`. Part of item 1.
3. **Then fix the docs to match — do not forget this:**
   - D34b: drop the "status logic inverted" note, redraw as a plug-in connection;
   - D34a: if the outputs become active low, the status LEDs hang from 3V3
     through 1 kΩ to the pin;
   - `hardware.md`: pin map table, the D34b caption and polarity paragraph,
     "Status LEDs";
   - README: the wiring table;
   - `modules.md` `pico_ice` ports table, if port names or polarities change;
   - rebuild both bitstreams and update `bitstreams/README.md`.
4. **Restore the `pico_ice.sv` comment pass.** The file is byte-identical to the pre-edit copy in `tmp/rtl_before/`, so the A-06 and A-15 changes recorded as done are not there: line 69 still reads `synchroous`, line 34 still asserts "24MHz div 3 = 8MHz". The six `src/` files are fine. The `pico-ice/` folder was refreshed on 2026-09-17 along with the build results, which probably overwrote it. Redo the edit and verify that the logic is unchanged. Rebuilding the bitstreams is not needed for a comment-only change.
5. **Core clock**, if Q-01 (1.1) confirms 4 MHz on the Pico-ICE:
   `CLKHF_DIV("0b00")` gives exactly 8 MHz with the existing divider; rename or
   re-comment `clk_8M` accordingly (A-05).

### 5. Needs bench equipment, not available yet

1. **Confirm that unmodulated codes pass the IR PMOD's AC-coupled input.** Input
   is 1 kΩ + 100 nF into the BC807 base with a 10 kΩ pull-up. The 16 EU and 2 NA
   codes without a carrier hold the input low for whole bursts, at most 140 µs
   (median 40 µs), which should pass a time constant of 100 µs or more. One scope
   check settles it.
2. **Carrier capture** for figure P02 (1.2) needs the same equipment.

## Starting a session

1. Read this file, then the "What is left" section above.
2. Skim `open-questions.md` for anything answered since the last update.
3. Before writing a page, read documentation-plan.md §2.1 and its outline in §5.
   Before drawing a figure, read `diagrams/README.md`.
4. When done: run the checks under [Commands](#commands), update the status table
   and the to-do list here, and update the tracker.
