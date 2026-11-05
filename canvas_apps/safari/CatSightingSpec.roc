## These are CatSighting's checks: how far ahead each segment starts, which
## cats are in view as the rider comes on them, and the keys the depth sort
## reads.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Cat
import CatSighting
import Frame
import Grade
import Speed
import World

## The second segment, with a cat crossing it.
cat_segment : World.Segment
cat_segment = { ..World.route_segment(1), crossing: World.route_segment(3).crossing }

segs : List(World.Segment)
segs = [
	World.route_segment(0),
	cat_segment,
	World.route_segment(2),
]

origin : Frame.Pose
origin = {
	along: 0.0,
	across: 0.0,
	yaw: Angle.straight_ahead,
	half_width: 2.0,
}

## The first three segments seen from the origin, at 1 m a step.
from_origin : Frame.Viewpoint
from_origin = {
	road: {
		world: segs,
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		pose: origin,
	},
	cam_focal: 500.0,
}

metre_a_step : Speed
metre_a_step = Speed.metres_a_step(1.0)

## The cats seen from the origin on a road of only `chain`.
cats_on_chain : List(World.SegmentIndex) -> List(CatSighting.CatItem)
cats_on_chain = |chain| CatSighting.in_view(
	{ ..from_origin, road: { ..from_origin.road, chain } },
	metre_a_step,
)

## The cat on the segment at `number` in the chain, if it is in view.
cat_at : U32 -> List(CatSighting.CatItem)
cat_at = |number| CatSighting.segment_cat(
	from_origin,
	{ position: Frame.ChainPosition.number(number), speed: metre_a_step },
)

has_got : List(Bool)
has_got = segs.map(has_cat)

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |seg|
	match seg.crossing {
		CatCrosses(_) => True
		BirdFlies(_) | QuietRoad => False
	}

has_want : List(Bool)
has_want = [False, True, False]

gap_got : List(F64)
gap_got = [0.0, 120.0].join_map(
	|along| [
		0,
		1,
		2,
	].map(
		|number| Frame.gap_to_segment(
			{ ..from_origin.road, pose: { ..origin, along } },
			Frame.ChainPosition.number(number),
		),
	),
)

gap_want : List(F64)
gap_want = [
	0.0,
	500.0,
	820.0,
	(-120.0),
	380.0,
	700.0,
]

## The cats in view for a rider `along` metres into the first segment.
riding : F64 -> List(CatSighting.CatItem)
riding = |along| CatSighting.in_view(
	{ ..from_origin, road: { ..from_origin.road, pose: { ..origin, along } } },
	metre_a_step,
)

seen : List(CatSighting.CatItem)
seen = riding(300.0)

## The first cat in view for a rider `along` metres in.
first_cat : F64 -> CatSighting.CatItem
first_cat = |along|
	riding(along).first() ?? crash "CatSightingSpec: the second segment's cat is in view"

count_got : List(I64)
count_got = [
	seen.len().to_i64_wrap(),
	cat_at(0).len().to_i64_wrap(),
	cat_at(2).len().to_i64_wrap(),
	CatSighting.max_vis_cats,
]

count_want : List(I64)
count_want = [1, 0, 0, 8]

place_got : List(F64)
place_got = [first_cat(300.0).height, first_cat(300.0).lift]

place_want : List(F64)
place_want = [1.7, 0.0]

pose_got : List(I64)
pose_got = [Cat.pose_index(first_cat(300.0).pose)]

pose_want : List(I64)
pose_want = [0]

closing_got : List(F64)
closing_got = [
	(first_cat(300.0).forward - first_cat(200.0).forward),
	(first_cat(400.0).forward - first_cat(300.0).forward),
	(first_cat(300.0).right - first_cat(200.0).right),
]

closing_want : List(F64)
closing_want = [
	(-100.0),
	(-100.0),
	0.0,
]

cull_got : List(I64)
cull_got = [
	riding(0.0).len().to_i64_wrap(),
	riding(200.0).len().to_i64_wrap(),
	riding(500.0).len().to_i64_wrap(),
	riding(600.0).len().to_i64_wrap(),
	cats_on_chain([]).len().to_i64_wrap(),
	cats_on_chain([World.SegmentIndex.first]).len().to_i64_wrap(),
]

cull_want : List(I64)
cull_want = [0, 1, 1, 0, 0, 0]

## One cat in view gives one key, which names the first cat; none gives none.
items_got : List(Bool)
items_got = {
	key = CatSighting.depth_keys(seen).first() ?? crash "CatSightingSpec: one cat is in view"
	[
		CatSighting.depth_keys(seen).len() == 1,
		CatSighting.depth_keys([]).len() == 0,
		key.subject == Cat(0),
	]
}

items_want : List(Bool)
items_want = [True, True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.bools({
			name: "cp-has   ",
			got: has_got,
			want: has_want,
		}),
		Grade.reals({
			name: "cp-gap   ",
			got: gap_got,
			want: gap_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "cp-count ",
			got: count_got,
			want: count_want,
		}),
		Grade.reals({
			name: "cp-place ",
			got: place_got,
			want: place_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "cp-pose  ",
			got: pose_got,
			want: pose_want,
		}),
		Grade.reals({
			name: "cp-close ",
			got: closing_got,
			want: closing_want,
			tol: 0.0001,
		}),
		Grade.ints({
			name: "cp-cull  ",
			got: cull_got,
			want: cull_want,
		}),
		Grade.bools({
			name: "cp-items ",
			got: items_got,
			want: items_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
