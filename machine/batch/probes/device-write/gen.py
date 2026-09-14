#!/usr/bin/env python3
"""Write Probe.roc: what does writing a device cost when the devices sit in a
list of one (taken out and put back, as Machine.roc does) against a Box
(unboxed, updated, boxed again)? Two writes: a scalar field, and one byte of a
32,768-byte list inside the devices, like the NE2000's card memory. The shape,
the write and the count come from the command line."""

FIELDS = 64
scalars = ", ".join(f"a{i} : U64" for i in range(FIELDS))
values = ", ".join(f"a{i}: {i}" for i in range(FIELDS))

src = f"""Dev : {{ {scalars}, card : List(U8) }}

InList : {{ hot : U64, devices : List(Dev) }}
InBox : {{ hot : U64, devices : Box(Dev) }}

dev0 : U64 -> Dev
dev0 = |z| {{ {values}, card: List.repeat(0, 32768 + z) }}

vacant : Dev
vacant = {{ {values}, card: [] }}

# The machine's open and close: take the devices out, write, put them back.
list_scalar : InList -> InList
list_scalar = |m| {{
	{{ hot, devices }} = m
	taken = List.replace(devices, 0, vacant) ?? crash("slot")
	d = taken.prev
	{{ hot: hot, devices: List.set(taken.list, 0, {{ ..d, a0: d.a0 + 1 }}) ?? crash("slot") }}
}}

list_card : InList, U64 -> InList
list_card = |m, i| {{
	{{ hot, devices }} = m
	taken = List.replace(devices, 0, vacant) ?? crash("slot")
	d = taken.prev
	{{ hot: hot, devices: List.set(taken.list, 0, {{ ..d, card: List.set(d.card, i, 7) ?? crash("card") }}) ?? crash("slot") }}
}}

box_scalar : InBox -> InBox
box_scalar = |m| {{
	d = Box.unbox(m.devices)
	{{ ..m, devices: Box.box({{ ..d, a0: d.a0 + 1 }}) }}
}}

box_card : InBox, U64 -> InBox
box_card = |m, i| {{
	d = Box.unbox(m.devices)
	{{ ..m, devices: Box.box({{ ..d, card: List.set(d.card, i, 7) ?? crash("card") }}) }}
}}

main! = |args| {{
	n = U64.from_str(List.get(args, 0) ?? "") ?? 1000
	shape = List.get(args, 1) ?? "list"
	write = List.get(args, 2) ?? "scalar"
	z = List.len(args)
	result =
		if shape == "list" and write == "scalar" {{
			var $m = {{ hot: z, devices: [dev0(z)] }}
			var $i = 0
			while $i < n {{
				$m = list_scalar($m)
				$i = $i + 1
			}}
			(List.get($m.devices, 0) ?? vacant).a0
		}} else if shape == "list" {{
			var $m = {{ hot: z, devices: [dev0(z)] }}
			var $i = 0
			while $i < n {{
				$m = list_card($m, U64.rem_by($i, 32768))
				$i = $i + 1
			}}
			List.len((List.get($m.devices, 0) ?? vacant).card)
		}} else if write == "scalar" {{
			var $m = {{ hot: z, devices: Box.box(dev0(z)) }}
			var $i = 0
			while $i < n {{
				$m = box_scalar($m)
				$i = $i + 1
			}}
			Box.unbox($m.devices).a0
		}} else {{
			var $m = {{ hot: z, devices: Box.box(dev0(z)) }}
			var $i = 0
			while $i < n {{
				$m = box_card($m, U64.rem_by($i, 32768))
				$i = $i + 1
			}}
			List.len(Box.unbox($m.devices).card)
		}}
	echo!(Str.concat(U64.to_str(result), "\\n"))
	Ok({{}})
}}
"""
open("Probe.roc", "w").write(src)
