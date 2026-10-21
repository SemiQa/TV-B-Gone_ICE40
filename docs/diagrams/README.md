# Diagrams

Two kinds of figure in this documentation, per [ADR-002](../adr.md#adr-002--diagram-tooling-mermaid-inline-wavedrom-and-svg-committed):

| Kind | Lives | Rendered by | Used for |
| --- | --- | --- | --- |
| **Mermaid** | inline in the markdown, in ```` ```mermaid ```` blocks | GitHub, natively | block diagrams, state machines, sequence diagrams, flow and dependency graphs |
| **WaveDrom** | `src/*.json` here, exported to `*.svg` here | `tools/render_diagrams.py` | timing waveforms (`signal`) and bit-field / byte-layout figures (`reg`) |

Mermaid needs no tooling and no files in this directory — keeping its source in
the page is what makes it stay current. WaveDrom needs a render step because
GitHub does not render WaveDrom itself.

## Writing Mermaid

GitHub renders these, but a syntax error or a bad layout ships silently. To look at
one before committing it, extract the fenced block to a `.mmd` file in `tmp/` and:

```console
$ npx -y @mermaid-js/mermaid-cli -i tmp/fig.mmd -o tmp/fig.png
```

The first run downloads a headless browser, so allow it a few minutes.

### Keep edge labels to one to three words

Mermaid sizes the layout around label text. A label like
`header all zero, end of table` is placed far from its own arrow, stranded in
open canvas, and stretches the whole diagram around it. `table end` sits on the
edge where it belongs. Full guard conditions go in the accompanying state table,
which has room for them.

### Avoid self-transitions when the state has an outgoing label

A self-loop label and an outgoing transition label are placed at the same point and
**overwrite each other** — `delay running` plus `delay elapsed` rendered as
`deldelay elapsed`. If a state's "it stays here for a while" behaviour matters, say
so in the state table or a `note`, not a self-loop.

### Colour by role with `classDef` — saturated fills, white text

`classDef` and `class` work in `stateDiagram-v2` and give semantic grouping without
the layout upheaval of nested composite states.

**Use saturated fills with white text, not pastels.** Pale fills (`#dbeafe` blue
against `#ede9fe` violet) are nearly indistinguishable on a dark editor background —
every one of them reads as "white-ish", and the hue that separated them in light
mode disappears. Saturated fills carry their hue on any background:

```
classDef read fill:#2563eb,stroke:#1e3a8a,stroke-width:2px,color:#ffffff
class S_READ_HEADER,S_READ_INDEX read
```

**Give every node a class**, including the ones with no special role. An unclassed
node follows the viewer's theme while classed nodes keep fixed colours, so the
diagram looks different in light and dark. Classing everything makes it identical
in both.

**Pick hues that are not neighbours.** Blue against violet is the hardest pair to
separate. The palette here is blue / purple / teal / grey / red, which stays
readable even side by side in small boxes.

Verify by rendering against the background the reader will actually use:

```console
$ npx -y @mermaid-js/mermaid-cli -i tmp/fig.mmd -o tmp/dark.png -b '#1e1e1e'
$ npx -y @mermaid-js/mermaid-cli -i tmp/fig.mmd -o tmp/light.png -b white
```

### Check a state diagram against the RTL

[`tools/fsm_transitions.py`](../../tools/fsm_transitions.py) reads
`src/controller.sv` and can confirm a figure covers every state and transition:

```console
$ python tools/fsm_transitions.py --check docs/controller-fsm.md
controller-fsm.md: covers all 12 states and 16 transitions
```

It reads the file as text, so it works on the markdown page directly — no separate
`.mmd` copy to keep in step.

## Rendering

```console
$ python tools/render_diagrams.py            # render anything out of date
$ python tools/render_diagrams.py --force    # re-render everything
$ python tools/render_diagrams.py --check    # CI: fail if anything is stale
```

Needs node and npm on `PATH`. `wavedrom-cli` is fetched on demand by `npx`, so
nothing is vendored here — at the cost of needing network access the first time.
Readers never re-render; the SVGs are committed.

**After editing any `src/*.json`, re-render and commit both files.** `--check` is
there to catch it when that gets forgotten.

## The white background is deliberate

`wavedrom-cli` emits black strokes with no page background. GitHub renders
markdown in both light and dark themes, so an unmodified WaveDrom SVG is black on
near-black and effectively invisible on dark. The render script therefore inserts
an opaque white rect as the first child of every exported `<svg>`, sized from its
`viewBox`. WaveDrom's palette is designed against white anyway.

Any hand-authored SVG added here must do the same, explicitly.

## Hand-authored SVG

Used where neither tool fits, so far only for the wiring schematics, D34a and D34b. The SVG is
its own source, so it lives here with no `src/` counterpart and no render step.

- Start with an opaque white `<rect>` covering the whole `viewBox`, as above.
- Draw power and ground as local symbols at each circuit rather than as rails
  running across the figure.
- Keep reference designators unique across everything in the figure, including
  parts printed on a third-party board drawn alongside.
- Preview it the same way as any other figure, and look at the PNG:

```console
$ npx -y @resvg/resvg-js-cli --fit-width 1400 docs/diagrams/d34a-wiring-discrete.svg tmp/d34a.png
```

## Writing WaveDrom sources

> [!TIP]
> The full authoring recipe lives in the user-level **`wavedrom-diagrams` skill**
> (`~/.claude/skills/wavedrom-diagrams/SKILL.md`), so it is reusable across projects.
> What follows is the short version plus this project's own conventions.

### Use `l`/`h` for levels, never `0`/`1`

`0` and `1` render transitions as **slanted diagonal ramps** — WaveDrom's house
style, meant to suggest rise time. In a diagram about gating a carrier it just
looks imprecise. **`l` and `h` render the same levels with straight vertical
edges**, which is what these figures want. `L`/`H` are the same again plus an
arrow marker at the transition, useful for pointing at a specific edge.

Clock characters (`p`, `n`, `P`, `N`) already draw straight edges.

### Extend with `.`, never repeat the level character

`"h..."` holds high for four slots. `"hhhh"` looks almost the same but draws a
small **notch at every repeat**, because each character is read as a fresh
transition to that level. The result looks like a glitch that is not in the design.

### Gating a clock burst? Use `p`, not `n`

This one is subtle and looks like a rendering bug. A clock slot drawn with `n` is
**low then high**, so a burst written `"ln...l"` *ends high* — and WaveDrom does
**not draw the falling edge** at a clock-to-level boundary. The burst appears to
have a missing edge on its right-hand side.

`p` is **high then low**, so `"lp...l"` ends at the low rail and needs no boundary
edge at all. Both ends of the burst then render correctly.

`p` is also the honest depiction for a gated IR carrier: the drive idles low, rises
into the burst, and falls back to low.

### Give every pulse at least two slots

A one-slot pulse (`"hlhlhl"`) reads as a row of **Dirac spikes**, not as a signal.
Scale the figure so the shortest interesting interval is two slots or more, and
state the compression in the caption — being not-to-scale is fine, being unreadable
is not.

### Mark compressed time with `|`

Real IR intervals differ by large factors — a 264-unit leader against a 43-unit data
burst is over 6:1. Drawing that to scale makes the figure very wide; drawing it
compressed without saying so is misleading, since a 2-slot burst appears to hold 2
carrier cycles when the real one holds about 15.

`|` draws a torn-break glyph and the level, clock or cell continues through it. Put
breaks in the long intervals only and even up the drawn widths: compact figure, true
numbers in the labels, compression declared rather than hidden.

**Never put `|` in a data-cell row** — it lands on the cell's centred label and
slashes through the text (`on⁄264`). Keep breaks on the signal rows; a `.` at that
slot in the cell row just extends the cell, so alignment is unaffected.

### Measure intervals with data cells, not `node` + `edge`

**Do not annotate a span with an arrow between nodes.** Arrow and line endpoints are
positioned independently of the wave grid and never quite line up with the
transitions: `<->` arrowheads point outward with a fixed few-pixel overhang past the
anchor, which is invisible on a long span and glaringly wrong on a short one, and
even a plain `-` line sits marginally off against the edge glyph's own shaping.

Add a **data-cell row on the same wave grid** instead:

```json
{ "name": "envelope",    "wave": "lh.......l..h.l" },
{ "name": "10 us units", "wave": "x3.......4..3.4",
  "data": ["on 264", "off 90", "on 43"] }
```

Cell boundaries *are* slot boundaries, so the labels align with the transitions
above them by construction. Supplying fewer `data` strings than cells leaves the rest
as unlabelled boxes.

Use `x` for filler where there is nothing to label — **never a space**, which is
stripped from the wave string and silently shifts every slot after it.

### Cell colours: `5` and `8`

The digit picks the fill, and this project uses **`5` (pale blue)** for active phases
and **`8` (pale violet)** for inactive ones. Those sit closest to WaveDrom's own
signal-label blue, so a figure reads as a single palette; the default `3`/`4`
yellow-and-orange looks washed out beside it.

Full mapping: `2` white, `3` pale yellow, `4` pale orange, `5` pale blue, `6` pale
cyan, `7` pale green, `8` pale violet, `9` pale pink.

### Match trace lengths across groups

All waves in a figure should be the same number of slots, even across a
macro/zoom pair with different time bases. Uneven lengths leave a ragged right
edge that reads as a rendering fault.

### Keep group labels to one short word

They render as rotated text down the left edge, and anything longer than about six
characters collides with the neighbouring group's label. Put the explanation in the
figure's markdown caption instead. `macro` and `zoom` work;
`macro view: the envelope, from the pair table` does not.

### Keep `head`/`foot` text short

It is not wrapped or measured against the image width, so a long line is silently
**clipped** at both edges. Provenance, record references and unit conversions
belong in the markdown caption, which cannot clip and is searchable.

`tools/render_diagrams.py` now estimates the text width against the rendered image
and warns when it will not fit, because this one is easy to reintroduce and
invisible unless you look at the picture.

### Do not draw a slow strobe as a clock

A `p` wave renders as a square wave, which a reader reads as *a clock*. If the
signal is actually a one-clock enable pulse arriving every few thousand clocks,
that is a lie about its shape and invites the question "what is its relation to the
clock?"

At a scale where one slot is one sample period, a one-clock pulse cannot be drawn
honestly at all. Leave the strobe out and let the sampled values advancing once per
slot show the sampling, then state the divider ratio in prose.

### `hscale` 1 is usually right

Raising it to 2 doubles the width and, for a figure of only a few tracks, produces
an awkwardly wide image.

## Always look at the render before calling a figure done

**Valid JSON is not a correct picture.** Of the seven rules above, four described
problems that were invisible in the source and obvious the moment the figure was
rendered and viewed. Export a PNG and actually look at it:

```console
$ npx -y wavedrom-cli --input docs/diagrams/src/d02-carrier-and-envelope.json --png tmp/preview.png
```

Write previews to `tmp/`, never here — only the committed SVGs belong in this
directory.

## Checklist before committing a figure

- [ ] Levels use `l`/`h`, not `0`/`1`
- [ ] Runs extended with `.`, no repeated level characters
- [ ] Gated clock bursts use `p`, not `n`
- [ ] No pulse narrower than two slots
- [ ] Heavily compressed intervals carry a `|` break — on signal rows, never in a cell
- [ ] No spaces anywhere in a wave string
- [ ] Intervals labelled with data cells, not `node`/`edge` arrows
- [ ] Every wave in the figure has the same slot count
- [ ] Group labels are one short word
- [ ] `head`/`foot` text fits without clipping
- [ ] Rendered to PNG and visually inspected
- [ ] `python tools/render_diagrams.py` run, and both `src/*.json` and `*.svg` staged
- [ ] Caption in the markdown carries provenance, units, and any `Unconfirmed` marker

## Figure index

Figure IDs (`D01`…`D36`) are assigned in
[`../documentation-plan.md`](../documentation-plan.md) §6, which also holds the
specification for each one.

| ID | File | Mode | Page | Status |
| --- | --- | --- | --- | --- |
| D02 | `d02-carrier-and-envelope.svg` | signal | `ir-primer.md` | done |
| D10 | `d10-header-byte2.svg` | reg | `rom-format.md` | done |
| D12 | `d12-index-4bit.svg` | reg | `rom-format.md` | done |
| D13 | `d13-index-2bit.svg` | reg | `rom-format.md` | done |
| D14 | `d14-index-3bit.svg` | reg | `rom-format.md` | done |
| D15 | `d15a/b/c-window-after-*.svg` | reg | `rom-format.md` | done (3 panels) |
| D16 | `d16-worked-example.svg` | signal | `rom-format.md` | done |
| D34a | `d34a-wiring-discrete.svg` | hand-authored | `hardware.md` | done |
| D34b | `d34b-wiring-pmod.svg` | hand-authored | `hardware.md` | done |

D08, D09 and D11 are specified in the plan as figures but were written as ASCII
layout blocks inside `rom-format.md` instead — for a byte-region map and a two-byte
little-endian assembly, a code block is clearer than a rendered image and cannot
drift from the prose around it.
