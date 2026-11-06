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
import lib.DeviceMath
import Distance
import Fraction
import Geom
import Paint
import lib.Trig
import lib.Brush
import Screen
import lib.Shapes

Tower :: [].{

	tower_height : Distance
	tower_height = Distance.metres(80.0)

	tower_half : Distance
	tower_half = Distance.metres(6.0)

	storey_height : Distance
	storey_height = Distance.metres(20.0)

	brace_storeys : I64
	brace_storeys = 2

	rod_half : Distance
	rod_half = Distance.metres(0.12)

	rod_w : Distance
	rod_w = rod_half.times(2.0)

	tower_metal : I64
	tower_metal = 10133672

	## The radius a far tower sinks over, which hides it wholly at 1.8 km. It
	## is tighter than `Geom.ground_curve_radius`, so a tower sinks visibly as
	## it recedes: on the ground's curve it would stay in view to 4 km.
	sink_radius : Distance
	sink_radius = Distance.metres(20000.0)

	beacon_radius : Distance
	beacon_radius = Distance.metres(3.0)

	beacon_color : I64
	beacon_color = 16723942

	## A corner of the tower's square footprint, as seen along the route.
	Corner : [BackLeft, BackRight, FrontRight, FrontLeft]

	## Where the footprint's four corners stand in the rider's view.
	Footprint : {
		back_left : Geom.RiderPoint,
		back_right : Geom.RiderPoint,
		front_right : Geom.RiderPoint,
		front_left : Geom.RiderPoint,
	}

	## How a rod is drawn: its width on screen, and the camera.
	RodView : { rod_width_px : Pixels, cam_focal : Pixels }

	## One tower, ready to draw: where it stands, how far the earth's curve
	## has sunk it, which is never negative, and how its rods are drawn.
	TowerInView : {
		footprint : Tower.Footprint,
		center : Geom.RiderPoint,
		sunk : Distance,
		view : Tower.RodView,
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

	## Which way a corner lies from the footprint's centre, across the route
	## and along it.
	corner_offset : Tower.Corner -> { across : F64, along : F64 }
	corner_offset = |corner|
		match corner {
			BackLeft => { across: -1.0, along: -1.0 }
			BackRight => { across: 1.0, along: -1.0 }
			FrontRight => { across: 1.0, along: 1.0 }
			FrontLeft => { across: -1.0, along: 1.0 }
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
		offset = corner_offset(corner)
		half = tower_half.to_metres()
		du = (offset.across * half)
		dv = (offset.along * half)
		cy = Trig.r_cos(yaw.to_radians())
		sy = Trig.r_sin(yaw.to_radians())
		{
			along: along.plus(Distance.metres((du * sy) + (dv * cy))),
			across: across.plus(Distance.metres((du * cy) - (dv * sy))),
		}
	}

	## How far the earth's curve hides the bottom of a tower standing at `p`.
	sunk_below_horizon : Geom.RiderPoint -> Distance
	sunk_below_horizon = |p| {
		r = p.right.to_metres()
		f = p.forward.to_metres()
		Distance.metres(((r * r) + (f * f)) / (2.0 * sink_radius.to_metres()))
	}

	## The point `fraction` of the way from `from` to `to`.
	point_between : {
		from : Geom.RaisedPoint,
		to : Geom.RaisedPoint,
		fraction : Fraction,
	} -> Geom.RaisedPoint
	point_between = |{ from, to, fraction }| {
		share = fraction.to_f64()
		part_way = |start, end| start.plus(end.minus(start).times(share))
		{
			right: part_way(from.right, to.right),
			forward: part_way(from.forward, to.forward),
			height: part_way(from.height, to.height),
		}
	}

	## A corner of the tower at `height_on_tower`: drawn in toward the centre
	## as the tower tapers, and lowered by how far the tower has sunk.
	corner_at : Tower.TowerInView,
	{
		corner : Tower.Corner,
		height_on_tower : Distance,
	} -> Geom.RaisedPoint
	corner_at = |tower, { corner, height_on_tower }| {
		t = height_on_tower.ratio_to(tower_height)
		bottom = footprint_corner(tower.footprint, corner)
		tapered = |start, end| start.plus(end.minus(start).times(t))
		{
			right: tapered(bottom.right, tower.center.right),
			forward: tapered(bottom.forward, tower.center.forward),
			height: height_on_tower.minus(tower.sunk),
		}
	}

	## A rod between two points on screen, `width_px` wide.
	screen_rod : {
		from : Screen.Point,
		to : Screen.Point,
		width_px : Pixels,
	} -> List(Shapes.Shape)
	screen_rod = |{ from, to, width_px }| {
		dx = to.x.minus(from.x)
		dy = to.y.minus(from.y)
		raw = dx.hypotenuse(dy)
		len = if raw < Pixels.of(0.0001) {
			Pixels.of(1.0)
		} else {
			raw
		}
		rod_quad({
			from,
			to,
			offset_x: width_px.times(dy.opposite().ratio_to(len)).divided_by(2.0),
			offset_y: width_px.times(dx.ratio_to(len)).divided_by(2.0),
		})
	}

	## The quad of a rod from `from` to `to`, its sides `offset_x` and
	## `offset_y` either side of the line between them.
	rod_quad : {
		from : Screen.Point,
		to : Screen.Point,
		offset_x : Pixels,
		offset_y : Pixels,
	} -> List(Shapes.Shape)
	rod_quad = |
		{
			from: a,
			to: b,
			offset_x: ox,
			offset_y: oy,
		},
	| Paint.polygon(
		tower_metal,
		[
			{ x: a.x.plus(ox), y: a.y.plus(oy) },
			{ x: b.x.plus(ox), y: b.y.plus(oy) },
			{ x: b.x.minus(ox), y: b.y.minus(oy) },
			{ x: a.x.minus(ox), y: a.y.minus(oy) },
		],
	)

	## A rod between two points in the rider's view. A rod with one end
	## behind the near plane is cut there; one with both ends behind it is
	## not drawn.
	rod : Tower.RodView, { from : Geom.RaisedPoint, to : Geom.RaisedPoint } -> List(Shapes.Shape)
	rod = |view, { from, to }|
		match (sight_of(from), sight_of(to)) {
			(InView, InView) => rod_on_screen(view, { from, to })
			(InView, BehindCamera) => rod_on_screen(view, { from, to: cut_at_near({ from, to }) })
			(BehindCamera, InView) => rod_on_screen(view, { from: cut_at_near({ from, to }), to })
			(BehindCamera, BehindCamera) => []
		}

	sight_of : Geom.RaisedPoint -> [InView, BehindCamera]
	sight_of = |point|
		if point.forward >= Geom.near_plane {
			InView
		} else {
			BehindCamera
		}

	## Where the line from `from` to `to` crosses the near plane.
	cut_at_near : { from : Geom.RaisedPoint, to : Geom.RaisedPoint } -> Geom.RaisedPoint
	cut_at_near = |{ from, to }| {
		share = Geom.near_plane.minus(from.forward).ratio_to(to.forward.minus(from.forward))
		point_between({ from, to, fraction: Fraction.of(share) })
	}

	rod_on_screen : Tower.RodView,
	{
		from : Geom.RaisedPoint,
		to : Geom.RaisedPoint,
	} -> List(Shapes.Shape)
	rod_on_screen = |view, { from, to }|
		screen_rod({
			from: Camera.project(from, view.cam_focal),
			to: Camera.project(to, view.cam_focal),
			width_px: view.rod_width_px,
		})

	## How many pixels one metre across spans at distance `forward`.
	metre_px : { forward : Distance, cam_focal : Pixels } -> Pixels
	metre_px = |{ forward, cam_focal }| {
		p1 = Camera.project(
			{
				right: Distance.metres(1.0),
				forward: forward,
				height: Distance.zero,
			},
			cam_focal,
		)
		p0 = Camera.project(
			{
				right: Distance.zero,
				forward: forward,
				height: Distance.zero,
			},
			cam_focal,
		)
		p1.x.minus(p0.x)
	}

	## A rod's width on screen at distance `forward`.
	rod_width_at : { forward : Distance, cam_focal : Pixels } -> Pixels
	rod_width_at = |camera| metre_px(camera).times(rod_w.to_metres())

	## The four legs, from the footprint's corners up to the apex.
	legs : Tower.TowerInView, Geom.RaisedPoint -> List(Shapes.Shape)
	legs = |tower, apex| corners.join_map(
		|corner| rod(
			tower.view,
			{ from: corner_at(tower, { corner, height_on_tower: tower.sunk }), to: apex },
		),
	)

	## The ring of rods round the tower at height `h`.
	ring : Tower.TowerInView, Distance -> List(Shapes.Shape)
	ring = |tower, h| corners.join_map(
		|corner| rod(
			tower.view,
			{
				from: corner_at(tower, { corner, height_on_tower: h }),
				to: corner_at(tower, { corner: next_corner(corner), height_on_tower: h }),
			},
		),
	)

	## A ring at every storey below the top, bottom first, leaving out those
	## the earth has hidden.
	rings : Tower.TowerInView -> List(Shapes.Shape)
	rings = |tower| ring_heights_from(storey_height).join_map(
		|h|
			if h <= tower.sunk {
				[]
			} else {
				ring(tower, h)
			},
	)

	ring_heights_from : Distance -> List(Distance)
	ring_heights_from = |h|
		if h >= tower_height {
			[]
		} else {
			[h].concat(ring_heights_from(h.plus(storey_height)))
		}

	## The crossed braces of the lowest storeys, bottom first. A storey the
	## earth has partly hidden starts its braces at the horizon.
	braces : Tower.TowerInView -> List(Shapes.Shape)
	braces = |tower| brace_storeys_from(0).join_map(|storey| brace_storey(tower, storey))

	brace_storeys_from : I64 -> List(I64)
	brace_storeys_from = |storey|
		if storey >= brace_storeys {
			[]
		} else {
			[storey].concat(brace_storeys_from((storey + 1)))
		}

	brace_storey : Tower.TowerInView, I64 -> List(Shapes.Shape)
	brace_storey = |tower, storey| {
		storey_bottom = storey_height.times(storey.to_f64())
		storey_top = storey_bottom.plus(storey_height)
		if storey_top <= tower.sunk {
			[]
		} else {
			hidden_height = storey_bottom.max(tower.sunk).minus(storey_bottom)
			hidden_fraction = Fraction.of(hidden_height.ratio_to(storey_height))
			corners.join_map(
				|corner| brace_pair(tower, { corner, storey_bottom, storey_top, hidden_fraction }),
			)
		}
	}

	## The two braces crossing the face from `corner` to the next corner: one
	## rising each way.
	brace_pair : Tower.TowerInView,
	{
		corner : Tower.Corner,
		storey_bottom : Distance,
		storey_top : Distance,
		hidden_fraction : Fraction,
	} -> List(Shapes.Shape)
	brace_pair = |tower, { corner, storey_bottom, storey_top, hidden_fraction }| {
		next = next_corner(corner)
		brace_up = rod(
			tower.view,
			{
				from: point_between({
					from: corner_at(tower, { corner, height_on_tower: storey_bottom }),
					to: corner_at(tower, { corner: next, height_on_tower: storey_top }),
					fraction: hidden_fraction,
				}),
				to: corner_at(tower, { corner: next, height_on_tower: storey_top }),
			},
		)
		brace_down = rod(
			tower.view,
			{
				from: point_between({
					from: corner_at(tower, { corner: next, height_on_tower: storey_bottom }),
					to: corner_at(tower, { corner, height_on_tower: storey_top }),
					fraction: hidden_fraction,
				}),
				to: corner_at(tower, { corner, height_on_tower: storey_top }),
			},
		)
		brace_up.concat(brace_down)
	}

	## The beacon on the apex, at its brightness; too dim or too small, it
	## isn't drawn.
	beacon : Tower.TowerInView,
	{
		apex : Geom.RaisedPoint,
		brightness : Fraction,
	} -> List(Shapes.Shape)
	beacon = |tower, { apex, brightness }| {
		apex_on_screen = Camera.project(apex, tower.view.cam_focal)
		if brightness < Fraction.of(0.02) {
			[]
		} else {
			one_metre_px = metre_px({
				forward: tower.center.forward,
				cam_focal: tower.view.cam_focal,
			})
			radius = one_metre_px.times(beacon_radius.to_metres())
			if radius < Pixels.of(0.5) {
				[]
			} else {
				Paint.beacon({
					beacon_color,
					beacon_center: apex_on_screen,
					beacon_radius: radius,
					beacon_alpha: brightness,
				})
			}
		}
	}

	## The whole tower: legs, rings, braces and beacon, in that order. A tower
	## behind the camera, or sunk wholly below the horizon, draws nothing.
	draw : {
		footprint : Tower.Footprint,
		center : Geom.RiderPoint,
		cam_focal : Pixels,
		beacon_brightness : Fraction,
	} -> List(Shapes.Shape)
	draw = |{ footprint, center, cam_focal, beacon_brightness }| {
		sunk = sunk_below_horizon(center)
		if center.forward < Geom.near_plane or sunk >= tower_height {
			[]
		} else {
			view = { rod_width_px: rod_width_at({ forward: center.forward, cam_focal }), cam_focal }
			tower = { footprint, center, sunk, view }
			apex = {
				right: center.right,
				forward: center.forward,
				height: tower_height.minus(sunk),
			}
			[
				legs(tower, apex),
				rings(tower),
				braces(tower),
				beacon(tower, { apex, brightness: beacon_brightness }),
			].join()
		}
	}
}

expect Tower.tower_height.to_metres() == 80.0
expect Tower.tower_half.to_metres() == 6.0
expect Tower.storey_height.to_metres() == 20.0
expect Tower.rod_half.to_metres() == 0.12
expect Tower.rod_w.to_metres() == 0.24
expect Tower.sink_radius.to_metres() == 20000.0
expect Tower.beacon_radius.to_metres() == 3.0

expect Tower.brace_storeys == 2
expect Tower.tower_metal == 10133672
expect Tower.beacon_color == 16723942

expect Tower.corners.map(|corner| Tower.corner_offset(corner).across) == [-1.0, 1.0, 1.0, -1.0]
expect Tower.corners.map(|corner| Tower.corner_offset(corner).along) == [-1.0, -1.0, 1.0, 1.0]

expect {
	[
		(BackLeft, { along: 94.0, across: -6.0 }),
		(BackRight, { along: 94.0, across: 6.0 }),
		(FrontRight, { along: 106.0, across: 6.0 }),
		(FrontLeft, { along: 106.0, across: -6.0 }),
	].all(
		|(corner, want)| {
			got = Tower.base_corner_on_road(
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

sample_rod_view : Tower.RodView
sample_rod_view = { rod_width_px: Pixels.of(4.0), cam_focal: Pixels.of(500.0) }

# A tower 12 m square, centred 100 m ahead, sunk 1 m.
sample_tower : Tower.TowerInView
sample_tower = {
	footprint: {
		back_left: { right: Distance.metres(-6.0), forward: Distance.metres(94.0) },
		back_right: { right: Distance.metres(6.0), forward: Distance.metres(94.0) },
		front_right: { right: Distance.metres(6.0), forward: Distance.metres(106.0) },
		front_left: { right: Distance.metres(-6.0), forward: Distance.metres(106.0) },
	},
	center: { right: Distance.metres(0.0), forward: Distance.metres(100.0) },
	sunk: Distance.metres(1.0),
	view: sample_rod_view,
}

expect
	Tower.corner_at(sample_tower, { corner: BackLeft, height_on_tower: Distance.metres(0.0) })
		== {
			right: Distance.metres(-6.0),
			forward: Distance.metres(94.0),
			height: Distance.metres(-1.0),
		}
expect
	Tower.corner_at(sample_tower, { corner: BackLeft, height_on_tower: Distance.metres(40.0) })
		== {
			right: Distance.metres(-3.0),
			forward: Distance.metres(97.0),
			height: Distance.metres(39.0),
		}
expect
	Tower.corner_at(sample_tower, { corner: BackLeft, height_on_tower: Distance.metres(80.0) })
		== {
			right: Distance.metres(0.0),
			forward: Distance.metres(100.0),
			height: Distance.metres(79.0),
		}
expect
	Tower.corner_at(sample_tower, { corner: FrontRight, height_on_tower: Distance.metres(40.0) })
		== {
			right: Distance.metres(3.0),
			forward: Distance.metres(103.0),
			height: Distance.metres(39.0),
		}
expect
	Tower.corner_at(sample_tower, { corner: FrontRight, height_on_tower: Distance.metres(80.0) })
		== {
			right: Distance.metres(0.0),
			forward: Distance.metres(100.0),
			height: Distance.metres(79.0),
		}

expect Tower.sunk_below_horizon({
	right: Distance.metres(0.0),
	forward: Distance.metres(200.0),
}).to_metres() == 1.0
expect Tower.sunk_below_horizon({
	right: Distance.metres(100.0),
	forward: Distance.metres(100.0),
}).to_metres() == 0.5
expect Tower.sunk_below_horizon({
	right: Distance.metres(0.0),
	forward: Distance.metres(0.0),
}).to_metres() == 0.0

expect
	Tower.point_between({
		from: {
			right: Distance.metres(0.0),
			forward: Distance.metres(10.0),
			height: Distance.metres(20.0),
		},
		to: {
			right: Distance.metres(8.0),
			forward: Distance.metres(30.0),
			height: Distance.metres(0.0),
		},
		fraction: Fraction.of(0.25),
	})
		== {
			right: Distance.metres(2.0),
			forward: Distance.metres(15.0),
			height: Distance.metres(15.0),
		}

expect
	Tower.screen_rod({
		from: Screen.point(0.0, 0.0),
		to: Screen.point(30.0, 40.0),
		width_px: Pixels.of(10.0),
	})
		== [
			Poly({
				pts: [-4.0, 3.0, 26.0, 43.0, 34.0, 37.0, 4.0, -3.0],
				fill: Flat(Brush.opaque(Tower.tower_metal)),
			}),
		]

# A rod of no length is still one quad, all at its one point.
expect
	Tower.screen_rod({
		from: Screen.point(5.0, 6.0),
		to: Screen.point(5.0, 6.0),
		width_px: Pixels.of(10.0),
	})
		== [
			Poly({
				pts: [5.0, 6.0, 5.0, 6.0, 5.0, 6.0, 5.0, 6.0],
				fill: Flat(Brush.opaque(Tower.tower_metal)),
			}),
		]

expect
	Tower.rod_width_at({ forward: Distance.metres(10.0), cam_focal: Pixels.of(500.0) }).to_f64()
		== 12.0
expect
	Tower.rod_width_at({ forward: Distance.metres(25.0), cam_focal: Pixels.of(500.0) }).to_f64()
		== 4.8
expect
	Tower.rod_width_at({ forward: Distance.metres(50.0), cam_focal: Pixels.of(500.0) }).to_f64()
		== 2.4

rod_along_road : F64, F64 -> List(Shapes.Shape)
rod_along_road = |start, end|
	Tower.rod(
		sample_rod_view,
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

# A rod is cut at the near plane, and one wholly behind it draws nothing.
expect
	Tower.rod(
		sample_rod_view,
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
	).len()
		== 1
expect rod_along_road(0.0, 0.8).len() == 1
expect rod_along_road(0.8, 0.0).len() == 1
expect rod_along_road(0.0, 0.2).len() == 0

expect
	Tower.cut_at_near({
		from: {
			right: Distance.metres(0.0),
			forward: Distance.metres(0.0),
			height: Distance.metres(10.0),
		},
		to: {
			right: Distance.metres(8.0),
			forward: Distance.metres(0.8),
			height: Distance.metres(30.0),
		},
	})
		== {
			right: Distance.metres(4.0),
			forward: Distance.metres(0.4),
			height: Distance.metres(20.0),
		}
