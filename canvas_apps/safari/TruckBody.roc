## TruckBody draws the truck's body: the five faces of its trailer and cab,
## and its tires. They are painted far to near, so a nearer face covers a
## farther one.
import Across
import Along
import DepthSort
import Distance
import Fraction
import Geom
import TruckShape
import lib.RgbColor
import lib.Shapes

TruckBody :: [].{

	## A flat face of the truck, and its depth: the mean of its corners'
	## distances ahead, by which the faces are ordered for painting. That mean
	## is negative for a face behind the rider.
	TruckFace : {
		color : RgbColor,
		depth : Distance,
		corners : List(Geom.RaisedPoint),
	}

	## A tire is drawn as a polygon with this many corners.
	tire_sides : I64
	tire_sides = 16

	## The truck's body, its farthest faces painted first.
	body_shapes : TruckShape.TruckInView -> List(Shapes.Shape)
	body_shapes = |truck|
		DepthSort.sort_by(faces(truck), |face| face.depth)
			.keep_oks(
				|face| TruckShape.truck_polygon(
					truck,
					{ color: face.color, corners: face.corners },
				),
			)

	## A face of `color` with these corners.
	face : RgbColor, List(Geom.RaisedPoint) -> TruckBody.TruckFace
	face = |color, corners| {
		color,
		depth: sum_of_forward(corners).divided_by(corners.len().to_f64()),
		corners,
	}

	## Where the truck's axles are along the road, back to front: a pair
	## under the back of the trailer, a pair under its front, and one under
	## the cab.
	axles : TruckShape.TruckBox -> List(Along)
	axles = |box| {
		back_pair = box.rear.plus(trailer_axle_inset)
		front_pair = box.trailer_front.minus(trailer_axle_inset)
		half_gap = axle_pair_gap.divided_by(2.0)
		[
			back_pair.minus(half_gap),
			back_pair.plus(half_gap),
			front_pair.minus(half_gap),
			front_pair.plus(half_gap),
			box.trailer_front.plus(TruckShape.cab_length.times(cab_axle_fraction.to_f64())),
		]
	}
}

body_color : RgbColor
body_color = RgbColor.of(0x1C2E66)

roof_color : RgbColor
roof_color = RgbColor.of(0x3A52A8)

side_color : RgbColor
side_color = RgbColor.of(0x152150)

tire_color : RgbColor
tire_color = RgbColor.of(0x15151A)

## How far in from each end of the trailer the middle of its pair of axles is.
trailer_axle_inset : Distance
trailer_axle_inset = Distance.metres(1.6)

## The distance between the two axles of a pair.
axle_pair_gap : Distance
axle_pair_gap = Distance.metres(1.2)

## How far forward of the trailer the cab's axle is, as a fraction of the
## cab's length.
cab_axle_fraction : Fraction
cab_axle_fraction = Fraction.of(0.55)

## Where the windshield meets the nose: half the truck's height.
hood_height : Distance
hood_height = TruckShape.truck_height.divided_by(2.0)

## Summed from the last corner to the first. A float sum's rounding depends
## on its order, and another order can move a pixel.
sum_of_forward : List(Geom.RaisedPoint) -> Distance
sum_of_forward = |corners|
	corners.fold_rev(Distance.zero, |corner, sum| corner.forward.plus(sum))

## The truck's faces: its two sides, its back, its roof, its windshield, its
## nose, then its tires, the left side's and then the right's.
faces : TruckShape.TruckInView -> List(TruckBody.TruckFace)
faces = |truck| {
	box = truck.box
	axles = TruckBody.axles(box)
	[
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
	].join()
}

## A face of `color` whose corners are the truck's points `corners`.
face_in_view : TruckShape.TruckInView,
{
	color : RgbColor,
	corners : List(TruckShape.TruckPoint),
} -> TruckBody.TruckFace
face_in_view = |truck, { color, corners }| TruckBody.face(
	color,
	corners.map(|corner| TruckShape.point(truck, corner)),
)

## A side of the truck at `across`: up the back of the trailer, along its
## roof and the cab's, down the windshield's edge and the nose, back along
## the cab's floor, and down to the trailer's floor.
side : TruckShape.TruckInView, Across -> TruckBody.TruckFace
side = |truck, across| {
	box = truck.box
	face_in_view(
		truck,
		{
			color: side_color,
			corners: [
				{ along: box.rear, across, height: TruckShape.trailer_bottom },
				{ along: box.rear, across, height: TruckShape.truck_height },
				{ along: box.roof_front, across, height: TruckShape.truck_height },
				{ along: box.nose, across, height: hood_height },
				{ along: box.nose, across, height: TruckShape.cab_bottom },
				{ along: box.trailer_front, across, height: TruckShape.cab_bottom },
				{ along: box.trailer_front, across, height: TruckShape.trailer_bottom },
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

## The tire on the axle at `axle` along the road, on the side at `across`:
## a circle standing on the road.
tire : TruckShape.TruckInView, { axle : Along, across : Across } -> TruckBody.TruckFace
tire = |truck, { axle, across }| {
	radius = TruckShape.tire_radius
	face_in_view(
		truck,
		{
			color: tire_color,
			corners: TruckShape.circle_angles(TruckBody.tire_sides).map(
				|angle| {
					along: axle.plus(radius.times(angle.cos())),
					across,
					height: radius.plus(radius.times(angle.sin())),
				},
			),
		},
	)
}

axles_at : { along : Along, across : Across } -> List(F64)
axles_at = |center| TruckBody.axles(TruckShape.truck_box(center)).map(Along.to_metres)

expect
	axles_at({ along: Along.metres(0.0), across: Across.metres(0.0) })
		== [-3.2, -2.0, 2.0, 3.2, 6.125]
expect
	axles_at({ along: Along.metres(40.0), across: Across.metres(2.0) })
		== [36.8, 38.0, 42.0, 43.2, 46.125]
expect axles_at({ along: Along.metres(0.0), across: Across.metres(0.0) }).len() == 5

point_ahead : F64 -> Geom.RaisedPoint
point_ahead = |forward| {
	right: Distance.zero,
	forward: Distance.metres(forward),
	height: Distance.zero,
}

quad_face : TruckBody.TruckFace
quad_face = TruckBody.face(
	RgbColor.of(0x1C2E66),
	[
		point_ahead(10.0),
		point_ahead(20.0),
		point_ahead(30.0),
		point_ahead(40.0),
	],
)

triangle_face : TruckBody.TruckFace
triangle_face = TruckBody.face(
	RgbColor.of(0x15151A),
	[
		point_ahead(1.0),
		point_ahead(2.0),
		point_ahead(6.0),
	],
)

expect quad_face.depth.to_metres() == 25.0
expect triangle_face.depth.to_metres() == 3.0
expect quad_face.color == RgbColor.of(0x1C2E66)
expect quad_face.corners.len() == 4
expect triangle_face.color == RgbColor.of(0x15151A)
expect triangle_face.corners.len() == 3

# A face that is only a colour and a depth, for the sort.
marked_face : { color : RgbColor, depth : Distance } -> TruckBody.TruckFace
marked_face = |{ color, depth }| { color, depth, corners: [] }

colors_by_depth : List({ color : RgbColor, depth : Distance }) -> List(I64)
colors_by_depth = |marks|
	DepthSort.sort_by(marks.map(marked_face), |face| face.depth).map(|face| face.color.to_i64())

expect
	colors_by_depth([
		{ color: RgbColor.of(1), depth: Distance.metres(30.0) },
		{ color: RgbColor.of(2), depth: Distance.metres(10.0) },
		{ color: RgbColor.of(3), depth: Distance.metres(30.0) },
		{ color: RgbColor.of(4), depth: Distance.metres(20.0) },
		{ color: RgbColor.of(5), depth: Distance.metres(30.0) },
	])
		== [1, 3, 5, 4, 2]

expect
	colors_by_depth([
		{ color: RgbColor.of(1), depth: Distance.metres(20.0) },
		{ color: RgbColor.of(2), depth: Distance.metres(20.000001) },
		{ color: RgbColor.of(3), depth: Distance.metres(20.01) },
		{ color: RgbColor.of(4), depth: Distance.metres(19.0) },
	])
		== [3, 1, 2, 4]

expect colors_by_depth([]).len() == 0
expect colors_by_depth([{ color: RgbColor.of(7), depth: Distance.metres(1.0) }]) == [7]

expect TruckBody.tire_sides == 16
