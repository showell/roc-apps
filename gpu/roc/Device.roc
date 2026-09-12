# The Codex Device effect on the CPU. A [Device] kernel's loads and stores
# are threaded through this record, one thread (gid) after another, where
# the WGSL plug makes them storage-buffer reads and writes on the GPU. A
# buffer handle is its index into `bufs`: the Codex source passes a buffer
# as an Integer, and the plug turns each such parameter into a binding.
#
# Out of bounds reads 0 and writes nothing, as a WGSL storage access does.
Device :: [].{
	Device : { bufs : List(List(I64)) }

	new : List(List(I64)) -> Device.Device
	new = |bufs| { bufs: bufs }

	buffer : Device.Device, I64 -> List(I64)
	buffer = |dev, buf| List.get(dev.bufs, I64.to_u64_wrap(buf)) ?? []

	load : Device.Device, I64, I64 -> (Device.Device, I64)
	load = |dev, buf, i| {
		b = List.get(dev.bufs, I64.to_u64_wrap(buf)) ?? []
		(dev, List.get(b, I64.to_u64_wrap(i)) ?? 0)
	}

	# device-store answers the stored value.
	store : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	store = |dev, buf, i, v| {
		bufs = List.update(dev.bufs, I64.to_u64_wrap(buf), |b| List.set(b, I64.to_u64_wrap(i), v) ?? b) ?? dev.bufs
		({ bufs: bufs }, v)
	}

	# One dispatch: the kernel over gid 0..n-1, in order, threading the
	# device. What dispatchWorkgroups does in parallel on the GPU.
	dispatch : Device.Device, I64, (Device.Device, I64 -> (Device.Device, I64)) -> Device.Device
	dispatch = |dev, n, kernel| dispatch_from(dev, 0, n, kernel)

	dispatch_from : Device.Device, I64, I64, (Device.Device, I64 -> (Device.Device, I64)) -> Device.Device
	dispatch_from = |dev, gid, n, kernel|
		if gid >= n { dev } else {
			(dev1, _) = kernel(dev, gid)
			dispatch_from(dev1, gid + 1, n, kernel)
		}
}
