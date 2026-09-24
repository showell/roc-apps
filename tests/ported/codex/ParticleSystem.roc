# ParticleSystem -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Random

ParticleSystem :: [].{
	Particle := { part_x : I64, part_y : I64, part_z : I64, part_vx : I64, part_vy : I64, part_vz : I64, part_life : I64, part_max_life : I64, part_color : I64 }.{
		is_eq : ParticleSystem.Particle, ParticleSystem.Particle -> Bool
		is_eq = |a, b| a.part_x == b.part_x and a.part_y == b.part_y and a.part_z == b.part_z and a.part_vx == b.part_vx and a.part_vy == b.part_vy and a.part_vz == b.part_vz and a.part_life == b.part_life and a.part_max_life == b.part_max_life and a.part_color == b.part_color
	}
	ParticleEmitter := { emit_x : I64, emit_y : I64, emit_z : I64, emit_vx : I64, emit_vy : I64, emit_vz : I64, emit_spread : I64, emit_life : I64, emit_color : I64 }.{
		is_eq : ParticleSystem.ParticleEmitter, ParticleSystem.ParticleEmitter -> Bool
		is_eq = |a, b| a.emit_x == b.emit_x and a.emit_y == b.emit_y and a.emit_z == b.emit_z and a.emit_vx == b.emit_vx and a.emit_vy == b.emit_vy and a.emit_vz == b.emit_vz and a.emit_spread == b.emit_spread and a.emit_life == b.emit_life and a.emit_color == b.emit_color
	}
	ParticleSystem := { particles : List(ParticleSystem.Particle), count : I64, max_particles : I64 }.{
		is_eq : ParticleSystem.ParticleSystem, ParticleSystem.ParticleSystem -> Bool
		is_eq = |a, b| a.particles == b.particles and a.count == b.count and a.max_particles == b.max_particles
	}

	emitter_new : I64, I64, I64, I64, I64, I64, I64, I64, I64 -> ParticleSystem.ParticleEmitter
	emitter_new = |x, y, z, vx, vy, vz, spread, life, color| ParticleSystem.ParticleEmitter.{ emit_x: x, emit_y: y, emit_z: z, emit_vx: vx, emit_vy: vy, emit_vz: vz, emit_spread: spread, emit_life: life, emit_color: color }

	psys_new : I64 -> ParticleSystem.ParticleSystem
	psys_new = |max| ParticleSystem.ParticleSystem.{ particles: [], count: 0, max_particles: max }

	psys_emit : ParticleSystem.ParticleSystem, ParticleSystem.ParticleEmitter, I64, I64 -> ParticleSystem.ParticleSystem
	psys_emit = |sys, emitter, num, seed| psys_emit_loop(sys, emitter, num, seed, 0)

	psys_emit_loop : ParticleSystem.ParticleSystem, ParticleSystem.ParticleEmitter, I64, I64, I64 -> ParticleSystem.ParticleSystem
	psys_emit_loop = |sys, em, num, seed, i| (if (i >= num) { sys } else { (if (sys.count >= sys.max_particles) { sys } else { ({
		spread : I64
		spread = em.emit_spread
		svx : I64
		svx = (em.emit_vx + psys_noise(psys_hash(seed, (i * 3)), spread))
		svy : I64
		svy = (em.emit_vy + psys_noise(psys_hash(seed, ((i * 3) + 1)), spread))
		svz : I64
		svz = (em.emit_vz + psys_noise(psys_hash(seed, ((i * 3) + 2)), spread))
		p = ParticleSystem.Particle.{ part_x: em.emit_x, part_y: em.emit_y, part_z: em.emit_z, part_vx: svx, part_vy: svy, part_vz: svz, part_life: em.emit_life, part_max_life: em.emit_life, part_color: em.emit_color }
		psys_emit_loop(ParticleSystem.ParticleSystem.{ particles: List.append(sys.particles, p), count: (sys.count + 1), max_particles: sys.max_particles }, em, num, seed, (i + 1))
	}) }) })

	psys_hash : I64, I64 -> I64
	psys_hash = |seed, i| ({
		h : I64
		h = Random.mix_bits(seed, i)
		(if (h < 0) { (-h) } else { h })
	})

	psys_noise : I64, I64 -> I64
	psys_noise = |hash_val, spread| (if (spread == 0) { 0 } else { ({
		range : I64
		range = (spread * 2)
		positive : I64
		positive = (if (hash_val < 0) { (-hash_val) } else { hash_val })
		((positive - (I64.div_trunc_by(positive, range) * range)) - spread)
	}) })

	psys_update : ParticleSystem.ParticleSystem, I64, I64 -> ParticleSystem.ParticleSystem
	psys_update = |sys, dt, gravity| psys_compact(psys_update_all(sys, dt, gravity))

	psys_update_all : ParticleSystem.ParticleSystem, I64, I64 -> ParticleSystem.ParticleSystem
	psys_update_all = |sys, dt, gravity| ParticleSystem.ParticleSystem.{ particles: psys_update_loop(sys.particles, 0, sys.count, dt, gravity, []), count: sys.count, max_particles: sys.max_particles }

	psys_update_loop : List(ParticleSystem.Particle), I64, I64, I64, I64, List(ParticleSystem.Particle) -> List(ParticleSystem.Particle)
	psys_update_loop = |ps, i, len, dt, gravity, acc| (if (i >= len) { acc } else { ({
		p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		updated = ParticleSystem.Particle.{ part_x: (p.part_x + I64.div_trunc_by((p.part_vx * dt), 1000)), part_y: (p.part_y + I64.div_trunc_by((p.part_vy * dt), 1000)), part_z: (p.part_z + I64.div_trunc_by((p.part_vz * dt), 1000)), part_vx: p.part_vx, part_vy: (p.part_vy - I64.div_trunc_by((gravity * dt), 1000)), part_vz: p.part_vz, part_life: (p.part_life - dt), part_max_life: p.part_max_life, part_color: p.part_color }
		psys_update_loop(ps, (i + 1), len, dt, gravity, List.append(acc, updated))
	}) })

	psys_compact : ParticleSystem.ParticleSystem -> ParticleSystem.ParticleSystem
	psys_compact = |sys| psys_compact_loop(sys.particles, 0, sys.count, [], 0, sys.max_particles)

	psys_compact_loop : List(ParticleSystem.Particle), I64, I64, List(ParticleSystem.Particle), I64, I64 -> ParticleSystem.ParticleSystem
	psys_compact_loop = |ps, i, len, acc, alive, max| (if (i >= len) { ParticleSystem.ParticleSystem.{ particles: acc, count: alive, max_particles: max } } else { ({
		p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (p.part_life <= 0) { psys_compact_loop(ps, (i + 1), len, acc, alive, max) } else { psys_compact_loop(ps, (i + 1), len, List.append(acc, p), (alive + 1), max) })
	}) })

	psys_count : ParticleSystem.ParticleSystem -> I64
	psys_count = |sys| sys.count

	psys_alive_count : ParticleSystem.ParticleSystem -> I64
	psys_alive_count = |sys| psys_count_alive(sys.particles, 0, sys.count, 0)

	psys_count_alive : List(ParticleSystem.Particle), I64, I64, I64 -> I64
	psys_count_alive = |ps, i, len, acc| (if (i >= len) { acc } else { ({
		p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		psys_count_alive(ps, (i + 1), len, (acc + (if (p.part_life > 0) { 1 } else { 0 })))
	}) })
}
