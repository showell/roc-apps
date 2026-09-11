# CatDraw -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import CatStills
import Paint
import Stills

CatDraw :: [].{

	max_cat_pts : I64
	max_cat_pts = 256

	cat_pt : Camera.ScreenPt, F64, F64, Stills.StillPt -> Camera.ScreenPt
	cat_pt = |b, h, lift, p| { x: (b.x + (p.x * h)), y: (b.y - ((p.y + lift) * h)) }

	# cat_pts builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	cat_pts : Camera.ScreenPt, F64, F64, List(Stills.StillPt), I64 -> List(Camera.ScreenPt)
	cat_pts = |b, h, lift, ps, i| cat_pts_acc(b, h, lift, ps, i, [])

	cat_pts_acc : Camera.ScreenPt, F64, F64, List(Stills.StillPt), I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	cat_pts_acc = |b, h, lift, ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { cat_pts_acc(b, h, lift, ps, (i + 1), List.concat(acc, [cat_pt(b, h, lift, (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))])) })

	cat_poly : Camera.ScreenPt, F64, F64, Stills.StillPoly -> List(Paint.DrawCmd)
	cat_poly = |b, h, lift, poly| (if (U64.to_i64_wrap(List.len(poly.pts)) > max_cat_pts) { [] } else { Paint.push_poly(poly.color, cat_pts(b, h, lift, poly.pts, 0)) })

	# cat_polys builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	cat_polys : Camera.ScreenPt, F64, F64, List(Stills.StillPoly), I64 -> List(Paint.DrawCmd)
	cat_polys = |b, h, lift, ps, i| cat_polys_acc(b, h, lift, ps, i, [])

	cat_polys_acc : Camera.ScreenPt, F64, F64, List(Stills.StillPoly), I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	cat_polys_acc = |b, h, lift, ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { cat_polys_acc(b, h, lift, ps, (i + 1), List.concat(acc, cat_poly(b, h, lift, (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	cat_draw : F64, F64, F64, I64, F64, F64, F64 -> List(Paint.DrawCmd)
	cat_draw = |right, forward, height, pose_idx, lift, cf, view_w| ({
		base = Camera.project({ right: right, forward: forward, height: 0.0 }, cf, view_w)
		top = Camera.project({ right: right, forward: forward, height: height }, cf, view_w)
		h = (base.y - top.y)
		(if (h < 1.0) { [] } else { cat_polys(base, h, lift, CatStills.cat_polys_for(pose_idx), 0) })
	})
}
