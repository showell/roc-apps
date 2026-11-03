# Camera -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Geom
import Screen

Camera :: [].{
	ScreenPt : { x : F64, y : F64 }

	eye_h : F64
	eye_h = 1.2

	project : Geom.Vec3, F64, F64 -> Camera.ScreenPt
	project = |p, cf, view_w| { x: ((view_w / 2.0) + ((p.right / p.forward) * cf)), y: (Screen.horizon_y - (((p.height - eye_h) / p.forward) * cf)) }

	# project_all builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	project_all : List(Geom.Vec3), F64, F64 -> List(Camera.ScreenPt)
	project_all = |ps, cf, view_w| project_all_onto(ps, cf, view_w, 0, [])

	project_all_onto : List(Geom.Vec3), F64, F64, I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	project_all_onto = |ps, cf, view_w, i, acc| (
		if (i >= ps.len().to_i64_wrap()) {
			acc
		} else {
			project_all_onto(ps, cf, view_w, (i + 1), List.append(acc, project((List.get(ps, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")), cf, view_w)))
		}
	)
}
