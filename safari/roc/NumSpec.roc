# NumSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import ListUtils
import Num

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

round_in : List(F64)
round_in = [(-255.5), (-128.5), (-90.0), (-80.4), (-70.5), (-2.5), (-1.5), (-0.5000000000000001), (-0.5), (-0.49999999999999994), (-0.25), 0.0, 0.25, 0.49999999999999994, 0.5, 1.5, 2.5, 4.5, 14.5, 19.5, 29.5, 49.5, 70.5, 127.5, 128.5, 254.5, 255.0, 1048576.5]

round_want : List(F64)
round_want = [(-256.0), (-129.0), (-90.0), (-80.0), (-71.0), (-3.0), (-2.0), (-1.0), (-1.0), (-0.0), (-0.0), 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 5.0, 15.0, 20.0, 30.0, 50.0, 71.0, 128.0, 129.0, 255.0, 255.0, 1048577.0]

floor_in : List(F64)
floor_in = [(-1000.5), (-120.0), (-119.5), (-2.5), (-2.0), (-1.5), (-1.0), (-0.5), 0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 119.5, 120.0, 1000.5]

floor_want : List(F64)
floor_want = [(-1001.0), (-120.0), (-120.0), (-3.0), (-2.0), (-2.0), (-1.0), (-1.0), 0.0, 0.0, 1.0, 1.0, 2.0, 2.0, 119.0, 120.0, 1000.0]

ceil_want : List(F64)
ceil_want = [(-1000.0), (-120.0), (-119.0), (-2.0), (-2.0), (-1.0), (-1.0), 0.0, 0.0, 1.0, 1.0, 2.0, 2.0, 3.0, 120.0, 120.0, 1001.0]

mod_x : List(F64)
mod_x = [(-1000.0), (-240.0), (-239.5), (-120.0), (-119.5), (-0.5), 0.0, 0.5, 119.5, 120.0, 240.5, 1000.0, 3600.25]

mod_m : List(F64)
mod_m = [120.0, 7.5, (-120.0)]

mod_want : List(F64)
mod_want = [80.0, (-0.0), 0.5, (-0.0), 0.5, 119.5, 0.0, 0.5, 119.5, 0.0, 0.5, 40.0, 0.25, 5.0, (-0.0), 0.5, (-0.0), 0.5, 7.0, 0.0, 0.5, 7.0, 0.0, 0.5, 2.5, 0.25, (-40.0), (-0.0), (-119.5), (-0.0), (-119.5), (-0.5), 0.0, (-119.5), (-0.5), 0.0, (-119.5), (-80.0), (-119.75)]

# mod_inner builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
mod_inner : F64, List(F64), I64 -> List(F64)
mod_inner = |m, xs, j| mod_inner_acc(m, xs, j, [])

mod_inner_acc : F64, List(F64), I64, List(F64) -> List(F64)
mod_inner_acc = |m, xs, j, acc| (if (j >= U64.to_i64_wrap(List.len(xs))) { acc } else { mod_inner_acc(m, xs, (j + 1), List.append(acc, Num.mod_real((List.get(xs, I64.to_u64_wrap(j)) ?? crash("list-at out of range")), m))) })

# mod_outer builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
mod_outer : List(F64), List(F64), I64 -> List(F64)
mod_outer = |ms, xs, i| mod_outer_acc(ms, xs, i, [])

mod_outer_acc : List(F64), List(F64), I64, List(F64) -> List(F64)
mod_outer_acc = |ms, xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(ms))) { acc } else { mod_outer_acc(ms, xs, (i + 1), List.concat(acc, mod_inner((List.get(ms, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), xs, 0))) })

pow2_k : List(I64)
pow2_k = [(-55), (-20), (-8), (-1), 0, 1, 8, 20, 55]

pow2_want : List(F64)
pow2_want = [F64.from_bits(4359484439294640128), F64.from_bits(4517110426252607488), 0.00390625, 0.5, 1.0, 2.0, 256.0, 1048576.0, F64.from_bits(4854880398305394688)]

exp_in : List(F64)
exp_in = [(-100.0), (-50.0), (-20.0), (-5.0), (-2.5), (-1.0), (-0.6931471805599453), (-0.3465735902799727), (-0.34657359027997264), (-0.05), 0.0, 0.05, 0.3465735902799727, 0.6931471805599453, 1.0, 2.5, 5.0, 20.0]

exp_want : List(F64)
exp_want = [F64.from_bits(3957129287720677213), F64.from_bits(4282120040917895231), F64.from_bits(4477057993643618919), 0.006737946999085467, 0.0820849986238988, 0.36787944117144233, 0.5, 0.7071067811865475, 0.7071067811865475, 0.951229424500714, 1.0, 1.0512710963760241, 1.4142135623730951, 2.0, 2.7182818284590455, 12.182493960703473, 148.4131591025766, 485165195.4097903]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("n-round", ListUtils.list_map(Num.round_real, round_in), round_want, 0.0))
	line!(Grade.grade_reals("n-floor", ListUtils.list_map(Num.floor_real, floor_in), floor_want, 0.0))
	line!(Grade.grade_reals("n-ceil ", ListUtils.list_map(Num.ceil_real, floor_in), ceil_want, 0.0))
	line!(Grade.grade_reals("n-mod  ", mod_outer(mod_m, mod_x, 0), mod_want, 0.0))
	line!(Grade.grade_reals("n-pow2 ", ListUtils.list_map(Num.pow2_int, pow2_k), pow2_want, 0.0))
	line!(Grade.grade_rel("n-exp  ", ListUtils.list_map(Num.exp_real, exp_in), exp_want, F64.from_bits(4382569440205035030)))
	Ok({})
}
