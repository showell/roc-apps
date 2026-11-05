## CatDraw draws the cat: the still for the pose it is in, scaled to its
## height on screen and raised as it leaps.
import Camera
import Cat
import CatStills
import Paint
import lib.Brush
import Stills
import Screen
import lib.Shapes

CatDraw :: [].{

	## Where the cat is on screen: where its feet are, its height in pixels,
	## and how far it is raised off the ground, in the still's units (a cat's
	## height is 1).
	Anchor : {
		feet : Screen.Point,
		height_px : F64,
		lift : F64,
	}

	## A polygon with more corners than this is not drawn.
	max_cat_pts : I64
	max_cat_pts = 256

	## A corner of the still, on screen.
	screen_point : CatDraw.Anchor, Stills.StillPt -> Screen.Point
	screen_point = |anchor, pt| {
		x: (anchor.feet.x + (pt.x * anchor.height_px)),
		y: (anchor.feet.y - ((pt.y + anchor.lift) * anchor.height_px)),
	}

	## One polygon of the still, on screen.
	polygon : CatDraw.Anchor, Stills.StillPoly -> List(Shapes.Shape)
	polygon = |anchor, poly|
		if poly.pts.len().to_i64_wrap() > max_cat_pts {
			[]
		} else {
			Paint.push_poly(poly.color, poly.pts.map(|pt| screen_point(anchor, pt)))
		}

	## A still's polygons on screen, in order.
	polygons : CatDraw.Anchor, List(Stills.StillPoly) -> List(Shapes.Shape)
	polygons = |anchor, polys| polys.join_map(|poly| polygon(anchor, poly))

	## The cat standing `right` and `forward` of the camera, `height` tall,
	## in `pose` and raised by `lift`. A cat under a pixel tall is not drawn.
	draw : {
		right : F64,
		forward : F64,
		height : F64,
		pose : Cat.Pose,
		lift : F64,
		cam_focal : F64,
	} -> List(Shapes.Shape)
	draw = |
		{
			right,
			forward,
			height,
			pose,
			lift,
			cam_focal,
		},
	| {
		feet = Camera.project(
			{
				right,
				forward,
				height: 0.0,
			},
			cam_focal,
		)
		top = Camera.project(
			{
				right,
				forward,
				height,
			},
			cam_focal,
		)
		height_px = (feet.y - top.y)
		if height_px < 1.0 {
			[]
		} else {
			polygons(
				{
					feet,
					height_px,
					lift,
				},
				CatStills.pose_polys(pose),
			)
		}
	}
}

sample_feet : Screen.Point
sample_feet = { x: 100.0, y: 200.0 }

# A cat 50 px tall, standing at the feet.
standing : CatDraw.Anchor
standing = {
	feet: sample_feet,
	height_px: 50.0,
	lift: 0.0,
}

expect CatDraw.screen_point(standing, { x: 0.5, y: 0.4 }) == { x: 125.0, y: 180.0 }
expect CatDraw.screen_point(standing, { x: 0.0, y: 0.0 }) == { x: 100.0, y: 200.0 }
expect CatDraw.screen_point(standing, { x: -1.0, y: 1.0 }) == { x: 50.0, y: 150.0 }

# A lift raises a corner by that share of the cat's height, and doesn't move it
# across.
expect {
	on_ground = CatDraw.screen_point(standing, { x: 0.5, y: 0.4 })
	lifted = CatDraw.screen_point({ ..standing, lift: 0.2 }, { x: 0.5, y: 0.4 })
	lifted == {
		x: 125.0,
		y: 170.0,
	} and on_ground.y - lifted.y == 10.0 and lifted.x - on_ground.x == 0.0
}

expect
	CatDraw.screen_point(
		{
			feet: sample_feet,
			height_px: 100.0,
			lift: 0.2,
		},
		{ x: 0.5, y: 0.4 },
	).y
		== 140.0

expect
	[{ x: 0.0, y: 0.0 }, { x: 0.5, y: 0.4 }].map(|corner| CatDraw.screen_point(standing, corner))
		== [{ x: 100.0, y: 200.0 }, { x: 125.0, y: 180.0 }]

# A polygon of colour 9 with `count` corners, all at the feet.
poly_of : U64 -> Stills.StillPoly
poly_of = |count| {
	color: 9,
	grad: [],
	pts: List.repeat({ x: 0.0, y: 0.0 }, count),
}

expect CatDraw.max_cat_pts == 256
expect CatDraw.polygon(standing, poly_of(3)).len() == 1
expect CatDraw.polygon(standing, poly_of(256)).len() == 1
expect CatDraw.polygon(standing, poly_of(257)).len() == 0
expect CatDraw.polygon(standing, poly_of(2)).len() == 0

expect
	CatDraw.polygon(standing, poly_of(3))
		== [
			Poly({
				pts: [100.0, 200.0, 100.0, 200.0, 100.0, 200.0],
				fill: Flat(Brush.opaque(9)),
			}),
		]

expect
	CatDraw.polygons(
		standing,
		[
			poly_of(3),
			poly_of(4),
			poly_of(300),
		],
	).len()
		== 2
expect CatDraw.polygons(standing, []).len() == 0
expect
	CatDraw.polygons(standing, [poly_of(3), poly_of(4)]).drop_first(1)
		== [
			Poly({
				pts: [100.0, 200.0, 100.0, 200.0, 100.0, 200.0, 100.0, 200.0],
				fill: Flat(Brush.opaque(9)),
			}),
		]

# How many shapes a 1.7 m cat makes `forward` metres ahead, in `pose` and raised
# by `lift`, through a 500 px focal length on a 960 px view.
cat_shapes : {
	forward : F64,
	pose : Cat.Pose,
	lift : F64,
} -> U64
cat_shapes = |
	{
		forward,
		pose,
		lift,
	},
|
	CatDraw.draw({
		right: 0.0,
		forward,
		height: 1.7,
		pose,
		lift,
		cam_focal: 500.0,
	}).len()

expect
	cat_shapes({
		forward: 850.0,
		pose: Rest,
		lift: 0.0,
	})
		== CatStills.pose_polys(Rest).len()
expect
	cat_shapes({
		forward: 851.0,
		pose: Rest,
		lift: 0.0,
	})
		== 0
expect
	cat_shapes({
		forward: 2000.0,
		pose: Rest,
		lift: 0.0,
	})
		== 0

expect
	cat_shapes({
		forward: 100.0,
		pose: Rest,
		lift: 0.0,
	})
		== CatStills.pose_polys(Rest).len()
expect
	cat_shapes({
		forward: 100.0,
		pose: Rest,
		lift: 0.3,
	})
		== CatStills.pose_polys(Rest).len()
expect
	cat_shapes({
		forward: 100.0,
		pose: Frozen,
		lift: 0.0,
	})
		== CatStills.pose_polys(Frozen).len()

expect
	[
		Rest,
		Stride,
		Frozen,
		Coil,
		Flight,
		Land,
		Collapse,
	].all(|pose| CatStills.pose_polys(pose).len() > 0)
