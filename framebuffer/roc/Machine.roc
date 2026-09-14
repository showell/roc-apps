# Machine -- what the framebuffer platform gives a Codex program that reaches a
# device: its memory (pf.Heap) and the GPU codex-vm models behind ports
# 0x400-0x417 (pf.Gpu), both kept by the host. It stands in for machine/roc's
# Machine door for door, where a door is here; a program that reaches any other
# device does not build against it, and a 32-bit port outside the GPU's window
# stops the run, naming the port. The value carries only the heap's bump
# pointer. There is no process table, so every capability is held and no door
# answers -1.
import pf.Gpu
import pf.Heap

Machine :: [].{
	Machine : { top : I64 }

	# The heap starts where the machine's does, moved by the argument count.
	boot! : List(Str), List(Str) => Machine.Machine
	boot! = |args, _effects| { top: 6291456 + U64.to_i64_wrap(List.len(args)) }

	# The page shows the screen after every run.
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

	gpu_lo : U64
	gpu_lo = 0x400

	gpu_hi : U64
	gpu_hi = 0x417

	# `port-out-32`, and `gpu-out` with it: a port in the GPU's window is the
	# host's GPU, and the write answers 0.
	port_out_32! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	port_out_32! = |m, port, value| {
		p = I64.to_u64_wrap(port)
		if p >= Machine.gpu_lo and p <= Machine.gpu_hi {
			Gpu.out!(p, U64.bitwise_and(I64.to_u64_wrap(value), 0xFFFFFFFF))
			(m, 0)
		} else {
			crash("framebuffer: port-out-32 to port ${Str.inspect(p)}, a device this platform does not have")
		}
	}

	port_in_32! : Machine.Machine, I64 => (Machine.Machine, I64)
	port_in_32! = |m, port| {
		p = I64.to_u64_wrap(port)
		if p >= Machine.gpu_lo and p <= Machine.gpu_hi {
			(m, U64.to_i64_wrap(Gpu.in!(p)))
		} else {
			crash("framebuffer: port-in-32 from port ${Str.inspect(p)}, a device this platform does not have")
		}
	}
}
