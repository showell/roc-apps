## Thanksgiving is the cut: the order the backyard's things are painted in,
## back to front, at one tick. Script says when each beat is; EyePath and Lens
## say where the eye is and how it is zoomed; Dinner, Copies, March and Crowd
## say where everything is and how it stands; Backyard, Table, Robot, Dancer,
## Dishes, Lights, ParadeFloat, Speck, Army, Banner and Leaves each draw one
## thing from the numbers they are handed.
##
## Behind the fence come the robots jumping to see over it. At a table, the
## robots are painted farthest first, each with its chair and whatever it
## carries, and the table goes over them, because from a seated guest's eye
## the near end of the table hides their feet. A dish set down goes on the
## cloth, so it is painted after the table. The crowd's blocks stand in rows
## across the yard, so each table is painted among the rows at its depth.
## Every table stands farther from the eye than the army ever is, so the army
## goes over all of them.
import lib.Point
import lib.Shapes
import Army
import Backyard
import Banner
import Copies
import Crowd
import Dancer
import Dinner
import Dishes
import EyePath
import Leaves
import Lens
import Lights
import ParadeFloat
import Robot
import Script
import Seating
import SideBody
import Speck
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

	## The guest's eye, wherever EyePath has it and zoomed as Lens says.
	view_at : I64 -> View
	view_at = |tick| {
		spot = EyePath.eye_spot(tick)
		View.standing(
			{
				width,
				height,
				eye_height: spot.height,
				focal: Lens.setting_at(tick).focal,
				heading: spot.heading,
			},
			{ right: spot.right, forward: spot.forward },
		)
	}

	## The frame at one tick: the backyard and everything in it, tipped as
	## the lens is rolled, then the leaves and the banner over it, untipped.
	shapes : Thanksgiving.Model -> List(Shapes.Shape)
	shapes = |{ tick }| {
		view = view_at(tick)
		scene = [
			Backyard.beyond_fence_shapes(view),
			Crowd.fence_members_at(tick).map(|member| Speck.member_shapes(view, member)).join(),
			Backyard.fence_shapes(view),
			yard_shapes(view, tick),
			Army.army_shapes(view, tick),
		].join()
		[
			rolled_shapes(scene, Lens.setting_at(tick).roll),
			Leaves.leaf_shapes(Dinner.gust_seconds(tick), { width: width }),
			Banner.banner_shapes(Dinner.banner_drop(tick), { width: width }),
		].join()
	}
}

# The scene turned `roll` radians about the middle of the screen, and grown
# just enough that its corners stay off the screen as it turns.
rolled_shapes : List(Shapes.Shape), F64 -> List(Shapes.Shape)
rolled_shapes = |scene, roll| {
	middle = Point.at(Thanksgiving.width / 2.0, Thanksgiving.height / 2.0)
	cover = roll.cos().abs() + roll.sin().abs() * Thanksgiving.width / Thanksgiving.height
	space = Shapes.world_space({
		target: middle,
		offset: middle,
		rotation: roll * 180.0 / F64.pi,
		zoom: cover,
	})
	Shapes.shapes_in_space(space, scene)
}

# The tables and the two blocks of the crowd, farthest first. The crowd is
# already in that order, so each table goes in just before the first robot
# nearer the eye than the table's middle.
yard_shapes : View, I64 -> List(Shapes.Shape)
yard_shapes = |view, tick| {
	tables = Copies.table_places_at(tick)
	var $out = []
	var $next_table = 0
	for member in Crowd.block_members_at(tick) {
		while $next_table < tables.len() and table_depth(
			tables,
			$next_table,
		) > member.feet.forward {
			$out = List.concat($out, table_at_shapes(view, { tables, index: $next_table, tick }))
			$next_table = $next_table + 1
		}
		$out = List.concat($out, Speck.member_shapes(view, member))
	}
	while $next_table < tables.len() {
		$out = List.concat($out, table_at_shapes(view, { tables, index: $next_table, tick }))
		$next_table = $next_table + 1
	}
	$out
}

# How far down the yard the middle of table `index` stands.
table_depth : List(Copies.TablePlace), U64 -> F64
table_depth = |tables, index| {
	table = tables.get(index) ?? crash "Thanksgiving.table_depth: a table at every index asked"
	table.offset.forward + 3.3
}

table_at_shapes : View,
{
	tables : List(Copies.TablePlace),
	index : U64,
	tick : I64,
} -> List(Shapes.Shape)
table_at_shapes = |view, { tables, index, tick }| {
	table = tables.get(index) ?? crash "Thanksgiving.table_at_shapes: a table at every index asked"
	table_shapes(view.shifted_view(table.offset), { ride: table.ride, tick })
}

# One table seen through a view moved to it: its party on the lawn, or on
# its float with the float's pusher, painted under the deck or over the
# party by which side of the float it is on.
table_shapes : View,
{
	ride : [OnLawn, OnFloat(Copies.FloatRide)],
	tick : I64,
} -> List(Shapes.Shape)
table_shapes = |view, { ride, tick }|
	match ride {
		OnLawn => party_shapes(view, tick)
		OnFloat(float_ride) => {
			party = party_shapes(view.raised_view(Copies.deck_height), tick)
			deck = ParadeFloat.deck_shapes(view, float_ride)
			pusher = ParadeFloat.pusher_shapes(view, float_ride)
			if ParadeFloat.is_pusher_near(view, float_ride) {
				[deck, party, pusher].join()
			} else {
				[pusher, deck, party].join()
			}
		}
	}

# One table's whole party at one tick, back to front, through a view moved to
# that table. Every table is the same scene, so they move in step.
party_shapes : View, I64 -> List(Shapes.Shape)
party_shapes = |view, tick| {
	guests = [Tall, Round, Tiny]
	var $out = Lights.post_shapes(view)
	$out = List.concat($out, Table.shadow_shapes(view))
	for build in guests {
		guest = Dinner.guest_at(build, tick)
		$out = List.concat($out, Table.chair_shapes(view, { build, pulled: guest.chair_pulled }))
		$out = List.concat($out, guest_shapes(view, { build, guest }))
		$out = List.concat($out, dish_shapes(view, { build, tick, layer: Carried }))
	}
	$out = List.concat($out, Table.top_shapes(view))
	for build in guests {
		$out = List.concat($out, dish_shapes(view, { build, tick, layer: OnTable }))
	}
	$out = List.concat($out, dancer_shapes(view, tick))
	List.concat($out, Lights.strand_shapes(view, Dinner.bulb_glows(tick)))
}

# A guest side on, as it walks up the side of the table and sits.
guest_shapes : View, { build : Robot.Build, guest : Seating.Guest } -> List(Shapes.Shape)
guest_shapes = |view, { build, guest }|
	match view.sighting(guest.at) {
		Ok({ point, pixels_per_metre }) =>
			SideBody.figure_shapes({
				body: Robot.proportions(build),
				pose: guest.pose,
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
		Ok({ point, pixels_per_metre }) => Dancer.figure_shapes({
			pose: Dinner.dancer_pose(tick),
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
	last = Thanksgiving.shapes({ tick: Script.end_tick })
	last == Thanksgiving.shapes({ tick: Script.end_tick + 600 })
}

# And it is still moving just before the end, as the drum major's drumstick
# turns over in the air.
expect {
	last = Thanksgiving.shapes({ tick: Script.end_tick })
	last != Thanksgiving.shapes({ tick: Script.end_tick - 120 })
}
