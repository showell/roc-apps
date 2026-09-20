# Math -- the geometry roc-ray's own Math module offers, under the same name.
#
# Hand-written, and the same trick as Keys and Random: a game ported from an
# example says `import lib.Math` instead of `import rr.Math` and every `Math.`
# in its rules is left alone. Only what the games here actually ask for is
# implemented; roc-ray's is larger.
#
# Pixels, in F32, because that is what the examples are written in.

Math :: [].{
	Vec2 : { x : F32, y : F32 }
	Rect : { x : F32, y : F32, width : F32, height : F32 }
	Circle : { center : Math.Vec2, radius : F32 }

	zero : Math.Vec2
	zero = { x: 0, y: 0 }

	rect : F32, F32, F32, F32 -> Math.Rect
	rect = |x, y, width, height| { x, y, width, height }

	circle : Math.Vec2, F32 -> Math.Circle
	circle = |center, radius| { center, radius }

	left : Math.Rect -> F32
	left = |r| r.x

	right : Math.Rect -> F32
	right = |r| r.x + r.width

	top : Math.Rect -> F32
	top = |r| r.y

	bottom : Math.Rect -> F32
	bottom = |r| r.y + r.height

	center : Math.Rect -> Math.Vec2
	center = |r| { x: r.x + r.width / 2, y: r.y + r.height / 2 }

	clamp : F32, F32, F32 -> F32
	clamp = |v, lo, hi| if v < lo { lo } else if v > hi { hi } else { v }

	distance_squared : Math.Vec2, Math.Vec2 -> F32
	distance_squared = |a, b| {
		dx = a.x - b.x
		dy = a.y - b.y
		dx * dx + dy * dy
	}

	## Whether a circle touches a rectangle: the closest point on the box to
	## the centre, and whether that is within the radius.
	circle_rect : Math.Circle, Math.Rect -> Bool
	circle_rect = |c, r| {
		near_x = clamp(c.center.x, left(r), right(r))
		near_y = clamp(c.center.y, top(r), bottom(r))
		distance_squared(c.center, { x: near_x, y: near_y }) <= c.radius * c.radius
	}
}
