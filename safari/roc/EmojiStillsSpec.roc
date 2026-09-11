# EmojiStillsSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import EmojiStills
import Grade
import Stills
import Tuple

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
facts = |ps| (if (U64.to_i64_wrap(List.len(ps)) == 0) { [0, 0, 0, 0] } else { [U64.to_i64_wrap(List.len(ps)), pts_in(ps, 0), grads_in(ps, 0), (List.get(ps, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).color] })

emoji_facts : I64 -> List(I64)
emoji_facts = |cp| facts(EmojiStills.emoji_polys_for(cp))

table_got : List(I64)
table_got = List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(emoji_facts(129414), emoji_facts(128024)), emoji_facts(129426)), emoji_facts(129427)), emoji_facts(129423)), emoji_facts(128002)), emoji_facts(128004)), emoji_facts(128022)), emoji_facts(129425)), emoji_facts(0))

table_want : List(I64)
table_want = [6, 189, 0, 4493595, 6, 257, 0, 6513507, 24, 850, 0, 16745005, 22, 713, 0, 10197915, 6, 237, 0, 13882323, 43, 2309, 40, 4989733, 16, 469, 0, 10197915, 6, 243, 0, 16735833, 0, 0, 0, 0, 0, 0, 0, 0]

bull_grad : Stills.StillGrad
bull_grad = (List.get((List.get(EmojiStills.bull_polys, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).grad, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))

bg_int_got : List(I64)
bg_int_got = [bull_grad.kind]

bg_int_want : List(I64)
bg_int_want = [1]

bg_real_got : List(F64)
bg_real_got = [bull_grad.off0, bull_grad.off1]

bg_real_want : List(F64)
bg_real_want = [0.0, 1.0]

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_ints("es-table", table_got, table_want))
	line!(Grade.grade_ints("es-bgi  ", bg_int_got, bg_int_want))
	line!(Grade.grade_reals("es-bgr  ", bg_real_got, bg_real_want, 0.0))
	Ok({})
}
