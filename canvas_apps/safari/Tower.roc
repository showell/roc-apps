## A radio tower: a square lattice that tapers from a 12 m footprint to a
## point 80 m up. It is drawn as rods (four legs, a ring every 20 m, and
## crossed braces in the lowest two storeys) with a blinking beacon on top.
## The earth curves away under a far tower, so it sinks below the horizon
## from the bottom up.
import Pixels
import Across
import Along
import Angle
import Camera
import RoadAhead
import Distance
import Fraction
import Geom
import Picture
import Polygon
import lib.Brush
import lib.RgbColor
import Screen
import lib.Shapes
import World

## A tower in a frame: how it is turned, and how bright its beacon is.
Tower := { yaw : Angle.Turn, beacon_brightness : Fraction }.{

	## A corner of the tower's square footprint, as seen along the route.
	Corner : [BackLeft, BackRight, FrontRight, FrontLeft]

	## Where the footprint's four corners stand in the rider's view.
	Footprint : {
		back_left : Geom.RiderPoint,
		back_right : Geom.RiderPoint,
		front_right : Geom.RiderPoint,
		front_left : Geom.RiderPoint,
	}

	## How a tower looks. Its footprint is measured on the road, so the road and
	## where it stands there are its context.
	scenery_picture : Tower, Picture.Setting(RoadAhead.RoadContext) -> Picture
	scenery_picture = |tower, { foot, cam_focal, context }| {
		footprint = Tower.tower_footprint(tower, context)
		Picture.from_shapes(Tower.tower_shapes(tower, { foot, cam_focal, context: footprint }))
	}

	## Where a tower's four footprint corners stand in the rider's view.
	tower_footprint : Tower, RoadAhead.RoadContext -> Tower.Footprint
	tower_footprint = |tower, { road, place, along, across }| {
		corner_point = |corner| {
			on_road = base_corner_on_road(corner, { along, across, yaw: tower.yaw })
			RoadAhead.rider_point_at(road, { place, along: on_road.along, across: on_road.across })
		}
		{
			back_left: corner_point(BackLeft),
			back_right: corner_point(BackRight),
			front_right: corner_point(FrontRight),
			front_left: corner_point(FrontLeft),
		}
	}

	## The whole tower, once its footprint is in the rider's view: legs, rings,
	## braces and beacon, in that order. A tower sunk wholly below the horizon
	## has no shapes.
	tower_shapes : Tower, Picture.Setting(Tower.Footprint) -> List(Shapes.Shape)
	tower_shapes = |tower, { foot, cam_focal, context: footprint }| {
		sunk = sunk_below_horizon(foot.to_rider())
		if sunk >= tower_height {
			[]
		} else {
			sunk_tower = {
				footprint,
				foot,
				sunk,
				rod_width_on_screen: rod_width_at({ at: foot, cam_focal }),
				cam_focal,
			}
			apex = foot.at_height(tower_height.minus(sunk))
			[
				legs(sunk_tower, apex.to_raised()),
				rings(sunk_tower),
				braces(sunk_tower),
				beacon_shapes(sunk_tower, { apex, brightness: tower.beacon_brightness }),
			].join()
		}
	}

	## How far a corner lies from the footprint's centre, across the route and
	## along it. Left and back are the negative ways.
	corner_offset : Tower.Corner -> { across : Distance, along : Distance }
	corner_offset = |corner|
		match corner {
			BackLeft => { across: tower_half_width.opposite(), along: tower_half_width.opposite() }
			BackRight => { across: tower_half_width, along: tower_half_width.opposite() }
			FrontRight => { across: tower_half_width, along: tower_half_width }
			FrontLeft => { across: tower_half_width.opposite(), along: tower_half_width }
		}
}

tower_height : Distance
tower_height = Distance.metres(80.0)

tower_half_width : Distance
tower_half_width = Distance.metres(6.0)

storey_height : Distance
storey_height = Distance.metres(20.0)

brace_storeys : U64
brace_storeys = 2

rod_half_width : Distance
rod_half_width = Distance.metres(0.12)

rod_width : Distance
rod_width = rod_half_width.times(2.0)

tower_metal : RgbColor
tower_metal = RgbColor.of(0x9AA0A8)

## The radius a far tower sinks over, which hides it wholly at 1.8 km. It
## is tighter than `Ground.ground_curve_radius`, so a tower sinks visibly as
## it recedes: on the ground's curve it would stay in view to 4 km.
sink_radius : Distance
sink_radius = Distance.metres(20000.0)

beacon_radius : Distance
beacon_radius = Distance.metres(3.0)

beacon_color : RgbColor
beacon_color = RgbColor.of(0xFF2FE6)

## The dimmest beacon that is drawn. A dimmer one would tint the sky by less
## than one part in fifty, too little to see; the figure was chosen by eye.
dimmest_beacon : Fraction
dimmest_beacon = Fraction.of(0.02)

## The smallest beacon radius that is drawn. A disc under a pixel across
## covers no pixel whole, so a far beacon is left out rather than drawn as a
## speck.
smallest_beacon_radius : Pixels
smallest_beacon_radius = Pixels.of(0.5)

## One tower, as its shapes are worked out: where its footprint and foot
## stand, how far the earth's curve has sunk it, which is never negative,
## and how its rods look on screen.
TowerSetting : {
	footprint : Tower.Footprint,
	foot : Geom.LevelPoint,
	sunk : Distance,
	rod_width_on_screen : Pixels,
	cam_focal : Pixels,
}

## The corners in drawing order, going round the square.
corners : List(Tower.Corner)
corners = [BackLeft, BackRight, FrontRight, FrontLeft]

## The corner after this one, going round the square.
next_corner : Tower.Corner -> Tower.Corner
next_corner = |corner|
	match corner {
		BackLeft => BackRight
		BackRight => FrontRight
		FrontRight => FrontLeft
		FrontLeft => BackLeft
	}

footprint_corner : Tower.Footprint, Tower.Corner -> Geom.RiderPoint
footprint_corner = |footprint, corner|
	match corner {
		BackLeft => footprint.back_left
		BackRight => footprint.back_right
		FrontRight => footprint.front_right
		FrontLeft => footprint.front_left
	}

## Where a footprint corner stands on the map, for a tower centred at
## `along` and `across` and turned by `yaw`.
base_corner_on_road : Tower.Corner,
{
	along : Along,
	across : Across,
	yaw : Angle.Turn,
} -> Geom.RoadPoint
base_corner_on_road = |corner, { along, across, yaw }| {
	offset = Tower.corner_offset(corner)
	du = offset.across.to_metres()
	dv = offset.along.to_metres()
	cy = yaw.to_radians().cos()
	sy = yaw.to_radians().sin()
	{
		along: along.plus(Distance.metres(du * sy + dv * cy)),
		across: across.plus(Distance.metres(du * cy - dv * sy)),
	}
}

## How far the earth's curve hides the bottom of a tower standing at `p`.
sunk_below_horizon : Geom.RiderPoint -> Distance
sunk_below_horizon = |p| {
	r = p.right.to_metres()
	f = p.forward.to_metres()
	Distance.metres((r * r + f * f) / (2.0 * sink_radius.to_metres()))
}

## A corner of the tower at `height_on_tower`: drawn in toward the foot as
## the tower tapers, and lowered by how far the tower has sunk.
corner_at : TowerSetting, { corner : Tower.Corner, height_on_tower : Distance } -> Geom.RaisedPoint
corner_at = |tower, { corner, height_on_tower }| {
	t = height_on_tower.ratio_to(tower_height)
	bottom = footprint_corner(tower.footprint, corner)
	tapered = |start, end| start.plus(end.minus(start).times(t))
	{
		right: tapered(bottom.right, tower.foot.right()),
		forward: tapered(bottom.forward, tower.foot.forward()),
		height: height_on_tower.minus(tower.sunk),
	}
}

## A rod between two points on screen, `width` wide.
screen_rod : {
	from : Screen.Point,
	to : Screen.Point,
	width : Pixels,
} -> Shapes.Shape
screen_rod = |{ from, to, width }| {
	dx = to.x.minus(from.x).to_f64()
	dy = to.y.minus(from.y).to_f64()
	across = width.to_f64()
	raw = (dx * dx + dy * dy).sqrt()
	len = if raw < 0.0001 {
		1.0
	} else {
		raw
	}
	rod_quad({
		from,
		to,
		offset_x: Pixels.of(across * ((0.0 - dy) / len) / 2.0),
		offset_y: Pixels.of(across * (dx / len) / 2.0),
	})
}

## The quad of a rod from `from` to `to`, its sides `offset_x` and
## `offset_y` either side of the line between them.
rod_quad : {
	from : Screen.Point,
	to : Screen.Point,
	offset_x : Pixels,
	offset_y : Pixels,
} -> Shapes.Shape
rod_quad = |
	{
		from: a,
		to: b,
		offset_x: ox,
		offset_y: oy,
	},
| Polygon.flat_polygon(
	tower_metal,
	[
		{ x: a.x.plus(ox), y: a.y.plus(oy) },
		{ x: b.x.plus(ox), y: b.y.plus(oy) },
		{ x: b.x.minus(ox), y: b.y.minus(oy) },
		{ x: a.x.minus(ox), y: a.y.minus(oy) },
	],
)

## A rod between two points in the rider's view, cut where it crosses the
## near plane. A rod wholly behind the near plane has no shape.
rod_shape : TowerSetting,
{
	from : Geom.RaisedPoint,
	to : Geom.RaisedPoint,
} -> Try(Shapes.Shape, [BehindCamera])
rod_shape = |tower, line| {
	ahead = Geom.ahead_line(line)?
	Ok(
		screen_rod({
			from: Camera.project(ahead.from, tower.cam_focal),
			to: Camera.project(ahead.to, tower.cam_focal),
			width: tower.rod_width_on_screen,
		}),
	)
}

## How many pixels one metre across spans as far ahead as `at`.
metre_on_screen : { at : Geom.LevelPoint, cam_focal : Pixels } -> Pixels
metre_on_screen = |{ at, cam_focal }| {
	on_level = at.at_height(Distance.zero)
	p1 = Camera.project(on_level.at_right(Distance.metres(1.0)), cam_focal)
	p0 = Camera.project(on_level.at_right(Distance.zero), cam_focal)
	p1.x.minus(p0.x)
}

## A rod's width on screen as far ahead as `at`.
rod_width_at : { at : Geom.LevelPoint, cam_focal : Pixels } -> Pixels
rod_width_at = |camera| metre_on_screen(camera).times(rod_width.to_metres())

## The four legs, from the footprint's corners up to the apex.
legs : TowerSetting, Geom.RaisedPoint -> List(Shapes.Shape)
legs = |tower, apex| corners.keep_oks(
	|corner| rod_shape(
		tower,
		{ from: corner_at(tower, { corner, height_on_tower: tower.sunk }), to: apex },
	),
)

## The ring of rods round the tower at height `h`.
ring_shapes : TowerSetting, Distance -> List(Shapes.Shape)
ring_shapes = |tower, h| corners.keep_oks(
	|corner| rod_shape(
		tower,
		{
			from: corner_at(tower, { corner, height_on_tower: h }),
			to: corner_at(tower, { corner: next_corner(corner), height_on_tower: h }),
		},
	),
)

## A ring at every storey below the top, bottom first, leaving out those
## the earth has hidden.
rings : TowerSetting -> List(Shapes.Shape)
rings = |tower| ring_heights.join_map(
	|h|
		if h <= tower.sunk {
			[]
		} else {
			ring_shapes(tower, h)
		},
)

## The height of each ring: a storey up, and a storey more, to the top.
ring_heights : List(Distance)
ring_heights = {
	var $heights = []
	var $height = storey_height
	while $height < tower_height {
		$heights = $heights.append($height)
		$height = $height.plus(storey_height)
	}
	$heights
}

## The crossed braces of the lowest storeys, bottom first. A storey the
## earth has partly hidden starts its braces at the horizon.
braces : TowerSetting -> List(Shapes.Shape)
braces = |tower|
	List.from_iter(U64.until(0, brace_storeys)).join_map(|storey| storey_shapes(tower, storey))

storey_shapes : TowerSetting, U64 -> List(Shapes.Shape)
storey_shapes = |tower, storey| {
	storey_bottom = storey_height.times(storey.to_f64())
	storey_top = storey_bottom.plus(storey_height)
	if storey_top <= tower.sunk {
		[]
	} else {
		hidden_height = storey_bottom.max(tower.sunk).minus(storey_bottom)
		hidden_fraction = Fraction.of(hidden_height.ratio_to(storey_height))
		corners.join_map(
			|corner| brace_shapes(tower, { corner, storey_bottom, storey_top, hidden_fraction }),
		)
	}
}

## The two braces crossing the face from `corner` to the next corner: one
## rising each way.
brace_shapes : TowerSetting,
{
	corner : Tower.Corner,
	storey_bottom : Distance,
	storey_top : Distance,
	hidden_fraction : Fraction,
} -> List(Shapes.Shape)
brace_shapes = |tower, { corner, storey_bottom, storey_top, hidden_fraction }| {
	next = next_corner(corner)
	brace_up = {
		from: Geom.point_between({
			from: corner_at(tower, { corner, height_on_tower: storey_bottom }),
			to: corner_at(tower, { corner: next, height_on_tower: storey_top }),
			fraction: hidden_fraction,
		}),
		to: corner_at(tower, { corner: next, height_on_tower: storey_top }),
	}
	brace_down = {
		from: Geom.point_between({
			from: corner_at(tower, { corner: next, height_on_tower: storey_bottom }),
			to: corner_at(tower, { corner, height_on_tower: storey_top }),
			fraction: hidden_fraction,
		}),
		to: corner_at(tower, { corner, height_on_tower: storey_top }),
	}
	[brace_up, brace_down].keep_oks(|brace| rod_shape(tower, brace))
}

## The beacon on the apex, at its brightness; too dim or too small, it
## isn't drawn.
beacon_shapes : TowerSetting,
{
	apex : Geom.AheadPoint,
	brightness : Fraction,
} -> List(Shapes.Shape)
beacon_shapes = |tower, { apex, brightness }| {
	apex_on_screen = Camera.project(apex, tower.cam_focal)
	if brightness < dimmest_beacon {
		[]
	} else {
		one_metre = metre_on_screen({ at: tower.foot, cam_focal: tower.cam_focal })
		radius = one_metre.times(beacon_radius.to_metres())
		if radius < smallest_beacon_radius {
			[]
		} else {
			disc_shapes({
				beacon_color,
				beacon_center: apex_on_screen,
				beacon_radius: radius,
				beacon_alpha: brightness,
			})
		}
	}
}

## A beacon's disc, as a value: a list of one shape, seen through as far as
## `beacon_alpha` says.
disc_shapes : {
	beacon_color : RgbColor,
	beacon_center : Screen.Point,
	beacon_radius : Pixels,
	beacon_alpha : Fraction,
} -> List(Shapes.Shape)
disc_shapes = |
	{
		beacon_color: color,
		beacon_center: center,
		beacon_radius: radius,
		beacon_alpha: alpha,
	},
| {
	opaque = Brush.opaque(color)
	[
		Disc({
			x: center.x.to_f64(),
			y: center.y.to_f64(),
			radius: radius.to_f64(),
			fill: Flat({ ..opaque, a: alpha.to_f64() }),
		}),
	]
}

expect
	disc_shapes({
		beacon_color: RgbColor.of(7),
		beacon_center: Screen.point(1.0, 2.0),
		beacon_radius: Pixels.of(3.0),
		beacon_alpha: Fraction.of(0.5),
	}).len()
		== 1

expect
	disc_shapes({
		beacon_color: RgbColor.of(333),
		beacon_center: Screen.point(10.0, 20.0),
		beacon_radius: Pixels.of(30.0),
		beacon_alpha: Fraction.of(0.25),
	})
		== [
			Disc({
				x: 10.0,
				y: 20.0,
				radius: 30.0,
				fill: Flat({ ..Brush.opaque(RgbColor.of(333)), a: 0.25 }),
			}),
		]

# The first three segments, seen from the start of the route.
start_road : RoadAhead.RoadView
start_road = {
	route_segments: [0, 1, 2].map(World.route_segment),
	segments_ahead: [0, 1, 2].map(World.SegmentIndex.number),
	vantage: {
		along: Along.metres(0.0),
		across: Across.metres(0.0),
		yaw: Angle.straight_ahead,
	},
}

# A tower that isn't turned, its beacon dark.
plain_tower : Tower
plain_tower = { yaw: Angle.straight_ahead, beacon_brightness: Fraction.zero }

# The start of the route, and a place `along` metres down the first segment, 20 m
# right of the road's middle.
context_along : F64 -> RoadAhead.RoadContext
context_along = |along| {
	road: start_road,
	place: Ahead(RoadAhead.Position.first),
	along: Along.metres(along),
	across: Across.metres(20.0),
}

# The shapes of a tower standing there, seen from the start of the route.
shapes_of_tower_along : F64 -> List(Shapes.Shape)
shapes_of_tower_along = |along|
	plain_tower.scenery_picture({
		foot: ahead({ right: Distance.metres(20.0), forward: Distance.metres(along) }),
		cam_focal: Pixels.of(500.0),
		context: context_along(along),
	}).to_shapes()

## `point` on the rider's level and past the near plane, which every such
## point in these tests is.
ahead : Geom.RiderPoint -> Geom.LevelPoint
ahead = |point| Geom.ahead_on_level(point) ?? crash "a test's point is past the near plane"

expect {
	footprint = Tower.tower_footprint(plain_tower, context_along(200.0))
	[
		(footprint.back_left.forward.to_metres(), 194.0),
		(footprint.front_right.forward.to_metres(), 206.0),
		(footprint.back_left.right.to_metres(), 14.0),
		(footprint.back_right.right.to_metres(), 26.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)
}

expect shapes_of_tower_along(200.0).len() > 0
expect shapes_of_tower_along(1000.0).len() > 0

expect tower_height.to_metres() == 80.0
expect tower_half_width.to_metres() == 6.0
expect storey_height.to_metres() == 20.0
expect rod_half_width.to_metres() == 0.12
expect rod_width.to_metres() == 0.24
expect sink_radius.to_metres() == 20000.0
expect beacon_radius.to_metres() == 3.0

expect brace_storeys == 2
expect tower_metal == RgbColor.of(0x9AA0A8)
expect beacon_color == RgbColor.of(0xFF2FE6)

expect
	corners.map(|corner| Tower.corner_offset(corner).across.ratio_to(tower_half_width))
		== [-1.0, 1.0, 1.0, -1.0]
expect
	corners.map(|corner| Tower.corner_offset(corner).along.ratio_to(tower_half_width))
		== [-1.0, -1.0, 1.0, 1.0]

expect {
	[
		(BackLeft, { along: 94.0, across: -6.0 }),
		(BackRight, { along: 94.0, across: 6.0 }),
		(FrontRight, { along: 106.0, across: 6.0 }),
		(FrontLeft, { along: 106.0, across: -6.0 }),
	].all(
		|(corner, want)| {
			got = base_corner_on_road(
				corner,
				{
					along: Along.metres(100.0),
					across: Across.metres(0.0),
					yaw: Angle.straight_ahead,
				},
			)
			along_miss = (got.along.to_metres() - want.along).abs()
			across_miss = (got.across.to_metres() - want.across).abs()
			along_miss <= 0.000001 and across_miss <= 0.000001
		},
	)
}

# A tower 12 m square, its foot 100 m ahead, sunk 1 m, its rods 4 px wide.
sample_tower : TowerSetting
sample_tower = {
	footprint: {
		back_left: { right: Distance.metres(-6.0), forward: Distance.metres(94.0) },
		back_right: { right: Distance.metres(6.0), forward: Distance.metres(94.0) },
		front_right: { right: Distance.metres(6.0), forward: Distance.metres(106.0) },
		front_left: { right: Distance.metres(-6.0), forward: Distance.metres(106.0) },
	},
	foot: ahead({ right: Distance.metres(0.0), forward: Distance.metres(100.0) }),
	sunk: Distance.metres(1.0),
	rod_width_on_screen: Pixels.of(4.0),
	cam_focal: Pixels.of(500.0),
}

expect
	corner_at(sample_tower, { corner: BackLeft, height_on_tower: Distance.metres(0.0) })
		== {
			right: Distance.metres(-6.0),
			forward: Distance.metres(94.0),
			height: Distance.metres(-1.0),
		}
expect
	corner_at(sample_tower, { corner: BackLeft, height_on_tower: Distance.metres(40.0) })
		== {
			right: Distance.metres(-3.0),
			forward: Distance.metres(97.0),
			height: Distance.metres(39.0),
		}
expect
	corner_at(sample_tower, { corner: BackLeft, height_on_tower: Distance.metres(80.0) })
		== {
			right: Distance.metres(0.0),
			forward: Distance.metres(100.0),
			height: Distance.metres(79.0),
		}
expect
	corner_at(sample_tower, { corner: FrontRight, height_on_tower: Distance.metres(40.0) })
		== {
			right: Distance.metres(3.0),
			forward: Distance.metres(103.0),
			height: Distance.metres(39.0),
		}
expect
	corner_at(sample_tower, { corner: FrontRight, height_on_tower: Distance.metres(80.0) })
		== {
			right: Distance.metres(0.0),
			forward: Distance.metres(100.0),
			height: Distance.metres(79.0),
		}

expect sunk_below_horizon({
	right: Distance.metres(0.0),
	forward: Distance.metres(200.0),
}).to_metres() == 1.0
expect sunk_below_horizon({
	right: Distance.metres(100.0),
	forward: Distance.metres(100.0),
}).to_metres() == 0.5
expect sunk_below_horizon({
	right: Distance.metres(0.0),
	forward: Distance.metres(0.0),
}).to_metres() == 0.0

expect
	screen_rod({
		from: Screen.point(0.0, 0.0),
		to: Screen.point(30.0, 40.0),
		width: Pixels.of(10.0),
	})
		== Poly({
			coordinates: [-4.0, 3.0, 26.0, 43.0, 34.0, 37.0, 4.0, -3.0],
			fill: Flat(Brush.opaque(tower_metal)),
		})

# A rod of no length is still one quad, all at its one point.
expect
	screen_rod({
		from: Screen.point(5.0, 6.0),
		to: Screen.point(5.0, 6.0),
		width: Pixels.of(10.0),
	})
		== Poly({
			coordinates: [5.0, 6.0, 5.0, 6.0, 5.0, 6.0, 5.0, 6.0],
			fill: Flat(Brush.opaque(tower_metal)),
		})

## A rod's width on screen `forward` metres ahead, through a 500 px focal length.
rod_width_ahead : F64 -> F64
rod_width_ahead = |forward| {
	at = ahead({ right: Distance.metres(3.0), forward: Distance.metres(forward) })
	rod_width_at({ at, cam_focal: Pixels.of(500.0) }).to_f64()
}

expect rod_width_ahead(10.0) == 12.0
expect rod_width_ahead(25.0) == 4.8
expect rod_width_ahead(50.0) == 2.4

rod_shape_along_road : F64, F64 -> Try(Shapes.Shape, [BehindCamera])
rod_shape_along_road = |start, end|
	rod_shape(
		sample_tower,
		{
			from: {
				right: Distance.metres(0.0),
				forward: Distance.metres(start),
				height: Distance.metres(0.0),
			},
			to: {
				right: Distance.metres(0.0),
				forward: Distance.metres(end),
				height: Distance.metres(0.0),
			},
		},
	)

# A rod is cut at the near plane, and one wholly behind it has no shape.
expect
	rod_shape(
		sample_tower,
		{
			from: {
				right: Distance.metres(0.0),
				forward: Distance.metres(10.0),
				height: Distance.metres(0.0),
			},
			to: {
				right: Distance.metres(1.0),
				forward: Distance.metres(20.0),
				height: Distance.metres(0.0),
			},
		},
	).is_ok()
expect rod_shape_along_road(0.0, 0.8).is_ok()
expect rod_shape_along_road(0.8, 0.0).is_ok()
expect rod_shape_along_road(0.0, 0.2) == Err(BehindCamera)
