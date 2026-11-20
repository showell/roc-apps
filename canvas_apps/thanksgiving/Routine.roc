## Routine is the robot dance in time: Choreography's sections one after
## another, and the move danced any number of ticks in. A move snaps into
## place over its first few ticks and holds for the rest, so the dance goes
## in clicks rather than easing. Every dancer at every table dances it in
## step. Script says when it starts, and times the eye, the floats, the army
## and the crowd to its sections.
import Choreography
import Moves

Routine :: [].{

	## The routine's sections, in the order they are danced.
	Section : [Opening, Hello, Travel, Parade, Strut, Peek, Flood, Wave, Finale]

	## The move `since` ticks into the routine, and the last move after it
	## ends.
	move_at : I64 -> Moves.Move
	move_at = |since| {
		var $before = Moves.rest
		var $start = 0
		var $found = False
		var $move = Moves.rest
		for step in all_steps {
			if !$found and since < $start + step.frames {
				$move = Moves.mixed_move({
					from: $before,
					to: step.move,
					fraction: snap(since - $start + 1),
				})
				$found = True
			}
			$before = step.move
			$start = $start + step.frames
		}
		if $found {
			$move
		} else {
			$before
		}
	}

	## How many ticks into the routine a section starts.
	section_start : Routine.Section -> I64
	section_start = |wanted| {
		var $start = 0
		var $done = False
		for section in sections_in_order {
			if section == wanted {
				$done = True
			}
			if !$done {
				$start = $start + Choreography.ticks_of(steps_of(section))
			}
		}
		$start
	}

	## How long the whole routine is, in ticks.
	length : I64
	length = Choreography.ticks_of(all_steps)
}

sections_in_order : List(Routine.Section)
sections_in_order = [Opening, Hello, Travel, Parade, Strut, Peek, Flood, Wave, Finale]

steps_of : Routine.Section -> List(Choreography.Step)
steps_of = |section|
	match section {
		Opening => Choreography.opening_steps
		Hello => Choreography.hello_steps
		Travel => Choreography.travel_steps
		Parade => Choreography.parade_steps
		Strut => Choreography.strut_steps
		Peek => Choreography.peek_steps
		Flood => Choreography.flood_steps
		Wave => Choreography.wave_steps
		Finale => Choreography.finale_steps
	}

all_steps : List(Choreography.Step)
all_steps = sections_in_order.map(steps_of).join()

snap_frames : I64
snap_frames = 3

snap : I64 -> F64
snap = |since|
	if since <= 0 {
		0.0
	} else if since >= snap_frames {
		1.0
	} else {
		since.to_f64() / snap_frames.to_f64()
	}

# The sections follow one another, and the routine is their sum.
expect Routine.section_start(Opening) == 0
expect Routine.section_start(Hello) == 80
expect Routine.section_start(Finale) + Choreography.ticks_of(Choreography.finale_steps) == Routine.length

# The wink lands on the winking move, and the routine ends on the final pose.
expect Routine.move_at(Routine.section_start(Hello) + Choreography.wink_offset + 5).wink == 1.0
expect Routine.move_at(Routine.section_start(Finale) + Choreography.final_wink_offset + 5).wink == 1.0
expect Routine.move_at(Routine.length + 100) == Moves.final_pose
