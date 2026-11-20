## Thanksgiving is the cut: the order the backyard's things are painted in,
## back to front, at one tick. Script says when each beat is; EyePath and Lens
## say where the eye is and how it is zoomed; Guests, Family, Copies, March,
## Marchers and Crowd say where everything is and how it stands; Party draws
## each table's party, and Backyard, ParadeFloat, Speck, Army, Banner and
## Leaves each draw one thing from the numbers they are handed.
##
## Behind the fence come the robots jumping to see over it. Across the yard,
## the tables, the crowd's blocks and the army on the lawn are painted
## farthest first, each table by its middle and each robot by its feet, so a
## marcher running between the floats goes behind the near ones and in front
## of the far ones.
import lib.Point
import lib.Shapes
import Army
import Backyard
import Banner
import Copies
import Crowd
import Dinner
import EyePath
import Leaves
import Lens
import ParadeFloat
import Party
import Script
import Speck
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

# The tables, the crowd's two blocks and the army on the lawn, farthest
# first: each table by its middle, each robot by its feet.
yard_shapes : View, I64 -> List(Shapes.Shape)
yard_shapes = |view, tick| {
	tables = Copies.table_places_at(tick).map(
		|table| {
			depth: table.offset.forward + 3.3,
			shapes: table_shapes(view.shifted_view(table.offset), { table, tick }),
		},
	)
	crowd = Crowd.block_members_at(tick).map(
		|member| { depth: member.feet.forward, shapes: Speck.member_shapes(view, member) },
	)
	[tables, crowd, Army.army_layers(view, tick)]
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

# One table seen through a view moved to it: its party on the lawn, or on
# its float with the float's pusher, painted under the deck or over the
# party by which side of the float it is on.
table_shapes : View, { table : Copies.TablePlace, tick : I64 } -> List(Shapes.Shape)
table_shapes = |view, { table, tick }|
	match table.ride {
		OnLawn => Party.party_shapes(view, { tick, index: table.index })
		OnFloat(float_ride) => {
			party = Party.party_shapes(
				view.raised_view(float_ride.deck_height),
				{ tick, index: table.index },
			)
			deck = ParadeFloat.deck_shapes(view, float_ride)
			pusher = ParadeFloat.pusher_shapes(view, float_ride)
			if ParadeFloat.is_pusher_near(view, float_ride) {
				[deck, party, pusher].join()
			} else {
				[pusher, deck, party].join()
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
