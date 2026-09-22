# lib@cbor-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@cbor-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     uint-0=pass
#     uint-1=pass
#     uint-23=pass
#     uint-24=pass
#     uint-255=pass
#     uint-1000=pass
#     text-empty=pass
#     text-hello=pass
#     bool-true=pass
#     bool-false=pass
#     array-len=3
#     null=pass

app [main!] { cdx: "./codex/main.roc" }

import cdx.Cbor
import cdx.Text

# CborTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_bool : Bool -> List(U8)
show_bool = |b| (if b { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] })

cbor_rt_uint : I64 -> List(U8)
cbor_rt_uint = |n| ({
	encoded = Cbor.cbor_encode(CborUint(n))
	(match Cbor.cbor_decode(encoded) {
		Just(v) => (match v {
			CborUint(m) => (if (m == n) { [31, 15, 19, 19] } else { List.concat([28, 15, 17, 23, 69], Text.show_int(m)) })
			_ => [28, 15, 17, 23, 69, 27, 21, 16, 18, 29, 73, 14, 30, 31, 13]
		})
		None => [28, 15, 17, 23, 69, 22, 13, 24, 16, 22, 13]
	})
})

cbor_rt_text : List(U8) -> List(U8)
cbor_rt_text = |s| ({
	encoded = Cbor.cbor_encode(CborText(s))
	(match Cbor.cbor_decode(encoded) {
		Just(v) => (match v {
			CborText(t) => (if (t == s) { [31, 15, 19, 19] } else { List.concat([28, 15, 17, 23, 69], t) })
			_ => [28, 15, 17, 23, 69, 27, 21, 16, 18, 29, 73, 14, 30, 31, 13]
		})
		None => [28, 15, 17, 23, 69, 22, 13, 24, 16, 22, 13]
	})
})

cbor_rt_bool : Bool -> List(U8)
cbor_rt_bool = |b| ({
	encoded = Cbor.cbor_encode(CborBool(b))
	(match Cbor.cbor_decode(encoded) {
		Just(v) => (match v {
			CborBool(b2) => (if (b == b2) { [31, 15, 19, 19] } else { [28, 15, 17, 23] })
			_ => [28, 15, 17, 23, 69, 27, 21, 16, 18, 29, 73, 14, 30, 31, 13]
		})
		None => [28, 15, 17, 23, 69, 22, 13, 24, 16, 22, 13]
	})
})

cbor_rt_array : List(U8)
cbor_rt_array = ({
	arr = Cbor.cbor_encode(CborArray([CborUint(1), CborUint(2), CborUint(3)]))
	(match Cbor.cbor_decode(arr) {
		Just(v) => (match v {
			CborArray(items) => List.concat([15, 21, 21, 15, 30, 73, 23, 13, 18, 77], Text.show_int(U64.to_i64_wrap(List.len(items))))
			_ => [15, 21, 21, 15, 30, 77, 28, 15, 17, 23, 69, 14, 30, 31, 13]
		})
		None => [15, 21, 21, 15, 30, 77, 28, 15, 17, 23, 69, 22, 13, 24, 16, 22, 13]
	})
})

cbor_rt_null : List(U8)
cbor_rt_null = ({
	null_enc = Cbor.cbor_encode(CborNull)
	(match Cbor.cbor_decode(null_enc) {
		Just(v) => (match v {
			CborNull => [18, 25, 23, 23, 77, 31, 15, 19, 19]
			_ => [18, 25, 23, 23, 77, 28, 15, 17, 23, 69, 14, 30, 31, 13]
		})
		None => [18, 25, 23, 23, 77, 28, 15, 17, 23, 69, 22, 13, 24, 16, 22, 13]
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([25, 17, 18, 14, 73, 3, 77], cbor_rt_uint(0))))
	line!(Text.printed(List.concat([25, 17, 18, 14, 73, 4, 77], cbor_rt_uint(1))))
	line!(Text.printed(List.concat([25, 17, 18, 14, 73, 5, 6, 77], cbor_rt_uint(23))))
	line!(Text.printed(List.concat([25, 17, 18, 14, 73, 5, 7, 77], cbor_rt_uint(24))))
	line!(Text.printed(List.concat([25, 17, 18, 14, 73, 5, 8, 8, 77], cbor_rt_uint(255))))
	line!(Text.printed(List.concat([25, 17, 18, 14, 73, 4, 3, 3, 3, 77], cbor_rt_uint(1000))))
	line!(Text.printed(List.concat([14, 13, 36, 14, 73, 13, 26, 31, 14, 30, 77], cbor_rt_text([]))))
	line!(Text.printed(List.concat([14, 13, 36, 14, 73, 20, 13, 23, 23, 16, 77], cbor_rt_text([20, 13, 23, 23, 16]))))
	line!(Text.printed(List.concat([32, 16, 16, 23, 73, 14, 21, 25, 13, 77], cbor_rt_bool(True))))
	line!(Text.printed(List.concat([32, 16, 16, 23, 73, 28, 15, 23, 19, 13, 77], cbor_rt_bool(False))))
	line!(Text.printed(cbor_rt_array))
	line!(Text.printed(cbor_rt_null))
	Ok({})
}
