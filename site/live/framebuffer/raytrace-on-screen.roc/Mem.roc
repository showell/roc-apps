# Mem -- Codex's address space on the framebuffer platform, door for door
# the Mem rocemit writes. The bytes are the host's (pf.Heap), so a door that
# reads or writes is an effect, and the value carries only the bump pointer.
import pf.Heap

Mem :: [].{
	Mem : { top : I64 }

	new : I64 -> Mem.Mem
	new = |z| { top: 6291456 + z }

	alloc : Mem.Mem, I64 -> (Mem.Mem, I64)
	alloc = |mem, n| ({ top: mem.top + n }, mem.top)

	# `__heap-advance`: the bump pointer moves past `n` bytes.
	advance : Mem.Mem, I64 -> (Mem.Mem, {})
	advance = |mem, n| ({ top: mem.top + n }, {})

	# `__heap-save` answers the bump pointer, and `__heap-restore` rewinds to it.
	mark : Mem.Mem -> (Mem.Mem, I64)
	mark = |mem| (mem, mem.top)

	release : Mem.Mem, I64 -> (Mem.Mem, I64)
	release = |_mem, h| ({ top: h }, 0)

	at : I64 -> U64
	at = |addr| I64.to_u64_wrap(addr)

	load! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	load! = |mem, base, off, width| (mem, U64.to_i64_wrap(Heap.load!(Mem.at(base + off), Mem.at(width))))

	store! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	store! = |mem, base, off, v, width| {
		Heap.store!(Mem.at(base + off), I64.to_u64_wrap(v), Mem.at(width))
		(mem, 0)
	}

	# `atomic-exchange`: the qword at the address becomes `v`, and the old one
	# is the answer.
	exchange! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	exchange! = |mem, addr, v| {
		old = Heap.load!(Mem.at(addr), 8)
		Heap.store!(Mem.at(addr), I64.to_u64_wrap(v), 8)
		(mem, U64.to_i64_wrap(old))
	}

	# `__buf-write-byte base off v`: the low byte of `v` at base + off;
	# answers off + 1.
	write_byte! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	write_byte! = |mem, base, off, v| {
		Heap.store!(Mem.at(base + off), I64.to_u64_wrap(v), 1)
		(mem, off + 1)
	}

	# `__buf-write-bytes base off bytes`: the low byte of each element from
	# base + off on; answers off plus the count, the offset past the last.
	write_bytes! : Mem.Mem, I64, I64, List(I64) => (Mem.Mem, I64)
	write_bytes! = |mem, base, off, bytes| {
		n = U64.to_i64_wrap(List.len(bytes))
		var $i = 0
		while $i < n {
			Heap.store!(Mem.at(base + off + $i), I64.to_u64_wrap(List.get(bytes, I64.to_u64_wrap($i)) ?? 0), 1)
			$i = $i + 1
		}
		(mem, off + n)
	}

	# `__buf-read-bytes base off count`: the `count` bytes from base + off on,
	# each as an unsigned value; a count of zero or less reads none.
	read_bytes! : Mem.Mem, I64, I64, I64 => (Mem.Mem, List(I64))
	read_bytes! = |mem, base, off, count| {
		var $acc = List.with_capacity(I64.to_u64_wrap(I64.max(count, 0)))
		var $i = 0
		while $i < count {
			$acc = List.append($acc, U64.to_i64_wrap(Heap.load!(Mem.at(base + off + $i), 1)))
			$i = $i + 1
		}
		(mem, $acc)
	}
}
