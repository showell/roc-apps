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

show_bool : Bool -> Text
show_bool = |b| (if b { "true" } else { "false" })

cbor_rt_uint : I64 -> Text
cbor_rt_uint = |n| ({
	encoded = Cbor.cbor_encode(CborUint(n))
	(match Cbor.cbor_decode(encoded) {
		Just(v) => (match v {
			CborUint(m) => (if (m == n) { "pass" } else { Text.concat("fail:", Text.show_int(m)) })
			_ => "fail:wrong-type"
		})
		None => "fail:decode"
	})
})

cbor_rt_text : Text -> Text
cbor_rt_text = |s| ({
	encoded = Cbor.cbor_encode(CborText(s))
	(match Cbor.cbor_decode(encoded) {
		Just(v) => (match v {
			CborText(t) => (if (t == s) { "pass" } else { Text.concat("fail:", t) })
			_ => "fail:wrong-type"
		})
		None => "fail:decode"
	})
})

cbor_rt_bool : Bool -> Text
cbor_rt_bool = |b| ({
	encoded = Cbor.cbor_encode(CborBool(b))
	(match Cbor.cbor_decode(encoded) {
		Just(v) => (match v {
			CborBool(b2) => (if (b == b2) { "pass" } else { "fail" })
			_ => "fail:wrong-type"
		})
		None => "fail:decode"
	})
})

cbor_rt_array : Text
cbor_rt_array = ({
	arr = Cbor.cbor_encode(CborArray([CborUint(1), CborUint(2), CborUint(3)]))
	(match Cbor.cbor_decode(arr) {
		Just(v) => (match v {
			CborArray(items) => Text.concat("array-len=", Text.show_int(U64.to_i64_wrap(List.len(items))))
			_ => "array=fail:type"
		})
		None => "array=fail:decode"
	})
})

cbor_rt_null : Text
cbor_rt_null = ({
	null_enc = Cbor.cbor_encode(CborNull)
	(match Cbor.cbor_decode(null_enc) {
		Just(v) => (match v {
			CborNull => "null=pass"
			_ => "null=fail:type"
		})
		None => "null=fail:decode"
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("uint-0=", cbor_rt_uint(0))))
	line!(Text.printed(Text.concat("uint-1=", cbor_rt_uint(1))))
	line!(Text.printed(Text.concat("uint-23=", cbor_rt_uint(23))))
	line!(Text.printed(Text.concat("uint-24=", cbor_rt_uint(24))))
	line!(Text.printed(Text.concat("uint-255=", cbor_rt_uint(255))))
	line!(Text.printed(Text.concat("uint-1000=", cbor_rt_uint(1000))))
	line!(Text.printed(Text.concat("text-empty=", cbor_rt_text(""))))
	line!(Text.printed(Text.concat("text-hello=", cbor_rt_text("hello"))))
	line!(Text.printed(Text.concat("bool-true=", cbor_rt_bool(True))))
	line!(Text.printed(Text.concat("bool-false=", cbor_rt_bool(False))))
	line!(Text.printed(cbor_rt_array))
	line!(Text.printed(cbor_rt_null))
	Ok({})
}
