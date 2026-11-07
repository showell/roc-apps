# Witch -- whoever answers the door, in silhouette.
#
# Hand-written, and drawn at her own size at her own distance, so the
# projection shrinks her and stands her feet on the part of the floor she is
# on. Scaling a figure pinned to the doorway put her feet on the threshold
# whatever it was pretending about how far back she was.
#
# **SHE ARRIVES BY WALKING.** There is no clipping of one shape to another in
# the vocabulary, so she cannot walk in from the side of a doorway; coming up
# the hall from the back of it keeps her inside the one lit rectangle the whole
# way, and is what someone answering a door does.
#
# She knows nothing about a house or a clock: a distance, and how far along
# coming to the door she is.
import lib.Shapes
import lib.Brush
import lib.RgbColor
import Eye
import Panels

Witch :: [].{
	# She is between whoever is looking and the light behind her, so she has
	# no colour of her own beyond the little there is to catch.
	witch_c : Brush.Rgba
	witch_c = Brush.opaque(RgbColor.of(0x090608))
	eye_c : Brush.Rgba
	eye_c = Brush.opaque(RgbColor.of(0xc8f05a))

	# How far back she starts.
	comes_from : F64
	comes_from = 2.2

	shapes : Eye.Eye, F64, F64 -> List(Shapes.Shape)
	shapes = |v, door_f, u|
		if u <= 0.0 {
			[]
		} else {
			fwd = door_f + comes_from * (1.0 - u)
			stands = { right: 0.0, forward: fwd, height: 1.0 }
			match Eye.sighting(v, stands) {
				Err(BehindEye) => []
				Ok({ pixels_per_metre: ppm, .. }) => {
					shoulder_l = Eye.project(v, { right: 0.0 - 0.19, forward: fwd, height: 1.10 })
					shoulder_r = Eye.project(v, { right: 0.19, forward: fwd, height: 1.10 })
					hand_l = Eye.project(v, { right: 0.0 - 0.52, forward: fwd, height: 0.70 })
					hand_r = Eye.project(v, { right: 0.52, forward: fwd, height: 0.70 })
					head = Eye.project(v, { right: 0.0, forward: fwd, height: 1.24 })
					eye_l = Eye.project(v, { right: 0.0 - 0.045, forward: fwd, height: 1.26 })
					eye_r = Eye.project(v, { right: 0.045, forward: fwd, height: 1.26 })
					var $out = List.with_capacity(14)
					# Two legs and two long pointed shoes, under a hem that stops
					# short of the floor.
					$out = List.concat($out, Panels.face(v, fwd, [0.0 - 0.15, 0.26, 0.0 - 0.07, 0.26, 0.0 - 0.07, 0.05, 0.0 - 0.15, 0.05], Flat(witch_c)))
					$out = List.concat($out, Panels.face(v, fwd, [0.07, 0.26, 0.15, 0.26, 0.15, 0.05, 0.07, 0.05], Flat(witch_c)))
					$out = List.concat($out, Panels.face(v, fwd, [0.0 - 0.15, 0.08, 0.0 - 0.06, 0.08, 0.0 - 0.32, 0.0], Flat(witch_c)))
					$out = List.concat($out, Panels.face(v, fwd, [0.15, 0.08, 0.06, 0.08, 0.32, 0.0], Flat(witch_c)))
					# The robe, flaring to the hem.
					$out = List.concat($out, Panels.face(v, fwd, [0.0 - 0.19, 1.10, 0.19, 1.10, 0.30, 0.66, 0.42, 0.24, 0.0 - 0.42, 0.24, 0.0 - 0.30, 0.66], Flat(witch_c)))
					# Two arms, held out from it.
					$out = List.append($out, Shapes.line({ from: shoulder_l, to: hand_l, width: 0.075 * ppm }, Flat(witch_c)))
					$out = List.append($out, Shapes.line({ from: shoulder_r, to: hand_r, width: 0.075 * ppm }, Flat(witch_c)))
					$out = List.append($out, Disc({ x: head.x, y: head.y, radius: 0.115 * ppm, fill: Flat(witch_c) }))
					# The hat: a brim, and a point that leans.
					$out = List.concat($out, Panels.face(v, fwd, [0.0 - 0.32, 1.37, 0.32, 1.37, 0.30, 1.31, 0.0 - 0.30, 1.31], Flat(witch_c)))
					$out = List.concat($out, Panels.face(v, fwd, [0.0 - 0.25, 1.36, 0.25, 1.36, 0.12, 1.86], Flat(witch_c)))
					# **THE ONLY PART OF HER THAT IS NOT DARK.** A silhouette says
					# somebody; two eyes say who.
					$out = List.append($out, Disc({ x: eye_l.x, y: eye_l.y, radius: 0.022 * ppm, fill: Flat(eye_c) }))
					List.append($out, Disc({ x: eye_r.x, y: eye_r.y, radius: 0.022 * ppm, fill: Flat(eye_c) }))
				}
			}
		}
}
