# Machine -- what the floor gives a Codex program that reaches a device. It
# stands in for the Machine rocemit writes, door for door, but holds almost
# nothing: memory is the host's (pf.Heap), the block device's images are the
# host's (pf.Disk), and the clock is the host's (pf.Clock). The value carries
# the heap's bump pointer and nothing else.
#
# **THE POLICY STAYS HERE.** The capability word is memory, at the address
# x86's kernel keeps it, written by `boot!` from the effects the opening
# declares and read back by every block door -- so a program that clears its
# own grant is denied from then on, exactly as on the machine. The host
# enforces one thing only: that an address is backed. Whether this program may
# read that disk is a question answered in Roc.
#
# **A TRANSFER NAMES AN ADDRESS.** `block-read-sector` bump-allocates its 512
# bytes and hands the host the address to fill; the sector never becomes a Roc
# value. That is the same shape x86's builtin already had, and it is why this
# platform copies nothing.
import pf.Heap
import pf.Disk
import pf.Clock
import MachineCaps

Machine :: [].{
	Machine : { top : I64 }

	# The heap starts where the machine's does, moved by the argument count.
	# The grant the opening's effects earn goes where x86's boot writes it, and
	# the primary master is the position a block request addresses until
	# `block-select` says otherwise.
	boot! : List(Str), List(Str) => Machine.Machine
	boot! = |args, effects| {
		Heap.store!(Machine.at(MachineCaps.word_addr), MachineCaps.grant(effects), 8)
		Disk.select!(0)
		{ top: 6291456 + U64.to_i64_wrap(List.len(args)) }
	}

	# The host keeps the memory and the images; there is nothing to hand over.
	halt! : Machine.Machine => {}
	halt! = |_m| {}

	# ---- the heap --------------------------------------------------------

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

	# The machine's guarded and unguarded doors differ only by a capability
	# guard on a device page, and this floor has no device pages.
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

	# ---- the block device ------------------------------------------------

	# The grant the block syscalls check, as x86's do (X86_64Boot's
	# emit-block-elev-gate): the boot process holds the block-device bit, or
	# the filesystem servicer's cell is set.
	block_granted! : Machine.Machine => Bool
	block_granted! = |_m| {
		word = Heap.load!(Machine.at(MachineCaps.word_addr), 8)
		U64.bitwise_and(word, MachineCaps.bit(MachineCaps.block_device)) != 0 or Heap.load!(Machine.at(MachineCaps.fs_elevated_addr), 8) != 0
	}

	# `block-select` chooses the position the next block request addresses, and
	# answers 0; denied, it chooses nothing and answers -1.
	block_select! : Machine.Machine, I64 => (Machine.Machine, I64)
	block_select! = |m, n|
		if Machine.block_granted!(m) {
			Disk.select!(I64.to_u64_wrap(n))
			(m, 0)
		} else {
			(m, -1)
		}

	# `block-sector-count`: the selected position's size in sectors, 0 with
	# nothing on it; denied, -1.
	block_sector_count! : Machine.Machine => (Machine.Machine, I64)
	block_sector_count! = |m|
		if Machine.block_granted!(m) {
			(m, U64.to_i64_wrap(Disk.sector_count!()))
		} else {
			(m, -1)
		}

	# `block-read-sector` as x86 answers it: 512 bytes bump-allocated in
	# memory, the host asked to fill them, the address handed back. Denied, the
	# buffer is allocated and handed back all the same, with nothing read into
	# it.
	block_read_sector! : Machine.Machine, I64 => (Machine.Machine, I64)
	block_read_sector! = |m, lba| {
		(m1, base) = Machine.alloc(m, 512)
		if Machine.block_granted!(m1) {
			_outcome = Disk.read!(I64.to_u64_wrap(lba), Machine.at(base))
			(m1, base)
		} else {
			(m1, base)
		}
	}

	# `block-write-sector`: the 512 bytes at `buf` become the sector. A denied
	# write writes nothing and answers 0, as x86's does.
	#
	# **THE FLOOR REPORTS WHAT THE FLOOR DID WRONG, AND NOTHING ELSE.** A
	# position with nothing on it and a sector past the end answer 0, because
	# that is what the machine answers, and a clean run has to be the machine's
	# run exactly. A transfer an injected fault refused answers 1 -- Fat16
	# already reads this status (`fat16-put-entry-and-write` answers True only
	# for 0), so a write that did not land is reported as one instead of being
	# claimed as a success. A torn write still answers 0: the controller thought
	# it wrote, and finding out otherwise is the filesystem's problem, which is
	# the whole point of that fault.
	block_write_sector! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	block_write_sector! = |m, lba, buf| {
		if Machine.block_granted!(m) {
			outcome = Disk.write!(I64.to_u64_wrap(lba), Machine.at(buf))
			(m, if outcome == 3 { 1 } else { 0 })
		} else {
			(m, 0)
		}
	}

	# ---- the clock -------------------------------------------------------

	# The floor's clock, in nanoseconds, and a wait until a deadline on it.
	# Nothing rocemit writes calls these yet; they are here because they are
	# what an operating system above this floor is built on.
	now! : Machine.Machine => (Machine.Machine, I64)
	now! = |m| (m, U64.to_i64_wrap(Clock.now!()))

	wait! : Machine.Machine, I64 => (Machine.Machine, I64)
	wait! = |m, deadline| (m, U64.to_i64_wrap(Clock.wait!(I64.to_u64_wrap(deadline))))

	# ---- the process -----------------------------------------------------

	# One process runs here, the booted one, and it has no scope.
	process_get_pid : Machine.Machine -> (Machine.Machine, I64)
	process_get_pid = |m| (m, 0)

	process_get_scope : Machine.Machine, I64 -> (Machine.Machine, Str)
	process_get_scope = |m, _pid| (m, "")
}
