# Billboards -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Geom
import Lens

Billboards :: [].{
	Billboard : { right : F64, fwd : F64, height : F64, cp : I64, face_right : Bool }
	Placed : { b : Billboards.Billboard, kept : Bool, size_culled : Bool }

	min_critter_px : F64
	min_critter_px = 2.0

	no_billboard : Billboards.Billboard
	no_billboard = { right: 0.0, fwd: 0.0, height: 0.0, cp: 0, face_right: False }

	verdict : Geom.RiderPt, F64, I64, Bool -> Billboards.Placed
	verdict = |rp, h, cp, fr| (if (rp.forward <= Geom.near) { { b: no_billboard, kept: False, size_culled: False } } else { (if (((h / rp.forward) * Lens.focal) < min_critter_px) { { b: no_billboard, kept: False, size_culled: True } } else { { b: { right: rp.right, fwd: rp.forward, height: h, cp: cp, face_right: fr }, kept: True, size_culled: False } }) })

	kept_of : List(Billboards.Placed), I64 -> List(Billboards.Billboard)
	kept_of = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { [] } else { (if (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).kept { List.concat([(List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).b], kept_of(ps, (i + 1))) } else { kept_of(ps, (i + 1)) }) })

	size_culled_of : List(Billboards.Placed), I64 -> I64
	size_culled_of = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { 0 } else { (if (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).size_culled { (1 + size_culled_of(ps, (i + 1))) } else { size_culled_of(ps, (i + 1)) }) })
}
