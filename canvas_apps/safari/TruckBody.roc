## TruckBody gives the sprite of the truck's body: every face of its shape,
## placed at its spot, dimmed as far as the sky has darkened, and projected.
## The shapes come sorted far to near, so a nearer face drawn later covers a
## farther one.
import Camera
import DepthSort
import Distance
import Sky
import Sprite
import TruckPlacement
import TruckShape

TruckBody :: [].{

	## The truck's body in `setting`, its farthest faces first.
	body_sprite : Sprite.Setting -> Sprite
	body_sprite = |setting| {
		placed_faces = TruckShape.truck_faces.map(
			|face| TruckPlacement.placed_face(setting.spot, face),
		)
		faces_far_to_near = DepthSort.sort_by(placed_faces, face_depth)
		dimmed_faces = faces_far_to_near.map(
			|face| { ..face, color: Sky.color_at_darkness(face.color, setting.darkness) },
		)
		Sprite.from_shapes(
			dimmed_faces.keep_oks(|face| Camera.clipped_polygon(face, setting.focal_length)),
		)
	}
}

## How far ahead a placed face is, for the sort: the mean of its corners'
## distances ahead.
face_depth : Camera.FlatPolygon -> Distance
face_depth = |face| DepthSort.mean_depth(face.corners.map(|corner| corner.forward))
