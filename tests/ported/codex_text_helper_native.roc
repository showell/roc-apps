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

b2 : Bool -> List(U8)
b2 = |x| (if x { [40] } else { [54] })

join_loop : List(List(U8)), I64, List(U8) -> List(U8)
join_loop = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { join_loop(xs, (i + 1), List.concat(List.concat(List.concat(acc, [88]), (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), [89])) })

sp : List(U8), List(U8) -> List(U8)
sp = |s, sep| List.concat(Text.show_int(U64.to_i64_wrap(List.len(Text.split(s, sep)))), join_loop(Text.split(s, sep), 0, []))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([19, 27, 2], b2(Text.starts_with([20, 13, 23, 23, 16], [20, 13]))), b2(Text.starts_with([20, 13, 23, 23, 16], []))), b2(Text.starts_with([], []))), b2(Text.starts_with([], [15]))), b2(Text.starts_with([20, 13], [20, 13, 23, 23, 16]))), b2(Text.starts_with([20, 13, 23, 23, 16], [20, 13, 23, 23, 16]))), b2(Text.starts_with([15, 32, 24], [15, 32, 22])))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([24, 14, 2], b2(Text.contains([20, 13, 23, 23, 16], [13, 23, 23]))), b2(Text.contains([20, 13, 23, 23, 16], []))), b2(Text.contains([], []))), b2(Text.contains([], [15]))), b2(Text.contains([20, 13, 23, 23, 16], [23, 16]))), b2(Text.contains([20, 13, 23, 23, 16], [20, 13, 36]))), b2(Text.contains([15, 15, 15], [15, 15]))), b2(Text.contains([15, 32, 24], [15, 32, 24, 22])))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([21, 31, 2], Text.replace([20, 13, 23, 23, 16], [23], [49])), [87]), Text.replace([20, 13, 23, 23, 16], [20, 13, 23, 23, 16], [])), [87]), Text.replace([15, 15, 15, 15], [15, 15], [32])), [87]), Text.replace([15, 32, 24], [38], [30])), [87]), Text.replace([], [15], [32])), [87]), Text.replace([15, 32, 15, 32], [15, 32], [15, 32, 15, 32])), [87]), Text.replace([20, 13, 23, 23, 16], [], [36]))))
	line!(Text.printed(List.concat([19, 31, 4, 2], sp([15, 66, 32, 66, 66, 24], [66]))))
	line!(Text.printed(List.concat([19, 31, 5, 2], sp([], [66]))))
	line!(Text.printed(List.concat([19, 31, 6, 2], sp([15, 32, 24], [66]))))
	line!(Text.printed(List.concat([19, 31, 7, 2], sp([66, 15, 66], [66]))))
	line!(Text.printed(List.concat([19, 31, 8, 2], sp([15, 69, 69, 32, 69, 69, 24], [69, 69]))))
	line!(Text.printed(List.concat([19, 31, 9, 2], sp([15, 32, 24], []))))
	line!(Text.printed(List.concat([19, 31, 10, 2], sp([15, 62, 32, 62, 24], [62]))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([14, 17, 2], Text.show_int(Text.to_integer([7, 5]))), [2]), Text.show_int(Text.to_integer([73, 7, 5]))), [2]), Text.show_int(Text.to_integer([76, 10]))), [2]), Text.show_int(Text.to_integer([3]))), [2]), Text.show_int(Text.to_integer([3, 3, 10]))), [2]), Text.show_int(Text.to_integer([15, 32, 24]))), [2]), Text.show_int(Text.to_integer([4, 5, 15, 32, 24]))), [2]), Text.show_int(Text.to_integer([]))), [2]), Text.show_int(Text.to_integer([2, 7, 5]))), [2]), Text.show_int(Text.to_integer([73]))), [2]), Text.show_int(Text.to_integer([12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10])))))
	Ok({})
}
