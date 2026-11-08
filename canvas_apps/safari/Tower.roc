## A radio tower: a square lattice that tapers from a 12 m footprint to a
## point 80 m up. It is drawn as rods (four legs, a ring every 20 m, and
## crossed braces in the lowest two storeys) with a blinking beacon on top.
## The earth curves away under a far tower, so it sinks below the horizon
## from the bottom up.
import Pixels
import Angle
import Camera
import EarthCurve
import RoadAhead
import Spot
import Distance
import Fraction
import Geom
import RiderView
import Picture
import Polygon
import lib.Brush
import lib.RgbColor
import Screen
import lib.Shapes

## A tower in a frame: how it is turned, and how bright its beacon is.
Tower := { yaw : Angle.Turn, beacon_brightness : Fraction }.{

	## How a tower looks. Its footprint is measured on the road and seen from the
	## camera's vantage, so those are its context.
	scenery_picture : Tower,
	Picture.Setting(
		{ road : RoadAhead.RoadView, vantage : Geom.Vantage },
	) -> Picture
	scenery_picture = |tower, { spot, focal_length, context: { road, vantage } }| {
		footprint = tower_footprint(tower, { road, vantage, spot })
		Picture.from_shapes(tower_shapes(tower, { footprint, spot, focal_length }))
	}

}

## A corner of the tower's square footprint, as seen along the route.
Corner : [BackLeft, BackRight, FrontRight, FrontLeft]

## Where the footprint's four corners stand in the rider's view.
Footprint : {
	back_left : RiderView.RiderPoint,
	back_right : RiderView.RiderPoint,
	front_right : RiderView.RiderPoint,
	front_left : RiderView.RiderPoint,
}

## Where the four footprint corners of a tower standing at `spot` on `road`
## are in the view of the camera at `vantage`.
tower_footprint : Tower,
{
	road : RoadAhead.RoadView,
	vantage : Geom.Vantage,
	spot : Spot,
} -> Footprint
tower_footprint = |tower, { road, vantage, spot }| {
	center = spot.road_point()
	corner_point = |corner| {
		on_road = base_corner_on_road(corner, { center, yaw: tower.yaw })
		RoadAhead.rider_point_at(road, { vantage, place: spot.place(), road_point: on_road })
	}
	{
		back_left: corner_point(BackLeft),
		back_right: corner_point(BackRight),
		front_right: corner_point(FrontRight),
		front_left: corner_point(FrontLeft),
	}
}

## The whole tower standing on `footprint`: legs, rings, braces and beacon, in
## that order. A tower sunk wholly below the horizon has no shapes.
tower_shapes : Tower,
{
	footprint : Footprint,
	spot : Spot,
	focal_length : Pixels,
} -> List(Shapes.Shape)
tower_shapes = |tower, { footprint, spot, focal_length }| {
	foot = spot.foot()
	lift = spot.lift()
	sunk = EarthCurve.exaggerated_drop(foot.to_rider())
	if sunk >= tower_height {
		[]
	} else {
		sunk_tower = {
			footprint,
			foot,
			lift,
			sunk,
			metre_on_screen: metre_on_screen({ at: foot, focal_length }),
			focal_length,
		}
		apex = foot.at_height(lift.plus(tower_height.minus(sunk)))
		rods = [
			leg_shapes(sunk_tower, apex.to_raised()),
			ring_shapes(sunk_tower),
			brace_shapes(sunk_tower),
		].join()
		match beacon_shape(sunk_tower, { apex, brightness: tower.beacon_brightness }) {
			Ok(beacon) => rods.append(beacon)
			Err(TooDim) | Err(TooSmall) => rods
		}
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
## stand, how high off the ground it is, how far the earth's curve has sunk
## it, which is never negative, and how many pixels a metre across spans as
## far ahead as its foot, which sizes its rods and its beacon.
SunkTower : {
	footprint : Footprint,
	foot : RiderView.RiderPointAhead,
	lift : Distance,
	sunk : Distance,
	metre_on_screen : Pixels,
	focal_length : Pixels,
}

## How far a corner lies from the footprint's centre, across the route and
## along it. Left and back are the negative ways.
corner_offset : Corner -> { across : Distance, along : Distance }
corner_offset = |corner|
	match corner {
		BackLeft => { across: tower_half_width.opposite(), along: tower_half_width.opposite() }
		BackRight => { across: tower_half_width, along: tower_half_width.opposite() }
		FrontRight => { across: tower_half_width, along: tower_half_width }
		FrontLeft => { across: tower_half_width.opposite(), along: tower_half_width }
	}

## The corners in drawing order, going round the square.
corners : List(Corner)
corners = [BackLeft, BackRight, FrontRight, FrontLeft]

## The corner after this one, going round the square.
next_corner : Corner -> Corner
next_corner = |corner|
	match corner {
		BackLeft => BackRight
		BackRight => FrontRight
		FrontRight => FrontLeft
		FrontLeft => BackLeft
	}

footprint_corner : Footprint, Corner -> RiderView.RiderPoint
footprint_corner = |footprint, corner|
	match corner {
		BackLeft => footprint.back_left
		BackRight => footprint.back_right
		FrontRight => footprint.front_right
		FrontLeft => footprint.front_left
	}

## Where a footprint corner stands on the map, for a tower centred at
## `center` and turned by `yaw`.
base_corner_on_road : Corner, { center : Geom.RoadPoint, yaw : Angle.Turn } -> Geom.RoadPoint
base_corner_on_road = |corner, { center, yaw }| {
	offset = corner_offset(corner)
	du = offset.across.to_metres()
	dv = offset.along.to_metres()
	cy = yaw.to_radians().cos()
	sy = yaw.to_radians().sin()
	{
		along: center.along.plus(Distance.metres(du * sy + dv * cy)),
		across: center.across.plus(Distance.metres(du * cy - dv * sy)),
	}
}

## A corner of the tower at `height_on_tower`: drawn in toward the foot as
## the tower tapers, raised by the tower's lift, and lowered by how far the
## tower has sunk.
corner_at : SunkTower, { corner : Corner, height_on_tower : Distance } -> RiderView.RaisedPoint
corner_at = |tower, { corner, height_on_tower }| {
	t = height_on_tower.ratio_to(tower_height)
	bottom = footprint_corner(tower.footprint, corner)
	tapered = |start, end| start.plus(end.minus(start).times(t))
	{
		right: tapered(bottom.right, tower.foot.right()),
		forward: tapered(bottom.forward, tower.foot.forward()),
		height: tower.lift.plus(height_on_tower.minus(tower.sunk)),
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
	raw = Screen.distance({ from, to }).to_f64()
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
	[
		{ x: a.x.plus(ox), y: a.y.plus(oy) },
		{ x: b.x.plus(ox), y: b.y.plus(oy) },
		{ x: b.x.minus(ox), y: b.y.minus(oy) },
		{ x: a.x.minus(ox), y: a.y.minus(oy) },
	],
	tower_metal,
)

## A rod between two points in the rider's view, cut where it crosses the
## near plane. A rod wholly behind the near plane has no shape.
rod_shape : SunkTower,
{
	from : RiderView.RaisedPoint,
	to : RiderView.RaisedPoint,
} -> Try(Shapes.Shape, [BehindCamera])
rod_shape = |tower, line| {
	ahead = RiderView.ahead_line(line)?
	Ok(
		screen_rod({
			from: Camera.project(ahead.from, tower.focal_length),
			to: Camera.project(ahead.to, tower.focal_length),
			width: tower.metre_on_screen.times(rod_width.to_metres()),
		}),
	)
}

## How many pixels one metre across spans as far ahead as `at`.
metre_on_screen : { at : RiderView.RiderPointAhead, focal_length : Pixels } -> Pixels
metre_on_screen = |{ at, focal_length }| {
	on_level = at.at_height(Distance.zero)
	p1 = Camera.project(on_level.at_right(Distance.metres(1.0)), focal_length)
	p0 = Camera.project(on_level.at_right(Distance.zero), focal_length)
	p1.x.minus(p0.x)
}

## The four legs, from the footprint's corners up to the apex.
leg_shapes : SunkTower, RiderView.RaisedPoint -> List(Shapes.Shape)
leg_shapes = |tower, apex| corners.keep_oks(
	|corner| rod_shape(
		tower,
		{ from: corner_at(tower, { corner, height_on_tower: tower.sunk }), to: apex },
	),
)

## The ring of rods round the tower at height `h`.
ring_shapes_at : SunkTower, Distance -> List(Shapes.Shape)
ring_shapes_at = |tower, h| corners.keep_oks(
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
ring_shapes : SunkTower -> List(Shapes.Shape)
ring_shapes = |tower| ring_heights.join_map(
	|h|
		if h <= tower.sunk {
			[]
		} else {
			ring_shapes_at(tower, h)
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
brace_shapes : SunkTower -> List(Shapes.Shape)
brace_shapes = |tower|
	List.from_iter(U64.until(0, brace_storeys)).join_map(|storey| storey_shapes(tower, storey))

storey_shapes : SunkTower, U64 -> List(Shapes.Shape)
storey_shapes = |tower, storey| {
	storey_bottom = storey_height.times(storey.to_f64())
	storey_top = storey_bottom.plus(storey_height)
	if storey_top <= tower.sunk {
		[]
	} else {
		hidden_height = storey_bottom.max(tower.sunk).minus(storey_bottom)
		hidden_fraction = Fraction.of(hidden_height.ratio_to(storey_height))
		corners.join_map(
			|corner| face_brace_shapes(
				tower,
				{ corner, storey_bottom, storey_top, hidden_fraction },
			),
		)
	}
}

## The two braces crossing the face from `corner` to the next corner: one
## rising each way.
face_brace_shapes : SunkTower,
{
	corner : Corner,
	storey_bottom : Distance,
	storey_top : Distance,
	hidden_fraction : Fraction,
} -> List(Shapes.Shape)
face_brace_shapes = |tower, { corner, storey_bottom, storey_top, hidden_fraction }| {
	next = next_corner(corner)
	brace_up = {
		from: RiderView.point_between({
			from: corner_at(tower, { corner, height_on_tower: storey_bottom }),
			to: corner_at(tower, { corner: next, height_on_tower: storey_top }),
			fraction: hidden_fraction,
		}),
		to: corner_at(tower, { corner: next, height_on_tower: storey_top }),
	}
	brace_down = {
		from: RiderView.point_between({
			from: corner_at(tower, { corner: next, height_on_tower: storey_bottom }),
			to: corner_at(tower, { corner, height_on_tower: storey_top }),
			fraction: hidden_fraction,
		}),
		to: corner_at(tower, { corner, height_on_tower: storey_top }),
	}
	[brace_up, brace_down].keep_oks(|brace| rod_shape(tower, brace))
}

## The beacon on the apex, at its brightness, unless it is too dim or too
## small to draw.
beacon_shape : SunkTower,
{
	apex : RiderView.RaisedPointAhead,
	brightness : Fraction,
} -> Try(Shapes.Shape, [TooDim, TooSmall])
beacon_shape = |tower, { apex, brightness }| {
	apex_on_screen = Camera.project(apex, tower.focal_length)
	if brightness < dimmest_beacon {
		Err(TooDim)
	} else {
		radius = tower.metre_on_screen.times(beacon_radius.to_metres())
		if radius < smallest_beacon_radius {
			Err(TooSmall)
		} else {
			Ok(beacon_disc({ center: apex_on_screen, radius_on_screen: radius, brightness }))
		}
	}
}

## A beacon's disc, seen through as far as `brightness` says.
beacon_disc : {
	center : Screen.Point,
	radius_on_screen : Pixels,
	brightness : Fraction,
} -> Shapes.Shape
beacon_disc = |{ center, radius_on_screen, brightness }| {
	opaque = Brush.opaque(beacon_color)
	Disc({
		x: center.x.to_f64(),
		y: center.y.to_f64(),
		radius: radius_on_screen.to_f64(),
		fill: Flat({ ..opaque, a: brightness.to_f64() }),
	})
}

expect
	beacon_disc({
		center: Screen.point(10.0, 20.0),
		radius_on_screen: Pixels.of(30.0),
		brightness: Fraction.of(0.25),
	})
		== Disc({
			x: 10.0,
			y: 20.0,
			radius: 30.0,
			fill: Flat(Brush.with_alpha(beacon_color, 0.25)),
		})

## `point` on the rider's level and past the near plane, which every such
## point in these tests is.
ahead : RiderView.RiderPoint -> RiderView.RiderPointAhead
ahead = |point| RiderView.rider_point_ahead(point) ?? crash "a test's point is past the near plane"

# A tower 12 m square, its foot 100 m ahead, sunk 1 m, a metre 5 px across.
sample_tower : SunkTower
sample_tower = {
	footprint: {
		back_left: { right: Distance.metres(-6.0), forward: Distance.metres(94.0) },
		back_right: { right: Distance.metres(6.0), forward: Distance.metres(94.0) },
		front_right: { right: Distance.metres(6.0), forward: Distance.metres(106.0) },
		front_left: { right: Distance.metres(-6.0), forward: Distance.metres(106.0) },
	},
	foot: ahead({ right: Distance.metres(0.0), forward: Distance.metres(100.0) }),
	lift: Distance.zero,
	sunk: Distance.metres(1.0),
	metre_on_screen: Pixels.of(5.0),
	focal_length: Pixels.of(500.0),
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

## How many pixels a metre across spans `forward` metres ahead, through a
## 500 px focal length.
metre_ahead : F64 -> F64
metre_ahead = |forward| {
	at = ahead({ right: Distance.metres(3.0), forward: Distance.metres(forward) })
	metre_on_screen({ at, focal_length: Pixels.of(500.0) }).to_f64()
}

expect metre_ahead(10.0) == 50.0
expect metre_ahead(25.0) == 20.0
expect metre_ahead(50.0) == 10.0

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
