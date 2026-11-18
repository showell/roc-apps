## Thanksgiving is the cut: the order the backyard's things are painted in,
## back to front, at one tick. Dinner says where everything is and how it
## stands; Backyard, Table, Robot, Dishes, Lights, Banner and Leaves each draw
## one thing from the numbers they are handed.
##
## The robots are painted farthest first, each with its chair and whatever it
## carries, and the table goes over them, because from a seated guest's eye
## the near end of the table hides their feet. A dish set down goes on the
## cloth, so it is painted after the table.
import lib.Shapes
import Backyard
import Banner
import Dancer
import Dinner
import Dishes
import Leaves
import Lights
import Robot
import Table
import View

Thanksgiving :: [].{
	width : F64
	width = 640.0

	height : F64
	height = 480.0

	## The movie's own state is the tick: every frame is a function of it,
	## which is what lets it be scrubbed.
	Model : { tick : I64 }

	## The guest's eye, wherever Dinner has it. A wide lens, so a guest at the
	## end of the table sees its whole length.
	view_at : I64 -> View
	view_at = |tick| {
		spot = Dinner.eye_spot(tick)
		View.standing(
			{
				width,
				height,
				eye_height: spot.height,
				focal: focal,
				heading: 0.0,
			},
			{ right: spot.right, forward: spot.forward },
		)
	}

	shapes : Thanksgiving.Model -> List(Shapes.Shape)
	shapes = |{ tick }| {
		view = view_at(tick)
		var $out = Backyard.backyard_shapes(view)
		for offset in tables {
			$out = $out.concat(party_shapes(view.shifted(offset), tick))
		}
		$out = $out.concat(Banner.banner_shapes(Dinner.banner_drop(tick), { width: width }))
		$out.concat(Leaves.leaf_shapes(Dinner.gust_seconds(tick), { width: width }))
	}
}

focal : F64
focal = 380.0

# Five identical tables, farthest first. The first is the one the guest sits
# at; the other four stand nearer the eye than it ever comes until the
# reveal, so they are behind it, and out of sight, until it backs away.
tables : List({ right : F64, forward : F64 })
tables = [
	{ right: 0.0, forward: 0.0 },
	{ right: -2.75, forward: -8.5 },
	{ right: 2.75, forward: -8.5 },
	{ right: -5.5, forward: -17.0 },
	{ right: 5.5, forward: -17.0 },
]

# One table's whole party at one tick, back to front, through a view moved to
# that table. Every table is the same scene, so they move in step.
party_shapes : View, I64 -> List(Shapes.Shape)
party_shapes = |view, tick| {
	guests = [Tall, Round, Tiny]
	var $out = Lights.post_shapes(view)
	$out = $out.concat(Table.shadow_shapes(view))
	for build in guests {
		$out = $out.concat(Table.chair_shapes(view, build))
		$out = $out.concat(robot_shapes(view, { build, tick }))
		$out = $out.concat(dish_shapes(view, { build, tick, layer: Carried }))
	}
	$out = $out.concat(Table.top_shapes(view))
	for build in guests {
		$out = $out.concat(dish_shapes(view, { build, tick, layer: OnTable }))
	}
	$out = $out.concat(dancer_shapes(view, tick))
	$out.concat(Lights.strand_shapes(view, Dinner.bulb_glows(tick)))
}

robot_shapes : View, { build : Robot.Build, tick : I64 } -> List(Shapes.Shape)
robot_shapes = |view, { build, tick }|
	match view.sighting(Dinner.robot_feet(build, tick)) {
		Ok({ point, pixels_per_metre }) =>
			Robot.figure_shapes({
				build,
				pose: Dinner.robot_pose(build, tick),
				feet: point,
				pixels_per_metre,
			})
		Err(BehindEye) => []
	}

# The dancer stands beside the near end of the table, nearer than anything
# on it, so it is painted after the table and its dishes.
dancer_shapes : View, I64 -> List(Shapes.Shape)
dancer_shapes = |view, tick|
	match view.sighting(Dinner.dancer_feet(tick)) {
		Ok({ point, pixels_per_metre }) => Dancer.figure_shapes({ pose: Dinner.dancer_pose(tick), feet: point, pixels_per_metre })
		Err(BehindEye) => []
	}

# A robot's dish, when it is in the layer being painted.
dish_shapes : View,
{
	build : Robot.Build,
	tick : I64,
	layer : [Carried, OnTable],
} -> List(Shapes.Shape)
dish_shapes = |view, { build, tick, layer }| {
	place = Dinner.dish_place(build, tick)
	if place.layer != layer {
		[]
	} else {
		match view.sighting(place.at) {
			Ok({ point, pixels_per_metre }) => Dishes.dish_shapes(
				Dinner.dish_of(build),
				{ base: point, pixels_per_metre, tilt: place.tilt },
			)
			Err(BehindEye) => []
		}
	}
}

# The last frame is the frame after the end too: the movie holds.
expect {
	last = Thanksgiving.shapes({ tick: Dinner.end_tick })
	last == Thanksgiving.shapes({ tick: Dinner.end_tick + 600 })
}

# And it is still moving just before the end, as the last leaf blows off.
expect {
	last = Thanksgiving.shapes({ tick: Dinner.end_tick })
	last != Thanksgiving.shapes({ tick: Dinner.end_tick - 120 })
}
