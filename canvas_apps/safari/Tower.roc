## A radio tower: a square lattice that tapers from its footprint to a point
## at its top. It is drawn as rods (four legs, a ring at every storey, and
## crossed braces in the lowest storeys) with a blinking beacon on top.
## The earth curves away under a far tower, so it sinks below the horizon
## from the bottom up.
import Pixels
import Angle
import Beacon
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

## A tower in a frame: how it is turned, and its beacon as it shines.
Tower :: { yaw : Angle.Turn, beacon : Beacon.LitBeacon }.{

	## A tower turned by `yaw`, with `beacon` on top.
	standing : { yaw : Angle.Turn, beacon : Beacon.LitBeacon } -> Tower
	standing = |{ yaw, beacon }| Tower.({ yaw, beacon })

	## How far the tower is turned from square with the road.
	yaw : Tower -> Angle.Turn
	yaw = |Tower.(tower)| tower.yaw

	## The tower's beacon, as it shines in this frame.
	beacon : Tower -> Beacon.LitBeacon
	beacon = |Tower.(tower)| tower.beacon

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
		on_road = base_corner_on_road(corner, { center, yaw: tower.yaw() })
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
		geometry = {
			footprint,
			foot,
			lift,
			sunk,
			metre_on_screen: metre_on_screen({ at: foot, focal_length }),
			focal_length,
		}
		apex = foot.at_height(height_in_view(geometry, tower_height))
		rods = [
			leg_shapes(geometry, apex.to_raised()),
			ring_shapes(geometry),
			brace_shapes(geometry),
		].join()
		beacon_disc = tower.beacon().disc({
			center: Camera.project(apex, focal_length),
			metre_on_screen: geometry.metre_on_screen,
		})
		match beacon_disc {
			Ok(disc) => rods.append(disc)
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

tower_color : RgbColor
tower_color = RgbColor.of(0x9AA0A8)

## A tower's measurements in this frame, which its rods are worked out from:
## where its footprint and foot stand, how high off the ground it is, how far
## the earth's curve has sunk it, which is never negative, and how many pixels
## a metre across spans as far ahead as its foot, which sizes its rods and its
## beacon.
TowerGeometry : {
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
	across_metres = offset.across.to_metres()
	along_metres = offset.along.to_metres()
	yaw_cos = yaw.to_radians().cos()
	yaw_sin = yaw.to_radians().sin()
	along_shift = across_metres * yaw_sin + along_metres * yaw_cos
	across_shift = across_metres * yaw_cos - along_metres * yaw_sin
	{
		along: center.along.plus(Distance.metres(along_shift)),
		across: center.across.plus(Distance.metres(across_shift)),
	}
}

## How high a point `height_on_tower` up the tower stands in the rider's
## view: raised by the tower's lift, and lowered by how far it has sunk.
height_in_view : TowerGeometry, Distance -> Distance
height_in_view = |geometry, height_on_tower|
	geometry.lift.plus(height_on_tower.minus(geometry.sunk))

## A corner of the tower at `height_on_tower`: drawn in toward the foot as
## the tower tapers, raised by the tower's lift, and lowered by how far the
## tower has sunk.
corner_at : TowerGeometry, { corner : Corner, height_on_tower : Distance } -> RiderView.RaisedPoint
corner_at = |geometry, { corner, height_on_tower }| {
	taper_fraction = height_on_tower.ratio_to(tower_height)
	bottom = footprint_corner(geometry.footprint, corner)
	tapered = |start, end| start.plus(end.minus(start).times(taper_fraction))
	{
		right: tapered(bottom.right, geometry.foot.right()),
		forward: tapered(bottom.forward, geometry.foot.forward()),
		height: height_in_view(geometry, height_on_tower),
	}
}

## The shortest rod on screen that has a direction to turn its width across.
## A shorter one is drawn as if one pixel long, so its quad shrinks to its
## point rather than dividing by nearly nothing.
shortest_rod_with_direction : Pixels
shortest_rod_with_direction = Pixels.of(0.0001)

## A rod between two points on screen, `width` wide.
screen_rod : {
	from : Screen.Point,
	to : Screen.Point,
	width : Pixels,
} -> Shapes.Shape
screen_rod = |{ from, to, width }| {
	x_change = to.x.minus(from.x).to_f64()
	y_change = to.y.minus(from.y).to_f64()
	across = width.to_f64()
	measured_length = Screen.distance({ from, to }).to_f64()
	rod_length = if measured_length < shortest_rod_with_direction.to_f64() {
		1.0
	} else {
		measured_length
	}
	rod_quad({
		from,
		to,
		offset_x: Pixels.of(across * ((0.0 - y_change) / rod_length) / 2.0),
		offset_y: Pixels.of(across * (x_change / rod_length) / 2.0),
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
rod_quad = |{ from, to, offset_x, offset_y }| Polygon.flat_polygon(
	[
		{ x: from.x.plus(offset_x), y: from.y.plus(offset_y) },
		{ x: to.x.plus(offset_x), y: to.y.plus(offset_y) },
		{ x: to.x.minus(offset_x), y: to.y.minus(offset_y) },
		{ x: from.x.minus(offset_x), y: from.y.minus(offset_y) },
	],
	tower_color,
)

## A rod between two points in the rider's view, cut where it crosses the
## near plane. A rod wholly behind the near plane has no shape.
rod_shape : TowerGeometry,
{
	from : RiderView.RaisedPoint,
	to : RiderView.RaisedPoint,
} -> Try(Shapes.Shape, [BehindCamera])
rod_shape = |geometry, line| {
	ahead = RiderView.line_ahead(line)?
	Ok(
		screen_rod({
			from: Camera.project(ahead.from, geometry.focal_length),
			to: Camera.project(ahead.to, geometry.focal_length),
			width: geometry.metre_on_screen.times(rod_width.to_metres()),
		}),
	)
}

## How many pixels one metre across spans as far ahead as `at`.
metre_on_screen : { at : RiderView.RiderPointAhead, focal_length : Pixels } -> Pixels
metre_on_screen = |{ at, focal_length }| {
	on_level = at.at_height(Distance.zero)
	one_metre_right = Camera.project(on_level.at_right(Distance.metres(1.0)), focal_length)
	on_level_point = Camera.project(on_level.at_right(Distance.zero), focal_length)
	one_metre_right.x.minus(on_level_point.x)
}

## The four legs, from the footprint's corners up to the apex.
leg_shapes : TowerGeometry, RiderView.RaisedPoint -> List(Shapes.Shape)
leg_shapes = |geometry, apex| corners.keep_oks(
	|corner| rod_shape(
		geometry,
		{ from: corner_at(geometry, { corner, height_on_tower: geometry.sunk }), to: apex },
	),
)

## The ring of rods round the tower at `ring_height`.
ring_shapes_at : TowerGeometry, Distance -> List(Shapes.Shape)
ring_shapes_at = |geometry, ring_height| corners.keep_oks(
	|corner| rod_shape(
		geometry,
		{
			from: corner_at(geometry, { corner, height_on_tower: ring_height }),
			to: corner_at(geometry, { corner: next_corner(corner), height_on_tower: ring_height }),
		},
	),
)

## A ring at every storey below the top, bottom first, leaving out those
## the earth has hidden.
ring_shapes : TowerGeometry -> List(Shapes.Shape)
ring_shapes = |geometry| ring_heights.join_map(
	|ring_height|
		if ring_height <= geometry.sunk {
			[]
		} else {
			ring_shapes_at(geometry, ring_height)
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
brace_shapes : TowerGeometry -> List(Shapes.Shape)
brace_shapes = |geometry|
	List.from_iter(U64.until(0, brace_storeys)).join_map(|storey| storey_shapes(geometry, storey))

storey_shapes : TowerGeometry, U64 -> List(Shapes.Shape)
storey_shapes = |geometry, storey| {
	storey_bottom = storey_height.times(storey.to_f64())
	storey_top = storey_bottom.plus(storey_height)
	if storey_top <= geometry.sunk {
		[]
	} else {
		hidden_height = storey_bottom.max(geometry.sunk).minus(storey_bottom)
		hidden_fraction = Fraction.of(hidden_height.ratio_to(storey_height))
		corners.join_map(
			|corner| face_brace_shapes(
				geometry,
				{ corner, storey_bottom, storey_top, hidden_fraction },
			),
		)
	}
}

## The two braces crossing the face from `corner` to the next corner: one
## rising each way.
face_brace_shapes : TowerGeometry,
{
	corner : Corner,
	storey_bottom : Distance,
	storey_top : Distance,
	hidden_fraction : Fraction,
} -> List(Shapes.Shape)
face_brace_shapes = |geometry, { corner, storey_bottom, storey_top, hidden_fraction }| {
	next = next_corner(corner)
	brace_up = {
		from: RiderView.point_between({
			from: corner_at(geometry, { corner, height_on_tower: storey_bottom }),
			to: corner_at(geometry, { corner: next, height_on_tower: storey_top }),
			fraction: hidden_fraction,
		}),
		to: corner_at(geometry, { corner: next, height_on_tower: storey_top }),
	}
	brace_down = {
		from: RiderView.point_between({
			from: corner_at(geometry, { corner: next, height_on_tower: storey_bottom }),
			to: corner_at(geometry, { corner, height_on_tower: storey_top }),
			fraction: hidden_fraction,
		}),
		to: corner_at(geometry, { corner, height_on_tower: storey_top }),
	}
	[brace_up, brace_down].keep_oks(|brace| rod_shape(geometry, brace))
}

## `point` on the rider's level and past the near plane, which every such
## point in these tests is.
ahead : RiderView.RiderPoint -> RiderView.RiderPointAhead
ahead = |point| RiderView.rider_point_ahead(point) ?? crash "a test's point is past the near plane"

# A tower 12 m square, its foot 100 m ahead, sunk 1 m, a metre 5 px across.
sample_geometry : TowerGeometry
sample_geometry = {
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
	corner_at(sample_geometry, { corner: BackLeft, height_on_tower: Distance.metres(0.0) })
		== {
			right: Distance.metres(-6.0),
			forward: Distance.metres(94.0),
			height: Distance.metres(-1.0),
		}
expect
	corner_at(sample_geometry, { corner: BackLeft, height_on_tower: Distance.metres(40.0) })
		== {
			right: Distance.metres(-3.0),
			forward: Distance.metres(97.0),
			height: Distance.metres(39.0),
		}
expect
	corner_at(sample_geometry, { corner: BackLeft, height_on_tower: Distance.metres(80.0) })
		== {
			right: Distance.metres(0.0),
			forward: Distance.metres(100.0),
			height: Distance.metres(79.0),
		}
expect
	corner_at(sample_geometry, { corner: FrontRight, height_on_tower: Distance.metres(40.0) })
		== {
			right: Distance.metres(3.0),
			forward: Distance.metres(103.0),
			height: Distance.metres(39.0),
		}
expect
	corner_at(sample_geometry, { corner: FrontRight, height_on_tower: Distance.metres(80.0) })
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
			fill: Flat(Brush.opaque_rgba(tower_color)),
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
			fill: Flat(Brush.opaque_rgba(tower_color)),
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
		sample_geometry,
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
		sample_geometry,
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
