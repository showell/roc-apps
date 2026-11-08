## GroundPatch is a patch of ground, such as a stretch of road or a pond, and
## how it shows on screen as one polygon that follows the earth's curve down as
## it goes away from the rider.
import Pixels
import RiderView
import Polygon
import EarthCurve
import lib.RgbColor
import lib.Shapes

## A patch of ground: its corners and its colour.
GroundPatch :: { corners : List(RiderView.RiderPoint), color : RgbColor }.{

	## The patch with these corners, in this colour.
	of : List(RiderView.RiderPoint), RgbColor -> GroundPatch
	of = |corners, color| GroundPatch.({ corners, color })

	## The patch's corners, in the order its outline runs.
	corners : GroundPatch -> List(RiderView.RiderPoint)
	corners = |GroundPatch.(patch)| patch.corners

	## A patch on screen, cut at the horizon and at the camera's near plane,
	## unless nothing of it is left.
	patch_shape : GroundPatch, Pixels -> Try(Shapes.Shape, [PastHorizon, BehindCamera])
	patch_shape = |GroundPatch.(patch), focal_length| {
		before_horizon = EarthCurve.points_before_horizon(patch.corners)
		if before_horizon.is_empty() {
			Err(PastHorizon)
		} else {
			polygon = { color: patch.color, corners: before_horizon }
			shape = Polygon.clipped_polygon(polygon, focal_length)?
			Ok(shape)
		}
	}
}
