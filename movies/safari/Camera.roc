# Camera -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Geom

Camera :: [].{
	ScreenPt : { x : F64, y : F64 }

	camera_h : F64
	camera_h = 600.0

	eye_h : F64
	eye_h = 1.2

	project : Geom.Vec3, F64, F64 -> Camera.ScreenPt
	project = |p, cf, view_w| { x: ((view_w / 2.0) + ((p.right / p.forward) * cf)), y: ((camera_h / 2.0) - (((p.height - eye_h) / p.forward) * cf)) }

	# project_all builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	project_all : List(Geom.Vec3), F64, F64, I64 -> List(Camera.ScreenPt)
	project_all = |ps, cf, view_w, i| project_all_acc(ps, cf, view_w, i, [])

	project_all_acc : List(Geom.Vec3), F64, F64, I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	project_all_acc = |ps, cf, view_w, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { project_all_acc(ps, cf, view_w, (i + 1), List.append(acc, project((List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), cf, view_w))) })
}
