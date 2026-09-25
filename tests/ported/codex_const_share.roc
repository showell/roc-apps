# const-share
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/const-share.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     direct sum 32020
#     helper sum 96020
#     direct delta 0
#     helper delta 0
#     written direct 99001
#     written fn 99001
#     written alias 99001
#     written lambda 99001
#     written right 99002
#     written left 99002
#     left len 9
#     left sum 3875
#     left delta 0
#     buffer byte 8040
#     buffer delta 0
#     field sum 21500
#     field delta 0
#     field direct 99001
#     field fn 99001
#     field alias 99001

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Mem

# ConstShare -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Holder := { h_read : List(I64), h_direct : List(I64), h_fn : List(I64), h_alias : List(I64) }.{
	is_eq : Holder, Holder -> Bool
	is_eq = |a, b| a.h_read == b.h_read and a.h_direct == b.h_direct and a.h_fn == b.h_fn and a.h_alias == b.h_alias
}

table : List(I64)
table = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64]

read_at : List(I64), I64 -> I64
read_at = |xs, i| (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))

sum_direct : I64, I64, I64 -> I64
sum_direct = |n, i, acc| (if (i >= n) { acc } else { sum_direct(n, (i + 1), (acc + (List.get(table, I64.to_u64_wrap(I64.bitwise_and(i, 63))) ?? crash("list-at out of range")))) })

sum_helper : I64, I64, I64 -> I64
sum_helper = |n, i, acc| (if (i >= n) { acc } else { sum_helper(n, (i + 1), ((acc + read_at(table, I64.bitwise_and(i, 63))) + U64.to_i64_wrap(List.len(table)))) })

delta_direct : I64 -> I64
delta_direct = |n| ({
	h0 : I64
	h0 = 0
	s : I64
	s = sum_direct(n, 0, 0)
	h1 : I64
	h1 = 0
	(if (s < 0) { (0 - 1) } else { (h1 - h0) })
})

delta_helper : I64 -> I64
delta_helper = |n| ({
	h0 : I64
	h0 = 0
	s : I64
	s = sum_helper(n, 0, 0)
	h1 : I64
	h1 = 0
	(if (s < 0) { (0 - 1) } else { (h1 - h0) })
})

byte_table : List(I64)
byte_table = [10, 20, 30, 40, 50, 60, 70, 80]

buf_loop! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
buf_loop! = |mem, buf, n, i, acc| (if (i >= n) { (mem, acc) } else { ({
	(mem1, mem__1) = Mem.write_bytes!(mem, buf, 0, byte_table)
	buf_loop!(mem1, buf, n, (i + 1), (acc + mem__1))
}) })

delta_buf! : Mem.Mem, I64 => (Mem.Mem, I64)
delta_buf! = |mem, n| ({
	(mem5, mem__1) = ({
	(mem1, buf) = Mem.alloc(mem, 16)
	(mem2, h0) = Mem.mark(mem1)
	(mem3, s) = buf_loop!(mem2, buf, n, 0, 0)
	(mem4, h1) = Mem.mark(mem3)
	(mem4, (if (s < 0) { (0 - 1) } else { (h1 - h0) }))
})
	(mem5, mem__1)
})

buf_byte! : Mem.Mem => (Mem.Mem, I64)
buf_byte! = |mem| ({
	(mem4, mem__2) = ({
	(mem1, buf) = Mem.alloc(mem, 16)
	(mem2, p) = Mem.write_bytes!(mem1, buf, 0, byte_table)
	({
		(mem3, mem__1) = Mem.load!(mem2, buf, 3, 1)
		(mem3, (mem__1 + (p * 1000)))
	})
})
	(mem4, mem__2)
})

w_direct : List(I64)
w_direct = [1, 2, 3, 4]

w_fn : List(I64)
w_fn = [1, 2, 3, 4]

w_alias : List(I64)
w_alias = [1, 2, 3, 4]

w_lambda : List(I64)
w_lambda = [1, 2, 3, 4]

w_right : List(I64)
w_right = [1, 2, 3, 4]

after_right : I64
after_right = ({
	c : List(I64)
	c = List.concat([], w_right)
	a : List(I64)
	a = (List.set(c, I64.to_u64_wrap(1), 99) ?? crash("list-set-at past the end"))
	(((List.get(a, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) * 1000) + (List.get(w_right, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))
})

w_left : List(I64)
w_left = [1, 2, 3, 4]

after_left : I64
after_left = ({
	c : List(I64)
	c = List.concat(w_left, [])
	a : List(I64)
	a = (List.set(c, I64.to_u64_wrap(1), 99) ?? crash("list-set-at past the end"))
	(((List.get(a, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) * 1000) + (List.get(w_left, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))
})

l_table : List(I64)
l_table = [3, 1, 4, 1, 5, 9, 2, 6]

left_len : I64
left_len = U64.to_i64_wrap(List.len(List.concat(l_table, [7])))

sum_left : I64, I64, I64 -> I64
sum_left = |n, i, acc| (if (i >= n) { acc } else { sum_left(n, (i + 1), (acc + (List.get(l_table, I64.to_u64_wrap(I64.bitwise_and(i, 7))) ?? crash("list-at out of range")))) })

delta_left : I64 -> I64
delta_left = |n| ({
	h0 : I64
	h0 = 0
	s : I64
	s = sum_left(n, 0, 0)
	h1 : I64
	h1 = 0
	(if (s < 0) { (0 - 1) } else { (h1 - h0) })
})

poke : List(I64) -> List(I64)
poke = |xs| (List.set(xs, I64.to_u64_wrap(0), 99) ?? crash("list-set-at past the end"))

after_direct : I64
after_direct = ({
	a : List(I64)
	a = (List.set(w_direct, I64.to_u64_wrap(0), 99) ?? crash("list-set-at past the end"))
	(((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) * 1000) + (List.get(w_direct, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
})

after_fn : I64
after_fn = ({
	a : List(I64)
	a = poke(w_fn)
	(((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) * 1000) + (List.get(w_fn, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
})

after_alias : I64
after_alias = ({
	t : List(I64)
	t = w_alias
	a : List(I64)
	a = (List.set(t, I64.to_u64_wrap(0), 99) ?? crash("list-set-at past the end"))
	(((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) * 1000) + (List.get(w_alias, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
})

after_lambda : I64
after_lambda = ({
	f = lam_0
	a : List(I64)
	a = f(0)
	(((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) * 1000) + (List.get(w_lambda, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
})

f_read : List(I64)
f_read = [5, 6, 7, 8]

f_direct : List(I64)
f_direct = [1, 2, 3, 4]

f_fn : List(I64)
f_fn = [1, 2, 3, 4]

f_alias : List(I64)
f_alias = [1, 2, 3, 4]

mk_holder : List(I64), List(I64) -> Holder
mk_holder = |r, d| Holder.{ h_read: r, h_direct: d, h_fn: f_fn, h_alias: f_alias }

holder : Holder
holder = mk_holder(f_read, f_direct)

field_len : Holder -> I64
field_len = |h| ({
	t : List(I64)
	t = h.h_read
	U64.to_i64_wrap(List.len(t))
})

sum_field : Holder, I64, I64, I64 -> I64
sum_field = |h, n, i, acc| (if (i >= n) { acc } else { sum_field(h, n, (i + 1), ((((acc + (List.get(h.h_read, I64.to_u64_wrap(I64.bitwise_and(i, 3))) ?? crash("list-at out of range"))) + read_at(h.h_read, 0)) + (List.get(f_read, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))) + field_len(h))) })

delta_field : I64 -> I64
delta_field = |n| ({
	h = holder
	h0 : I64
	h0 = 0
	s : I64
	s = sum_field(h, n, 0, 0)
	h1 : I64
	h1 = 0
	(if (s < 0) { (0 - 1) } else { (h1 - h0) })
})

field_direct : I64
field_direct = ({
	h = holder
	a : List(I64)
	a = (List.set(h.h_direct, I64.to_u64_wrap(0), 99) ?? crash("list-set-at past the end"))
	(((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) * 1000) + (List.get(f_direct, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
})

field_fn : I64
field_fn = ({
	h = holder
	a : List(I64)
	a = poke(h.h_fn)
	(((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) * 1000) + (List.get(f_fn, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
})

field_alias : I64
field_alias = ({
	h = holder
	t : List(I64)
	t = h.h_alias
	a : List(I64)
	a = (List.set(t, I64.to_u64_wrap(0), 99) ?? crash("list-set-at past the end"))
	(((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) * 1000) + (List.get(f_alias, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
})

lam_0 : I64 -> List(I64)
lam_0 = |i| (List.set(w_lambda, I64.to_u64_wrap(i), 99) ?? crash("list-set-at past the end"))

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	line!(CceText.printed(CceText.concat("direct sum ", CceText.show_int(sum_direct(1000, 0, 0)))))
	line!(CceText.printed(CceText.concat("helper sum ", CceText.show_int(sum_helper(1000, 0, 0)))))
	line!(CceText.printed(CceText.concat("direct delta ", CceText.show_int(delta_direct(100000)))))
	line!(CceText.printed(CceText.concat("helper delta ", CceText.show_int(delta_helper(100000)))))
	line!(CceText.printed(CceText.concat("written direct ", CceText.show_int(after_direct))))
	line!(CceText.printed(CceText.concat("written fn ", CceText.show_int(after_fn))))
	line!(CceText.printed(CceText.concat("written alias ", CceText.show_int(after_alias))))
	line!(CceText.printed(CceText.concat("written lambda ", CceText.show_int(after_lambda))))
	line!(CceText.printed(CceText.concat("written right ", CceText.show_int(after_right))))
	line!(CceText.printed(CceText.concat("written left ", CceText.show_int(after_left))))
	line!(CceText.printed(CceText.concat("left len ", CceText.show_int(left_len))))
	line!(CceText.printed(CceText.concat("left sum ", CceText.show_int(sum_left(1000, 0, 0)))))
	line!(CceText.printed(CceText.concat("left delta ", CceText.show_int(delta_left(100000)))))
	(mem1, mem__1) = buf_byte!(mem)
	line!(CceText.printed(CceText.concat("buffer byte ", CceText.show_int(mem__1))))
	(_mem2, mem__2) = delta_buf!(mem1, 100000)
	line!(CceText.printed(CceText.concat("buffer delta ", CceText.show_int(mem__2))))
	line!(CceText.printed(CceText.concat("field sum ", CceText.show_int(sum_field(holder, 1000, 0, 0)))))
	line!(CceText.printed(CceText.concat("field delta ", CceText.show_int(delta_field(100000)))))
	line!(CceText.printed(CceText.concat("field direct ", CceText.show_int(field_direct))))
	line!(CceText.printed(CceText.concat("field fn ", CceText.show_int(field_fn))))
	line!(CceText.printed(CceText.concat("field alias ", CceText.show_int(field_alias))))
	Ok({})
}
