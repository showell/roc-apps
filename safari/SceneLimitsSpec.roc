# SceneLimits: three shared culls, pinned.
#
# Ported from safari-codex spec/SceneLimitsSpec.codex with the chapter it grades
# (port/SceneLimits.codex) and the grader it uses (spec/Grade.codex). The
# expected line is the Codex spec's own verdict, frozen in SceneLimitsSpec.expected.
#
# Every Real is an F64 here, annotated, because Roc's unannotated fraction is a
# Dec. g_finite is Grade's own: clear the sign bit of the double and every
# finite value is below 0x7FF0000000000000.

# --- Grade -------------------------------------------------------------------

g_abs : F64 -> F64
g_abs = |x| if x < 0.0 { 0.0 - x } else { x }

g_finite : F64 -> Bool
g_finite = |x| I64.bitwise_and(U64.to_i64_wrap(F64.to_bits(x)), 9223372036854775807) < 9218868437227405312

first_real_diff : List(F64), List(F64), F64, I64 -> I64
first_real_diff = |got, want, tol, i|
	if i >= U64.to_i64_wrap(List.len(got)) {
		0 - 1
	} else if g_finite(List.get(got, I64.to_u64_wrap(i)) ?? 0.0) {
		if g_abs((List.get(got, I64.to_u64_wrap(i)) ?? 0.0) - (List.get(want, I64.to_u64_wrap(i)) ?? 0.0)) > tol {
			i
		} else {
			first_real_diff(got, want, tol, i + 1)
		}
	} else {
		i
	}

grade_reals : Str, List(F64), List(F64), F64 -> Str
grade_reals = |name, got, want, tol|
	if List.len(got) != List.len(want) {
		Str.concat(Str.concat(Str.concat(Str.concat(name, " BAD length "), U64.to_str(List.len(got))), " want "), U64.to_str(List.len(want)))
	} else {
		i = first_real_diff(got, want, tol, 0)
		if i < 0 {
			Str.concat(Str.concat(name, " ok "), U64.to_str(List.len(got)))
		} else {
			Str.concat(Str.concat(name, " BAD at "), I64.to_str(i))
		}
	}

# --- SceneLimits -------------------------------------------------------------

detail_dist : F64
detail_dist = 200.0

crown_shade_dist : F64
crown_shade_dist = 80.0

min_scenery_px : F64
min_scenery_px = 2.0

# --- The Shared Culls --------------------------------------------------------

culls_got : List(F64)
culls_got = [detail_dist, crown_shade_dist, min_scenery_px]

culls_want : List(F64)
culls_want = [200.0, 80.0, 2.0]

# --- Entry -------------------------------------------------------------------

line! = |s| echo!(Str.concat(s, "\n"))

main! = |_args| {
	line!(grade_reals("sl-cull", culls_got, culls_want, 0.0))
	Ok({})
}
