## Table is the long table and the chairs around it: where each robot's chair
## stands, where each robot sets its dish down, and the shapes of the
## tablecloth, the plates and the chairs. It is laid out in the backyard's
## metres, the guest's chair at the origin and the table running away from it.
import lib.Brush
import lib.Eye
import lib.RgbColor
import lib.Shapes
import Robot
import View

Table :: [].{

	## The tabletop's height and its extent, in metres.
	top_height : F64
	top_height = 0.76

	near_end : F64
	near_end = 0.45

	far_end : F64
	far_end = 6.1

	half_width : F64
	half_width = 0.55

	## The chair each robot comes to: where it stands, how high its seat is,
	## and whether it has a back.
	chair_of : Robot.Build -> {
		right : F64,
		forward : F64,
		seat_height : F64,
		back : [HighBack, Stool],
	}
	chair_of = |build|
		match build {
			Tall => {
				right: -1.02,
				forward: 5.2,
				seat_height: 0.48,
				back: HighBack,
			}
			Round => {
				right: -1.02,
				forward: 3.9,
				seat_height: 0.24,
				back: HighBack,
			}
			Tiny => {
				right: -1.08,
				forward: 2.6,
				seat_height: 0.42,
				back: Stool,
			}
		}

	## Where each robot sets its dish, on the tabletop.
	dish_spot : Robot.Build -> Eye.At
	dish_spot = |build|
		match build {
			Tall => {
				right: -0.2,
				forward: 5.5,
				height: top_height,
			}
			Round => {
				right: -0.22,
				forward: 4.2,
				height: top_height,
			}
			Tiny => {
				right: -0.24,
				forward: 2.95,
				height: top_height,
			}
		}

	## The table's shadow on the lawn, which goes under everything at the table.
	shadow_shapes : View -> List(Shapes.Shape)
	shadow_shapes = |view|
		view.region_shapes({
			corners: ground_rectangle_corners({
				left: -0.8,
				right: 0.8,
				near: near_end - 0.2,
				far: far_end + 0.3,
			}),
			fill: Flat({ ..Brush.opaque_rgba(RgbColor.of(0x10160E)), a: 0.45 }),
		})

	## A chair, seat and back, or a stool, pulled out from its place by
	## `pulled` metres, away from the table. Its back is on the side away from
	## the table, so a robot sitting in it faces the table.
	chair_shapes : View, { build : Robot.Build, pulled : F64 } -> List(Shapes.Shape)
	chair_shapes = |view, { build, pulled }| {
		placed = chair_of(build)
		chair = { ..placed, right: placed.right - pulled }
		half = 0.21
		leg_spots = [
			{ right: chair.right - half + 0.03, forward: chair.forward - half + 0.03 },
			{ right: chair.right + half - 0.03, forward: chair.forward - half + 0.03 },
			{ right: chair.right - half + 0.03, forward: chair.forward + half - 0.03 },
			{ right: chair.right + half - 0.03, forward: chair.forward + half - 0.03 },
		]
		legs = leg_spots.map(
			|spot|
				view.line_shapes({
					from: {
						right: spot.right,
						forward: spot.forward,
						height: 0.0,
					},
					to: {
						right: spot.right,
						forward: spot.forward,
						height: chair.seat_height,
					},
					width: 0.04,
					fill: wood_dark,
				}),
		).join()
		seat = view.region_shapes({
			corners: [
				{
					right: chair.right - half,
					forward: chair.forward - half,
					height: chair.seat_height,
				},
				{
					right: chair.right + half,
					forward: chair.forward - half,
					height: chair.seat_height,
				},
				{
					right: chair.right + half,
					forward: chair.forward + half,
					height: chair.seat_height,
				},
				{
					right: chair.right - half,
					forward: chair.forward + half,
					height: chair.seat_height,
				},
			],
			fill: wood,
		})
		back =
			match chair.back {
				HighBack =>
					view.region_shapes({
						corners: [
							{
								right: chair.right - half,
								forward: chair.forward - half,
								height: chair.seat_height,
							},
							{
								right: chair.right - half,
								forward: chair.forward + half,
								height: chair.seat_height,
							},
							{
								right: chair.right - half,
								forward: chair.forward + half,
								height: chair.seat_height + 0.62,
							},
							{
								right: chair.right - half,
								forward: chair.forward - half,
								height: chair.seat_height + 0.62,
							},
						],
						fill: wood_dark,
					})
				Stool => []
			}
		List.concat(List.concat(back, legs), seat)
	}

	## The tablecloth, its runner, the near legs under it and a plate at each
	## place.
	top_shapes : View -> List(Shapes.Shape)
	top_shapes = |view| {
		apron_bottom = top_height - 0.22
		legs = [-0.48, 0.48].map(
			|right|
				view.line_shapes({
					from: {
						right,
						forward: near_end + 0.1,
						height: 0.0,
					},
					to: {
						right,
						forward: near_end + 0.1,
						height: apron_bottom,
					},
					width: 0.06,
					fill: wood_dark,
				}),
		).join()
		apron = view.region_shapes({
			corners: [
				{
					right: -0.57,
					forward: near_end,
					height: top_height,
				},
				{
					right: 0.57,
					forward: near_end,
					height: top_height,
				},
				{
					right: 0.57,
					forward: near_end,
					height: apron_bottom,
				},
				{
					right: -0.57,
					forward: near_end,
					height: apron_bottom,
				},
			],
			fill: cloth_shade,
		})
		cloth = view.region_shapes({
			corners: top_rectangle_corners({
				left: -0.57,
				right: 0.57,
				near: near_end,
				far: far_end,
			}),
			fill: cloth_top,
		})
		runner = view.region_shapes({
			corners: top_rectangle_corners({
				left: -0.14,
				right: 0.14,
				near: near_end + 0.15,
				far: far_end - 0.15,
			}),
			fill: runner_red,
		})
		plates = places.map(|spot| plate_shapes(view, spot)).join()
		List.concat(List.concat(List.concat(List.concat(legs, apron), cloth), runner), plates)
	}
}

# A place at the table: the guest's own at the near end, and the robots'.
places : List({ right : F64, forward : F64 })
places = [
	{ right: -0.3, forward: 0.78 },
	{ right: -0.38, forward: 2.6 },
	{ right: -0.38, forward: 3.9 },
	{ right: -0.38, forward: 5.2 },
]

# A plate is a circle on the cloth, so the eye sees it as an oval.
plate_shapes : View, { right : F64, forward : F64 } -> List(Shapes.Shape)
plate_shapes = |view, spot| {
	rim = circle_points({
		right: spot.right,
		forward: spot.forward,
		radius: 0.13,
	})
	middle = circle_points({
		right: spot.right,
		forward: spot.forward,
		radius: 0.085,
	})
	List.concat(
		view.region_shapes({ corners: rim, fill: plate_rim }),
		view.region_shapes({ corners: middle, fill: plate_white }),
	)
}

circle_points : {
	right : F64,
	forward : F64,
	radius : F64,
} -> List(Eye.At)
circle_points = |{ right, forward, radius }| {
	sides : U64
	sides = 18
	var $out = List.with_capacity(sides)
	for k in 0..<sides {
		angle = F64.tau * k.to_f64() / sides.to_f64()
		$out = $out.append({
			right: right + radius * angle.cos(),
			forward: forward + radius * angle.sin(),
			height: Table.top_height + 0.004,
		})
	}
	$out
}

top_rectangle_corners : {
	left : F64,
	right : F64,
	near : F64,
	far : F64,
} -> List(Eye.At)
top_rectangle_corners = |{ left, right, near, far }| [
	{
		right: left,
		forward: near,
		height: Table.top_height,
	},
	{ right, forward: near, height: Table.top_height },
	{ right, forward: far, height: Table.top_height },
	{
		right: left,
		forward: far,
		height: Table.top_height,
	},
]

ground_rectangle_corners : {
	left : F64,
	right : F64,
	near : F64,
	far : F64,
} -> List(Eye.At)
ground_rectangle_corners = |{ left, right, near, far }| [
	{
		right: left,
		forward: near,
		height: 0.0,
	},
	{ right, forward: near, height: 0.0 },
	{ right, forward: far, height: 0.0 },
	{
		right: left,
		forward: far,
		height: 0.0,
	},
]

wood : Brush.Fill
wood = Brush.flat(RgbColor.of(0x8A5A33))

wood_dark : Brush.Fill
wood_dark = Brush.flat(RgbColor.of(0x5E3B20))

cloth_top : Brush.Fill
cloth_top = Brush.flat(RgbColor.of(0xEFE3C8))

cloth_shade : Brush.Fill
cloth_shade = Brush.flat(RgbColor.of(0xCDBE9F))

runner_red : Brush.Fill
runner_red = Brush.flat(RgbColor.of(0xB8562B))

plate_rim : Brush.Fill
plate_rim = Brush.flat(RgbColor.of(0xD9D2C3))

plate_white : Brush.Fill
plate_white = Brush.flat(RgbColor.of(0xFAF7F0))

# Every dish lands on the tabletop, between its ends and its edges.
expect
	[Tall, Round, Tiny].all(
		|build| {
			spot = Table.dish_spot(build)
			spot.height == Table.top_height
				and spot.forward > Table.near_end
				and spot.forward < Table.far_end
				and spot.right.abs() < Table.half_width
		},
	)

# Every chair stands off the tabletop, beside the table or past its far end.
expect
	[Tall, Round, Tiny].all(
		|build| {
			chair = Table.chair_of(build)
			chair.right.abs() > Table.half_width or chair.forward > Table.far_end
		},
	)
