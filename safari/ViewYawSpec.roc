# ViewYaw: the extra camera yaw on top of the bike's heading.
#
# Ported from safari-codex spec/ViewYawSpec.codex together with the chapter it
# grades (port/ViewYaw.codex) and the grader it uses (spec/Grade.codex). The
# expected lines are the Codex spec's own verdict, frozen in ViewYawSpec.expected.
#
# Every Real is an F64 here, annotated, because Roc's unannotated fraction is a
# Dec and the wants are IEEE-754 doubles: 0.125 + 0.15 * (-0.75) is
# 0.012500000000000011, and the spec grades it at tolerance 0.0.
#
# pose-for is not ported: it needs a List Segment, which the Codex spec does not
# build either.

# --- Grade -------------------------------------------------------------------

g_abs : F64 -> F64
g_abs = |x| if x < 0.0 { 0.0 - x } else { x }

g_finite : F64 -> Bool
g_finite = |x| if F64.is_nan(x) { False } else if F64.is_infinite(x) { False } else { True }

first_real_diff : List(F64), List(F64), F64, U64 -> [AllOk, BadAt(U64)]
first_real_diff = |got, want, tol, i|
	if i >= List.len(got) {
		AllOk
	} else {
		g = List.get(got, i) ?? 0.0
		w = List.get(want, i) ?? 0.0
		if g_finite(g) {
			if g_abs(g - w) > tol {
				BadAt(i)
			} else {
				first_real_diff(got, want, tol, i + 1)
			}
		} else {
			BadAt(i)
		}
	}

grade_reals : Str, List(F64), List(F64), F64 -> Str
grade_reals = |name, got, want, tol|
	if List.len(got) != List.len(want) {
		Str.concat(Str.concat(Str.concat(Str.concat(name, " BAD length "), U64.to_str(List.len(got))), " want "), U64.to_str(List.len(want)))
	} else {
		match first_real_diff(got, want, tol, 0) {
			AllOk => Str.concat(Str.concat(name, " ok "), U64.to_str(List.len(got)))
			BadAt(i) => Str.concat(Str.concat(name, " BAD at "), U64.to_str(i))
		}
	}

# --- ViewYaw -----------------------------------------------------------------

RiderState : { segment : U64, along : F64, across : F64, yaw : F64, v : F64, tilt : F64, heading : F64, gaze_yaw : F64, focus : F64 }

head_yaw_frac : F64
head_yaw_frac = 0.15

view_yaw_for : RiderState -> F64
view_yaw_for = |s| s.gaze_yaw + head_yaw_frac * s.tilt

heading_for : RiderState -> F64
heading_for = |s| s.heading + view_yaw_for(s)

# --- The Rider States --------------------------------------------------------

s0 : RiderState
s0 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

s1 : RiderState
s1 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.125, heading: 4.5, gaze_yaw: 0.375, focus: 0.0 }

s2 : RiderState
s2 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.5, heading: 1.0, gaze_yaw: -0.25, focus: 0.0 }

s3 : RiderState
s3 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: -0.75, heading: -2.0, gaze_yaw: 0.125, focus: 0.0 }

s4 : RiderState
s4 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 1.25, heading: 0.5, gaze_yaw: 0.0, focus: 0.0 }

# --- The Fold ----------------------------------------------------------------

frac_got : List(F64)
frac_got = [head_yaw_frac]

frac_want : List(F64)
frac_want = [0.15]

yaw_got : List(F64)
yaw_got = [view_yaw_for(s0), view_yaw_for(s1), view_yaw_for(s2), view_yaw_for(s3), view_yaw_for(s4)]

yaw_want : List(F64)
yaw_want = [0.0, 0.39375, -0.175, 0.012500000000000011, 0.1875]

head_got : List(F64)
head_got = [heading_for(s0), heading_for(s1), heading_for(s2), heading_for(s3), heading_for(s4)]

head_want : List(F64)
head_want = [0.0, 4.89375, 0.825, -1.9875, 0.6875]

# --- Entry -------------------------------------------------------------------

main! = || {
	echo!(grade_reals("vy-frac", frac_got, frac_want, 0.0))
	echo!(grade_reals("vy-yaw ", yaw_got, yaw_want, 0.0))
	echo!(grade_reals("vy-head", head_got, head_want, 0.0))
}
