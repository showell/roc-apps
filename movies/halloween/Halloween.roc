# Halloween -- up the path, and back down it rather faster.
#
# **THE FIRST MOVIE HERE WITH A WORLD IN IT.** capture_plot and particles draw
# in screen coordinates; the skeletons used to dance on a flat black rectangle.
# This one puts things in metres -- right, forward, height -- and asks View
# where they land, so walking is one number changing and everything else
# follows: the house grows, the path widens, the skeletons pass by.
#
# The eye is a metre off the ground, which is a small child's. That is the same
# trick Safari plays with its rider: the whole scene is told from a height, and
# the height is the character.
#
# **THIS FILE IS THE CUT, NOT THE SCENE.** Walk says where the child is and
# what time it is; Night, Fence, Streetlight, House, Witch and Guards each draw
# one thing and are told a number rather than a tick. What is left here is the
# movie itself and the order the things are painted in, which is back to front.
import Movie
import Shapes
import View
import Walk
import Night
import Fence
import Streetlight
import House
import Witch
import Guards
import Trig

Halloween :: [].{
	width : F64
	width = 640.0
	height : F64
	height = 480.0

	# A wide-ish lens: a child looking up at a house sees a lot of it, and a
	# long lens put the roof above the frame long before the doorstep.
	focal : F64
	focal = 380.0

	house_at : F64
	house_at = 12.5

	Model : { tick : I64 }

	movie : Movie.Movie(Halloween.Model)
	movie = {
		size: { width: width, height: height },
		fps: 60,
		init: { tick: 0 },
		advance: |m| { tick: m.tick + 1 },
		# Every frame is a function of the tick, so back is a step the other
		# way and costs nothing to remember.
		back: |m| { tick: if m.tick > 0 { m.tick - 1 } else { 0 } },
		skip: |m| { tick: m.tick + 60 },
		frame: |m| shapes(m),
		roll: |_m| 0.0,
		clock: |m| I64.to_f64(m.tick),
		title: "Trick or Treat",
		stem: "halloween",
	}

	# The eye, wherever the walk has it and whichever way the walk has it
	# facing.
	view_of : I64 -> View.View
	view_of = |tick| { width: width, height: height, eye: Walk.eye(tick), focal: focal, heading: Walk.heading(tick) }

	shapes : Halloween.Model -> List(Shapes.Shape)
	shapes = |m| {
		tick = m.tick
		now = Walk.here(tick)
		v = view_of(tick)
		hf = house_at - now

		var $out = Night.backdrop(v)
		$out = List.concat($out, Night.street(v, now))
		$out = List.concat($out, Fence.shapes(v, now))
		$out = List.concat($out, Streetlight.shapes(v, 0.0 - 1.1 - now))
		$out = if hf > View.near { List.concat($out, House.shapes(v, hf, Walk.door_open(tick))) } else { $out }
		$out = List.concat($out, Witch.shapes(v, hf, Walk.witch_in(tick)))
		$out = List.concat($out, Night.path(v, now, house_at))
		tilt = (1.0 - Walk.attend(tick)) * Trig.pi / 4.0
		List.concat($out, Guards.shapes(v, tick, now, Walk.here(tick - Guards.lag_frames), tilt))
	}
}
