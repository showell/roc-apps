# convolution-identity
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/convolution-identity.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     impulse-identity=100 200 300 400 500
#     box3-on-constant=666 999 999 999 666
#     lengths=5 5

app [main!] { cdx: "./codex/main.roc" }

import cdx.Convolution
import cdx.Text

# ConvolutionIdentity -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

sig : List(I64)
sig = [100, 200, 300, 400, 500]

impulse : List(I64)
impulse = [0, 1000, 0]

flat : List(I64)
flat = [1000, 1000, 1000, 1000, 1000]

conv_imp : List(I64)
conv_imp = Convolution.convolve(sig, impulse)

conv_box : List(I64)
conv_box = Convolution.convolve(flat, Convolution.kernel_box_3)

five : List(I64) -> Text
five = |xs| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.show_int((List.get(xs, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), " "), Text.show_int((List.get(xs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), " "), Text.show_int((List.get(xs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), " "), Text.show_int((List.get(xs, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))), " "), Text.show_int((List.get(xs, I64.to_u64_wrap(4)) ?? crash("list-at out of range"))))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("impulse-identity=", five(conv_imp))))
	line!(Text.printed(Text.concat("box3-on-constant=", five(conv_box))))
	line!(Text.printed(Text.concat(Text.concat(Text.concat("lengths=", Text.show_int(U64.to_i64_wrap(List.len(conv_imp)))), " "), Text.show_int(U64.to_i64_wrap(List.len(conv_box))))))
	Ok({})
}
