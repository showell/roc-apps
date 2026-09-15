# Machine -- what the framebuffer platform gives a Codex program that reaches a
# device: its memory (pf.Heap) and the ports the host answers (pf.Port):
# codex-vm's GPU at 0x400-0x417 and its keyboard controller at 0x60 and 0x64.
# It stands in for machine/roc's Machine door for door, where a door is here;
# a program that reaches any other device does not build against it, and a
# port no device here answers stops the run, naming the port. The value carries
# only the heap's bump pointer. There is no process table, so every capability
# is held and no door answers -1.
import pf.Heap
import pf.Port

Machine :: [].{
	Machine : { top : I64 }

	# The heap starts where the machine's does, moved by the argument count.
	boot! : List(Str), List(Str) => Machine.Machine
	boot! = |args, _effects| { top: 6291456 + U64.to_i64_wrap(List.len(args)) }

	# The page shows the screen itself.
	halt! : Machine.Machine => {}
	halt! = |_m| {}

	alloc : Machine.Machine, I64 -> (Machine.Machine, I64)
	alloc = |m, n| ({ top: m.top + n }, m.top)

	# `__heap-advance`: the bump pointer moves past `n` bytes.
	advance : Machine.Machine, I64 -> (Machine.Machine, {})
	advance = |m, n| ({ top: m.top + n }, {})

	# `__heap-save` answers the bump pointer, and `__heap-restore` rewinds to it.
	mark : Machine.Machine -> (Machine.Machine, I64)
	mark = |m| (m, m.top)

	release : Machine.Machine, I64 -> (Machine.Machine, I64)
	release = |_m, h| ({ top: h }, 0)

	at : I64 -> U64
	at = |addr| I64.to_u64_wrap(addr)

	load! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	load! = |m, base, off, width| (m, U64.to_i64_wrap(Heap.load!(Machine.at(base + off), Machine.at(width))))

	store! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	store! = |m, base, off, v, width| {
		Heap.store!(Machine.at(base + off), I64.to_u64_wrap(v), Machine.at(width))
		(m, 0)
	}

	# The machine's guarded and unguarded doors differ only by the capability
	# guard on the GPU's page, and every capability is held here.
	load_unguarded! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	load_unguarded! = |m, base, off, width| Machine.load!(m, base, off, width)

	store_unguarded! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	store_unguarded! = |m, base, off, v, width| Machine.store!(m, base, off, v, width)

	# `atomic-exchange`: the qword at the address becomes `value`, and the old
	# one is the answer.
	exchange! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	exchange! = |m, addr, value| {
		old = Heap.load!(Machine.at(addr), 8)
		Heap.store!(Machine.at(addr), I64.to_u64_wrap(value), 8)
		(m, U64.to_i64_wrap(old))
	}

	# `__buf-write-byte base off v`: the low byte of `v` at base + off;
	# answers off + 1.
	write_byte! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	write_byte! = |m, base, off, v| {
		Heap.store!(Machine.at(base + off), I64.to_u64_wrap(v), 1)
		(m, off + 1)
	}

	# `__buf-write-bytes base off bytes`: the low byte of each element from
	# base + off on; answers off plus the count.
	write_bytes! : Machine.Machine, I64, I64, List(I64) => (Machine.Machine, I64)
	write_bytes! = |m, base, off, bytes| {
		n = U64.to_i64_wrap(List.len(bytes))
		var $i = 0
		while $i < n {
			Heap.store!(Machine.at(base + off + $i), I64.to_u64_wrap(List.get(bytes, I64.to_u64_wrap($i)) ?? 0), 1)
			$i = $i + 1
		}
		(m, off + n)
	}

	# `__buf-read-bytes base off count`: the `count` bytes from base + off on,
	# each as an unsigned value.
	read_bytes! : Machine.Machine, I64, I64, I64 => (Machine.Machine, List(I64))
	read_bytes! = |m, base, off, count| {
		var $acc = List.with_capacity(I64.to_u64_wrap(I64.max(count, 0)))
		var $i = 0
		while $i < count {
			$acc = List.append($acc, U64.to_i64_wrap(Heap.load!(Machine.at(base + off + $i), 1)))
			$i = $i + 1
		}
		(m, $acc)
	}

	# `uefi-read-key-ex` asks UEFI's ConIn through the system table whose
	# address sits at 30704; with none there, as on codex-vm's bare-metal boot,
	# it answers -1.
	uefi_read_key_ex! : Machine.Machine => (Machine.Machine, I64)
	uefi_read_key_ex! = |m| {
		table = Heap.load!(30704, 8)
		if table == 0 {
			(m, -1)
		} else {
			crash("framebuffer: uefi-read-key-ex with a UEFI system table, which this platform does not model")
		}
	}

	# `uefi-read-key`: the key cell at 28680 exchanged with zero, as its
	# scancode byte.
	uefi_read_key! : Machine.Machine => (Machine.Machine, I64)
	uefi_read_key! = |m| {
		cell = Heap.load!(28680, 8)
		Heap.store!(28680, 0, 8)
		(m, U64.to_i64_wrap(U64.bitwise_and(cell, 255)))
	}

	# A port write answers 0, as it does on x86; the host masks the value to the
	# port's width.
	port_write! : Machine.Machine, I64, I64, U64 => (Machine.Machine, I64)
	port_write! = |m, port, value, width| {
		Port.out!(Machine.at(port), I64.to_u64_wrap(value), width)
		(m, 0)
	}

	port_read! : Machine.Machine, I64, U64 => (Machine.Machine, I64)
	port_read! = |m, port, width| (m, U64.to_i64_wrap(Port.in!(Machine.at(port), width)))

	# `port-out-32`, and `gpu-out` with it.
	port_out_32! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	port_out_32! = |m, port, value| Machine.port_write!(m, port, value, 4)

	port_in_32! : Machine.Machine, I64 => (Machine.Machine, I64)
	port_in_32! = |m, port| Machine.port_read!(m, port, 4)

	port_out_16! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	port_out_16! = |m, port, value| Machine.port_write!(m, port, value, 2)

	port_in_16! : Machine.Machine, I64 => (Machine.Machine, I64)
	port_in_16! = |m, port| Machine.port_read!(m, port, 2)

	port_out_byte! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	port_out_byte! = |m, port, value| Machine.port_write!(m, port, value, 1)

	port_in_byte! : Machine.Machine, I64 => (Machine.Machine, I64)
	port_in_byte! = |m, port| Machine.port_read!(m, port, 1)
}
