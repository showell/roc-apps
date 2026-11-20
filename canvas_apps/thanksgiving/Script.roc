## Script is the Thanksgiving movie's running order: the tick each beat
## starts at, sixty ticks a second. Dinner, EyePath, Copies and March ask it
## when things happen, and nothing else knows what time it is.
##
## The guests arrive and sit, the lights blink on and the eye eases back to
## take in the table. The banner drops, the leaves blow, and a fourth robot
## walks in and starts the robot dance. The eye moves in close, and the
## dancer winks at it. Then the eye backs far away over an empty lawn, and
## at each of the dancer's shoulder pops a copy of the whole table springs
## up, until there are five. An army of robots marches in from behind the
## eye, bringing more food, a drum major in front; it halts, a straggler
## rolls up late, and the dancers strike their final pose.
##
## From the dance on, the beats are the routine's own sections, so the
## camera and the copies stay on the dance's beat when the routine changes.
import Routine

Script :: [].{

	## When the first bulb blinks on.
	lights_tick : I64
	lights_tick = 800

	## When the eye starts to ease back from the guest's seat.
	pull_tick : I64
	pull_tick = 880

	## When the banner starts to drop, and the leaves start to blow.
	banner_tick : I64
	banner_tick = 1020

	gust_tick : I64
	gust_tick = 1060

	## When the dancer starts walking in, and when the seated robots turn
	## their eyes to watch it.
	walk_in_tick : I64
	walk_in_tick = 1090

	watch_tick : I64
	watch_tick = 1110

	## When the routine starts.
	dance_tick : I64
	dance_tick = 1236

	## When a section of the routine starts.
	section_tick : Routine.Section -> I64
	section_tick = |section| dance_tick + Routine.section_start(section)

	## The eye moves in on the dancer as the routine opens.
	close_up_tick : I64
	close_up_tick = section_tick(Opening)

	## The dancer winks at the eye, close up.
	wink_tick : I64
	wink_tick = section_tick(Hello) + Routine.wink_offset

	## The eye backs away to the wide shot while the dancer travels through
	## its middle section, arriving as the copies begin.
	wide_tick : I64
	wide_tick = section_tick(Travel)

	## The ticks at which each copied table pops up, one a shoulder pop.
	copy_ticks : List(I64)
	copy_ticks = Routine.pop_offsets.map(|offset| section_tick(Multiply) + offset)

	## The army steps out from behind the eye as the dancers start to strut,
	## and halts `march_frames` later.
	army_tick : I64
	army_tick = section_tick(Strut)

	march_frames : I64
	march_frames = 330

	halt_tick : I64
	halt_tick = army_tick + march_frames

	## When the dancers strike the final pose.
	finale_tick : I64
	finale_tick = section_tick(Finale)

	## The last tick that moves. Every tick after it shows the same frame.
	end_tick : I64
	end_tick = dance_tick + Routine.length

	## The tick the movie shows at `tick`, which holds at the end.
	held_tick : I64 -> I64
	held_tick = |tick|
		if tick < 0 {
			0
		} else if tick > end_tick {
			end_tick
		} else {
			tick
		}
}

# The movie holds after its end, and not before it.
expect Script.held_tick(Script.end_tick + 600) == Script.end_tick
expect Script.held_tick(Script.end_tick - 1) == Script.end_tick - 1
expect Script.held_tick(-5) == 0

# The army halts before the finale, and every copy is up before it marches.
expect Script.halt_tick < Script.finale_tick
expect Script.copy_ticks.all(|tick| tick + 20 <= Script.army_tick)
