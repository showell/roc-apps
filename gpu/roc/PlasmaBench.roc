# A native bench for the plasma kernel: dispatch one frame of W*H threads,
# N frames, print a checksum of the last frame. Hand-written.
#
#   roc build --opt=speed PlasmaBench.roc --output=<bin>; <bin> 10
import Device
import PlasmaKernel

w : I32
w = 1024
h : I32
h = 768

frames : Device.Device, I32, I32 -> Device.Device
frames = |dev, frame, last|
	if frame > last { dev } else {
		next = Device.dispatch(dev, w * h, |d, gid| PlasmaKernel.plasma_step(d, 0, frame, gid))
		frames(next, frame + 1, last)
	}

main! = |args| {
	n = I32.from_str(List.get(args, 0) ?? "10") ?? 10
	dev = frames(Device.new([List.repeat(0, I32.to_u64_wrap(w * h))]), 0, n - 1)
	out = Device.buffer(dev, 0)
	sum = List.fold(out, 0, |acc, v| U64.plus_wrap(acc, I32.to_u64_wrap(v)))
	echo!(Str.concat(Str.concat(Str.concat("frames ", I32.to_str(n)), " checksum "), Str.concat(U64.to_str(sum), "\n")))
	Ok({})
}
