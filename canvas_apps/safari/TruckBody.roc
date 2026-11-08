## TruckBody gives the picture of the truck's body: the six faces of its
## trailer and cab, and its tires. The shapes come sorted far to near, so a
## nearer face drawn later covers a farther one.
import DepthSort
import Distance
import EarthCurve
import Fraction
import Picture
import Polygon
import TruckShape
import lib.RgbColor

TruckBody :: [].{

	## The truck's body, its farthest faces first. A face is ordered by the
	## mean of its corners' distances ahead.
	body_picture : TruckShape.TruckSetting -> Picture
	body_picture = |truck|
		Picture.from_shapes(
			DepthSort.sort_by(
				faces(truck),
				|face| DepthSort.mean_depth(face.corners.map(|corner| corner.forward)),
			)
				.keep_oks(|face| Polygon.clipped_polygon(face, truck.focal_length)),
		)
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

## How far ahead of the trailer's centre each of the truck's axles is, back
## to front: a pair under the back of the trailer, a pair under its front,
## and one under the cab.
axles : List(Distance)
axles = {
	box = TruckShape.truck_box
	back_pair = box.rear.plus(trailer_axle_inset)
	front_pair = box.trailer_front.minus(trailer_axle_inset)
	half_gap = axle_pair_gap.divided_by(2.0)
	[
		back_pair.minus(half_gap),
		back_pair.plus(half_gap),
		front_pair.minus(half_gap),
		front_pair.plus(half_gap),
		box.trailer_front.plus(TruckShape.cab_length.scaled_by(cab_axle_fraction)),
	]
}

## The truck's faces: its two sides, its back, its roof, its windshield, its
## nose, then its tires, the left side's and then the right's.
faces : TruckShape.TruckSetting -> List(Polygon.FlatPolygon)
faces = |truck| {
	box = TruckShape.truck_box
	[
		[
			side(truck, box.left),
			side(truck, box.right),
			back(truck),
			roof(truck),
			windshield(truck),
			nose(truck),
		],
		axles.map(|axle| tire(truck, { axle, rightward: box.left })),
		axles.map(|axle| tire(truck, { axle, rightward: box.right })),
	].join()
}

## A face of `color` whose corners are the truck's points `corners`.
face : TruckShape.TruckSetting,
{
	color : RgbColor,
	corners : List(TruckShape.TruckPoint),
} -> Polygon.FlatPolygon
face = |truck, { color, corners }| {
	color,
	corners: corners.map(
		|corner| {
			over_road = TruckShape.road_point_on_truck(truck, corner)
			EarthCurve.raised_ground_point(truck.context, over_road)
		},
	),
}

## A side of the truck `rightward` of its centre line: up the back of the
## trailer, along its roof and the cab's, down the windshield's edge and the
## nose, back along the cab's floor, and down to the trailer's floor.
side : TruckShape.TruckSetting, Distance -> Polygon.FlatPolygon
side = |truck, rightward| {
	box = TruckShape.truck_box
	face(
		truck,
		{
			color: side_color,
			corners: [
				{ ahead: box.rear, rightward, height: TruckShape.trailer_bottom },
				{ ahead: box.rear, rightward, height: TruckShape.truck_height },
				{ ahead: box.roof_front, rightward, height: TruckShape.truck_height },
				{ ahead: box.nose, rightward, height: TruckShape.hood_height },
				{ ahead: box.nose, rightward, height: TruckShape.cab_bottom },
				{ ahead: box.trailer_front, rightward, height: TruckShape.cab_bottom },
				{ ahead: box.trailer_front, rightward, height: TruckShape.trailer_bottom },
			],
		},
	)
}

back : TruckShape.TruckSetting -> Polygon.FlatPolygon
back = |truck| {
	box = TruckShape.truck_box
	face(
		truck,
		{
			color: body_color,
			corners: TruckShape.strip_corners(
				{ left: box.left, right: box.right },
				{
					near: { ahead: box.rear, height: TruckShape.trailer_bottom },
					far: { ahead: box.rear, height: TruckShape.truck_height },
				},
			),
		},
	)
}

## The roof of the trailer and the cab, one flat face.
roof : TruckShape.TruckSetting -> Polygon.FlatPolygon
roof = |truck| {
	box = TruckShape.truck_box
	face(
		truck,
		{
			color: roof_color,
			corners: TruckShape.strip_corners(
				{ left: box.left, right: box.right },
				{
					near: { ahead: box.rear, height: TruckShape.truck_height },
					far: { ahead: box.roof_front, height: TruckShape.truck_height },
				},
			),
		},
	)
}

windshield : TruckShape.TruckSetting -> Polygon.FlatPolygon
windshield = |truck| {
	box = TruckShape.truck_box
	face(
		truck,
		{
			color: body_color,
			corners: TruckShape.strip_corners(
				{ left: box.left, right: box.right },
				{
					near: { ahead: box.roof_front, height: TruckShape.truck_height },
					far: { ahead: box.nose, height: TruckShape.hood_height },
				},
			),
		},
	)
}

nose : TruckShape.TruckSetting -> Polygon.FlatPolygon
nose = |truck| {
	box = TruckShape.truck_box
	face(
		truck,
		{
			color: body_color,
			corners: TruckShape.strip_corners(
				{ left: box.left, right: box.right },
				{
					near: { ahead: box.nose, height: TruckShape.hood_height },
					far: { ahead: box.nose, height: TruckShape.cab_bottom },
				},
			),
		},
	)
}

## The tire on the axle `axle` ahead of the trailer's centre, on the side
## `rightward` of its centre line: a circle standing on the road.
tire : TruckShape.TruckSetting, { axle : Distance, rightward : Distance } -> Polygon.FlatPolygon
tire = |truck, { axle, rightward }| {
	radius = TruckShape.tire_radius
	face(
		truck,
		{
			color: tire_color,
			corners: TruckShape.circle_angles(tire_sides).map(
				|angle| {
					ahead: axle.plus(radius.times(angle.cos())),
					rightward,
					height: radius.plus(radius.times(angle.sin())),
				},
			),
		},
	)
}
