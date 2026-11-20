## Party draws one table's whole party at one tick, back to front, through a
## view moved to that table: the light posts and the table's shadow, the
## chairs and the robots at them by how far down the table they are, the
## dishes still in hands, the cloth, the dishes on it, the dancer and the
## lights over everything. Every table is the same scene, so its guests move
## in step; the marchers who come to sit along a float's right side are that
## table's own.
import lib.Shapes
import Dancer
import Dinner
import Dishes
import Guests
import Lights
import Marchers
import Robot
import Seating
import Serving
import SideBody
import Table
import View

Party :: [].{

	## The party at table `index`, the first table 0, at `tick`.
	party_shapes : View, { tick : I64, index : U64 } -> List(Shapes.Shape)
	party_shapes = |view, { tick, index }| {
		visitors = Marchers.visitors_at(index, tick)
		var $out = Lights.post_shapes(view)
		$out = List.concat($out, Table.shadow_shapes(view))
		$out = List.concat($out, chairs_and_guests_shapes(view, { tick, index, visitors }))
		$out = List.concat($out, all_dish_shapes(view, { tick, visitors, layer: Carried }))
		$out = List.concat($out, Table.top_shapes(view))
		$out = List.concat($out, all_dish_shapes(view, { tick, visitors, layer: OnTable }))
		$out = List.concat($out, dancer_shapes(view, tick))
		List.concat($out, Lights.strand_shapes(view, Dinner.bulb_glows(tick)))
	}
}

# The chairs and the robots, farthest from the eye first. A robot goes over
# its own chair once it is on it, and under a nearer chair it walks behind.
chairs_and_guests_shapes : View,
{
	tick : I64,
	index : U64,
	visitors : List(Marchers.Visitor),
} -> List(Shapes.Shape)
chairs_and_guests_shapes = |view, { tick, index, visitors }| {
	guests =
		Guests.everyone
			.map(
				|build| {
					guest = Guests.guest_at(build, tick)
					chair = Table.chair_of(build)
					[
						{
							depth: chair.forward,
							shapes: Table.chair_shapes(
								view,
								{ chair, pulled: Guests.chair_pulled(build, tick) },
							),
						},
						{
							depth: guest.at.forward - 0.01,
							shapes: guest_shapes(view, { build, guest }),
						},
					]
				},
			)
			.join()
	right_chairs = Marchers.right_chairs(index).map(
		|chair| {
			depth: chair.forward,
			shapes: Table.chair_shapes(view, { chair, pulled: pulled_by(visitors, chair) }),
		},
	)
	marchers = visitors.map(
		|visit| {
			depth: visit.guest.at.forward - 0.01,
			shapes: guest_shapes(view, { build: visit.build, guest: visit.guest }),
		},
	)
	[guests, right_chairs, marchers]
		.join()
		.sort_with(
			|a, b|
				if a.depth > b.depth {
					Before
				} else if a.depth < b.depth {
					After
				} else {
					Same
				},
		)
		.map(|layer| layer.shapes)
		.join()
}

# How far a marcher has pulled `chair` out; an empty chair is in its place.
pulled_by : List(Marchers.Visitor), Table.Chair -> F64
pulled_by = |visitors, chair|
	visitors.fold(
		0.0,
		|pulled, visit| if visit.chair == chair {
			visit.guest.chair_pulled
		} else {
			pulled
		},
	)

# Every dish in the layer being painted: the opening guests' and the
# marchers'.
all_dish_shapes : View,
{
	tick : I64,
	visitors : List(Marchers.Visitor),
	layer : [Carried, OnTable],
} -> List(Shapes.Shape)
all_dish_shapes = |view, { tick, visitors, layer }| {
	served = Serving.dishes.map(|dish| { dish, place: Serving.dish_place(dish, tick) })
	brought = visitors.map(|visit| { dish: visit.dish, place: visit.dish_place })
	List.concat(served, brought)
		.keep_if(|dish| dish.place.layer == layer)
		.map(
			|dish|
				match view.sighting(dish.place.at) {
					Ok({ point, pixels_per_metre }) =>
						Dishes.dish_shapes(
							dish.dish,
							{ base: point, pixels_per_metre, tilt: dish.place.tilt },
						)
					Err(BehindEye) => []
				},
		)
		.join()
}

# A robot side on, as it walks up the side of the table and sits.
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
