## A plan view is a picture that looks straight down on the road, as several of
## the book's widgets do. This module holds the one mapping those pictures all
## draw through: a point of the plan, in metres right of and below a chosen
## place, lands on the canvas at so many pixels a metre from that place. Each
## widget chooses its own place and which way its road runs. Their colors are
## WidgetPalette's `plan_*` ones.
import lib.Point

PlanView := {
	## Where the plan's chosen place lands on the canvas.
	origin : Point.Point,

	## How many canvas pixels a metre of the plan takes up, either way.
	pixels_a_metre : F64,
}.{

	## Where a point `metres_right` right of the plan's chosen place and
	## `metres_down` below it lands on the canvas. Either can be negative.
	canvas_point : PlanView, { metres_right : F64, metres_down : F64 } -> Point.Point
	canvas_point = |plan, { metres_right, metres_down }| {
		x: plan.origin.x + metres_right * plan.pixels_a_metre,
		y: plan.origin.y + metres_down * plan.pixels_a_metre,
	}
}

## A plan of two pixels a metre, its chosen place at (10, 20).
sample_plan : PlanView
sample_plan = { origin: { x: 10.0, y: 20.0 }, pixels_a_metre: 2.0 }

# A metre right or down is the scale's pixels from the chosen place, either way.
expect sample_plan.canvas_point({ metres_right: 0.0, metres_down: 0.0 }) == { x: 10.0, y: 20.0 }
expect sample_plan.canvas_point({ metres_right: 3.0, metres_down: -4.0 }) == { x: 16.0, y: 12.0 }
expect sample_plan.canvas_point({ metres_right: -5.0, metres_down: 1.0 }) == { x: 0.0, y: 22.0 }
