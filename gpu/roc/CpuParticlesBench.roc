# A native bench for the fountain: seed buffer 0 the way the page would (a
# fixed integer pattern here, so Python can match it), ping-pong two buffers
# for N frames, print a checksum of the last frame's output. Hand-written.
#
#   roc build --opt=speed CpuParticlesBench.roc --output=<bin>; <bin> 100
import Device
import CpuParticlesKernel

n : I32
n = 14000

seed_particle : I32 -> List(I32)
seed_particle = |i| [
	8192 + I32.rem_by(i * 37, 300) - 150,
	11600 - I32.rem_by(i * 53, 700),
	I32.rem_by(i * 29, 620) - 310,
	0 - (230 + I32.rem_by(i * 17, 250)),
]

seed_from : List(I32), I32 -> List(I32)
seed_from = |acc, i| if i >= n { acc } else { seed_from(List.concat(acc, seed_particle(i)), i + 1) }

frames : Device.Device, I32, I32 -> Device.Device
frames = |dev, frame, last|
	if frame >= last { dev } else {
		src = I32.rem_by(frame, 2)
		dst = 1 - src
		next = Device.dispatch(dev, n, |d, gid| CpuParticlesKernel.cp_step(d, src, dst, frame, gid))
		frames(next, frame + 1, last)
	}

main! = |args| {
	count = I32.from_str(List.get(args, 0) ?? "100") ?? 100
	dev = frames(Device.new([seed_from([], 0), List.repeat(0, I32.to_u64_wrap(n * 4))]), 0, count)
	out = Device.buffer(dev, I32.rem_by(count, 2))
	sum = List.fold(out, 0, |acc, v| U64.plus_wrap(acc, I32.to_u64_wrap(v)))
	echo!(Str.concat(Str.concat(Str.concat("frames ", I32.to_str(count)), " checksum "), Str.concat(U64.to_str(sum), "\n")))
	Ok({})
}
