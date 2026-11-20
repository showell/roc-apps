## Crowd is the robots by the hundred: where each one stands and how it moves
## at a tick. First a row of short robots behind the fence, jumping one
## after another to see over it, until the whole row jumps at once. Then two great blocks of robots pour in
## from far off to either side of the tables, the inside columns first, and
## hop on the beat once they are in place. Twice the whole crowd does the
## wave: arms up as it sweeps across the yard, one way and then back.
import lib.Eye
import Ease
import Robot
import Script

Crowd :: [].{

	## One robot in the crowd: its build, where its feet are, how far its
	## arms are up, from 0, at its sides, to 1, over its head, and how hard
	## it is running and how far through its stride, as a Robot's walk is.
	Member : {
		build : Robot.Build,
		feet : Eye.At,
		arms : F64,
		running : F64,
		phase : F64,
	}

	## The two blocks at `tick`, farthest first: only those that have set
	## off.
	block_members_at : I64 -> List(Crowd.Member)
	block_members_at = |tick| {
		now = Script.held_tick(tick)
		block_spots.keep_if(|spot| now > set_off_tick(spot)).map(|spot| block_member(spot, now))
	}

	## The row behind the fence at `tick`, from when the noise starts.
	fence_members_at : I64 -> List(Crowd.Member)
	fence_members_at = |tick| {
		now = Script.held_tick(tick)
		if now < Script.peek_tick {
			[]
		} else {
			fence_spots.map(|spot| fence_member(spot, now))
		}
	}
}

# Where a robot in a block ends up, which side it comes in from, and how
# long after the flood starts it sets off.
BlockSpot : {
	build : Robot.Build,
	right : F64,
	forward : F64,
	from_side : F64,
	delay : I64,
}

builds : List(Robot.Build)
builds = [Tall, Round, Tiny]

build_at : U64 -> Robot.Build
build_at = |index| builds.get(index % 3) ?? crash "Crowd.build_at: three builds"

# Rows a metre and a half apart from beside the first table to beside the
# army, each row both blocks, every other row shifted half a
# place so the robots behind show between those in front. The rows are in
# order far to near, which is the order they are painted in.
block_spots : List(BlockSpot)
block_spots = {
	row_count : U64
	row_count = 22
	column_count : U64
	column_count = 9
	var $out = List.with_capacity(2 * row_count * column_count)
	for row in 0..<row_count {
		shift = 0.65 * (row % 2).to_f64()
		for from_side in [-1.0, 1.0] {
			for column in 0..<column_count {
				$out = $out.append({
					build: build_at(row + column),
					right: from_side * (9.5 + shift + 1.3 * column.to_f64()),
					forward: 8.5 - 1.5 * row.to_f64(),
					from_side,
					delay: 12 * column.to_i64_wrap() + 2 * row.to_i64_wrap(),
				})
			}
		}
	}
	$out
}

set_off_tick : BlockSpot -> I64
set_off_tick = |spot| Script.flood_tick + spot.delay

# How far out a robot starts, and how long it takes to run in, braking as
# it comes.
run_metres : F64
run_metres = 70.0

run_frames : I64
run_frames = 100

block_member : BlockSpot, I64 -> Crowd.Member
block_member = |spot, now| {
	progress = Ease.ramp(now - set_off_tick(spot), run_frames)
	left_to_go = (1.0 - progress) * (1.0 - progress)
	arms = wave_arms(now, spot.right)
	beat = (F64.pi * (now - Script.flood_tick).to_f64() / 30.0).sin().abs()
	{
		build: spot.build,
		feet: {
			right: spot.right + spot.from_side * run_metres * left_to_go,
			forward: spot.forward,
			height: progress * progress * (0.12 * beat + 0.35 * arms),
		},
		arms,
		running: (1.0 - progress) * 2.0,
		phase: run_metres * (1.0 - left_to_go) * 6.0,
	}
}

# The fence row: short robots only, so the fence hides them until they jump.
FenceSpot : {
	build : Robot.Build,
	right : F64,
	first_jump : I64,
}

fence_spots : List(FenceSpot)
fence_spots = {
	place_count : U64
	place_count = 41
	var $out = List.with_capacity(place_count)
	for place in 0..<place_count {
		$out = $out.append({
			build: if place % 2 == 0 {
				Round
			} else {
				Tiny
			},
			right: -22.0 + 1.1 * place.to_f64(),
			first_jump: Script.peek_tick + 60 + (37 * place.to_i64_wrap()) % 100,
		})
	}
	$out
}

fence_forward : F64
fence_forward = 11.9

jump_period : I64
jump_period = 48

jump_frames : I64
jump_frames = 30

fence_member : FenceSpot, I64 -> Crowd.Member
fence_member = |spot, now| {
	# Just before the flood the whole row jumps at once, twice as high, and
	# jumps together from then on.
	together = Script.flood_tick - jump_frames
	since = now - (
		if now >= together {
			together
		} else {
			spot.first_jump
		}
	)
	boost = if now >= together and now < Script.flood_tick {
		2.2
	} else {
		1.0
	}
	in_jump = since - jump_period * (since // jump_period)
	up =
		if since < 0 or in_jump >= jump_frames {
			0.0
		} else {
			x = in_jump.to_f64() / jump_frames.to_f64()
			4.0 * x * (1.0 - x)
		}
	jump_height =
		match spot.build {
			Tiny => 1.6
			Tall | Round => 1.0
		}
	{
		build: spot.build,
		feet: {
			right: spot.right,
			forward: fence_forward,
			height: boost * jump_height * up,
		},
		arms: wave_arms(now, spot.right).max(up),
		running: 0.0,
		phase: 0.0,
	}
}

# How far up a robot's arms are as the wave goes by: the wave crosses the
# middle of the yard at each of Script's wave ticks, left to right the first
# time and back the second, `wave_speed` metres a tick, and the arms are up
# for a moment either side of it.
wave_arms : I64, F64 -> F64
wave_arms = |now, right| {
	passes = List.map2(
		Script.wave_ticks,
		[1.0, -1.0],
		|tick, way| (tick, way),
	)
	passes.fold(
		0.0,
		|arms, (tick, way)| {
			front = tick.to_f64() + way * right / wave_speed
			lift = 1.0 - (now.to_f64() - front).abs() / 18.0
			arms.max(lift)
		},
	)
}

wave_speed : F64
wave_speed = 0.6

# Nobody is out before the flood; at the end both blocks are in place, by
# the hundred.
expect Crowd.block_members_at(Script.flood_tick) == []
expect {
	at_end = Crowd.block_members_at(Script.end_tick)
	at_end.len() > 350 and at_end.all(|member| member.running == 0.0)
}

# The wave lifts arms in the middle of the yard as it passes, and not well
# before.
expect wave_arms(Script.wave_ticks.first() ?? 0, 0.0) == 1.0
expect wave_arms((Script.wave_ticks.first() ?? 0) - 100, 0.0) == 0.0
