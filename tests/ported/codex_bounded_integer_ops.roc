# bounded-integer-ops
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bounded-integer-ops.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     155
#     165
#     52
#     18
#     4660
#     100

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# BoundedIntegerOps -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Byte : { val : I64 }
Port : { num : I64 }
Pair : { lo : I64, hi : I64 }

make_byte : I64 -> Byte
make_byte = |n| { val: n }

byte_add : Byte, Byte -> Byte
byte_add = |a, b| make_byte((a.val + b.val))

byte_mul : Byte, I64 -> Byte
byte_mul = |b, n| make_byte((b.val * n))

split_u16 : Port -> Pair
split_u16 = |p| { lo: Prelude.int_mod(p.num, 256), hi: I64.div_trunc_by(p.num, 256) }

join_pair : Pair -> I64
join_pair = |p| ((p.hi * 256) + p.lo)

sum_bytes_acc : List(Byte), I64, I64 -> I64
sum_bytes_acc = |bs, i, acc| (if (i == U64.to_i64_wrap(List.len(bs))) { acc } else { sum_bytes_acc(bs, (i + 1), (acc + (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).val)) })

# --- Entry ---

main! = |_args| {
	a = make_byte(100)
	b = make_byte(55)
	c = byte_add(a, b)
	d = byte_mul(b, 3)
	port = { num: 4660 }
	parts = split_u16(port)
	rejoined = join_pair(parts)
	bytes = [make_byte(10), make_byte(20), make_byte(30), make_byte(40)]
	total = sum_bytes_acc(bytes, 0, 0)
	line!(Text.printed(Text.show_int(c.val)))
	line!(Text.printed(Text.show_int(d.val)))
	line!(Text.printed(Text.show_int(parts.lo)))
	line!(Text.printed(Text.show_int(parts.hi)))
	line!(Text.printed(Text.show_int(rejoined)))
	line!(Text.printed(Text.show_int(total)))
	Ok({})
}
