# Prebuilt bitstreams

Ready-to-flash bitstreams for the Pico-ICE board, one per region, so the gadget
can be tried **without installing an FPGA toolchain**. You only need `dfu-util`.

## Which one do I want?

Each bitstream carries a different set of TV power-off codes. Pick the one for
your region.

| File | Code table | Records | Region |
| --- | --- | --- | --- |
| `pico-ice-eu.bin` | `rom/eu_tv_codes_rom.mif` | 138 | Europe |
| `pico-ice-na.bin` | `rom/na_tv_codes_rom.mif` | 137 | North America |

There is no combined build. The repository holds a third code table with both
regions in one, 228 records from upstream's two-region build, but it does not fit
this device: the address decode tree it needs is twice the size of the one in
these builds. See [`../docs/porting.md`](../docs/porting.md).

## Flashing

Connect the board over USB. With its default firmware it appears to `dfu-util -l`
as `iCE40 DFU (CRAM)` and `iCE40 DFU (flash)`. Then:

```console
dfu-util --alt 1 --download bitstreams/pico-ice-eu.bin --device 1209:b1c0
```

Same arguments the `prog` target in [`../pico-ice/Makefile`](../pico-ice/Makefile)
uses, just pointing at a released file instead of a fresh build. `--alt 1` loads
the FPGA's configuration RAM, which is lost at power-off; `--alt 0 ... --reset`
writes the flash instead. Details, including the Windows driver, are in the
[Pico-ICE programming guide](http://pico-ice.tinyvision.ai/md_programming__the__fpga.html).

See [`../docs/hardware.md`](../docs/hardware.md) for wiring the IR transmitter
and the status LEDs. Without them nothing visible happens.

## Provenance

A binary nobody can trace is a binary nobody should trust.

| | `pico-ice-eu.bin` | `pico-ice-na.bin` |
| --- | --- | --- |
| Code table | `rom/eu_tv_codes_rom.mif` | `rom/na_tv_codes_rom.mif` |
| Board and package | Pico-ICE, iCE40UP5K, SG48 | same |
| Core clock | 8 MHz | same |
| Synthesis | Yosys 0.68+58 (git edbc62a44) | same |
| Look-up tables used | 3664 of 5280, 69 % | 3842 of 5280, 73 % |
| Longest path | 69.59 ns, 14.37 MHz | 70.36 ns, 14.21 MHz |
| Size | 104 090 bytes | 104 090 bytes |
| Built | 2026-09-17 | 2026-09-17 |

The two files are the same size because an iCE40 bitstream is a fixed-length
configuration image; only its contents differ. The timing report for each
build is kept in [`../pico-ice/eu/`](../pico-ice/eu/) and
[`../pico-ice/na/`](../pico-ice/na/).

> [!NOTE]
> These files are **not** rebuilt automatically, so they can lag the RTL. If you
> are modifying the design, build from source rather than trusting a release —
> and if you are changing the RTL, rebuilding these is part of the job.

## Why these are committed when other build products are not

The netlist, the placed design and the synthesis log are intermediates with no
value to a reader, and they are gitignored. Only the timing report of each
released build is kept, in `pico-ice/eu/` and `pico-ice/na/`. A bitstream is a
usable product, so it is committed. The reasoning is recorded in
[`../docs/adr.md`](../docs/adr.md).

The transient `pico-ice/pico-ice.bin` produced by a local `make` is *also*
gitignored — only the deliberately released files here are tracked.
