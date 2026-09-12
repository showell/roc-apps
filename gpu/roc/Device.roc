# The Codex Device effect on the CPU. A [Device] kernel's loads and stores
# are threaded through this record, one thread (gid) after another, where
# the WGSL plug makes them storage-buffer reads and writes on the GPU. A
# buffer handle is its index into `bufs`: the Codex source passes a buffer
# as an Integer, and the plug turns each such parameter into a binding.
#
# Out of bounds reads 0 and writes nothing, as a WGSL storage access does.
#
# Everything is I32 and F32 because the plug's WGSL is: a kernel's pixels
# are i32 bits, wrapping included, and rocemit spells a unit with a Device
# kernel in those types with the wrapping operations.
Device :: [].{
	# `gid` is the thread being run, set by dispatch; the index operations
	# read it as WGSL's global_invocation_id over workgroups of 64.
	Device : { bufs : List(List(I32)), gid : I32 }

	new : List(List(I32)) -> Device.Device
	new = |bufs| { bufs: bufs, gid: 0 }

	workgroup : I32
	workgroup = 64

	# WGSL's integer division and remainder are total: by zero, and for the
	# one overflow, `/` yields the dividend and `%` yields zero, where Roc's
	# would crash. rocemit spells a kernel's `/` as Device.div.
	div : I32, I32 -> I32
	div = |a, b| if b == 0 or (a == I32.lowest and b == -1) { a } else { I32.div_trunc_by(a, b) }

	rem : I32, I32 -> I32
	rem = |a, b| if b == 0 or (a == I32.lowest and b == -1) { 0 } else { I32.rem_by(a, b) }

	thread_idx_x : Device.Device -> (Device.Device, I32)
	thread_idx_x = |dev| (dev, I32.rem_by(dev.gid, workgroup))

	block_idx_x : Device.Device -> (Device.Device, I32)
	block_idx_x = |dev| (dev, I32.div_trunc_by(dev.gid, workgroup))

	block_dim_x : Device.Device -> (Device.Device, I32)
	block_dim_x = |dev| (dev, workgroup)

	buffer : Device.Device, I32 -> List(I32)
	buffer = |dev, buf| List.get(dev.bufs, I32.to_u64_wrap(buf)) ?? []

	load : Device.Device, I32, I32 -> (Device.Device, I32)
	load = |dev, buf, i| {
		b = List.get(dev.bufs, I32.to_u64_wrap(buf)) ?? []
		(dev, List.get(b, I32.to_u64_wrap(i)) ?? 0)
	}

	# device-store answers the stored value.
	store : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	store = |dev, buf, i, v| {
		bufs = List.update(dev.bufs, I32.to_u64_wrap(buf), |b| List.set(b, I32.to_u64_wrap(i), v) ?? b) ?? dev.bufs
		({ bufs: bufs, gid: dev.gid }, v)
	}

	# One dispatch: the kernel over gid 0..n-1, in order, threading the
	# device. What dispatchWorkgroups does in parallel on the GPU.
	dispatch : Device.Device, I32, (Device.Device, I32 -> (Device.Device, I32)) -> Device.Device
	dispatch = |dev, n, kernel| dispatch_from(dev, 0, n, kernel)

	dispatch_from : Device.Device, I32, I32, (Device.Device, I32 -> (Device.Device, I32)) -> Device.Device
	dispatch_from = |dev, gid, n, kernel|
		if gid >= n { dev } else {
			(dev1, _) = kernel({ bufs: dev.bufs, gid: gid }, gid)
			dispatch_from(dev1, gid + 1, n, kernel)
		}
}
