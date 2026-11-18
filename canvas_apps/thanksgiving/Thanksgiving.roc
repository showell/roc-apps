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
		guests = [Tall, Round, Tiny]
		var $out = Backyard.backyard_shapes(view)
		$out = $out.concat(Lights.post_shapes(view))
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
		$out = $out.concat(Lights.strand_shapes(view, Dinner.bulb_glows(tick)))
		$out = $out.concat(Banner.banner_shapes(Dinner.banner_drop(tick), { width: width }))
		$out.concat(Leaves.leaf_shapes(Dinner.gust_seconds(tick), { width: width }))
	}
}

focal : F64
focal = 380.0

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
