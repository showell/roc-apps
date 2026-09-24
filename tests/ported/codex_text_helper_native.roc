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

import cdx.Text

# TextHelperNative -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

b2 : Bool -> Text
b2 = |x| (if x { "T" } else { "F" })

join_loop : List(Text), I64, Text -> Text
join_loop = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { join_loop(xs, (i + 1), Text.concat(Text.concat(Text.concat(acc, "["), (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), "]")) })

sp : Text, Text -> Text
sp = |s, sep| Text.concat(Text.show_int(U64.to_i64_wrap(List.len(Text.split(s, sep)))), join_loop(Text.split(s, sep), 0, ""))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("sw ", b2(Text.starts_with("hello", "he"))), b2(Text.starts_with("hello", ""))), b2(Text.starts_with("", ""))), b2(Text.starts_with("", "a"))), b2(Text.starts_with("he", "hello"))), b2(Text.starts_with("hello", "hello"))), b2(Text.starts_with("abc", "abd")))))
	line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("ct ", b2(Text.contains("hello", "ell"))), b2(Text.contains("hello", ""))), b2(Text.contains("", ""))), b2(Text.contains("", "a"))), b2(Text.contains("hello", "lo"))), b2(Text.contains("hello", "hex"))), b2(Text.contains("aaa", "aa"))), b2(Text.contains("abc", "abcd")))))
	line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("rp ", Text.replace("hello", "l", "L")), "|"), Text.replace("hello", "hello", "")), "|"), Text.replace("aaaa", "aa", "b")), "|"), Text.replace("abc", "z", "y")), "|"), Text.replace("", "a", "b")), "|"), Text.replace("abab", "ab", "abab")), "|"), Text.replace("hello", "", "x"))))
	line!(Text.printed(Text.concat("sp1 ", sp("a,b,,c", ","))))
	line!(Text.printed(Text.concat("sp2 ", sp("", ","))))
	line!(Text.printed(Text.concat("sp3 ", sp("abc", ","))))
	line!(Text.printed(Text.concat("sp4 ", sp(",a,", ","))))
	line!(Text.printed(Text.concat("sp5 ", sp("a::b::c", "::"))))
	line!(Text.printed(Text.concat("sp6 ", sp("abc", ""))))
	line!(Text.printed(Text.concat("sp7 ", sp("aXbXc", "X"))))
	line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("ti ", Text.show_int(Text.to_integer("42"))), " "), Text.show_int(Text.to_integer("-42"))), " "), Text.show_int(Text.to_integer("+7"))), " "), Text.show_int(Text.to_integer("0"))), " "), Text.show_int(Text.to_integer("007"))), " "), Text.show_int(Text.to_integer("abc"))), " "), Text.show_int(Text.to_integer("12abc"))), " "), Text.show_int(Text.to_integer(""))), " "), Text.show_int(Text.to_integer(" 42"))), " "), Text.show_int(Text.to_integer("-"))), " "), Text.show_int(Text.to_integer("9223372036854775807")))))
	Ok({})
}
