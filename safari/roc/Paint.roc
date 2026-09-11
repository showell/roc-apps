# Paint -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera

Paint :: [].{
	DrawCmd : { tag : I64, color : I64, color2 : I64, strength : F64, geom : List(F64), pts : List(F64) }

	# flatten_screen builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	flatten_screen : List(Camera.ScreenPt), I64 -> List(F64)
	flatten_screen = |ps, i| flatten_screen_acc(ps, i, [])

	flatten_screen_acc : List(Camera.ScreenPt), I64, List(F64) -> List(F64)
	flatten_screen_acc = |ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { ({
		p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		flatten_screen_acc(ps, (i + 1), List.concat(acc, [p.x, p.y]))
	}) })

	push_poly : I64, List(Camera.ScreenPt) -> List(Paint.DrawCmd)
	push_poly = |color, ps| (if (U64.to_i64_wrap(List.len(ps)) < 3) { [] } else { [{ tag: 0, color: color, color2: 0, strength: 0.0, geom: [], pts: flatten_screen(ps, 0) }] })

	push_round_poly : I64, F64, List(Camera.ScreenPt) -> List(Paint.DrawCmd)
	push_round_poly = |color, strength, ps| (if (U64.to_i64_wrap(List.len(ps)) < 3) { [] } else { [{ tag: 1, color: color, color2: 0, strength: strength, geom: [], pts: flatten_screen(ps, 0) }] })

	push_beacon : I64, F64, F64, F64, F64 -> List(Paint.DrawCmd)
	push_beacon = |color, x, y, r, alpha| [{ tag: 3, color: color, color2: 0, strength: alpha, geom: [x, y, r], pts: [] }]

	push_grad_poly : I64, I64, F64, F64, F64, List(Camera.ScreenPt) -> List(Paint.DrawCmd)
	push_grad_poly = |rgba_center, rgba_edge, cx, cy, r, ps| (if (U64.to_i64_wrap(List.len(ps)) < 3) { [] } else { [{ tag: 4, color: rgba_center, color2: rgba_edge, strength: 0.0, geom: [cx, cy, r], pts: flatten_screen(ps, 0) }] })

	push_linear_grad_poly : I64, I64, F64, F64, F64, F64, F64, F64, List(Camera.ScreenPt) -> List(Paint.DrawCmd)
	push_linear_grad_poly = |rgba0, rgba1, off0, off1, ax, ay, bx, by, ps| (if (U64.to_i64_wrap(List.len(ps)) < 3) { [] } else { [{ tag: 5, color: rgba0, color2: rgba1, strength: 0.0, geom: [off0, off1, ax, ay, bx, by], pts: flatten_screen(ps, 0) }] })

	push_radial_grad_poly : I64, I64, F64, F64, F64, F64, F64, F64, F64, F64, List(Camera.ScreenPt) -> List(Paint.DrawCmd)
	push_radial_grad_poly = |rgba0, rgba1, off0, off1, cx, cy, ux, uy, vx, vy, ps| (if (U64.to_i64_wrap(List.len(ps)) < 3) { [] } else { [{ tag: 6, color: rgba0, color2: rgba1, strength: 0.0, geom: [off0, off1, cx, cy, ux, uy, vx, vy], pts: flatten_screen(ps, 0) }] })
}
