# Ground -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import Geom
import Paint

Ground :: [].{

	ground_vert : Geom.RiderPt -> Geom.Vec3
	ground_vert = |p| { right: p.right, forward: p.forward, height: (0.0 - Geom.ground_drop(p.right, p.forward)) }

	# ground_verts builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	ground_verts : List(Geom.RiderPt), I64 -> List(Geom.Vec3)
	ground_verts = |ps, i| ground_verts_acc(ps, i, [])

	ground_verts_acc : List(Geom.RiderPt), I64, List(Geom.Vec3) -> List(Geom.Vec3)
	ground_verts_acc = |ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { ground_verts_acc(ps, (i + 1), List.append(acc, ground_vert((List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	emit_ground_color : List(Geom.RiderPt), I64, F64, F64 -> List(Paint.DrawCmd)
	emit_ground_color = |ps, color, cf, view_w| (if (U64.to_i64_wrap(List.len(ps)) > 8) { [] } else { ground_clip(Geom.clip_near(ground_verts(ps, 0), Geom.near), color, cf, view_w) })

	ground_clip : List(Geom.Vec3), I64, F64, F64 -> List(Paint.DrawCmd)
	ground_clip = |vs, color, cf, view_w| (if (U64.to_i64_wrap(List.len(vs)) < 3) { [] } else { Paint.push_poly(color, Camera.project_all(vs, cf, view_w, 0)) })
}
