## Critter draws a still, a picture made of polygons, standing on screen.
## A still is drawn in a unit frame: its feet at the origin, y up, and its
## height 1. Critter scales it to its height in pixels, stands it on its feet,
## and mirrors it when asked. A critter in view is drawn from the emoji still
## for its codepoint.
import Billboards
import Camera
import EmojiStills
import Paint
import Stills

Critter :: [].{

	## Which way a still is drawn: as its polygons are, or mirrored left to
	## right.
	Flip : [AsDrawn, Mirrored]

	## Where a still stands on screen: its feet, which way it is drawn, and
	## its height in pixels.
	Anchor : {
		feet : Camera.ScreenPt,
		flip : Critter.Flip,
		height_px : F64,
	}

	## A polygon with more points than this is not drawn.
	max_still_points : U64
	max_still_points = 512

	## The sign that a still's x is multiplied by.
	x_sign : Critter.Flip -> F64
	x_sign = |flip|
		match flip {
			AsDrawn => 1.0
			Mirrored => (0.0 - 1.0)
		}

	## Where a point of the still lands on screen.
	screen_point : Critter.Anchor, Stills.StillPt -> Camera.ScreenPt
	screen_point = |anchor, point| {
		x: (anchor.feet.x + ((x_sign(anchor.flip) * point.x) * anchor.height_px)),
		y: (anchor.feet.y - (point.y * anchor.height_px)),
	}

	## How far, and which way, a step in the still goes on screen.
	screen_vector : Critter.Anchor, Stills.StillPt -> Camera.ScreenPt
	screen_vector = |anchor, step| {
		x: ((x_sign(anchor.flip) * step.x) * anchor.height_px),
		y: (0.0 - (step.y * anchor.height_px)),
	}

	screen_points : Critter.Anchor, List(Stills.StillPt) -> List(Camera.ScreenPt)
	screen_points = |anchor, points| points.map(|point| Critter.screen_point(anchor, point))

	## One polygon of a still, filled with its colour or its gradient.
	draw_poly : Critter.Anchor, Stills.StillPoly -> List(Paint.DrawCmd)
	draw_poly = |anchor, poly|
		if (poly.pts.len() > max_still_points) {
			[]
		} else {
			points = Critter.screen_points(anchor, poly.pts)
			match poly.grad.first() {
				Ok(gradient) => draw_gradient_poly(anchor, { gradient, points })
				Err(ListWasEmpty) => Paint.push_poly(poly.color, points)
			}
		}

	## A whole still, its polygons in order.
	draw_still : Critter.Anchor, List(Stills.StillPoly) -> List(Paint.DrawCmd)
	draw_still = |anchor, polys| polys.join_map(|poly| Critter.draw_poly(anchor, poly))

	## A critter in view. An emoji faces left, so a critter facing right is
	## its still mirrored. A critter less than a pixel tall isn't drawn.
	draw : Billboards.Billboard, { cam_focal : F64, view_w : F64 } -> List(Paint.DrawCmd)
	draw = |critter, { cam_focal, view_w }| {
		on_screen = |height| Camera.project({ right: critter.right, forward: critter.forward, height }, { cam_focal, view_w })
		feet = on_screen(0.0)
		height_px = (feet.y - on_screen(critter.height).y)
		if (height_px < 1.0) {
			[]
		} else {
			flip =
				match critter.facing {
					FacesLeft => AsDrawn
					FacesRight => Mirrored
				}
			Critter.draw_still({ feet, flip, height_px }, EmojiStills.emoji_polys_for(critter.codepoint))
		}
	}
}

## A still's gradient is linear when its kind is 1, and radial otherwise.
gradient_shape : Stills.StillGrad -> [Linear, Radial]
gradient_shape = |gradient| if (gradient.kind == 1) Linear else Radial

draw_gradient_poly : Critter.Anchor, { gradient : Stills.StillGrad, points : List(Camera.ScreenPt) } -> List(Paint.DrawCmd)
draw_gradient_poly = |anchor, { gradient, points }|
	match gradient_shape(gradient) {
		Linear => {
			start = Critter.screen_point(anchor, { x: gradient.ax, y: gradient.ay })
			stop = Critter.screen_point(anchor, { x: gradient.bx, y: gradient.by })
			Paint.push_linear_grad_poly(
				gradient.rgba0,
				gradient.rgba1,
				gradient.off0,
				gradient.off1,
				start.x,
				start.y,
				stop.x,
				stop.y,
				points,
			)
		}
		Radial => {
			center = Critter.screen_point(anchor, { x: gradient.cx, y: gradient.cy })
			u = Critter.screen_vector(anchor, { x: gradient.ux, y: gradient.uy })
			v = Critter.screen_vector(anchor, { x: gradient.vx, y: gradient.vy })
			Paint.push_radial_grad_poly(
				gradient.rgba0,
				gradient.rgba1,
				gradient.off0,
				gradient.off1,
				center.x,
				center.y,
				u.x,
				u.y,
				v.x,
				v.y,
				points,
			)
		}
	}
