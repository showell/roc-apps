## MusicalChairs is the game the drum major loses before its army marches
## in: where everything in it is at each tick. A boombox thumps down on the
## lawn in front of the floats and starts to play, and four chairs drop out
## of the sky beside it, in a row facing the eye. Four robots and the drum
## major come in in a line and go round and round the chairs while the music
## plays. It stops, and everybody freezes mid-step; then the four robots
## dive for the chairs, and the drum major, strutting too grandly to be
## quick, is left standing at the end of the row. Seatless says what it
## does about that.
##
## Everything is in the backyard's metres. The row runs down the yard, so
## the eye watches it from the aisle, looking left across the lawn, where
## nothing else is going on.
import lib.Eye
import Ease
import Robot
import Script
import Table

MusicalChairs :: [].{

	## A robot in the game: its build, where its feet are, how it stands,
	## and how far its hips are lifted above standing, as sitting on a chair
	## lifts or lowers them to the seat.
	Player : {
		build : Robot.Build,
		feet : Eye.At,
		pose : Robot.Pose,
		hips_up : F64,
	}

	## The boombox on the lawn: where it stands, and how hard it is thumping,
	## from 0, silent, to 1, on the beat.
	Boombox : { at : Eye.At, thump : F64 }

	## A note in the air: where it is, which of the note colors it is, and
	## how far it has faded, from 0 to 1, gone.
	Note : { at : Eye.At, color : U64, fade : F64 }

	## When the music starts, when it stops, when the robots dive for the
	## chairs, and when the drum major is left standing in front of them.
	music_start_tick : I64
	music_start_tick = Script.chairs_tick + 20

	music_stop_tick : I64
	music_stop_tick = Script.music_stop_tick

	scramble_tick : I64
	scramble_tick = music_stop_tick + 14

	left_standing_tick : I64
	left_standing_tick = scramble_tick + 26

	## Where the drum major ends up: at the end of the row, beside the
	## chair it was too late for.
	stand_spot : Eye.At
	stand_spot = { right: row.right + 0.35, forward: row.forward + 2.15, height: 0.0 }

	## The four chairs at `tick`, each with how high over the lawn it still
	## is as it drops in; none before the first starts to fall.
	chairs_at : I64 -> List({ chair : Table.Chair, drop : F64 })
	chairs_at = |tick| {
		now = Script.held_tick(tick)
		List.map2(chairs, [0, 1, 2, 3], |chair, k| (chair, chair_land_tick(k)))
			.keep_if(|(_, landed)| now >= landed - drop_frames)
			.map(|(chair, landed)| { chair, drop: dropped_height(now - landed) })
	}

	## The boombox at `tick`, dropping in and then thumping while the music
	## plays.
	boombox_at : I64 -> [Out, In(MusicalChairs.Boombox)]
	boombox_at = |tick| {
		now = Script.held_tick(tick)
		landed = boombox_land_tick
		if now < landed - drop_frames {
			Out
		} else {
			thump =
				if now >= music_start_tick and now < music_stop_tick {
					beat_thump(now)
				} else {
					0.0
				}
			# It jumps when the music stops, as if someone had kicked it.
			kicked = 0.25 * (F64.pi * Ease.ramp(now - music_stop_tick, 10)).sin()
			In({ at: { ..boombox_spot, height: dropped_height(now - landed) + kicked }, thump })
		}
	}

	## The notes in the air at `tick`: one pops out of the boombox on every
	## beat and floats up over the chairs, and when the music stops they all
	## drop to the lawn.
	notes_at : I64 -> List(MusicalChairs.Note)
	notes_at = |tick| {
		now = Script.held_tick(tick)
		count = ((music_stop_tick - music_start_tick) // note_gap).to_u64_wrap()
		var $out = []
		for n in 0..<count {
			match note(n, now) {
				Ok(shown) => {
					$out = $out.append(shown)
				}
				Err(Gone) => {}
			}
		}
		$out
	}

	## The four robots at `tick`, from when the music starts: going round,
	## frozen, diving for a chair, and sat in it, eyes on the drum major.
	players_at : I64 -> List(MusicalChairs.Player)
	players_at = |tick| {
		now = Script.held_tick(tick)
		if now < music_start_tick {
			[]
		} else {
			seatings.map(|seating| player(seating, now))
		}
	}

	## Where the drum major walks in the game, last in the line: round the
	## chairs, frozen, then hurrying to the front of the row a moment too
	## late, with how much it is walking and how far through its stride.
	drum_major_walk : I64 -> { feet : Eye.At, stride : F64, phase : F64 }
	drum_major_walk = |now| {
		frozen = circling(drum_major_place, music_stop_tick)
		hurry = Ease.smooth(Ease.ramp(now - scramble_tick, left_standing_tick - 2 - scramble_tick))
		if now < music_stop_tick {
			circling(drum_major_place, now)
		} else {
			{
				feet: {
					right: frozen.feet.right + (stand_spot.right - frozen.feet.right) * hurry,
					forward: frozen.feet.forward + (stand_spot.forward - frozen.feet.forward) * hurry,
					height: 0.0,
				},
				stride: if hurry > 0.0 and hurry < 1.0 {
					1.0
				} else if hurry >= 1.0 {
					0.0
				} else {
					frozen.stride
				},
				phase: frozen.phase + 12.0 * hurry,
			}
		}
	}
}

# The middle of the row, on the lawn in front of the near left float, off
# the army's way up the aisle.
row : { right : F64, forward : F64 }
row = { right: -4.6, forward: -21.5 }

seat_height : F64
seat_height = 0.45

# The chairs, nearest the eye's left first. A chair left of the table faces
# right, which is toward the eye watching from the aisle.
chairs : List(Table.Chair)
chairs = [-1.35, -0.45, 0.45, 1.35].map(
	|along| { right: row.right, forward: row.forward + along, seat_height },
)

boombox_spot : Eye.At
boombox_spot = { right: row.right - 0.6, forward: row.forward - 3.0, height: 0.0 }

# Something dropped onto the lawn: how high it is, falling from `drop_from`
# metres over `drop_frames` ticks, landing at 0 and bouncing once.
drop_from : F64
drop_from = 4.0

drop_frames : I64
drop_frames = 14

dropped_height : I64 -> F64
dropped_height = |since_landing|
	if since_landing < 0 {
		left = Ease.ramp(0 - since_landing, drop_frames)
		drop_from * left * left
	} else {
		0.18 * (F64.pi * Ease.ramp(since_landing, 12)).sin()
	}

boombox_land_tick : I64
boombox_land_tick = Script.chairs_tick + 14

chair_land_tick : I64 -> I64
chair_land_tick = |k| Script.chairs_tick + 24 + 7 * k

# The music's beat: half a second, the march's.
beat_frames : I64
beat_frames = 15

beat_thump : I64 -> F64
beat_thump = |now| {
	into = (now - MusicalChairs.music_start_tick) % beat_frames
	1.0 - into.to_f64() / beat_frames.to_f64()
}

note_gap : I64
note_gap = 15

note_life : I64
note_life = 70

# Note `n`, born on the `n`th beat, at `now`, or nothing when it has not
# popped out yet, or has faded or landed.
note : U64, I64 -> Try(MusicalChairs.Note, [Gone])
note = |n, now| {
	born = MusicalChairs.music_start_tick + note_gap * n.to_i64_wrap()
	risen = (now.min(MusicalChairs.music_stop_tick) - born).to_f64()
	sway = 0.15 * (risen * 0.12 + n.to_f64()).sin()
	at_stop = {
		right: boombox_spot.right + sway,
		forward: boombox_spot.forward + 0.3 + 0.012 * risen,
		height: 0.55 + 0.022 * risen,
	}
	fallen = (now - MusicalChairs.music_stop_tick).max(0).to_f64()
	at = { ..at_stop, height: at_stop.height - 0.004 * fallen * fallen }
	age = now - born
	if age < 0 or age > note_life or at.height < 0.0 {
		Err(Gone)
	} else {
		Ok({ at, color: n % 3, fade: Ease.ramp(age - note_life + 20, 20) })
	}
}

# The way round the chairs: a straight up the side nearer the eye, round
# the far end, back down the other side and round the near end, `track`
# metres from the row. Before the start of the way round is the way in,
# along the near side from far off to the left.
track : F64
track = 0.85

straight : F64
straight = 2.4

lap : F64
lap = 2.0 * straight + F64.tau / 2.0 * track

# Where on the way round a robot is, `walked` metres along it.
on_track : F64 -> { right : F64, forward : F64 }
on_track = |walked|
	if walked < 0.0 {
		{ right: row.right + track, forward: row.forward - straight / 2.0 + walked }
	} else {
		into = walked - lap * (walked / lap).to_i64_wrap().to_f64()
		end = F64.pi * track
		if into < straight {
			{ right: row.right + track, forward: row.forward - straight / 2.0 + into }
		} else if into < straight + end {
			turned = (into - straight) / track
			{
				right: row.right + track * turned.cos(),
				forward: row.forward + straight / 2.0 + track * turned.sin(),
			}
		} else if into < 2.0 * straight + end {
			{ right: row.right - track, forward: row.forward + straight / 2.0 - (into - straight - end) }
		} else {
			turned = (into - 2.0 * straight - end) / track
			{
				right: row.right - track * turned.cos(),
				forward: row.forward - straight / 2.0 - track * turned.sin(),
			}
		}
	}

# How fast the line goes round, and how far off the first in it starts.
pace : F64
pace = 0.075

way_in : F64
way_in = 3.6

# The robots in the line, in order, and the drum major's place, last; each
# a fifth of the way round behind the one in front.
builds : List(Robot.Build)
builds = [Tall, Round, Tiny, Round]

drum_major_place : U64
drum_major_place = 4

# Where the robot in place `place` in the line is at `now`, walking until
# the music stops and frozen mid-step from then on.
circling : U64, I64 -> { feet : Eye.At, stride : F64, phase : F64 }
circling = |place, now| {
	walked = pace * (now.min(MusicalChairs.music_stop_tick) - MusicalChairs.music_start_tick).to_f64() - way_in - lap / 5.0 * place.to_f64()
	spot = on_track(walked)
	{
		feet: { right: spot.right, forward: spot.forward, height: 0.0 },
		stride: 1.0,
		phase: walked * F64.tau / 0.9,
	}
}

# A robot's dive: its place in the line, where it froze, and the chair it
# ends up in.
Seating : {
	build : Robot.Build,
	place : U64,
	frozen : Eye.At,
	chair : Table.Chair,
}

# Each robot dives for the chair nearest it along the row: the robots by
# where they froze, down the row, take the chairs in the same order.
seatings : List(Seating)
seatings = {
	froze = List.map2(
		builds,
		[0, 1, 2, 3],
		|build, place| { build, place, frozen: circling(place, MusicalChairs.music_stop_tick).feet },
	)
	in_order = froze.sort_with(
		|a, b|
			if a.frozen.forward < b.frozen.forward {
				Before
			} else if a.frozen.forward > b.frozen.forward {
				After
			} else {
				Same
			},
	)
	List.map2(
		in_order,
		chairs,
		|robot, chair| {
			build: robot.build,
			place: robot.place,
			frozen: robot.frozen,
			chair,
		},
	)
}

dive_frames : I64
dive_frames = 16

player : Seating, I64 -> MusicalChairs.Player
player = |seating, now| {
	walk = circling(seating.place, now)
	dive = Ease.ramp(now - MusicalChairs.scramble_tick, dive_frames)
	moved = Ease.whip(dive)
	seat = { right: seating.chair.right + 0.05, forward: seating.chair.forward }
	seated_hips = seating.chair.seat_height + 0.03 - Robot.proportions(seating.build).hip
	# Once the drum major is left standing, every robot sat looks at it.
	stare = Ease.smooth(Ease.ramp(now - MusicalChairs.left_standing_tick, 12))
	look = 0.9 * stare * (MusicalChairs.stand_spot.forward - seating.chair.forward).max(-1.0).min(1.0)
	feet =
		if dive <= 0.0 {
			walk.feet
		} else {
			{
				right: seating.frozen.right + (seat.right - seating.frozen.right) * moved,
				forward: seating.frozen.forward + (seat.forward - seating.frozen.forward) * moved,
				height: 0.5 * (F64.pi * dive).sin(),
			}
		}
	{
		build: seating.build,
		feet,
		pose: {
			phase: walk.phase + 9.0 * dive,
			stride: walk.stride * (1.0 - Ease.ramp(now - MusicalChairs.scramble_tick - dive_frames, 4)),
			reach: 0.0,
			eye_glow: 1.0,
			look,
		},
		hips_up: seated_hips * Ease.smooth(dive),
	}
}
