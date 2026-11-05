## TruckBody draws the truck's body: the five faces of its trailer and cab,
## and its tyres. They are painted far to near, so a nearer face covers a
## farther one.
import DepthSort
import Geom
import lib.Trig
import TruckShape
import lib.Shapes

TruckBody :: [].{

	## A flat face of the truck, and its depth: the mean of its corners'
	## distances ahead, by which the faces are ordered for painting.
	TruckFace : {
		color : I64,
		depth : F64,
		corners : List(Geom.SpacePoint),
	}

	## A tyre is drawn as a polygon with this many corners.
	tire_sides : I64
	tire_sides = 16

	## The truck's body, its farthest faces painted first.
	draw : TruckShape.TruckInView -> List(Shapes.Shape)
	draw = |truck|
		DepthSort.sort_by(faces(truck), |face| face.depth)
			.join_map(|face| TruckShape.fill(truck, { color: face.color, corners: face.corners }))

	## A face of `color` with these corners.
	face : I64, List(Geom.SpacePoint) -> TruckBody.TruckFace
	face = |color, corners| {
		color,
		depth: (sum_of_forward(corners) / corners.len().to_f64()),
		corners,
	}

	## Where the truck's axles are along the road, back to front: a pair
	## under the back of the trailer, a pair under its front, and one under
	## the cab.
	axles : TruckShape.TruckBox -> List(F64)
	axles = |box| {
		back_pair = (box.rear + trailer_axle_inset)
		front_pair = (box.trailer_front - trailer_axle_inset)
		[
			(back_pair - (axle_pair_gap / 2.0)),
			(back_pair + (axle_pair_gap / 2.0)),
			(front_pair - (axle_pair_gap / 2.0)),
			(front_pair + (axle_pair_gap / 2.0)),
			(box.trailer_front + (TruckShape.cab_length * cab_axle_fraction)),
		]
	}
}

body_color : I64
body_color = 0x1C2E66

roof_color : I64
roof_color = 0x3A52A8

side_color : I64
side_color = 0x152150

tire_color : I64
tire_color = 0x15151A

## How far in from each end of the trailer the middle of its pair of axles is.
trailer_axle_inset : F64
trailer_axle_inset = 1.6

## The distance between the two axles of a pair.
axle_pair_gap : F64
axle_pair_gap = 1.2

## How far forward of the trailer the cab's axle is, as a fraction of the
## cab's length.
cab_axle_fraction : F64
cab_axle_fraction = 0.55

## Where the windshield meets the nose: half the truck's height.
hood_height : F64
hood_height = (TruckShape.truck_height / 2.0)

## Summed from the last corner to the first. A float sum's rounding depends
## on its order, and another order can move a pixel.
sum_of_forward : List(Geom.SpacePoint) -> F64
sum_of_forward = |corners| corners.fold_rev(0.0, |corner, sum| corner.forward + sum)

## The truck's faces: its two sides, its back, its roof, its windshield, its
## nose, then its tyres, the left side's and then the right's.
faces : TruckShape.TruckInView -> List(TruckBody.TruckFace)
faces = |truck| {
	box = truck.box
	axles = TruckBody.axles(box)
	List.join([
		[
			side(truck, box.left),
			side(truck, box.right),
			back(truck),
			roof(truck),
			windshield(truck),
			nose(truck),
		],
		axles.map(|axle| tire(truck, { axle, across: box.left })),
		axles.map(|axle| tire(truck, { axle, across: box.right })),
	])
}

## A face of `color` whose corners are the truck's points `corners`.
face_in_view : TruckShape.TruckInView,
{
	color : I64,
	corners : List(TruckShape.RoadPoint),
} -> TruckBody.TruckFace
face_in_view = |truck, { color, corners }| TruckBody.face(
	color,
	corners.map(|corner| TruckShape.point(truck, corner)),
)

## A side of the truck at `across`: up the back of the trailer, along its
## roof and the cab's, down the windshield's edge and the nose, back along
## the cab's floor, and down to the trailer's floor.
side : TruckShape.TruckInView, F64 -> TruckBody.TruckFace
side = |truck, across| {
	box = truck.box
	face_in_view(
		truck,
		{
			color: side_color,
			corners: [
				{
					along: box.rear,
					across,
					height: TruckShape.trailer_bottom,
				},
				{
					along: box.rear,
					across,
					height: TruckShape.truck_height,
				},
				{
					along: box.roof_front,
					across,
					height: TruckShape.truck_height,
				},
				{
					along: box.nose,
					across,
					height: hood_height,
				},
				{
					along: box.nose,
					across,
					height: TruckShape.cab_bottom,
				},
				{
					along: box.trailer_front,
					across,
					height: TruckShape.cab_bottom,
				},
				{
					along: box.trailer_front,
					across,
					height: TruckShape.trailer_bottom,
				},
			],
		},
	)
}

back : TruckShape.TruckInView -> TruckBody.TruckFace
back = |truck| {
	box = truck.box
	face_in_view(
		truck,
		{
			color: body_color,
			corners: [
				{
					along: box.rear,
					across: box.left,
					height: TruckShape.trailer_bottom,
				},
				{
					along: box.rear,
					across: box.right,
					height: TruckShape.trailer_bottom,
				},
				{
					along: box.rear,
					across: box.right,
					height: TruckShape.truck_height,
				},
				{
					along: box.rear,
					across: box.left,
					height: TruckShape.truck_height,
				},
			],
		},
	)
}

## The roof of the trailer and the cab, one flat face.
roof : TruckShape.TruckInView -> TruckBody.TruckFace
roof = |truck| {
	box = truck.box
	face_in_view(
		truck,
		{
			color: roof_color,
			corners: [
				{
					along: box.rear,
					across: box.left,
					height: TruckShape.truck_height,
				},
				{
					along: box.rear,
					across: box.right,
					height: TruckShape.truck_height,
				},
				{
					along: box.roof_front,
					across: box.right,
					height: TruckShape.truck_height,
				},
				{
					along: box.roof_front,
					across: box.left,
					height: TruckShape.truck_height,
				},
			],
		},
	)
}

windshield : TruckShape.TruckInView -> TruckBody.TruckFace
windshield = |truck| {
	box = truck.box
	face_in_view(
		truck,
		{
			color: body_color,
			corners: [
				{
					along: box.roof_front,
					across: box.left,
					height: TruckShape.truck_height,
				},
				{
					along: box.roof_front,
					across: box.right,
					height: TruckShape.truck_height,
				},
				{
					along: box.nose,
					across: box.right,
					height: hood_height,
				},
				{
					along: box.nose,
					across: box.left,
					height: hood_height,
				},
			],
		},
	)
}

nose : TruckShape.TruckInView -> TruckBody.TruckFace
nose = |truck| {
	box = truck.box
	face_in_view(
		truck,
		{
			color: body_color,
			corners: [
				{
					along: box.nose,
					across: box.left,
					height: hood_height,
				},
				{
					along: box.nose,
					across: box.right,
					height: hood_height,
				},
				{
					along: box.nose,
					across: box.right,
					height: TruckShape.cab_bottom,
				},
				{
					along: box.nose,
					across: box.left,
					height: TruckShape.cab_bottom,
				},
			],
		},
	)
}

## The tyre on the axle at `axle` along the road, on the side at `across`:
## a circle standing on the road.
tire : TruckShape.TruckInView, { axle : F64, across : F64 } -> TruckBody.TruckFace
tire = |truck, { axle, across }|
	face_in_view(
		truck,
		{
			color: tire_color,
			corners: TruckShape.circle_angles(TruckBody.tire_sides).map(
				|angle| {
					along: (axle + (TruckShape.tire_radius * Trig.r_cos(angle))),
					across,
					height: (TruckShape.tire_radius + (TruckShape.tire_radius * Trig.r_sin(angle))),
				},
			),
		},
	)

expect
	TruckBody.axles(TruckShape.truck_box({ along: 0.0, across: 0.0 }))
		== [-3.2, -2.0, 2.0, 3.2, 6.125]
expect
	TruckBody.axles(TruckShape.truck_box({ along: 40.0, across: 2.0 }))
		== [36.8, 38.0, 42.0, 43.2, 46.125]
expect TruckBody.axles(TruckShape.truck_box({ along: 0.0, across: 0.0 })).len() == 5

point_ahead : F64 -> Geom.SpacePoint
point_ahead = |forward| {
	right: 0.0,
	forward,
	height: 0.0,
}

quad_face : TruckBody.TruckFace
quad_face = TruckBody.face(
	1846886,
	[
		point_ahead(10.0),
		point_ahead(20.0),
		point_ahead(30.0),
		point_ahead(40.0),
	],
)

triangle_face : TruckBody.TruckFace
triangle_face = TruckBody.face(
	1381658,
	[
		point_ahead(1.0),
		point_ahead(2.0),
		point_ahead(6.0),
	],
)

expect quad_face.depth == 25.0
expect triangle_face.depth == 3.0
expect quad_face.color == 1846886
expect quad_face.corners.len() == 4
expect triangle_face.color == 1381658
expect triangle_face.corners.len() == 3

# A face that is only a colour and a depth, for the sort.
marked_face : { color : I64, depth : F64 } -> TruckBody.TruckFace
marked_face = |{ color, depth }| {
	color,
	depth,
	corners: [],
}

colors_by_depth : List({ color : I64, depth : F64 }) -> List(I64)
colors_by_depth = |marks|
	DepthSort.sort_by(marks.map(marked_face), |face| face.depth).map(|face| face.color)

expect
	colors_by_depth([
		{ color: 1, depth: 30.0 },
		{ color: 2, depth: 10.0 },
		{ color: 3, depth: 30.0 },
		{ color: 4, depth: 20.0 },
		{ color: 5, depth: 30.0 },
	])
		== [1, 3, 5, 4, 2]

expect
	colors_by_depth([
		{ color: 1, depth: 20.0 },
		{ color: 2, depth: 20.000001 },
		{ color: 3, depth: 20.01 },
		{ color: 4, depth: 19.0 },
	])
		== [3, 1, 2, 4]

expect colors_by_depth([]).len() == 0
expect colors_by_depth([{ color: 7, depth: 1.0 }]) == [7]

expect TruckBody.tire_sides == 16
