# lang-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lang-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     bool-ok
#     lt
#     eq
#     255
#     3735928559
#     5
#     warm
#     cool
#     large-circle
#     square
#     4
#     10
#     15
#     6
#     7
#     42
#     129
#     63
#     hello
#     True
#     False
#     False
#     8
#     256
#     1
#     42
#     hello
#     3

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceChar
import cdx.CceText
import cdx.Iterate
import cdx.ListUtils
import cdx.Prelude
import cdx.Tuple

# LangSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Color : [Red, Green, Blue, Yellow, Orange]
Shape : [Circle(I64), Rect(I64, I64)]
Opt(a) : [Some(a), Nada]

check_bool : Bool, Bool -> Bool
check_bool = |a, b| (a and (b or a))

is_warm : Color -> CceText
is_warm = |c| (match c {
	Red => "warm"
	Orange => "warm"
	Yellow => "warm"
	Blue => "cool"
	Green => "cool"
})

area_kind : Shape -> CceText
area_kind = |s| (match s {
	Circle(r) if (r > 10) => "large-circle"
	Circle(_r) => "small-circle"
	Rect(w, h) if (w == h) => "square"
	Rect(_w, _h) => "rectangle"
})

count_letters : CceText, I64, I64 -> I64
count_letters = |s, i, acc| (if (i >= CceText.len(s)) { acc } else { (if CceChar.is_letter(CceText.char_at(s, i)) { count_letters(s, (i + 1), (acc + 1)) } else { count_letters(s, (i + 1), acc) }) })

make_adder : I64, I64 -> I64
make_adder = |x, y| (x + y)

three_deep : I64, I64, I64 -> I64
three_deep = |a, b, c| ((a + b) + c)

id : a -> a
id = |x| x

inc : I64 -> I64
inc = |n| (n + 1)

opt_or : a, Opt(a) -> a
opt_or = |d, m| (match m {
	Some(x) => x
	Nada => d
})

opt_map : (a -> b), Opt(a) -> Opt(b)
opt_map = |f, m| (match m {
	Some(x) => Some(f(x))
	Nada => Nada
})

swap_tup : Tuple.Tup2(a, b) -> Tuple.Tup2(b, a)
swap_tup = |p| (match p {
	MkTup2(x, y) => MkTup2(y, x)
})

sum3 : Tuple.Tup3(I64, I64, I64) -> I64
sum3 = |t| (match t {
	MkTup3(a, b, c) => ((a + b) + c)
})

my_combiner : I64, I64, I64 -> I64
my_combiner = |acc, elem, idx| ((acc + (elem * 10)) + idx)

eq_Color : Color, Color -> Bool
eq_Color = |ex, ey| (match ex {
	Red => (match ey {
		Red => True
		_ => False
	})
	Green => (match ey {
		Green => True
		_ => False
	})
	Blue => (match ey {
		Blue => True
		_ => False
	})
	Yellow => (match ey {
		Yellow => True
		_ => False
	})
	Orange => (match ey {
		Orange => True
		_ => False
	})
})

eq_Shape : Shape, Shape -> Bool
eq_Shape = |ex, ey| (match ex {
	Circle(exf0) => (match ey {
		Circle(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Rect(exf0, exf1) => (match ey {
		Rect(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_Opt : Opt(a), Opt(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Opt = |ex, ey| (match ex {
	Some(exf0) => (match ey {
		Some(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Nada => (match ey {
		Nada => True
		_ => False
	})
})

lam_0 : I64 -> I64
lam_0 = |x| (x + x)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed((if check_bool(True, True) { "bool-ok" } else { "BAD" })))
	line!(CceText.printed((if (5 < 10) { "lt" } else { "nlt" })))
	line!(CceText.printed((if (5 == 5) { "eq" } else { "neq" })))
	line!(CceText.printed(CceText.show_int(255)))
	line!(CceText.printed(CceText.show_int(3735928559)))
	({
		chain = ({
			a = 1
			b = (a + 1)
			c = (b + a)
			(c + b)
		})
		({
			line!(CceText.printed(CceText.show_int(chain)))
			line!(CceText.printed(is_warm(Red)))
			line!(CceText.printed(is_warm(Blue)))
			line!(CceText.printed(area_kind(Circle(20))))
			line!(CceText.printed(area_kind(Rect(4, 4))))
			({
				doubled = ListUtils.map_list(lam_0, [1, 2, 3])
				({
					line!(CceText.printed(CceText.show_int((List.get(doubled, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))))
					line!(CceText.printed(CceText.show_int(count_letters("hello world", 0, 0))))
					({
						partial = ({
							dev__1 = 10
							|dev__2| make_adder(dev__1, dev__2)
						})
						({
							line!(CceText.printed(CceText.show_int(partial(5))))
							({
								p2 = ({
									dev__3 = 1
									dev__4 = 2
									|dev__5| three_deep(dev__3, dev__4, dev__5)
								})
								({
									line!(CceText.printed(CceText.show_int(p2(3))))
									line!(CceText.printed(CceText.show_int(id(7))))
									line!(CceText.printed(CceText.show_int(opt_or(0, opt_map(inc, Some(41))))))
									line!(CceText.printed(CceText.show_int((match swap_tup(MkTup2(10, 20)) {
										MkTup2(x, y) => sum3(MkTup3(x, y, 99))
									}))))
									line!(CceText.printed(CceText.show_int(Iterate.list_fold_indexed([1, 2, 3], 0, my_combiner))))
									line!(CceText.printed("hello"))
									line!(CceText.printed((if eq_Shape(Circle(5), Circle(5)) { "True" } else { "False" })))
									line!(CceText.printed((if eq_Shape(Circle(5), Circle(7)) { "True" } else { "False" })))
									line!(CceText.printed((if eq_Shape(Circle(5), Rect(3, 4)) { "True" } else { "False" })))
									line!(CceText.printed(CceText.show_int(I64.bitwise_and(12, 10))))
									line!(CceText.printed(CceText.show_int(I64.shl_wrap(1, I64.to_u8_wrap(8)))))
									line!(CceText.printed(CceText.show_int(Prelude.int_mod(7, 3))))
									line!(CceText.printed(CceText.show_int(Prelude.int_abs((-42)))))
									line!(CceText.printed(CceText.substring("hello world", 0, 5)))
									({
										parts = CceText.split("a,b,c", ",")
										line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(parts)))))
									})
								})
							})
						})
					})
				})
			})
		})
	})
	Ok({})
}
