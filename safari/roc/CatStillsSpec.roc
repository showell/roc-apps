# CatStillsSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import CatStills
import Grade
import Stills
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pts_in : List(Stills.StillPoly), I64 -> I64
pts_in = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { 0 } else { ({
	p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	(U64.to_i64_wrap(List.len(p.pts)) + pts_in(ps, (i + 1)))
}) })

grads_in : List(Stills.StillPoly), I64 -> I64
grads_in = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { 0 } else { ({
	p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	(U64.to_i64_wrap(List.len(p.grad)) + grads_in(ps, (i + 1)))
}) })

facts : List(Stills.StillPoly) -> List(I64)
facts = |ps| [U64.to_i64_wrap(List.len(ps)), pts_in(ps, 0), grads_in(ps, 0)]

pose_facts : I64 -> List(I64)
pose_facts = |i| facts(CatStills.cat_polys_for(i))

table_got : List(I64)
table_got = List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(pose_facts(0), pose_facts(1)), pose_facts(2)), pose_facts(3)), pose_facts(4)), pose_facts(5)), pose_facts(6)), pose_facts(7)), pose_facts((0 - 1)))

table_want : List(I64)
table_want = [46, 2198, 0, 46, 2198, 0, 47, 2197, 0, 34, 1715, 0, 34, 1715, 0, 34, 1715, 0, 34, 1715, 0, 0, 0, 0, 0, 0, 0]

first_x : I64 -> F64
first_x = |i| ({
	ps = CatStills.cat_polys_for(i)
	(List.get((List.get(ps, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).x
})

spot_got : List(F64)
spot_got = [first_x(3), first_x(4), first_x(5), first_x(6)]

spot_want : List(F64)
spot_want = [0.5062, 0.6873, 0.6467, 0.6377]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_ints([24, 19, 73, 14, 15, 32, 23, 13], table_got, table_want)))
	line!(Text.printed(Grade.grade_reals([24, 19, 73, 19, 31, 16, 14, 2], spot_got, spot_want, 0.0)))
	Ok({})
}
