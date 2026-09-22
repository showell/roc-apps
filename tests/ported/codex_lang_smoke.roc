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

import cdx.Iterate
import cdx.ListUtils
import cdx.Prelude
import cdx.Text
import cdx.Tuple

# LangSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Color : [Red, Green, Blue, Yellow, Orange]
Shape : [Circle(I64), Rect(I64, I64)]
Opt(a) : [Some(a), Nada]

check_bool : Bool, Bool -> Bool
check_bool = |a, b| (a and (b or a))

is_warm : Color -> List(U8)
is_warm = |c| (match c {
	Red => [27, 15, 21, 26]
	Orange => [27, 15, 21, 26]
	Yellow => [27, 15, 21, 26]
	Blue => [24, 16, 16, 23]
	Green => [24, 16, 16, 23]
})

area_kind : Shape -> List(U8)
area_kind = |s| (match s {
	Circle(r) if (r > 10) => [23, 15, 21, 29, 13, 73, 24, 17, 21, 24, 23, 13]
	Circle(_r) => [19, 26, 15, 23, 23, 73, 24, 17, 21, 24, 23, 13]
	Rect(w, h) if (w == h) => [19, 37, 25, 15, 21, 13]
	Rect(_w, _h) => [21, 13, 24, 14, 15, 18, 29, 23, 13]
})

count_letters : List(U8), I64, I64 -> I64
count_letters = |s, i, acc| (if (i >= Text.len(s)) { acc } else { (if ((Text.char_at(s, i) >= 13 and Text.char_at(s, i) <= 64) or (Text.char_at(s, i) >= 97 and Text.char_at(s, i) <= 127)) { count_letters(s, (i + 1), (acc + 1)) } else { count_letters(s, (i + 1), acc) }) })

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
	line!(Text.printed((if check_bool(True, True) { [32, 16, 16, 23, 73, 16, 34] } else { [58, 41, 48] })))
	line!(Text.printed((if (5 < 10) { [23, 14] } else { [18, 23, 14] })))
	line!(Text.printed((if (5 == 5) { [13, 37] } else { [18, 13, 37] })))
	line!(Text.printed(Text.show_int(255)))
	line!(Text.printed(Text.show_int(3735928559)))
	({
		chain = ({
			a = 1
			b = (a + 1)
			c = (b + a)
			(c + b)
		})
		({
			line!(Text.printed(Text.show_int(chain)))
			line!(Text.printed(is_warm(Red)))
			line!(Text.printed(is_warm(Blue)))
			line!(Text.printed(area_kind(Circle(20))))
			line!(Text.printed(area_kind(Rect(4, 4))))
			({
				doubled = ListUtils.map_list(lam_0, [1, 2, 3])
				({
					line!(Text.printed(Text.show_int((List.get(doubled, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))))
					line!(Text.printed(Text.show_int(count_letters([20, 13, 23, 23, 16, 2, 27, 16, 21, 23, 22], 0, 0))))
					({
						partial = ({
							dev__1 = 10
							|dev__2| make_adder(dev__1, dev__2)
						})
						({
							line!(Text.printed(Text.show_int(partial(5))))
							({
								p2 = ({
									dev__3 = 1
									dev__4 = 2
									|dev__5| three_deep(dev__3, dev__4, dev__5)
								})
								({
									line!(Text.printed(Text.show_int(p2(3))))
									line!(Text.printed(Text.show_int(id(7))))
									line!(Text.printed(Text.show_int(opt_or(0, opt_map(inc, Some(41))))))
									line!(Text.printed(Text.show_int((match swap_tup(MkTup2(10, 20)) {
										MkTup2(x, y) => sum3(MkTup3(x, y, 99))
									}))))
									line!(Text.printed(Text.show_int(Iterate.list_fold_indexed([1, 2, 3], 0, my_combiner))))
									line!(Text.printed([20, 13, 23, 23, 16]))
									line!(Text.printed((if eq_Shape(Circle(5), Circle(5)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })))
									line!(Text.printed((if eq_Shape(Circle(5), Circle(7)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })))
									line!(Text.printed((if eq_Shape(Circle(5), Rect(3, 4)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })))
									line!(Text.printed(Text.show_int(I64.bitwise_and(12, 10))))
									line!(Text.printed(Text.show_int(I64.shl_wrap(1, I64.to_u8_wrap(8)))))
									line!(Text.printed(Text.show_int(Prelude.int_mod(7, 3))))
									line!(Text.printed(Text.show_int(Prelude.int_abs((-42)))))
									line!(Text.printed(Text.substring([20, 13, 23, 23, 16, 2, 27, 16, 21, 23, 22], 0, 5)))
									({
										parts = Text.split([15, 66, 32, 66, 24], [66])
										line!(Text.printed(Text.show_int(U64.to_i64_wrap(List.len(parts)))))
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
