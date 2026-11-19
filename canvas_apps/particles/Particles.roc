## Particles is roc-ray's `examples/particles`: a fountain of four thousand
## sprites that follows the pointer.
##
## Upstream steers the emitter with the pointer, widens the spray while Space
## is held, and has a recording mode in which the emitter travels a fixed
## figure. Both are here: the emitter follows the pointer once the pointer has
## moved over the canvas, and travels the recording's figure until then, so
## the fountain is alive before anyone touches it.
##
## The app is here for the volume: it draws four thousand discs a frame, and
## every one of them crosses to the page.
##
## A sprite becomes a disc. Upstream's sprite is an 8-by-8 white texture with
## a tint and a rotation, so nothing is lost but the spin, which cannot be
## seen on a sprite three to nine pixels across.
import lib.Pixels
import lib.Point
import lib.Shapes
import lib.Brush
import lib.RgbColor

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
	start = { particles: initial_particles(0, []), tick: 0 }

	## One step, with the emitter where it is and the spray as wide as it is.
	advance : Particles.Model, { x : F64, y : F64 }, F64 -> Particles.Model
	advance = |model, at, spread| {
		particles: next_particles(model.particles, at, spread, 0, []),
		tick: model.tick + 1,
	}

	# Their recording's emitter: a slow figure that keeps the fountain moving.
	emitter : I64 -> { x : F64, y : F64 }
	emitter = |tick| {
		phase = I64.to_f64(tick) * 0.055
		{ x: 400.0 + phase.sin() * 170.0, y: 205.0 + (phase * 0.7).cos() * 45.0 }
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
		I64.to_f64((index * (2654435761 + salt * 40503) + salt * 7919 + 1).rem_by(65521)) / 65521.0

	initial_particles : I64, List(Particles.Particle) -> List(Particles.Particle)
	initial_particles = |index, particles|
		if index >= count {
			particles
		} else {
			seed = unit_hash(index, 0)
			initial_particles(
				index + 1,
				List.append(
					particles,
					{
						x: 0.0,
						y: 0.0,
						vx: 0.0,
						vy: 0.0,
						# Stagger the first respawn so the fountain fills rather
						# than pulsing.
						life: seed * 2.8,
						seed: seed,
						phase: unit_hash(index, 1),
						tint: index.rem_by(4),
					},
				),
			)
		}

	next_particles : List(Particles.Particle), { x : F64, y : F64 }, F64, U64, List(Particles.Particle) -> List(Particles.Particle)
	next_particles = |particles, at, spread, index, stepped_particles|
		if index >= List.len(particles) {
			stepped_particles
		} else {
			next_particles(
				particles,
				at,
				spread,
				index + 1,
				List.append(
					stepped_particles,
					step(
						List.get(particles, index) ?? crash ("particle"),
						at,
						spread,
					),
				),
			)
		}

	step : Particles.Particle, { x : F64, y : F64 }, F64 -> Particles.Particle
	step = |particle, at, spread| {
		life = particle.life - dt
		if life > 0.0 {
			{
				..particle,
				x: particle.x + particle.vx * dt,
				y: particle.y + particle.vy * dt,
				vy: particle.vy + 420.0 * dt,
				life: life,
			}
		} else {
			angle = particle.phase * F64.tau
			speed = 90.0 + 150.0 * particle.seed
			{
				..particle,
				x: at.x,
				y: at.y,
				vx: angle.cos() * speed * spread,
				vy: angle.sin() * speed - 210.0,
				life: 1.1 + particle.seed * 1.7,
			}
		}
	}

	# Their four colours.
	palette : I64 -> Brush.Rgba
	palette = |tint|
		if tint == 0 {
			Brush.opaque_rgba(RgbColor.of(0xffd166))
		} else if tint == 1 {
			Brush.opaque_rgba(RgbColor.of(0xef476f))
		} else if tint == 2 {
			Brush.opaque_rgba(RgbColor.of(0x06d6a0))
		} else {
			Brush.opaque_rgba(RgbColor.of(0x118ab2))
		}

	shapes : Particles.Model -> List(Shapes.Shape)
	shapes = |model| {
		particle_count = List.len(model.particles)
		var $out = List.with_capacity(particle_count + 1)
		$out = List.append($out, Shapes.rectangle({ top_left: Point.at(0.0, 0.0), width: Pixels.of(width), height: Pixels.of(height), fill: Brush.flat(RgbColor.of(0x0b0e17)) }))
		var $i = 0
		while $i < particle_count {
			particle = List.get(model.particles, $i) ?? crash ("particle")
			# Their sprite is 3 to 9 pixels across, sized by the same seed.
			radius = (3.0 + 6.0 * particle.seed) / 2.0
			$out = List.append(
				$out,
				Disc({
					center: Point.at(particle.x, particle.y),
					radius: Pixels.of(radius),
					fill: Flat(palette(particle.tint)),
				}),
			)
			$i = $i + 1
		}
		$out
	}
}
