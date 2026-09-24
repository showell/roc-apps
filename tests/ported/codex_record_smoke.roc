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

import cdx.Text

# RecordSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Point : { x : I64, y : I64 }
Rect : { origin : Point, width : I64, height : I64 }
Color : [Red, Green, Blue]
Shape : [Circle(Color, I64), Square(Color, I64)]
Wrapped : [Wrapped(Color, Shape)]
TestRec : { name : Text, effect : I64, value : I64 }
Inner : { x_val : I64, y_val : I64, label : Text }
Outer : [OWrapped(Inner), OPlain(I64), OEmpty]
Rec1 : { rx : I64, ry : I64 }
Rec2 : { ra : Text, rb : I64 }
V : [VarA(Rec1), VarB(Rec2)]
Box_ : { box_label : Text, apply : (I64 -> Text) }
Entry : { ent_name : Text, emit : (I64 -> Text) }

area : Rect -> I64
area = |r| (r.width * r.height)

describe_rect : Rect -> Text
describe_rect = |r| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("rect at ", Text.show_int(r.origin.x)), ","), Text.show_int(r.origin.y)), " area="), Text.show_int(area(r)))

color_name : Color -> Text
color_name = |c| (match c {
	Red => "red"
	Green => "green"
	Blue => "blue"
})

describe_shape : Shape -> Text
describe_shape = |s| (match s {
	Circle(c, r) => Text.concat(Text.concat(Text.concat("circle-", color_name(c)), "-r"), Text.show_int(r))
	Square(c, side) => Text.concat(Text.concat(Text.concat("square-", color_name(c)), "-s"), Text.show_int(side))
})

describe_wrapped : Wrapped -> Text
describe_wrapped = |w| (match w {
	Wrapped(c, s) => (match s {
		Circle(_c2, r) => Text.concat(Text.concat(color_name(c), " circle r="), Text.show_int(r))
		Square(_c2, side) => Text.concat(Text.concat(color_name(c), " square s="), Text.show_int(side))
	})
})

make_test : I64 -> TestRec
make_test = |n| { name: "hello", effect: (n * 2), value: n }

make_wrapped : I64 -> Outer
make_wrapped = |n| OWrapped({ x_val: n, y_val: (n * 2), label: "test" })

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

make_box : Text, I64 -> Box_
make_box = |lbl, offset| { box_label: lbl, apply: ({
	dev__1 = offset
	dev__2 = lbl
	|dev__3| lam_0(dev__1, dev__2, dev__3)
}) }

emit_one : I64 -> Text
emit_one = |x| Text.concat("one:", Text.show_int(x))

emit_two : I64 -> Text
emit_two = |x| Text.concat("two:", Text.show_int((x + x)))

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

eq_Outer : Outer, Outer -> Bool
eq_Outer = |ex, ey| (match ex {
	OWrapped(exf0) => (match ey {
		OWrapped(eyf0) => (exf0 == eyf0)
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

eq_V : V, V -> Bool
eq_V = |ex, ey| (match ex {
	VarA(exf0) => (match ey {
		VarA(eyf0) => (exf0 == eyf0)
		_ => False
	})
	VarB(exf0) => (match ey {
		VarB(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

lam_0 : I64, Text, I64 -> Text
lam_0 = |offset, lbl, x| Text.concat(Text.concat(lbl, ":"), Text.show_int((x + offset)))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(describe_rect({ origin: { x: 10, y: 20 }, width: 7, height: 3 })))
	({
		tr = make_test(5)
		({
			line!(Text.printed(Text.show_int((tr.effect + tr.value))))
			line!(Text.printed(describe_shape(Circle(Green, 5))))
			line!(Text.printed(describe_wrapped(Wrapped(Red, Circle(Red, 5)))))
			line!(Text.printed(Text.show_int(use_wrapped(make_wrapped(5)))))
			line!(Text.printed(Text.show_int(extract_int(VarA({ rx: 42, ry: 7 })))))
			line!(Text.printed(Text.show_int(extract_int(VarB({ ra: "hello", rb: 99 })))))
			({
				b1 = make_box("a", 10)
				({
					line!(Text.printed((b1.apply)(3)))
					({
						e = { ent_name: "one", emit: emit_one }
						line!(Text.printed((e.emit)(5)))
					})
				})
			})
		})
	})
	Ok({})
}
