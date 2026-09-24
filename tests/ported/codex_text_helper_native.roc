# text-helper-native
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/text-helper-native.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     sw TTTFFTF
#     ct TTTFTFTF
#     rp heLLo||bb|abc||abababab|hello
#     sp1 4[a][b][][c]
#     sp2 1[]
#     sp3 1[abc]
#     sp4 3[][a][]
#     sp5 3[a][b][c]
#     sp6 1[abc]
#     sp7 3[a][b][c]
#     ti 42 -42 0 0 7 0 12 0 0 0 9223372036854775807

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TextHelperNative -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

b2 : Bool -> CceText
b2 = |x| (if x { "T" } else { "F" })

join_loop : List(CceText), I64, CceText -> CceText
join_loop = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { join_loop(xs, (i + 1), CceText.concat(CceText.concat(CceText.concat(acc, "["), (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), "]")) })

sp : CceText, CceText -> CceText
sp = |s, sep| CceText.concat(CceText.show_int(U64.to_i64_wrap(List.len(CceText.split(s, sep)))), join_loop(CceText.split(s, sep), 0, ""))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("sw ", b2(CceText.starts_with("hello", "he"))), b2(CceText.starts_with("hello", ""))), b2(CceText.starts_with("", ""))), b2(CceText.starts_with("", "a"))), b2(CceText.starts_with("he", "hello"))), b2(CceText.starts_with("hello", "hello"))), b2(CceText.starts_with("abc", "abd")))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("ct ", b2(CceText.contains("hello", "ell"))), b2(CceText.contains("hello", ""))), b2(CceText.contains("", ""))), b2(CceText.contains("", "a"))), b2(CceText.contains("hello", "lo"))), b2(CceText.contains("hello", "hex"))), b2(CceText.contains("aaa", "aa"))), b2(CceText.contains("abc", "abcd")))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("rp ", CceText.replace("hello", "l", "L")), "|"), CceText.replace("hello", "hello", "")), "|"), CceText.replace("aaaa", "aa", "b")), "|"), CceText.replace("abc", "z", "y")), "|"), CceText.replace("", "a", "b")), "|"), CceText.replace("abab", "ab", "abab")), "|"), CceText.replace("hello", "", "x"))))
	line!(CceText.printed(CceText.concat("sp1 ", sp("a,b,,c", ","))))
	line!(CceText.printed(CceText.concat("sp2 ", sp("", ","))))
	line!(CceText.printed(CceText.concat("sp3 ", sp("abc", ","))))
	line!(CceText.printed(CceText.concat("sp4 ", sp(",a,", ","))))
	line!(CceText.printed(CceText.concat("sp5 ", sp("a::b::c", "::"))))
	line!(CceText.printed(CceText.concat("sp6 ", sp("abc", ""))))
	line!(CceText.printed(CceText.concat("sp7 ", sp("aXbXc", "X"))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("ti ", CceText.show_int(CceText.to_integer("42"))), " "), CceText.show_int(CceText.to_integer("-42"))), " "), CceText.show_int(CceText.to_integer("+7"))), " "), CceText.show_int(CceText.to_integer("0"))), " "), CceText.show_int(CceText.to_integer("007"))), " "), CceText.show_int(CceText.to_integer("abc"))), " "), CceText.show_int(CceText.to_integer("12abc"))), " "), CceText.show_int(CceText.to_integer(""))), " "), CceText.show_int(CceText.to_integer(" 42"))), " "), CceText.show_int(CceText.to_integer("-"))), " "), CceText.show_int(CceText.to_integer("9223372036854775807")))))
	Ok({})
}
