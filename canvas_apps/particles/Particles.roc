# Particles -- roc-ray's `examples/particles`: a fountain of four thousand
# sprites that follows the pointer.
#
# Upstream steers the emitter with the pointer, widens the spray while Space is
# held, and has a recording mode in which the emitter travels a fixed figure.
# Both are here: the emitter follows the pointer once it has moved over the
# canvas, and travels the recording's figure until then, so the fountain is
# alive before anyone touches it.
#
# **IT IS HERE FOR THE VOLUME**: four thousand discs a frame, every one of them
# crossing to the page.
#
# A sprite becomes a disc: theirs is an 8-by-8 white texture with a tint and a
# rotation, so nothing is lost but the spin, which at three to nine pixels
# across is not visible anyway.
import lib.Shapes
import lib.Brush
import lib.Trig

Particles :: [].{
	# Their window.
	width : F64
	width = 800.0
	height : F64
	height = 600.0

	count : I64
	count = 4000

	# Their recording's fixed step.
	dt : F64
	dt = 1.0 / 60.0

	# A particle carries what it needs to respawn itself, so the fountain needs
	# no random source and looks the same on every run.
	Particle : { x : F64, y : F64, vx : F64, vy : F64, life : F64, seed : F64, phase : F64, tint : I64 }

	Model : { particles : List(Particles.Particle), tick : I64 }

	start : Particles.Model
	start = { particles: initial(0, []), tick: 0 }

	## One step, with the emitter where it is and the spray as wide as it is.
	advance : Particles.Model, { x : F64, y : F64 }, F64 -> Particles.Model
	advance = |m, at, spread| { particles: stepped(m.particles, at, spread, 0, []), tick: m.tick + 1 }

	# Their recording's emitter: a slow figure that keeps the fountain moving.
	emitter : I64 -> { x : F64, y : F64 }
	emitter = |tick| {
		phase = I64.to_f64(tick) * 0.055
		{ x: 400.0 + Trig.r_sin(phase) * 170.0, y: 205.0 + Trig.r_cos(phase * 0.7) * 45.0 }
	}

	# Their two spreads: the wide one while Space is held, and in recording.
	spread_wide : F64
	spread_wide = 1.9

	spread_narrow : F64
	spread_narrow = 0.7

	# **SPREAD AN INDEX OVER 0..1 WITHOUT A RANDOM SOURCE**, exactly as they
	# do: the modulus is prime and the multiplier coprime to it, so every
	# particle gets its own value and `index % small` does not collapse
	# thousands of them onto a handful of trajectories.
	unit_hash : I64, I64 -> F64
	unit_hash = |index, salt|
		I64.to_f64(rem(index * (2654435761 + salt * 40503) + salt * 7919 + 1, 65521)) / 65521.0

	# This Roc has no remainder, and the rest of this repository does it the
	# same way (see Trees.roc).
	rem : I64, I64 -> I64
	rem = |a, b| a - I64.div_trunc_by(a, b) * b

	initial : I64, List(Particles.Particle) -> List(Particles.Particle)
	initial = |i, acc|
		if i >= count { acc } else {
			seed = unit_hash(i, 0)
			initial(
				i + 1,
				List.append(acc, {
					x: 0.0,
					y: 0.0,
					vx: 0.0,
					vy: 0.0,
					# Stagger the first respawn so the fountain fills rather
					# than pulsing.
					life: seed * 2.8,
					seed: seed,
					phase: unit_hash(i, 1),
					tint: rem(i, 4),
				}),
			)
		}

	stepped : List(Particles.Particle), { x : F64, y : F64 }, F64, U64, List(Particles.Particle) -> List(Particles.Particle)
	stepped = |ps, at, spread, i, acc|
		if i >= List.len(ps) { acc } else {
			stepped(ps, at, spread, i + 1, List.append(acc, step(List.get(ps, i) ?? crash("particle"), at, spread)))
		}

	step : Particles.Particle, { x : F64, y : F64 }, F64 -> Particles.Particle
	step = |p, at, spread| {
		life = p.life - dt
		if life > 0.0 {
			{ ..p, x: p.x + p.vx * dt, y: p.y + p.vy * dt, vy: p.vy + 420.0 * dt, life: life }
		} else {
			angle = p.phase * 6.2831855
			speed = 90.0 + 150.0 * p.seed
			{
				..p,
				x: at.x,
				y: at.y,
				vx: Trig.r_cos(angle) * speed * spread,
				vy: Trig.r_sin(angle) * speed - 210.0,
				life: 1.1 + p.seed * 1.7,
			}
		}
	}

	# Their four colours.
	palette : I64 -> Brush.Rgba
	palette = |i|
		if i == 0 { Brush.opaque(0xffd166) } else if i == 1 { Brush.opaque(0xef476f) } else if i == 2 { Brush.opaque(0x06d6a0) } else { Brush.opaque(0x118ab2) }

	shapes : Particles.Model -> List(Shapes.Shape)
	shapes = |m| {
		n = List.len(m.particles)
		var $out = List.with_capacity(n + 1)
		$out = List.append($out, Rect({ x: 0.0, y: 0.0, w: width, h: height, fill: Flat(Brush.opaque(0x0b0e17)) }))
		var $i = 0
		while $i < n {
			p = List.get(m.particles, $i) ?? crash("particle")
			# Their sprite is 3 to 9 pixels across, sized by the same seed.
			r = (3.0 + 6.0 * p.seed) / 2.0
			$out = List.append($out, Disc({ x: p.x, y: p.y, r: r, fill: Flat(palette(p.tint)), clip: Anywhere }))
			$i = $i + 1
		}
		$out
	}
}
