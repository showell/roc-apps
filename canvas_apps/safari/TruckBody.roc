## TruckBody gives the sprite of the truck's body: every face of its shape,
## placed at its spot, dimmed as far as the sky has darkened, and projected.
## The shapes come sorted far to near, so a nearer face drawn later covers a
## farther one.
import Camera
import DepthSort
import Sky
import Sprite
import TruckPlacement
import TruckShape

TruckBody :: [].{

	## The truck's body, its farthest faces first. A face is ordered by the
	## mean of its corners' distances ahead.
	body_sprite : TruckPlacement.TruckSetting -> Sprite
	body_sprite = |truck| {
		Sprite.from_shapes(
			DepthSort.sort_by(
				TruckShape.truck_faces.map(|face| TruckPlacement.placed_face(truck.spot, face)),
				|face| DepthSort.mean_depth(face.corners.map(|corner| corner.forward)),
			)
				.map(|face| { ..face, color: Sky.color_at_darkness(face.color, truck.darkness) })
				.keep_oks(|face| Camera.clipped_polygon(face, truck.focal_length)),
		)
	}
}
