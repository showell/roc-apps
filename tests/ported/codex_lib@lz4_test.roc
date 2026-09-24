# lib@lz4-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@lz4-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     empty=pass
#     tiny=pass
#     repeating=pass
#     uniform-100=pass

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Lz4

# Lz4Test -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

list_equal : List(I64), List(I64), I64, I64 -> Bool
list_equal = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { list_equal(a, b, (i + 1), len) } else { False }) })

check_rt : List(I64), CceText -> CceText
check_rt = |input, label| ({
	compressed : List(I64)
	compressed = Lz4.lz4_compress(input)
	decompressed : List(I64)
	decompressed = Lz4.lz4_decompress(compressed)
	ok : Bool
	ok = (if (U64.to_i64_wrap(List.len(decompressed)) == U64.to_i64_wrap(List.len(input))) { list_equal(input, decompressed, 0, U64.to_i64_wrap(List.len(input))) } else { False })
	CceText.concat(CceText.concat(label, "="), (if ok { "pass" } else { "fail" }))
})

make_repeated : I64, I64, I64, List(I64) -> List(I64)
make_repeated = |val, n, i, acc| (if (i >= n) { acc } else { make_repeated(val, n, (i + 1), List.append(acc, val)) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(check_rt([], "empty")))
	line!(CceText.printed(check_rt([1, 2, 3], "tiny")))
	line!(CceText.printed(check_rt([65, 66, 67, 68, 65, 66, 67, 68, 65, 66, 67, 68], "repeating")))
	line!(CceText.printed(check_rt(make_repeated(42, 100, 0, []), "uniform-100")))
	Ok({})
}
