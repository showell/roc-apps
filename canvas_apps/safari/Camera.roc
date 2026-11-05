## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Geom
import Screen

Camera :: [].{

	## What a frame is seen through: the lens's focal length in pixels, and
	## the width of the view.
	View : { cam_focal : F64, view_w : F64 }

	## The camera's height above the ground, in metres.
	eye_h : F64
	eye_h = 1.2

	## Where a point in front of the camera lands on the screen.
	project : Geom.SpacePoint, Camera.View -> Screen.Point
	project = |p, { cam_focal, view_w }| {
		x: ((view_w / 2.0) + ((p.right / p.forward) * cam_focal)),
		y: (Screen.horizon_y - (((p.height - eye_h) / p.forward) * cam_focal)),
	}

	project_all : List(Geom.SpacePoint), Camera.View -> List(Screen.Point)
	project_all = |points, view| points.map(|p| project(p, view))
}
