
# ---- iCE40 Pico-ICE Board ----

pico-ice.json: ../src/btn_debouncer.sv ../src/ctc_generator.sv ../src/delay_timer.sv ../src/tv_codes_rom.sv ../src/controller.sv ../src/tv_b_gone.sv pico_ice.sv
	yosys -ql pico-ice.log -p 'synth_ice40 -top pico_ice -json pico-ice.json' $^

pico-ice.asc: pico-ice.pcf pico-ice.json
	nextpnr-ice40 --freq 10 --up5k --package sg48 --asc pico-ice.asc --pcf pico-ice.pcf --json pico-ice.json

pico-ice.bin: pico-ice.asc
	icetime -d up5k -c 12 -mtr pico-ice.rpt pico-ice.asc
	icepack pico-ice.asc pico-ice.bin

prog: pico-ice.bin
	dfu-util --alt 1 --download pico-ice.bin --device 1209:b1c0

lint: pico-ice.json
	verilator --lint-only --top pico_ice -I../src pico_ice.sv

# ---- Clean ----

clean:
	rm -f pico-ice.json pico-ice.log pico-ice.asc pico-ice.rpt pico-ice.bin

.PHONY: prog
