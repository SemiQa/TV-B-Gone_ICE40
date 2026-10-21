# Compared with the AVR original

This project reimplements the [Adafruit TV-B-Gone
kit](https://github.com/adafruit/TV-B-Gone-kit) firmware, which runs as C on an
8-bit AVR. The code tables are the same data; the machine playing them is not.

- [What changed](#what-changed)
- [How a code is stored](#how-a-code-is-stored)
- [The one field that is new](#the-one-field-that-is-new)
- [What stayed the same](#what-stayed-the-same)

## What changed

| | AVR firmware | This design |
| --- | --- | --- |
| Sequencing | A C loop on a processor | A twelve-state machine |
| Code table | `PROGMEM` structs with pointers | One flat byte stream |
| Carrier | Hardware timer in CTC mode | `ctc_generator` |
| Burst timing | `delay_ten_us()` busy loop | `delay_timer` |
| Reading the table | Pointer dereference | Address register plus adder |
| Region | Chosen at runtime by a jumper | Chosen at build time by a parameter |

The processor is the part that disappears. Everything the firmware did with
instructions — advance a pointer, read a byte, call a delay, branch back — becomes
a state and a register. See [design-notes.md](design-notes.md).

## How a code is stored

The upstream structure holds three bytes of header, a **pointer** to the
durations, and the packed indices inline:

```c
struct IrCode {
  uint8_t timer_val;        // carrier compare value
  uint8_t numpairs;         // how many bursts to send
  uint8_t bitcompression;   // bits per packed index
  uint16_t const *times;    // -> a separate array elsewhere in PROGMEM
  uint8_t codes[];          // packed indices, inline
};
```

A real entry, `code_na000Code`, sets `freq_to_timerval(38400)`, 26 bursts, 2 bits
per index, points at `code_na000Times`, and carries seven bytes of indices.

The format here keeps the same three header values and the same packed indices,
and replaces the pointer with the table itself:

```
upstream                          here
┌───────────────────────┐         ┌───────────────────────┐
│ timer_val             │         │ frequency             │
│ numpairs              │         │ chirps_num            │
│ bitcompression        │         │ pairs_num + index_bits│
│ times  ───────────────┼──┐      ├───────────────────────┤
│ codes[] (inline)      │  │      │ pair table (inline)   │
└───────────────────────┘  │      ├───────────────────────┤
                           │      │ index bytes (inline)  │
   ┌───────────────────────▼─┐    └───────────────────────┘
   │ code_na000Times[]       │
   │ 60,60, 60,2700, 120,60  │
   └─────────────────────────┘
```

**Figure D17** — The same information, with one indirection removed.

Field by field:

| Upstream | Here | Note |
| --- | --- | --- |
| `timer_val` | header byte 0, `frequency` | same value, unchanged |
| `numpairs` | header byte 1, `chirps_num` | same meaning: how many bursts |
| `bitcompression` | header byte 2, bits [2:0] | same meaning: bits per index |
| `*times` | pair table, immediately after the header | pointer replaced by the data |
| `codes[]` | index bytes, after the pair table | already inline upstream |
| — | header byte 2, bits [7:4], `pairs_num` | **new** |

A `times` entry is four bytes — on-time then off-time, both little-endian 16-bit —
which is the layout the pair table uses here as well. The transmit loop computes
`index × 4` to reach one, exactly as the controller does.

> [!NOTE]
> `numpairs` counts **bursts**, not entries in the duration table, despite the
> name. It is `chirps_num` here. The count of duration entries is what
> `pairs_num` holds, and upstream has no equivalent.

## The one field that is new

Upstream never stores the length of the `times` array. A pointer does not need
one: the array is a separate object, and the compiler places it.

Inlining the table removes the pointer and with it that knowledge. A reader
walking the bytes has to be told where the durations stop and the indices start,
so the format here spends four spare bits of header byte 2 on `pairs_num`. That
single field is the whole cost of flattening the structure.

Flattening has one other consequence. Upstream, several codes may share a
durations array — `code_na014Code` and `code_na015Code` both point at
`code_na004Times`. Inline tables cannot be shared, so those duplicate here. Most
codes have their own array upstream, so the duplication is small.

## What stayed the same

The timing data is untouched. Durations are still counted in 10 µs units, matching
the firmware's `delay_ten_us()`, so every number in the tables carries over
unchanged.

So do the carrier values. `freq_to_timerval` on an 8 MHz AVR turns 38.4 kHz into
103, which is the most common compare value in the tables here — 72 of the 138
European codes. Reusing those bytes is why this design runs its core at 8 MHz: the
data was generated against that clock.

The compression scheme is unchanged too. Storing each distinct duration pair once
and referring to it by a 2-, 3- or 4-bit index is the upstream idea; only the
placement of the table moved.

---

**Previous:** [design-notes.md](design-notes.md) · **Unfamiliar term?**
[glossary.md](glossary.md)

The code tables are derived from the Adafruit TV-B-Gone kit firmware; see that
project for their provenance and terms.
