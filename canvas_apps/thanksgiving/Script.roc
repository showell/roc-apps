## Script is the Thanksgiving movie's running order: the tick each beat
## starts at, sixty ticks a second. Every timeline module asks it when
## things happen, and nothing else knows what time it is.
##
## The guests arrive and sit, the first while the eye moves in to watch it
## sit down; the pie slips and the eye whips in to watch
## the catch. The lights blink on, the eye eases back, the leaves blow, and
## a fourth robot walks in and starts the robot dance. The eye snaps in
## close, and the dancer winks at it while the yard stretches away behind.
## The eye flies far back, tipping, and four copies of the whole table roll
## in on parade floats, each pushed by a robot and each faster than the
## last. An army marches in at the double from under the eye, a drum major
## in front, and halts with a drumstick tossed and caught. Heads pop up over
## the fence until the whole row jumps at once; then robots pour in from
## both sides by the hundred, the eye does a barrel roll, and the whole
## crowd does the wave. The dancers strike their final pose, one winks
## again, and the banner drops.
##
## Something new happens every few seconds: there is no waiting about.
##
## From the dance on, the beats are the routine's own sections, so
## everything stays on the dance's beat when the routine changes.
import Choreography
import Routine

Script :: [].{

	## When the tall robot, the first to sit, starts down onto its seat.
	## Dinner's plan for it lands here, which its test holds.
	first_sit_tick : I64
	first_sit_tick = 260

	## When the first bulb blinks on.
	lights_tick : I64
	lights_tick = 850

	## When the eye starts to ease back from the guest's seat.
	pull_tick : I64
	pull_tick = 910

	## When the leaves start to blow.
	gust_tick : I64
	gust_tick = 960

	## When the dancer starts walking in, and when the seated robots turn
	## their eyes to watch it.
	walk_in_tick : I64
	walk_in_tick = 990

	watch_tick : I64
	watch_tick = 1010

	## When the routine starts.
	dance_tick : I64
	dance_tick = 1120

	## When a section of the routine starts.
	section_tick : Routine.Section -> I64
	section_tick = |section| dance_tick + Routine.section_start(section)

	## The eye moves in on the dancer as the routine opens.
	close_up_tick : I64
	close_up_tick = section_tick(Opening)

	## The dancer winks at the eye, close up.
	wink_tick : I64
	wink_tick = section_tick(Hello) + Choreography.wink_offset

	## The eye flies back to the wide shot while the dancer travels through
	## its middle section, arriving as the floats set off.
	wide_tick : I64
	wide_tick = section_tick(Travel)

	parade_tick : I64
	parade_tick = section_tick(Parade)

	## The ticks at which each float brakes to a stop, one a shoulder pop.
	float_stop_ticks : List(I64)
	float_stop_ticks = Choreography.pop_offsets.map(|offset| parade_tick + offset)

	## The army steps out from under the eye as the dancers start to strut,
	## and halts `march_frames` later.
	army_tick : I64
	army_tick = section_tick(Strut)

	march_frames : I64
	march_frames = 240

	halt_tick : I64
	halt_tick = army_tick + march_frames

	## Heads start popping up over the fence.
	peek_tick : I64
	peek_tick = section_tick(Peek)

	## The crowd starts pouring in from both sides.
	flood_tick : I64
	flood_tick = section_tick(Flood)

	## The eye does a barrel roll as the last of the crowd runs in.
	spin_tick : I64
	spin_tick = flood_tick + 170

	## The ticks at which the wave passes the middle of the yard, once each
	## way.
	wave_ticks : List(I64)
	wave_ticks = Choreography.wave_offsets.map(|offset| section_tick(Wave) + offset)

	## When the dancers strike the final pose, and when one winks again.
	finale_tick : I64
	finale_tick = section_tick(Finale)

	final_wink_tick : I64
	final_wink_tick = finale_tick + Choreography.final_wink_offset

	## The banner drops once the eye has backed away from the last wink.
	banner_tick : I64
	banner_tick = final_wink_tick + 50

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

# The army halts before heads pop up, and every float has stopped before the
# army marches.
expect Script.halt_tick < Script.peek_tick
expect Script.float_stop_ticks.all(|tick| tick + 20 <= Script.army_tick)

# The banner is the last thing to happen, a few seconds before the end, and
# the movie runs under a minute.
expect Script.banner_tick + 180 < Script.end_tick
expect Script.end_tick < 60 * 60
