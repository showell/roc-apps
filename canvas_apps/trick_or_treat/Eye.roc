## Eye is the child's eye in the Halloween walk: where a thing in the world
## lands on the screen. Safari has a camera of its own with its screen and its
## rider's eye fixed; this one takes the screen's size and the eye's height as
## parameters, so the walk is seen from a child's height.
##
## The world is three numbers, all in metres and taken from where the eye is:
## `right` across, `forward` away and `height` up from the ground. The screen
## is pixels. `focal` turns one into the other: it is the pixels a metre
## subtends a metre away, so a bigger focal is a longer lens and a narrower
## view.
##
## The eye can turn. `heading` is which way it faces, in radians, right from
## straight down the world's forward axis. A quarter turn puts half the world
## behind the eye, where dividing by `forward` says nothing useful, so a
## polygon is cut against the near plane on its way to the screen, and a point
## is sighted only when it is in front.
import lib.Point

Eye :: [].{
	Eye : { width : F64, height : F64, eye_height : F64, focal : F64, heading : F64 }

	## A place on the screen in plain pixels, for the walk's own arithmetic.
	OnScreen : { x : F64, y : F64 }

	At : { right : F64, forward : F64, height : F64 }

	## Nothing nearer than this is drawn: at the eye it would be infinite.
	near : F64
	near = 0.35

	## A point on the screen.
	project : Eye.Eye, Eye.At -> Eye.OnScreen
	project = |eye, at| flat(eye, turn(eye, at))

	## A point on the screen, with how many pixels a metre is at its distance,
	## or `BehindEye` when it is not in front of the eye. Anything drawn as a
	## disc or a line is sighted this way, because only a polygon can be cut.
	sighting : Eye.Eye, Eye.At -> Try({ point : Eye.OnScreen, pixels_per_metre : F64 }, [BehindEye])
	sighting = |eye, at| {
		turned_at = turn(eye, at)
		if turned_at.forward > near {
			Ok({ point: flat(eye, turned_at), pixels_per_metre: eye.focal / turned_at.forward })
		} else {
			Err(BehindEye)
		}
	}

	## A polygon of world points as corners on the screen: turned, cut to what
	## is in front of the eye, and projected. Empty when none of it is.
	screen_corners : Eye.Eye, List(Eye.At) -> List(Point.Point)
	screen_corners = |eye, points|
		clipped(turned(eye, points)).map(
			|point| {
				spot = flat(eye, point)
				Point.at(spot.x, spot.y)
			},
		)
}

# The point as this eye has it: the world turned the other way by the heading,
# so `forward` means "in front of this eye" rather than "up the path".
turn : Eye.Eye, Eye.At -> Eye.At
turn = |eye, p| {
	c = eye.heading.cos()
	s = eye.heading.sin()
	{ right: p.right * c - p.forward * s, forward: p.right * s + p.forward * c, height: p.height }
}

# A point the eye has already turned, on the screen.
flat : Eye.Eye, Eye.At -> Eye.OnScreen
flat = |eye, p| {
	x: eye.width / 2.0 + p.right / p.forward * eye.focal,
	y: eye.height / 2.0 - (p.height - eye.eye_height) / p.forward * eye.focal,
}

turned : Eye.Eye, List(Eye.At) -> List(Eye.At)
turned = |eye, points| points.map(|p| turn(eye, p))

# A polygon is cut rather than dropped. Dropping one the moment a corner goes
# behind the eye would pop a whole house off the screen while most of it is
# still in the frame, so this walks the boundary and puts a new corner on the
# near plane wherever an edge crosses it.
clipped : List(Eye.At) -> List(Eye.At)
clipped = |points| {
	neighbours = points.drop_first(1).concat(points.take_first(1))
	var $out = List.with_capacity(points.len() + 2)
	for (a, b) in points.map2(neighbours, |a, b| (a, b)) {
		a_in = a.forward > Eye.near
		b_in = b.forward > Eye.near
		if a_in {
			$out = $out.append(a)
		}
		if a_in != b_in {
			$out = $out.append(crossing(a, b))
		}
	}
	$out
}

# Where the edge from a to b meets the near plane. It is asked only of an edge
# with one end on each side of the plane, so the two ends' distances differ.
crossing : Eye.At, Eye.At -> Eye.At
crossing = |a, b| {
	t = (Eye.near - a.forward) / (b.forward - a.forward)
	{ right: a.right + (b.right - a.right) * t, forward: Eye.near, height: a.height + (b.height - a.height) * t }
}
