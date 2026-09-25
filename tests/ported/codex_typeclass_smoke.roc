# typeclass-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/typeclass-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42
#     Value: 99
#     Value: yes
#     Value: 42
#     list of 3
#     True
#     False
#     False
#     0
#     none
#     42
#     Green
#     Circle 5
#     Rect 3 4
#     True
#     False
#     True
#     False
#     True
#     -1
#     0
#     [Circle 5]
#     [42]
#     [True]
#     42/Blue
#     <7>
#     lt
#     eq
#     lt

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# TypeClassSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Color : [Red, Green, Blue]
Shape : [Circle(I64), Rect(I64, I64)]
Wrap : [Wrap(I64)]
Point := { x : I64, y : I64 }.{
	is_eq : Point, Point -> Bool
	is_eq = |a, b| eq_Point(a, b)
}
ShowDict := { show_impl : (I64 -> CceText) }
ShowableDict(a) : { to_text_impl : (a -> CceText) }
EquatableDict(a) : { is_equal_impl : (a, a -> Bool) }
ZeroedDict(a) : { zero_val_impl : a }

compare_Integer : I64, I64 -> I64
compare_Integer = |wx, wy| ({
	cmpa : I64
	cmpa = wx
	cmpb : I64
	cmpb = wy
	(if (cmpa < cmpb) { (-1) } else { (if (cmpa > cmpb) { 1 } else { 0 }) })
})

compare_Boolean : Bool, Bool -> I64
compare_Boolean = |wx, wy| if wx == wy { 0 } else if wx { 1 } else { -1 }

compare_Text : CceText, CceText -> I64
compare_Text = |wx, wy| CceText.compare(wx, wy)

compare_Real : F64, F64 -> I64
compare_Real = |wx, wy| if wx < wy { -1 } else if wx > wy { 1 } else { 0 }

show_Integer : I64 -> CceText
show_Integer = |w| CceText.show_int(w)

show_Boolean : Bool -> CceText
show_Boolean = |w| (if w { "True" } else { "False" })

show_Text : CceText -> CceText
show_Text = |w| w

show_Real : F64 -> CceText
show_Real = |w| CceText.of_str(Prelude.real_to_str(w))

describe : ShowableDict(a), a -> CceText
describe = |showable_dict, x| CceText.concat("Value: ", (showable_dict.to_text_impl)(x))

go : I64 -> CceText
go = |n| describe(showable_dict_Integer, n)

pick_int : I64
pick_int = zero_val_Integer

pick_text : CceText
pick_text = zero_val_Text

describe_show : (a -> CceText), a -> CceText
describe_show = |d_Show_a, x| CceText.concat(CceText.concat("[", d_Show_a(x)), "]")

describe_let : (a -> CceText), a -> CceText
describe_let = |d_Show_a, x| ({
	n : I64
	n = 42
	CceText.concat(CceText.concat(CceText.show_int(n), "/"), d_Show_a(x))
})

describe_match : (a -> CceText), a -> CceText
describe_match = |d_Show_a, x| (match x {
	_ => CceText.concat(CceText.concat("<", d_Show_a(x)), ">")
})

rel : (a, a -> I64), a, a -> CceText
rel = |d_Ord_a, x, y| ({
	c : I64
	c = d_Ord_a(x, y)
	(if (c < 0) { "lt" } else { (if (c > 0) { "gt" } else { "eq" }) })
})

show_dict_integer : ShowDict
show_dict_integer = ShowDict.{ show_impl: lam_0 }

show_via : ShowDict, I64 -> CceText
show_via = |dict, x| (dict.show_impl)(x)

show_Color : Color -> CceText
show_Color = |sv| (match sv {
	Red => "Red"
	Green => "Green"
	Blue => "Blue"
})

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
})

compare_Color : Color, Color -> I64
compare_Color = |cx, cy| (match cx {
	Red => (match cy {
		Red => 0
		Green => (-1)
		Blue => (-1)
	})
	Green => (match cy {
		Red => 1
		Green => 0
		Blue => (-1)
	})
	Blue => (match cy {
		Red => 1
		Green => 1
		Blue => 0
	})
})

show_Shape : Shape -> CceText
show_Shape = |sv| (match sv {
	Circle(f0) => CceText.concat(CceText.concat("Circle", " "), CceText.show_int(f0))
	Rect(f0, f1) => CceText.concat(CceText.concat(CceText.concat(CceText.concat("Rect", " "), CceText.show_int(f0)), " "), CceText.show_int(f1))
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

compare_Shape : Shape, Shape -> I64
compare_Shape = |cx, cy| (match cx {
	Circle(cxf0) => (match cy {
		Circle(cyf0) => ({
			cc0 : I64
			cc0 = ({
				cmpa : I64
				cmpa = cxf0
				cmpb : I64
				cmpb = cyf0
				(if (cmpa < cmpb) { (-1) } else { (if (cmpa > cmpb) { 1 } else { 0 }) })
			})
			(if (cc0 == 0) { 0 } else { cc0 })
		})
		Rect(_, _) => (-1)
	})
	Rect(cxf0, cxf1) => (match cy {
		Circle(_) => 1
		Rect(cyf0, cyf1) => ({
			cc0 : I64
			cc0 = ({
				cmpa : I64
				cmpa = cxf0
				cmpb : I64
				cmpb = cyf0
				(if (cmpa < cmpb) { (-1) } else { (if (cmpa > cmpb) { 1 } else { 0 }) })
			})
			(if (cc0 == 0) { ({
				cc1 : I64
				cc1 = ({
					cmpa : I64
					cmpa = cxf1
					cmpb : I64
					cmpb = cyf1
					(if (cmpa < cmpb) { (-1) } else { (if (cmpa > cmpb) { 1 } else { 0 }) })
				})
				(if (cc1 == 0) { 0 } else { cc1 })
			}) } else { cc0 })
		})
	})
})

eq_Wrap : Wrap, Wrap -> Bool
eq_Wrap = |ex, ey| (match ex {
	Wrap(exf0) => (match ey {
		Wrap(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

eq_Point : Point, Point -> Bool
eq_Point = |ex, ey| ((ex.x == ey.x) and (ex.y == ey.y))

showable_dict_Integer : ShowableDict(I64)
showable_dict_Integer = { to_text_impl: lam_1 }

to_text_Integer : I64 -> CceText
to_text_Integer = |x| CceText.show_int(x)

showable_dict_Boolean : ShowableDict(Bool)
showable_dict_Boolean = { to_text_impl: lam_2 }

to_text_Boolean : Bool -> CceText
to_text_Boolean = |b| (if b { "yes" } else { "no" })

showable_dict_List_of_Integer_end : ShowableDict(List(I64))
showable_dict_List_of_Integer_end = { to_text_impl: lam_3 }

to_text_List_of_Integer_end : List(I64) -> CceText
to_text_List_of_Integer_end = |xs| CceText.concat("list of ", CceText.show_int(U64.to_i64_wrap(List.len(xs))))

equatable_dict_Integer : EquatableDict(I64)
equatable_dict_Integer = { is_equal_impl: lam_4 }

is_equal_Integer : I64, I64 -> Bool
is_equal_Integer = |x, y| (x == y)

equatable_dict_Boolean : EquatableDict(Bool)
equatable_dict_Boolean = { is_equal_impl: lam_5 }

is_equal_Boolean : Bool, Bool -> Bool
is_equal_Boolean = |a, b| (if a { b } else { (if b { False } else { True }) })

zeroed_dict_Integer : ZeroedDict(I64)
zeroed_dict_Integer = { zero_val_impl: 0 }

zero_val_Integer : I64
zero_val_Integer = 0

zeroed_dict_Text : ZeroedDict(CceText)
zeroed_dict_Text = { zero_val_impl: "none" }

zero_val_Text : CceText
zero_val_Text = "none"

lam_0 : I64 -> CceText
lam_0 = |x| CceText.show_int(x)

lam_1 : I64 -> CceText
lam_1 = |x| CceText.show_int(x)

lam_2 : Bool -> CceText
lam_2 = |b| (if b { "yes" } else { "no" })

lam_3 : List(I64) -> CceText
lam_3 = |xs| CceText.concat("list of ", CceText.show_int(U64.to_i64_wrap(List.len(xs))))

lam_4 : I64, I64 -> Bool
lam_4 = |x, y| (x == y)

lam_5 : Bool, Bool -> Bool
lam_5 = |a, b| (if a { b } else { (if b { False } else { True }) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(to_text_Integer(42)))
	line!(CceText.printed(describe(showable_dict_Integer, 99)))
	line!(CceText.printed(describe(showable_dict_Boolean, True)))
	line!(CceText.printed(go(42)))
	line!(CceText.printed(to_text_List_of_Integer_end([1, 2, 3])))
	line!(CceText.printed((if is_equal_Integer(3, 3) { "True" } else { "False" })))
	line!(CceText.printed((if is_equal_Integer(3, 4) { "True" } else { "False" })))
	line!(CceText.printed((if is_equal_Boolean(True, False) { "True" } else { "False" })))
	line!(CceText.printed(CceText.show_int(pick_int)))
	line!(CceText.printed(pick_text))
	line!(CceText.printed(show_via(show_dict_integer, 42)))
	line!(CceText.printed(show_Color(Green)))
	line!(CceText.printed(show_Shape(Circle(5))))
	line!(CceText.printed(show_Shape(Rect(3, 4))))
	line!(CceText.printed((if eq_Color(Red, Red) { "True" } else { "False" })))
	line!(CceText.printed((if eq_Color(Red, Blue) { "True" } else { "False" })))
	line!(CceText.printed((if eq_Wrap(Wrap(5), Wrap(5)) { "True" } else { "False" })))
	line!(CceText.printed((if eq_Wrap(Wrap(5), Wrap(6)) { "True" } else { "False" })))
	line!(CceText.printed((if eq_Point(Point.{ x: 1, y: 2 }, Point.{ x: 1, y: 2 }) { "True" } else { "False" })))
	line!(CceText.printed(CceText.show_int(compare_Color(Red, Blue))))
	line!(CceText.printed(CceText.show_int(compare_Color(Green, Green))))
	line!(CceText.printed(describe_show(show_Shape, Circle(5))))
	line!(CceText.printed(describe_show(show_Integer, 42)))
	line!(CceText.printed(describe_show(show_Boolean, True)))
	line!(CceText.printed(describe_let(show_Color, Blue)))
	line!(CceText.printed(describe_match(show_Integer, 7)))
	line!(CceText.printed(rel(compare_Shape, Circle(1), Circle(2))))
	line!(CceText.printed(rel(compare_Shape, Circle(5), Circle(5))))
	line!(CceText.printed(rel(compare_Integer, 1, 2)))
	Ok({})
}
