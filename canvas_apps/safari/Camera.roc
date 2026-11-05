## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Geom
import Screen

Camera :: [].{

	## The camera's height above the ground, in metres.
	eye_h : F64
	eye_h = 1.2

	## Where a point in front of the camera lands on the screen, through a
	## lens of focal length `cam_focal` in pixels.
	project : Geom.SpacePoint, F64 -> Screen.Point
	project = |p, cam_focal| {
		x: (Screen.center_x + ((p.right / p.forward) * cam_focal)),
		y: (Screen.horizon_y - (((p.height - eye_h) / p.forward) * cam_focal)),
	}

	project_all : List(Geom.SpacePoint), F64 -> List(Screen.Point)
	project_all = |points, cam_focal| points.map(|p| project(p, cam_focal))
}
