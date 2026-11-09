## What the truck looks like, in its own frame and nowhere in the world: its
## size, its colors and its faces. It's blue, a navy body with darker sides
## and a lighter roof, on near-black tires. TruckPlacement stands it at its
## spot, and TruckBody, TruckHeadlights and TruckBrakeLights draw from these.
import Distance
import Fraction
import lib.RgbColor

TruckShape :: [].{

	## The box the truck fills, in the truck's own frame. Four offsets run
	## ahead of the trailer's center, from the back of the trailer to the front
	## of the cab, so `rear` is negative. The two sides are offsets to the
	## right of the trailer's center line, so `left` is negative. The cab's flat
	## roof ends at `roof_front`, where its windshield slopes down to the nose.
	TruckBox : {
		rear : Distance,
		trailer_front : Distance,
		roof_front : Distance,
		nose : Distance,
		left : Distance,
		right : Distance,
	}

	## A point on the truck, in the truck's own frame: how far ahead of the
	## trailer's center and how far to the right of it, each negative the other
	## way, and how high above the road under the truck.
	TruckPoint : {
		ahead : Distance,
		rightward : Distance,
		height : Distance,
	}

	## A face of the truck: a color and its corners, in the truck's own frame.
	TruckFace : { color : RgbColor, corners : List(TruckShape.TruckPoint) }

	## The truck's body, its back, nose and windshield.
	body_color : RgbColor
	body_color = RgbColor.of(0x1C2E66)

	roof_color : RgbColor
	roof_color = RgbColor.of(0x3A52A8)

	side_color : RgbColor
	side_color = RgbColor.of(0x152150)

	tire_color : RgbColor
	tire_color = RgbColor.of(0x15151A)

	## The whole truck as it is built: its two sides, the trailer's back, its
	## roof, the cab's windshield and nose, then its tires.
	truck_faces : List(TruckShape.TruckFace)
	truck_faces = [
		sides,
		[trailer_back, roof, windshield, nose],
		tires,
	].join()

	## The truck's two sides, left then right. Each side is one outline, the
	## trailer and the cab together: up the back of the trailer, along its roof
	## and the cab's, down the windshield's edge and the nose, back along the
	## cab's floor, and down to the trailer's floor.
	sides : List(TruckShape.TruckFace)
	sides = {
		box = truck_box
		[box.left, box.right].map(
			|rightward| {
				color: side_color,
				corners: [
					{ ahead: box.rear, rightward, height: trailer_bottom },
					{ ahead: box.rear, rightward, height: truck_height },
					{ ahead: box.roof_front, rightward, height: truck_height },
					{ ahead: box.nose, rightward, height: hood_height },
					{ ahead: box.nose, rightward, height: cab_bottom },
					{ ahead: box.trailer_front, rightward, height: cab_bottom },
					{ ahead: box.trailer_front, rightward, height: trailer_bottom },
				],
			},
		)
	}

	## The back of the trailer, from its floor to its roof.
	trailer_back : TruckShape.TruckFace
	trailer_back = across_truck(
		body_color,
		{
			near: { ahead: truck_box.rear, height: trailer_bottom },
			far: { ahead: truck_box.rear, height: truck_height },
		},
	)

	## The roof of the trailer and the cab, one flat face.
	roof : TruckShape.TruckFace
	roof = across_truck(
		roof_color,
		{
			near: { ahead: truck_box.rear, height: truck_height },
			far: { ahead: truck_box.roof_front, height: truck_height },
		},
	)

	## The cab's windshield, sloping down from the roof to the nose. It is
	## the body's color: there is no glass.
	windshield : TruckShape.TruckFace
	windshield = across_truck(
		body_color,
		{
			near: { ahead: truck_box.roof_front, height: truck_height },
			far: { ahead: truck_box.nose, height: hood_height },
		},
	)

	## The cab's nose, from the hood down to the cab's floor.
	nose : TruckShape.TruckFace
	nose = across_truck(
		body_color,
		{
			near: { ahead: truck_box.nose, height: hood_height },
			far: { ahead: truck_box.nose, height: cab_bottom },
		},
	)

	## A tire on each side of each axle, the left side's and then the right's.
	## A tire is a circle standing on the road.
	tires : List(TruckShape.TruckFace)
	tires = {
		box = truck_box
		tire = |{ axle, rightward }| {
			color: tire_color,
			corners: TruckShape.circle_angles(tire_sides).map(
				|angle| {
					ahead: axle.plus(tire_radius.times(angle.cos())),
					rightward,
					height: tire_radius.plus(tire_radius.times(angle.sin())),
				},
			),
		}
		[
			axles.map(|axle| tire({ axle, rightward: box.left })),
			axles.map(|axle| tire({ axle, rightward: box.right })),
		].join()
	}

	truck_width : Distance
	truck_width = Distance.metres(2.4)

	truck_height : Distance
	truck_height = Distance.metres(3.6)

	cab_length : Distance
	cab_length = Distance.metres(3.5)

	tire_radius : Distance
	tire_radius = Distance.metres(0.5)

	## The trailer's floor clears the top of its tires by 12 cm.
	trailer_bottom : Distance
	trailer_bottom = tire_radius.times(2.0).plus(Distance.metres(0.12))

	## The cab's floor is level with its axle.
	cab_bottom : Distance
	cab_bottom = tire_radius

	## Where the windshield meets the nose: half the truck's height.
	hood_height : Distance
	hood_height = truck_height.divided_by(2.0)

	## How tall the trailer is, from its floor to its roof.
	trailer_height : Distance
	trailer_height = truck_height.minus(trailer_bottom)

	## The box the truck fills, in its own frame, centered where its trailer
	## is; the cab is ahead of the trailer.
	truck_box : TruckShape.TruckBox
	truck_box = {
		trailer_front = trailer_length.divided_by(2.0)
		{
			rear: trailer_length.divided_by(2.0).opposite(),
			trailer_front,
			roof_front: trailer_front.plus(cab_length.scaled_by(cab_roof_fraction)),
			nose: trailer_front.plus(cab_length),
			left: truck_width.divided_by(2.0).opposite(),
			right: truck_width.divided_by(2.0),
		}
	}

	## The four corners of a strip across the truck from `left` to `right`,
	## between its `near` edge and its `far` edge: near left, near right, far
	## right, far left.
	strip_corners : { left : Distance, right : Distance },
	{
		near : { ahead : Distance, height : Distance },
		far : { ahead : Distance, height : Distance },
	} -> List(TruckShape.TruckPoint)
	strip_corners = |{ left, right }, { near, far }| [
		{
			ahead: near.ahead,
			rightward: left,
			height: near.height,
		},
		{
			ahead: near.ahead,
			rightward: right,
			height: near.height,
		},
		{
			ahead: far.ahead,
			rightward: right,
			height: far.height,
		},
		{
			ahead: far.ahead,
			rightward: left,
			height: far.height,
		},
	]

	## The angles of the corners of a circle drawn as a polygon with
	## `corner_count` corners, going round from angle 0.
	circle_angles : I64 -> List(F64)
	circle_angles = |corner_count| List.from_iter(
		I64.until(0, corner_count),
	).map(|corner| corner.to_f64() / corner_count.to_f64() * F64.tau)
}

## A face of `color` across the whole width of the truck, between its `near`
## edge and its `far` edge.
across_truck : RgbColor,
{
	near : { ahead : Distance, height : Distance },
	far : { ahead : Distance, height : Distance },
} -> TruckShape.TruckFace
across_truck = |color, edges| {
	color,
	corners: TruckShape.strip_corners(
		{ left: TruckShape.truck_box.left, right: TruckShape.truck_box.right },
		edges,
	),
}

trailer_length : Distance
trailer_length = Distance.metres(8.4)

## How far forward of the trailer the cab's flat roof reaches, as a fraction
## of the cab's length, a proportion chosen by eye.
cab_roof_fraction : Fraction
cab_roof_fraction = Fraction.of(0.3)

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

expect
	TruckShape.strip_corners(
		{ left: Distance.metres(-1.0), right: Distance.metres(1.0) },
		{
			near: { ahead: Distance.metres(2.0), height: Distance.metres(3.0) },
			far: { ahead: Distance.metres(5.0), height: Distance.metres(7.0) },
		},
	).map(
		|corner| (
			corner.ahead.to_metres(),
			corner.rightward.to_metres(),
			corner.height.to_metres(),
		),
	)
		== [
			(2.0, -1.0, 3.0),
			(2.0, 1.0, 3.0),
			(5.0, 1.0, 7.0),
			(5.0, -1.0, 7.0),
		]

# The truck is its two sides, its back, roof, windshield and nose, and a tire
# on each side of each of its five axles.
expect TruckShape.truck_faces.len() == 16
