## TruckBody draws the truck's body: the five faces of its trailer and cab,
## and its tires. They are painted far to near, so a nearer face covers a
## farther one.
import Across
import Along
import Camera
import DepthSort
import Distance
import Fraction
import Geom
import Picture
import TruckShape
import lib.RgbColor
import lib.Shapes

TruckBody :: [].{

	## The truck's body, its farthest faces painted first. A face is ordered by
	## the mean of its corners' distances ahead.
	body_shapes : Picture.Setting(TruckShape.TruckOnRoad) -> List(Shapes.Shape)
	body_shapes = |truck|
		DepthSort.sort_by(faces(truck), |face| mean_forward(face.corners))
			.keep_oks(|face| TruckShape.truck_polygon(truck, face))
}

body_color : RgbColor
body_color = RgbColor.of(0x1C2E66)

roof_color : RgbColor
roof_color = RgbColor.of(0x3A52A8)

side_color : RgbColor
side_color = RgbColor.of(0x152150)

tire_color : RgbColor
tire_color = RgbColor.of(0x15151A)

## A tire is drawn as a polygon with this many corners.
tire_sides : I64
tire_sides = 16

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

## The mean of the corners' distances ahead, negative for a face behind the
## rider. The sum runs from the last corner to the first; a float sum's
## rounding depends on its order, and another order can move a pixel.
mean_forward : List(Geom.RaisedPoint) -> Distance
mean_forward = |corners|
	corners
		.fold_rev(Distance.zero, |corner, sum| corner.forward.plus(sum))
		.divided_by(corners.len().to_f64())

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

## The truck's faces: its two sides, its back, its roof, its windshield, its
## nose, then its tires, the left side's and then the right's.
faces : Picture.Setting(TruckShape.TruckOnRoad) -> List(Camera.FlatPolygon)
faces = |truck| {
	box = truck.context.box
	truck_axles = axles(box)
	[
		[
			side(truck, box.left),
			side(truck, box.right),
			back(truck),
			roof(truck),
			windshield(truck),
			nose(truck),
		],
		truck_axles.map(|axle| tire(truck, { axle, across: box.left })),
		truck_axles.map(|axle| tire(truck, { axle, across: box.right })),
	].join()
}

## A face of `color` whose corners are the truck's points `corners`.
face : Picture.Setting(TruckShape.TruckOnRoad),
{
	color : RgbColor,
	corners : List(TruckShape.TruckPoint),
} -> Camera.FlatPolygon
face = |truck, { color, corners }| {
	color,
	corners: corners.map(|corner| TruckShape.point(truck, corner)),
}

## A side of the truck at `across`: up the back of the trailer, along its
## roof and the cab's, down the windshield's edge and the nose, back along
## the cab's floor, and down to the trailer's floor.
side : Picture.Setting(TruckShape.TruckOnRoad), Across -> Camera.FlatPolygon
side = |truck, across| {
	box = truck.context.box
	face(
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

back : Picture.Setting(TruckShape.TruckOnRoad) -> Camera.FlatPolygon
back = |truck| {
	box = truck.context.box
	face(
		truck,
		{
			color: body_color,
			corners: TruckShape.strip_corners(
				{ left: box.left, right: box.right },
				{
					near: { along: box.rear, height: TruckShape.trailer_bottom },
					far: { along: box.rear, height: TruckShape.truck_height },
				},
			),
		},
	)
}

## The roof of the trailer and the cab, one flat face.
roof : Picture.Setting(TruckShape.TruckOnRoad) -> Camera.FlatPolygon
roof = |truck| {
	box = truck.context.box
	face(
		truck,
		{
			color: roof_color,
			corners: TruckShape.strip_corners(
				{ left: box.left, right: box.right },
				{
					near: { along: box.rear, height: TruckShape.truck_height },
					far: { along: box.roof_front, height: TruckShape.truck_height },
				},
			),
		},
	)
}

windshield : Picture.Setting(TruckShape.TruckOnRoad) -> Camera.FlatPolygon
windshield = |truck| {
	box = truck.context.box
	face(
		truck,
		{
			color: body_color,
			corners: TruckShape.strip_corners(
				{ left: box.left, right: box.right },
				{
					near: { along: box.roof_front, height: TruckShape.truck_height },
					far: { along: box.nose, height: hood_height },
				},
			),
		},
	)
}

nose : Picture.Setting(TruckShape.TruckOnRoad) -> Camera.FlatPolygon
nose = |truck| {
	box = truck.context.box
	face(
		truck,
		{
			color: body_color,
			corners: TruckShape.strip_corners(
				{ left: box.left, right: box.right },
				{
					near: { along: box.nose, height: hood_height },
					far: { along: box.nose, height: TruckShape.cab_bottom },
				},
			),
		},
	)
}

## The tire on the axle at `axle` along the road, on the side at `across`:
## a circle standing on the road.
tire : Picture.Setting(TruckShape.TruckOnRoad),
{
	axle : Along,
	across : Across,
} -> Camera.FlatPolygon
tire = |truck, { axle, across }| {
	radius = TruckShape.tire_radius
	face(
		truck,
		{
			color: tire_color,
			corners: TruckShape.circle_angles(tire_sides).map(
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
axles_at = |center| axles(TruckShape.truck_box(center)).map(Along.to_metres)

expect
	axles_at({ along: Along.metres(0.0), across: Across.metres(0.0) })
		== [-3.2, -2.0, 2.0, 3.2, 6.125]
expect
	axles_at({ along: Along.metres(40.0), across: Across.metres(2.0) })
		== [36.8, 38.0, 42.0, 43.2, 46.125]

point_ahead : F64 -> Geom.RaisedPoint
point_ahead = |forward| {
	right: Distance.zero,
	forward: Distance.metres(forward),
	height: Distance.zero,
}

expect mean_forward([10.0, 20.0, 30.0, 40.0].map(point_ahead)).to_metres() == 25.0
expect mean_forward([1.0, 2.0, 6.0].map(point_ahead)).to_metres() == 3.0
