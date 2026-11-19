## Math is the geometry roc-ray's own Math module offers, under the same name.
## As with Keys and Random, a game that starts from an example says
## `import lib.Math` instead of `import rr.Math`, and every `Math.` in its rules
## is left alone. Only what the games here ask for is written, and roc-ray's
## is larger.
##
## Pixels, in F32, because that is what the examples are written in.

Math :: [].{
	Vec2 : { x : F32, y : F32 }
	Rect : {
		x : F32,
		y : F32,
		width : F32,
		height : F32,
	}
	Circle : { center : Math.Vec2, radius : F32 }

	zero : Math.Vec2
	zero = { x: 0, y: 0 }

	rect : F32, F32, F32, F32 -> Math.Rect
	rect = |x, y, width, height| { x, y, width, height }

	circle : Math.Vec2, F32 -> Math.Circle
	circle = |center, radius| { center, radius }

	## The sum of two vectors.
	add : Math.Vec2, Math.Vec2 -> Math.Vec2
	add = |first, second| { x: first.x + second.x, y: first.y + second.y }

	## `vector` stretched by `factor` on both axes.
	scale : Math.Vec2, F32 -> Math.Vec2
	scale = |vector, factor| { x: vector.x * factor, y: vector.y * factor }

	left : Math.Rect -> F32
	left = |rectangle| rectangle.x

	right : Math.Rect -> F32
	right = |rectangle| rectangle.x + rectangle.width

	top : Math.Rect -> F32
	top = |rectangle| rectangle.y

	bottom : Math.Rect -> F32
	bottom = |rectangle| rectangle.y + rectangle.height

	center : Math.Rect -> Math.Vec2
	center = |rectangle| { x: rectangle.x + rectangle.width / 2, y: rectangle.y + rectangle.height / 2 }

	## Whether a rectangle contains a point, including its edges.
	contains : Math.Rect, Math.Vec2 -> Bool
	contains = |rectangle, point|
		point.x >= left(rectangle) and point.x <= right(rectangle) and point.y >= top(rectangle) and point.y <= bottom(rectangle)

	clamp : F32, F32, F32 -> F32
	clamp = |value, low, high|
		if value < low {
			low
		} else if value > high {
			high
		} else {
			value
		}

	distance_squared : Math.Vec2, Math.Vec2 -> F32
	distance_squared = |first, second| {
		dx = first.x - second.x
		dy = first.y - second.y
		dx * dx + dy * dy
	}

	## Whether a circle touches a rectangle: the closest point on the box to
	## the centre, and whether that is within the radius.
	circle_rect : Math.Circle, Math.Rect -> Bool
	circle_rect = |circle_shape, rectangle| {
		near_x = clamp(circle_shape.center.x, left(rectangle), right(rectangle))
		near_y = clamp(circle_shape.center.y, top(rectangle), bottom(rectangle))
		distance_squared(circle_shape.center, { x: near_x, y: near_y }) <= circle_shape.radius * circle_shape.radius
	}
}
