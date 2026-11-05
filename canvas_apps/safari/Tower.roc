## A radio mast: a square lattice that tapers from a 12 m footprint to a
## point 80 m up. It is drawn as rods (four legs, a ring every 20 m, and
## crossed braces in the lowest two stages) with a blinking beacon on top.
## The earth curves away under a far mast, so it sinks below the horizon
## from the bottom up.
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
import Screen
import lib.Shapes

Tower :: [].{

	tower_height : F64
	tower_height = 80.0

	tower_half : F64
	tower_half = 6.0

	stage_height : F64
	stage_height = 20.0

	brace_stages : I64
	brace_stages = 2

	rod_half : F64
	rod_half = 0.12

	rod_w : F64
	rod_w = (rod_half * 2.0)

	tower_metal : I64
	tower_metal = 10133672

	## The earth's radius for sinking masts. It is far smaller than the real
	## one, so a mast sinks visibly as it recedes.
	earth_radius : F64
	earth_radius = 20000.0

	beacon_radius : F64
	beacon_radius = 3.0

	beacon_color : I64
	beacon_color = 16723942

	## A corner of the mast's square footprint, as seen along the route.
	Corner : [BackLeft, BackRight, FrontRight, FrontLeft]

	## Where the footprint's four corners stand in the rider's view.
	Footprint : {
		back_left : Geom.RiderPoint,
		back_right : Geom.RiderPoint,
		front_right : Geom.RiderPoint,
		front_left : Geom.RiderPoint,
	}

	## How a rod is drawn: its width on screen, and the camera.
	RodView : {
		rod_width_px : F64,
		cam_focal : F64,
	}

	## One mast, ready to draw: where it stands, how far the earth's curve
	## has sunk it, and how its rods are drawn.
	Mast : {
		footprint : Tower.Footprint,
		center : Geom.RiderPoint,
		sunk : F64,
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

	## Where a footprint corner stands on the map, for a mast centred at
	## `along` and `across` and turned by `yaw`.
	base_corner_on_road : Tower.Corner,
	{
		along : Along,
		across : Across,
		yaw : Angle.Turn,
	} -> Geom.RoadPoint
	base_corner_on_road = |
		corner,
		{
			along,
			across,
			yaw,
		},
	| {
		offset = corner_offset(corner)
		du = (offset.across * tower_half)
		dv = (offset.along * tower_half)
		cy = Trig.r_cos(yaw.to_radians())
		sy = Trig.r_sin(yaw.to_radians())
		{
			along: along.plus(Distance.metres((du * sy) + (dv * cy))),
			across: across.plus(Distance.metres((du * cy) - (dv * sy))),
		}
	}

	## How far the earth's curve hides the bottom of a mast standing at `p`.
	sunk_below_horizon : Geom.RiderPoint -> F64
	sunk_below_horizon = |p|
		(((p.right * p.right) + (p.forward * p.forward)) / (2.0 * earth_radius))

	## The point `fraction` of the way from `from` to `to`.
	point_between : {
		from : Geom.SpacePoint,
		to : Geom.SpacePoint,
		fraction : Fraction,
	} -> Geom.SpacePoint
	point_between = |
		{
			from,
			to,
			fraction,
		},
	| {
		share = fraction.to_f64()
		{
			right: (from.right + ((to.right - from.right) * share)),
			forward: (from.forward + ((to.forward - from.forward) * share)),
			height: (from.height + ((to.height - from.height) * share)),
		}
	}

	## A corner of the mast at `height_on_mast`: drawn in toward the centre
	## as the mast tapers, and lowered by how far the mast has sunk.
	corner_at : Tower.Mast, { corner : Tower.Corner, height_on_mast : F64 } -> Geom.SpacePoint
	corner_at = |mast, { corner, height_on_mast: h }| {
		t = (h / tower_height)
		bottom = footprint_corner(mast.footprint, corner)
		{
			right: (bottom.right + ((mast.center.right - bottom.right) * t)),
			forward: (bottom.forward + ((mast.center.forward - bottom.forward) * t)),
			height: (h - mast.sunk),
		}
	}

	## A rod between two points on screen, `width_px` wide.
	screen_rod : {
		from : Screen.Point,
		to : Screen.Point,
		width_px : F64,
	} -> List(Shapes.Shape)
	screen_rod = |
		{
			from,
			to,
			width_px,
		},
	| {
		dx = (to.x - from.x)
		dy = (to.y - from.y)
		raw = DeviceMath.real_sqrt(((dx * dx) + (dy * dy)))
		len = if (raw < 0.0001) 1.0 else raw
		rod_quad({
			from,
			to,
			offset_x: ((((0.0 - dy) / len) * width_px) / 2.0),
			offset_y: (((dx / len) * width_px) / 2.0),
		})
	}

	## The quad of a rod from `from` to `to`, its sides `offset_x` and
	## `offset_y` either side of the line between them.
	rod_quad : {
		from : Screen.Point,
		to : Screen.Point,
		offset_x : F64,
		offset_y : F64,
	} -> List(Shapes.Shape)
	rod_quad = |
		{
			from: a,
			to: b,
			offset_x: ox,
			offset_y: oy,
		},
	| Paint.push_poly(
		tower_metal,
		[
			{ x: (a.x + ox), y: (a.y + oy) },
			{ x: (b.x + ox), y: (b.y + oy) },
			{ x: (b.x - ox), y: (b.y - oy) },
			{ x: (a.x - ox), y: (a.y - oy) },
		],
	)

	## A rod between two points in the rider's view. A rod with one end
	## behind the near plane is cut there; one with both ends behind it is
	## not drawn.
	rod : Tower.RodView, { from : Geom.SpacePoint, to : Geom.SpacePoint } -> List(Shapes.Shape)
	rod = |view, { from, to }|
		match (sight_of(from), sight_of(to)) {
			(InView, InView) => rod_on_screen(view, { from, to })
			(InView, BehindCamera) => rod_on_screen(view, { from, to: cut_at_near({ from, to }) })
			(BehindCamera, InView) => rod_on_screen(view, { from: cut_at_near({ from, to }), to })
			(BehindCamera, BehindCamera) => []
		}

	sight_of : Geom.SpacePoint -> [InView, BehindCamera]
	sight_of = |point| if (point.forward >= Geom.near_plane) InView else BehindCamera

	## Where the line from `from` to `to` crosses the near plane.
	cut_at_near : { from : Geom.SpacePoint, to : Geom.SpacePoint } -> Geom.SpacePoint
	cut_at_near = |{ from, to }| point_between({
		from,
		to,
		fraction: Fraction.of(((Geom.near_plane - from.forward) / (to.forward - from.forward))),
	})

	rod_on_screen : Tower.RodView,
	{
		from : Geom.SpacePoint,
		to : Geom.SpacePoint,
	} -> List(Shapes.Shape)
	rod_on_screen = |view, { from, to }|
		screen_rod({
			from: Camera.project(from, view.cam_focal),
			to: Camera.project(to, view.cam_focal),
			width_px: view.rod_width_px,
		})

	## How many pixels one metre across spans at distance `forward`.
	metre_px : { forward : F64, cam_focal : F64 } -> F64
	metre_px = |{ forward, cam_focal }| {
		p1 = Camera.project(
			{
				right: 1.0,
				forward: forward,
				height: 0.0,
			},
			cam_focal,
		)
		p0 = Camera.project(
			{
				right: 0.0,
				forward: forward,
				height: 0.0,
			},
			cam_focal,
		)
		(p1.x - p0.x)
	}

	## A rod's width on screen at distance `forward`.
	rod_width_at : { forward : F64, cam_focal : F64 } -> F64
	rod_width_at = |camera| (rod_w * metre_px(camera))

	## The four legs, from the footprint's corners up to the apex.
	legs : Tower.Mast, Geom.SpacePoint -> List(Shapes.Shape)
	legs = |mast, apex| corners.join_map(
		|corner| rod(
			mast.view,
			{
				from: corner_at(mast, { corner, height_on_mast: mast.sunk }),
				to: apex,
			},
		),
	)

	## The ring of rods round the mast at height `h`.
	ring : Tower.Mast, F64 -> List(Shapes.Shape)
	ring = |mast, h| corners.join_map(
		|corner| rod(
			mast.view,
			{
				from: corner_at(mast, { corner, height_on_mast: h }),
				to: corner_at(mast, { corner: next_corner(corner), height_on_mast: h }),
			},
		),
	)

	## A ring at every stage below the top, bottom first, leaving out those
	## the earth has hidden.
	rings : Tower.Mast -> List(Shapes.Shape)
	rings = |mast| ring_heights_from(stage_height).join_map(
		|h| if (h <= mast.sunk) [] else ring(
			mast,
			h,
		),
	)

	ring_heights_from : F64 -> List(F64)
	ring_heights_from = |h| if (h >= tower_height) [] else [h].concat(
		ring_heights_from((h + stage_height)),
	)

	## The crossed braces of the lowest stages, bottom first. A stage the
	## earth has partly hidden starts its braces at the horizon.
	braces : Tower.Mast -> List(Shapes.Shape)
	braces = |mast| brace_stages_from(0).join_map(|stage| brace_stage(mast, stage))

	brace_stages_from : I64 -> List(I64)
	brace_stages_from = |stage| if (stage >= brace_stages) [] else [stage].concat(
		brace_stages_from((stage + 1)),
	)

	brace_stage : Tower.Mast, I64 -> List(Shapes.Shape)
	brace_stage = |mast, stage| {
		stage_bottom = (stage.to_f64() * stage_height)
		stage_top = (stage_bottom + stage_height)
		if stage_top <= mast.sunk {
			[]
		} else {
			hidden_height = DeviceMath.real_max(stage_bottom, mast.sunk) - stage_bottom
			hidden_fraction = Fraction.of(hidden_height / stage_height)
			corners.join_map(
				|corner| brace_pair(
					mast,
					{
						corner,
						stage_bottom,
						stage_top,
						hidden_fraction,
					},
				),
			)
		}
	}

	## The two braces crossing the face from `corner` to the next corner: one
	## rising each way.
	brace_pair : Tower.Mast,
	{
		corner : Tower.Corner,
		stage_bottom : F64,
		stage_top : F64,
		hidden_fraction : Fraction,
	} -> List(Shapes.Shape)
	brace_pair = |
		mast,
		{
			corner,
			stage_bottom,
			stage_top,
			hidden_fraction,
		},
	| {
		next = next_corner(corner)
		brace_up = rod(
			mast.view,
			{
				from: point_between({
					from: corner_at(mast, { corner, height_on_mast: stage_bottom }),
					to: corner_at(mast, { corner: next, height_on_mast: stage_top }),
					fraction: hidden_fraction,
				}),
				to: corner_at(mast, { corner: next, height_on_mast: stage_top }),
			},
		)
		brace_down = rod(
			mast.view,
			{
				from: point_between({
					from: corner_at(mast, { corner: next, height_on_mast: stage_bottom }),
					to: corner_at(mast, { corner, height_on_mast: stage_top }),
					fraction: hidden_fraction,
				}),
				to: corner_at(mast, { corner, height_on_mast: stage_top }),
			},
		)
		brace_up.concat(brace_down)
	}

	## The beacon on the apex, at its brightness; too dim or too small, it
	## isn't drawn.
	beacon : Tower.Mast, { apex : Geom.SpacePoint, brightness : Fraction } -> List(Shapes.Shape)
	beacon = |mast, { apex, brightness }| {
		apex_on_screen = Camera.project(
			apex,
			mast.view.cam_focal,
		)
		if brightness < Fraction.of(0.02) {
			[]
		} else {
			one_metre_px = metre_px({
				forward: mast.center.forward,
				cam_focal: mast.view.cam_focal,
			})
			radius = beacon_radius * one_metre_px
			if (radius < 0.5) [] else Paint.push_beacon({
				beacon_color,
				beacon_center: apex_on_screen,
				beacon_radius: radius,
				beacon_alpha: brightness,
			})
		}
	}

	## The whole mast: legs, rings, braces and beacon, in that order. A mast
	## behind the camera, or sunk wholly below the horizon, draws nothing.
	draw : {
		footprint : Tower.Footprint,
		center : Geom.RiderPoint,
		cam_focal : F64,
		beacon_brightness : Fraction,
	} -> List(Shapes.Shape)
	draw = |
		{
			footprint,
			center,
			cam_focal,
			beacon_brightness,
		},
	| {
		sunk = sunk_below_horizon(center)
		if center.forward < Geom.near_plane or sunk >= tower_height {
			[]
		} else {
			view = {
				rod_width_px: rod_width_at({ forward: center.forward, cam_focal }),
				cam_focal,
			}
			mast = {
				footprint,
				center,
				sunk,
				view,
			}
			apex = {
				right: center.right,
				forward: center.forward,
				height: (tower_height - sunk),
			}
			[
				legs(mast, apex),
				rings(mast),
				braces(mast),
				beacon(mast, { apex, brightness: beacon_brightness }),
			].join()
		}
	}
}
