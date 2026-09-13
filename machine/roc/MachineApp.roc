# Step 1 of the machine emulator (essay notes/roc-machine-emulator.md): a
# hand-written Roc program running on the machine, one door at a time, for the
# page to watch. It walks PCI bus 0 through the configuration ports, reads
# sector 0 through the block door into memory, then echoes the keys the page
# sends.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import Machine
import Pci

Phase : [Scan(U64), Sector, Keys]

Found : { slot : U64, vendor : U64, device : U64, class : U64, sub : U64, progif : U64, irq : U64 }

Model : { m : Machine.M, phase : Phase, found : List(Found) }

new : List(U8) -> Box(Model)
new = |image| {
	m0 = Machine.new(image)
	count = U64.to_str(Machine.block_sector_count(m0))
	Box.box({ m: Machine.print_line(m0, "machine: drive 0 holds ${count} sectors; scanning PCI bus 0"), phase: Scan(0), found: [] })
}

# Up to `budget` operations, stopping early when the program waits for a key.
step : Box(Model), I64 -> Box(Model)
step = |boxed, budget| Box.box(run(Box.unbox(boxed), budget))

key : Box(Model), I64 -> Box(Model)
key = |boxed, code| {
	model = Box.unbox(boxed)
	Box.box({ ..model, m: Machine.key_in(model.m, U64.to_u8_wrap(I64.to_u64_wrap(code))) })
}

run : Model, I64 -> Model
run = |model, budget| if budget <= 0 or idle(model) { model } else { run(one(model), budget - 1) }

idle : Model -> Bool
idle = |model|
	match model.phase {
		Keys => !(Machine.keys_waiting(model.m))
		_ => False
	}

# One operation of the program.
one : Model -> Model
one = |model| {
	m = Machine.tick(model.m)
	match model.phase {
		Scan(slot) =>
			if slot >= 32 {
				n = U64.to_str(List.len(model.found))
				{ ..model, m: Machine.print_line(m, "PCI: ${n} devices on bus 0; reading sector 0"), phase: Sector }
			} else {
				at = 2147483648 + slot * 2048
				m1 = Machine.port_out_32(m, Pci.config_addr, at)
				(m2, id) = Machine.port_in_32(m1, Pci.config_data)
				if id == Pci.all_ones {
					{ ..model, m: m2, phase: Scan(slot + 1) }
				} else {
					m3 = Machine.port_out_32(m2, Pci.config_addr, at + 8)
					(m4, class) = Machine.port_in_32(m3, Pci.config_data)
					m5 = Machine.port_out_32(m4, Pci.config_addr, at + 60)
					(m6, irq) = Machine.port_in_32(m5, Pci.config_data)
					f = {
						slot: slot,
						vendor: U64.bitwise_and(id, 65535),
						device: U64.div_trunc_by(id, 65536),
						class: U64.div_trunc_by(class, 16777216),
						sub: U64.bitwise_and(U64.div_trunc_by(class, 65536), 255),
						progif: U64.bitwise_and(U64.div_trunc_by(class, 256), 255),
						irq: U64.bitwise_and(irq, 255),
					}
					line = "00:${two(slot)}.0 ${hex(f.vendor, 4)}:${hex(f.device, 4)} class ${hex(f.class, 2)}${hex(f.sub, 2)}${hex(f.progif, 2)} irq ${U64.to_str(f.irq)}"
					{ ..model, m: Machine.print_line(m6, line), phase: Scan(slot + 1), found: List.append(model.found, f) }
				}
			}
		Sector => {
			(m1, base) = Machine.block_read_sector(m, 0)
			# `lba0` is what upstream's block-select-drives prints for the same
			# image on bare metal: `drive 0 sectors 128 lba0 161`.
			first = U64.to_str(Machine.peek_byte(m1, base))
			sig = Machine.peek_byte(m1, base + 510) * 256 + Machine.peek_byte(m1, base + 511)
			m2 = Machine.print_line(m1, "sector 0 read into memory at ${hex(I64.to_u64_wrap(base), 8)}: lba0 ${first}, bytes 510-511 ${hex(sig, 4)}")
			{ ..model, m: Machine.print_line(m2, "keys: type, and each scancode echoes"), phase: Keys }
		}
		Keys => {
			(m1, k) = Machine.key_next(m)
			if k < 0 {
				{ ..model, m: m1 }
			} else {
				{ ..model, m: Machine.print_line(m1, "key: scancode ${hex(I64.to_u64_wrap(k), 2)} ${letter(k)}") }
			}
		}
	}
}

# ---- the page's view ------------------------------------------------------
#
# status (u8: 1 waiting for a key, 5 running) · steps (u32) · the console
# (u32 length, bytes) · the PCI devices found (u32 count, 12 bytes each) · the
# span the last block read landed on (u32 address, u32 length, bytes read back
# out of memory).

view : Box(Model) -> List(U8)
view = |boxed| {
	model = Box.unbox(boxed)
	m = model.m
	status = if idle(model) { 1 } else { 5 }
	head = List.concat([status], u32(m.steps))
	con = List.concat(u32(List.len(m.console)), m.console)
	pci = List.concat(u32(List.len(model.found)), rows(model.found, 0, []))
	span = List.concat(
		List.concat(u32(I64.to_u64_wrap(m.landed)), u32(I64.to_u64_wrap(m.landed_len))),
		window(m, 0, []),
	)
	List.concat(List.concat(head, con), List.concat(pci, span))
}

rows : List(Found), U64, List(U8) -> List(U8)
rows = |fs, i, acc|
	match List.get(fs, i) {
		Ok(f) => {
			row = [lo(f.slot), lo(f.class), lo(f.sub), lo(f.progif), lo(f.irq), 0, 0, 0]
			rows(fs, i + 1, List.concat(List.concat(acc, row), List.concat(u16(f.vendor), u16(f.device))))
		}
		Err(_) => acc
	}

window : Machine.M, I64, List(U8) -> List(U8)
window = |m, i, acc|
	if i >= m.landed_len {
		acc
	} else {
		window(m, i + 1, List.append(acc, lo(Machine.peek_byte(m, m.landed + i))))
	}

lo : U64 -> U8
lo = |v| U64.to_u8_wrap(U64.bitwise_and(v, 255))

u16 : U64 -> List(U8)
u16 = |v| [lo(v), lo(U64.div_trunc_by(v, 256))]

u32 : U64 -> List(U8)
u32 = |v| [lo(v), lo(U64.div_trunc_by(v, 256)), lo(U64.div_trunc_by(v, 65536)), lo(U64.div_trunc_by(v, 16777216))]

# ---- formatting -----------------------------------------------------------

hex : U64, U64 -> Str
hex = |v, digits| hex_go(v, digits, "")

hex_go : U64, U64, Str -> Str
hex_go = |v, left, acc|
	if left == 0 {
		acc
	} else {
		d = List.get(hex_digits, U64.bitwise_and(v, 15)) ?? "?"
		hex_go(U64.div_trunc_by(v, 16), left - 1, Str.concat(d, acc))
	}

hex_digits : List(Str)
hex_digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

two : U64 -> Str
two = |n| if n < 10 { "0${U64.to_str(n)}" } else { U64.to_str(n) }

# A PS/2 set-1 scancode's letter, for the echo.
letter : I64 -> Str
letter = |k|
	if k >= 16 and k <= 25 {
		pick("qwertyuiop", k - 16)
	} else if k >= 30 and k <= 38 {
		pick("asdfghjkl", k - 30)
	} else if k >= 44 and k <= 50 {
		pick("zxcvbnm", k - 44)
	} else if k == 57 {
		"(space)"
	} else if k == 28 {
		"(enter)"
	} else {
		""
	}

pick : Str, I64 -> Str
pick = |s, i| Str.from_utf8([List.get(Str.to_utf8(s), I64.to_u64_wrap(i)) ?? 63]) ?? "?"

drop : Box(Model) -> {}
drop = |_boxed| {}

program = { new, step, key, view, drop }
