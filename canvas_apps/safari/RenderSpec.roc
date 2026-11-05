## These are Render's checks, on the scene from the start of the route:
## every kind's keys are in the depth order, each kind is in view and held
## to its cap, and the order runs far to near.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import BirdSighting
import CatSighting
import Clock
import CritterSighting
import DepthSort
import Distance
import Frame
import Across
import Along
import Grade
import RailSighting
import Render
import TowerSighting
import TreeSighting
import TruckSighting
import VehicleLimits
import World

segs : List(World.Segment)
segs = List.from_iter(U32.until(0, World.route.len().to_u32_wrap())).map(World.route_segment)

origin : Frame.Pose
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
	half_width: Distance.metres(2.0),
}

scene : Render.Scene
scene = Render.collect(
	{
		road: {
			world: segs,
			chain: Frame.chain_ahead(segs, World.SegmentIndex.first),
			pose: origin,
		},
		cam_focal: 500.0,
	},
	{
		speed: VehicleLimits.v_base,
		truck: {
			route_position: Distance.metres(500.0),
			lights: { headlights: Off, brake_lights: Off },
		},
		clock: Clock.start,
	},
)

merge_got : List(I64)
merge_got = {
	n = scene.order.len().to_i64_wrap()
	kind_counts = [
		TreeSighting.depth_keys(scene.trees).len(),
		TowerSighting.depth_keys(scene.towers).len(),
		CritterSighting.cow_items(scene.critters).len(),
		CatSighting.depth_keys(scene.cats).len(),
		TruckSighting.depth_keys(scene.truck).len(),
		RailSighting.depth_keys(scene.rails).len(),
		BirdSighting.depth_keys(scene.birds).len(),
	]
	[(n - List.sum(kind_counts).to_i64_wrap())]
}

merge_want : List(I64)
merge_want = [0]

present_got : List(Bool)
present_got = [
	(scene.trees.len() > 0),
	(scene.towers.len() > 0),
	(scene.critters.len() > 0),
	(scene.rails.len() > 0),
	(scene.order.len() > 0),
]

present_want : List(Bool)
present_want = [True, True, True, True, True]

cap_got : List(Bool)
cap_got = [
	(scene.trees.len().to_i64_wrap() <= TreeSighting.max_vis_trees),
	(scene.towers.len().to_i64_wrap() <= TowerSighting.max_vis_towers),
	(scene.critters.len().to_i64_wrap() <= CritterSighting.max_vis_critters),
	(scene.cats.len().to_i64_wrap() <= CatSighting.max_vis_cats),
]

cap_want : List(Bool)
cap_want = [True, True, True, True]

cap_values_got : List(I64)
cap_values_got = [
	TreeSighting.max_vis_trees,
	TowerSighting.max_vis_towers,
	CatSighting.max_vis_cats,
]

cap_values_want : List(I64)
cap_values_want = [640, 16, 8]

## Whether no key in `keys` is farther than the one before it.
is_far_to_near : List(DepthSort.DepthKey) -> Bool
is_far_to_near = |keys|
	List.map2(
		keys,
		keys.drop_first(1),
		|before, after| DepthSort.is_farther({ this: after.forward, that: before.forward }),
	)
		.all(|is_out_of_order| !is_out_of_order)

sorted_got : List(Bool)
sorted_got = [is_far_to_near(scene.order), is_far_to_near([])]

sorted_want : List(Bool)
sorted_want = [True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "rn-merge ",
			got: merge_got,
			want: merge_want,
		}),
		Grade.bools({
			name: "rn-presnt",
			got: present_got,
			want: present_want,
		}),
		Grade.bools({
			name: "rn-cap   ",
			got: cap_got,
			want: cap_want,
		}),
		Grade.ints({
			name: "rn-caps  ",
			got: cap_values_got,
			want: cap_values_want,
		}),
		Grade.bools({
			name: "rn-sorted",
			got: sorted_got,
			want: sorted_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
