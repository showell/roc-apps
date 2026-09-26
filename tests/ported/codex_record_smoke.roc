# record-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/record-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     rect at 10,20 area=21
#     15
#     circle-green-r5
#     red circle r=5
#     15
#     42
#     99
#     a:13
#     one:5

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RecordSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Point := { x : I64, y : I64 }.{
	is_eq : Point, Point -> Bool
	is_eq = |a, b| eq_Point(a, b)
}
Rect := { origin : Point, width : I64, height : I64 }.{
	is_eq : Rect, Rect -> Bool
	is_eq = |a, b| eq_Rect(a, b)
}
Color : [Red, Green, Blue]
Shape : [Circle(Color, I64), Square(Color, I64)]
Wrapped : [Wrapped(Color, Shape)]
TestRec := { name : CceText, effect : I64, value : I64 }.{
	is_eq : TestRec, TestRec -> Bool
	is_eq = |a, b| eq_TestRec(a, b)
}
Inner := { x_val : I64, y_val : I64, label : CceText }.{
	is_eq : Inner, Inner -> Bool
	is_eq = |a, b| eq_Inner(a, b)
}
Outer : [OWrapped(Inner), OPlain(I64), OEmpty]
Rec1 := { rx : I64, ry : I64 }.{
	is_eq : Rec1, Rec1 -> Bool
	is_eq = |a, b| eq_Rec1(a, b)
}
Rec2 := { ra : CceText, rb : I64 }.{
	is_eq : Rec2, Rec2 -> Bool
	is_eq = |a, b| eq_Rec2(a, b)
}
V : [VarA(Rec1), VarB(Rec2)]
Box_ := { box_label : CceText, apply : (I64 -> CceText) }
Entry := { ent_name : CceText, emit : (I64 -> CceText) }

area : Rect -> I64
area = |r| (r.width * r.height)

describe_rect : Rect -> CceText
describe_rect = |r| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("rect at ", CceText.show_int(r.origin.x)), ","), CceText.show_int(r.origin.y)), " area="), CceText.show_int(area(r)))

color_name : Color -> CceText
color_name = |c| (match c {
	Red => "red"
	Green => "green"
	Blue => "blue"
})

describe_shape : Shape -> CceText
describe_shape = |s| (match s {
	Circle(c, r) => CceText.concat(CceText.concat(CceText.concat("circle-", color_name(c)), "-r"), CceText.show_int(r))
	Square(c, side) => CceText.concat(CceText.concat(CceText.concat("square-", color_name(c)), "-s"), CceText.show_int(side))
})

describe_wrapped : Wrapped -> CceText
describe_wrapped = |w| (match w {
	Wrapped(c, s) => (match s {
		Circle(_c2, r) => CceText.concat(CceText.concat(color_name(c), " circle r="), CceText.show_int(r))
		Square(_c2, side) => CceText.concat(CceText.concat(color_name(c), " square s="), CceText.show_int(side))
	})
})

make_test : I64 -> TestRec
make_test = |n| TestRec.{ name: "hello", effect: (n * 2), value: n }

make_wrapped : I64 -> Outer
make_wrapped = |n| OWrapped(Inner.{ x_val: n, y_val: (n * 2), label: "test" })

use_wrapped : Outer -> I64
use_wrapped = |o| (match o {
	OWrapped(i) => (i.x_val + i.y_val)
	OPlain(n) => n
	OEmpty => 0
})

extract_int : V -> I64
extract_int = |v| (match v {
	VarA(r) => r.rx
	VarB(r) => r.rb
})

make_box : CceText, I64 -> Box_
make_box = |lbl, offset| Box_.{ box_label: lbl, apply: ({
	dev__1 = offset
	dev__2 = lbl
	|dev__3| lam_0(dev__1, dev__2, dev__3)
}) }

emit_one : I64 -> CceText
emit_one = |x| CceText.concat("one:", CceText.show_int(x))

emit_two : I64 -> CceText
emit_two = |x| CceText.concat("two:", CceText.show_int((x + x)))

eq_Point : Point, Point -> Bool
eq_Point = |ex, ey| ((ex.x == ey.x) and (ex.y == ey.y))

eq_Rect : Rect, Rect -> Bool
eq_Rect = |ex, ey| ((eq_Point(ex.origin, ey.origin) and (ex.width == ey.width)) and (ex.height == ey.height))

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

eq_Shape : Shape, Shape -> Bool
eq_Shape = |ex, ey| (match ex {
	Circle(exf0, exf1) => (match ey {
		Circle(eyf0, eyf1) => (eq_Color(exf0, eyf0) and (exf1 == eyf1))
		_ => False
	})
	Square(exf0, exf1) => (match ey {
		Square(eyf0, eyf1) => (eq_Color(exf0, eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_Wrapped : Wrapped, Wrapped -> Bool
eq_Wrapped = |ex, ey| (match ex {
	Wrapped(exf0, exf1) => (match ey {
		Wrapped(eyf0, eyf1) => (eq_Color(exf0, eyf0) and eq_Shape(exf1, eyf1))
		_ => False
	})
})

eq_TestRec : TestRec, TestRec -> Bool
eq_TestRec = |ex, ey| (((ex.name == ey.name) and (ex.effect == ey.effect)) and (ex.value == ey.value))

eq_Inner : Inner, Inner -> Bool
eq_Inner = |ex, ey| (((ex.x_val == ey.x_val) and (ex.y_val == ey.y_val)) and (ex.label == ey.label))

eq_Outer : Outer, Outer -> Bool
eq_Outer = |ex, ey| (match ex {
	OWrapped(exf0) => (match ey {
		OWrapped(eyf0) => eq_Inner(exf0, eyf0)
		_ => False
	})
	OPlain(exf0) => (match ey {
		OPlain(eyf0) => (exf0 == eyf0)
		_ => False
	})
	OEmpty => (match ey {
		OEmpty => True
		_ => False
	})
})

eq_Rec1 : Rec1, Rec1 -> Bool
eq_Rec1 = |ex, ey| ((ex.rx == ey.rx) and (ex.ry == ey.ry))

eq_Rec2 : Rec2, Rec2 -> Bool
eq_Rec2 = |ex, ey| ((ex.ra == ey.ra) and (ex.rb == ey.rb))

eq_V : V, V -> Bool
eq_V = |ex, ey| (match ex {
	VarA(exf0) => (match ey {
		VarA(eyf0) => eq_Rec1(exf0, eyf0)
		_ => False
	})
	VarB(exf0) => (match ey {
		VarB(eyf0) => eq_Rec2(exf0, eyf0)
		_ => False
	})
})

lam_0 : I64, CceText, I64 -> CceText
lam_0 = |offset, lbl, x| CceText.concat(CceText.concat(lbl, ":"), CceText.show_int((x + offset)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(describe_rect(Rect.{ origin: Point.{ x: 10, y: 20 }, width: 7, height: 3 })))
	({
		tr = make_test(5)
		({
			line!(CceText.printed(CceText.show_int((tr.effect + tr.value))))
			line!(CceText.printed(describe_shape(Circle(Green, 5))))
			line!(CceText.printed(describe_wrapped(Wrapped(Red, Circle(Red, 5)))))
			line!(CceText.printed(CceText.show_int(use_wrapped(make_wrapped(5)))))
			line!(CceText.printed(CceText.show_int(extract_int(VarA(Rec1.{ rx: 42, ry: 7 })))))
			line!(CceText.printed(CceText.show_int(extract_int(VarB(Rec2.{ ra: "hello", rb: 99 })))))
			({
				b1 = make_box("a", 10)
				({
					line!(CceText.printed((b1.apply)(3)))
					({
						e = Entry.{ ent_name: "one", emit: emit_one }
						line!(CceText.printed((e.emit)(5)))
					})
				})
			})
		})
	})
	Ok({})
}
