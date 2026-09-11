# TrigSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import ListUtils
import Trig

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ang : List(F64)
ang = [0.0, 0.3, 0.7, 1.0, 1.5, 2.0, 3.0, 4.5, 6.0]

sin_want : List(F64)
sin_want = [0.0, 0.29552020666133955, 0.644217687237691, 0.8414709848078965, 0.9974949866040544, 0.9092974268256817, 0.1411200080598672, (-0.977530117665097), (-0.27941549819892586)]

cos_want : List(F64)
cos_want = [1.0, 0.955336489125606, 0.7648421872844885, 0.5403023058681398, 0.0707372016677029, (-0.4161468365471424), (-0.9899924966004454), (-0.2107957994307797), 0.960170286650366]

atan_in : List(F64)
atan_in = [0.0, 0.25, 0.5, 1.0, 2.0, 4.0]

atan_want : List(F64)
atan_want = [0.0, 0.24497866312686414, 0.4636476090008061, 0.7853981633974483, 1.1071487177940904, 1.3258176636680326]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("t-sin ", ListUtils.list_map(Trig.r_sin, ang), sin_want, F64.from_bits(4502148214488346440)))
	line!(Grade.grade_reals("t-cos ", ListUtils.list_map(Trig.r_cos, ang), cos_want, F64.from_bits(4506651814115716936)))
	line!(Grade.grade_reals("t-atan", ListUtils.list_map(Trig.r_atan, atan_in), atan_want, F64.from_bits(4382569440205035030)))
	Ok({})
}
