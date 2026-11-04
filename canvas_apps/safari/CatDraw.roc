## CatDraw draws the cat: the still for the pose it is in, scaled to its
## height on screen and raised as it leaps.
import Camera
import Cat
import CatStills
import Paint
import Stills

CatDraw :: [].{

	## Where the cat is on screen: where its feet are, its height in pixels,
	## and how far it is raised off the ground, in the still's units (a cat's
	## height is 1).
	Anchor : { feet : Camera.ScreenPt, height_px : F64, lift : F64 }

	## A polygon with more corners than this is not drawn.
	max_cat_pts : I64
	max_cat_pts = 256

	## A corner of the still, on screen.
	screen_point : CatDraw.Anchor, Stills.StillPt -> Camera.ScreenPt
	screen_point = |anchor, pt| {
		x: (anchor.feet.x + (pt.x * anchor.height_px)),
		y: (anchor.feet.y - ((pt.y + anchor.lift) * anchor.height_px)),
	}

	## One polygon of the still, on screen.
	polygon : CatDraw.Anchor, Stills.StillPoly -> List(Paint.DrawCmd)
	polygon = |anchor, poly|
		if (poly.pts.len().to_i64_wrap() > max_cat_pts) {
			[]
		} else {
			Paint.push_poly(poly.color, poly.pts.map(|pt| screen_point(anchor, pt)))
		}

	## A still's polygons on screen, in order.
	polygons : CatDraw.Anchor, List(Stills.StillPoly) -> List(Paint.DrawCmd)
	polygons = |anchor, polys| polys.join_map(|poly| polygon(anchor, poly))

	## The cat standing `right` and `forward` of the camera, `height` tall,
	## in `pose` and raised by `lift`. A cat under a pixel tall is not drawn.
	draw : {
		right : F64,
		forward : F64,
		height : F64,
		pose : Cat.Pose,
		lift : F64,
		cam_focal : F64,
		view_w : F64,
	} -> List(Paint.DrawCmd)
	draw = |{ right, forward, height, pose, lift, cam_focal, view_w }| {
		feet = Camera.project({ right, forward, height: 0.0 }, { cam_focal, view_w })
		top = Camera.project({ right, forward, height }, { cam_focal, view_w })
		height_px = (feet.y - top.y)
		if (height_px < 1.0) {
			[]
		} else {
			polygons({ feet, height_px, lift }, CatStills.pose_polys(pose))
		}
	}
}
