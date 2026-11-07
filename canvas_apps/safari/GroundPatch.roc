## GroundPatch is a patch of ground, such as a stretch of road or a pond, and
## how it shows on screen as one polygon that follows the earth's curve down as
## it goes away from the rider.
import Pixels
import Camera
import Geom
import EarthCurve
import lib.RgbColor
import lib.Shapes

## A patch of ground: its corners and its colour.
GroundPatch := { corners : List(Geom.RiderPoint), color : RgbColor }.{

	## A patch on screen, cut at the horizon and at the camera's near plane,
	## unless nothing of it is left.
	patch_shape : GroundPatch, Pixels -> Try(Shapes.Shape, [PastHorizon, BehindCamera])
	patch_shape = |patch, cam_focal| {
		before_horizon = EarthCurve.points_before_horizon(patch.corners)
		if before_horizon.is_empty() {
			Err(PastHorizon)
		} else {
			polygon = { color: patch.color, corners: before_horizon }
			shape = Camera.clipped_polygon(polygon, cam_focal)?
			Ok(shape)
		}
	}
}
