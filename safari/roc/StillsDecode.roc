# StillsDecode -- the decoder for baked stills; see roc-apps/safari/bake_stills.py.
import Stills

StillsDecode :: [].{
	stills_real : Str -> F64
	stills_real = |t| F64.from_str(t) ?? crash("stills: bad real")

	stills_int : Str -> I64
	stills_int = |t| I64.from_str(t) ?? crash("stills: bad integer")

	stills_pt : Str -> Stills.StillPt
	stills_pt = |t| match Str.split_first(t, ",") {
		Ok(r) => { x: stills_real(r.before), y: stills_real(r.after) }
		Err(_) => crash("stills: bad point")
	}

	stills_field : List(Str), U64 -> Str
	stills_field = |f, i| List.get(f, i) ?? crash("stills: short row")

	stills_grad : Str -> List(Stills.StillGrad)
	stills_grad = |t| if Str.is_empty(t) { [] } else { stills_grad_row(Str.split_on(t, ",")) }

	stills_grad_row : List(Str) -> List(Stills.StillGrad)
	stills_grad_row = |f| [{ kind: stills_int(stills_field(f, 0)), rgba0: stills_int(stills_field(f, 1)), rgba1: stills_int(stills_field(f, 2)), off0: stills_real(stills_field(f, 3)), off1: stills_real(stills_field(f, 4)), ax: stills_real(stills_field(f, 5)), ay: stills_real(stills_field(f, 6)), bx: stills_real(stills_field(f, 7)), by: stills_real(stills_field(f, 8)), cx: stills_real(stills_field(f, 9)), cy: stills_real(stills_field(f, 10)), ux: stills_real(stills_field(f, 11)), uy: stills_real(stills_field(f, 12)), vx: stills_real(stills_field(f, 13)), vy: stills_real(stills_field(f, 14)) }]

	stills_poly : Str -> Stills.StillPoly
	stills_poly = |t| stills_poly_row(Str.split_on(t, "|"))

	stills_poly_row : List(Str) -> Stills.StillPoly
	stills_poly_row = |f| { color: stills_int(stills_field(f, 0)), grad: stills_grad(stills_field(f, 1)), pts: List.map(Str.split_on(stills_field(f, 2), ";"), stills_pt) }

	stills_polys : Str -> List(Stills.StillPoly)
	stills_polys = |t| List.map(Str.split_on(t, "/"), stills_poly)
}
