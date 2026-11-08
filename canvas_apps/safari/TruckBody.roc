## TruckBody gives the picture of the truck's body: every face of its shape,
## placed at its spot and projected. The shapes come sorted far to near, so a
## nearer face drawn later covers a farther one.
import DepthSort
import Picture
import Polygon
import TruckPlacement
import TruckShape

TruckBody :: [].{

	## The truck's body, its farthest faces first. A face is ordered by the
	## mean of its corners' distances ahead.
	body_picture : TruckPlacement.TruckSetting -> Picture
	body_picture = |truck|
		Picture.from_shapes(
			DepthSort.sort_by(
				TruckShape.truck_faces.map(|face| TruckPlacement.placed_face(truck, face)),
				|face| DepthSort.mean_depth(face.corners.map(|corner| corner.forward)),
			)
				.keep_oks(|face| Polygon.clipped_polygon(face, truck.focal_length)),
		)
}
