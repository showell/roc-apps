# Critter -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import EmojiStills
import Paint
import Stills

Critter :: [].{

	map_p : Camera.ScreenPt, F64, F64, F64, F64 -> Camera.ScreenPt
	map_p = |b, s, ht, x, y| { x: (b.x + ((s * x) * ht)), y: (b.y - (y * ht)) }

	facing : Bool -> F64
	facing = |face_right| (if face_right { (0.0 - 1.0) } else { 1.0 })

	# mapped_pts builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	mapped_pts : Camera.ScreenPt, F64, F64, List(Stills.StillPt), I64 -> List(Camera.ScreenPt)
	mapped_pts = |b, s, ht, ps, i| mapped_pts_acc(b, s, ht, ps, i, [])

	mapped_pts_acc : Camera.ScreenPt, F64, F64, List(Stills.StillPt), I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	mapped_pts_acc = |b, s, ht, ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { mapped_pts_acc(b, s, ht, ps, (i + 1), List.concat(acc, [map_p(b, s, ht, (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).y)])) })

	max_critter_pts : I64
	max_critter_pts = 512

	map_v : F64, F64, F64, F64 -> Camera.ScreenPt
	map_v = |s, ht, x, y| { x: ((s * x) * ht), y: (0.0 - (y * ht)) }

	critter_poly : Camera.ScreenPt, F64, F64, Stills.StillPoly -> List(Paint.DrawCmd)
	critter_poly = |b, s, ht, poly| (if (U64.to_i64_wrap(List.len(poly.pts)) > max_critter_pts) { [] } else { (if (U64.to_i64_wrap(List.len(poly.grad)) > 0) { critter_grad(b, s, ht, poly, (List.get(poly.grad, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) } else { Paint.push_poly(poly.color, mapped_pts(b, s, ht, poly.pts, 0)) }) })

	critter_grad : Camera.ScreenPt, F64, F64, Stills.StillPoly, Stills.StillGrad -> List(Paint.DrawCmd)
	critter_grad = |b, s, ht, poly, g| ({
		pts = mapped_pts(b, s, ht, poly.pts, 0)
		(if (g.kind == 1) { critter_linear(b, s, ht, g, pts) } else { critter_radial(b, s, ht, g, pts) })
	})

	critter_linear : Camera.ScreenPt, F64, F64, Stills.StillGrad, List(Camera.ScreenPt) -> List(Paint.DrawCmd)
	critter_linear = |b, s, ht, g, pts| ({
		p0 = map_p(b, s, ht, g.ax, g.ay)
		p1 = map_p(b, s, ht, g.bx, g.by)
		Paint.push_linear_grad_poly(g.rgba0, g.rgba1, g.off0, g.off1, p0.x, p0.y, p1.x, p1.y, pts)
	})

	critter_radial : Camera.ScreenPt, F64, F64, Stills.StillGrad, List(Camera.ScreenPt) -> List(Paint.DrawCmd)
	critter_radial = |b, s, ht, g, pts| ({
		c = map_p(b, s, ht, g.cx, g.cy)
		u = map_v(s, ht, g.ux, g.uy)
		v = map_v(s, ht, g.vx, g.vy)
		Paint.push_radial_grad_poly(g.rgba0, g.rgba1, g.off0, g.off1, c.x, c.y, u.x, u.y, v.x, v.y, pts)
	})

	# critter_polys builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	critter_polys : Camera.ScreenPt, F64, F64, List(Stills.StillPoly), I64 -> List(Paint.DrawCmd)
	critter_polys = |b, s, ht, ps, i| critter_polys_acc(b, s, ht, ps, i, [])

	critter_polys_acc : Camera.ScreenPt, F64, F64, List(Stills.StillPoly), I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	critter_polys_acc = |b, s, ht, ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { critter_polys_acc(b, s, ht, ps, (i + 1), List.concat(acc, critter_poly(b, s, ht, (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	critter_draw : F64, F64, F64, I64, Bool, F64, F64 -> List(Paint.DrawCmd)
	critter_draw = |right, forward, height, cp, face_right, cf, view_w| ({
		base = Camera.project({ right: right, forward: forward, height: 0.0 }, cf, view_w)
		top = Camera.project({ right: right, forward: forward, height: height }, cf, view_w)
		h = (base.y - top.y)
		(if (h < 1.0) { [] } else { critter_polys(base, facing(face_right), h, EmojiStills.emoji_polys_for(cp), 0) })
	})
}
