# forewords@ai-normalization
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@ai-normalization.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     group-norm, 1 group, 1 channel, spatial 4, values 0 1 2 3:
#       -1341 -447 447 1341   true -1342 -447 447 1342
#     
#     control: all values equal, so every deviation is zero and the
#     answer is beta no matter what the divisor is.
#       beta 0: 0 0 0 0   true 0 0 0 0
#       beta 7: 7 7 7 7   true 7 7 7 7
#     
#     gamma scales the normalized value, so doubling it doubles the answer:
#       gamma 2.0: -2682 -894 894 2682   true -2683 -894 894 2683
#     
#     layer-norm carried the identical defect and the identical fix:
#       -1341 -447 447 1341   true -1342 -447 447 1342
#     
#     silu is x * sigmoid(x). Its sigmoid used to be a private copy of
#     the one in Activation, byte for byte, and carried the same defect;
#     it now delegates, so there is one sigmoid in the quire.
#       silu 1000: 731   true 731
#       silu 3000: 2859   true 2858
#       silu 5000: 4970   true 4967
#       silu -1000: -268   true -269

app [main!] { cdx: "./codex/main.roc" }

import cdx.Normalization
import cdx.Text

# AiNormalization -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

dump : List(I64), I64, I64, List(U8) -> List(U8)
dump = |xs, i, n, acc| (if (i >= n) { acc } else { dump(xs, (i + 1), n, List.concat(List.concat(acc, (if (i > 0) { [2] } else { [] })), Text.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

show_all : List(I64) -> List(U8)
show_all = |xs| dump(xs, 0, U64.to_i64_wrap(List.len(xs)), [])

# --- Entry ---

main! = |_args| {
	line!(Text.printed([29, 21, 16, 25, 31, 73, 18, 16, 21, 26, 66, 2, 4, 2, 29, 21, 16, 25, 31, 66, 2, 4, 2, 24, 20, 15, 18, 18, 13, 23, 66, 2, 19, 31, 15, 14, 17, 15, 23, 2, 7, 66, 2, 33, 15, 23, 25, 13, 19, 2, 3, 2, 4, 2, 5, 2, 6, 69]))
	({
		p = Normalization.group_norm_params(1, 1, [1000], [0])
		({
			line!(Text.printed(List.concat(List.concat([2, 2], show_all(Normalization.group_norm(p, [0, 1000, 2000, 3000], 1, 4))), [2, 2, 2, 14, 21, 25, 13, 2, 73, 4, 6, 7, 5, 2, 73, 7, 7, 10, 2, 7, 7, 10, 2, 4, 6, 7, 5])))
			line!(Text.printed([]))
			line!(Text.printed([24, 16, 18, 14, 21, 16, 23, 69, 2, 15, 23, 23, 2, 33, 15, 23, 25, 13, 19, 2, 13, 37, 25, 15, 23, 66, 2, 19, 16, 2, 13, 33, 13, 21, 30, 2, 22, 13, 33, 17, 15, 14, 17, 16, 18, 2, 17, 19, 2, 38, 13, 21, 16, 2, 15, 18, 22, 2, 14, 20, 13]))
			line!(Text.printed([15, 18, 19, 27, 13, 21, 2, 17, 19, 2, 32, 13, 14, 15, 2, 18, 16, 2, 26, 15, 14, 14, 13, 21, 2, 27, 20, 15, 14, 2, 14, 20, 13, 2, 22, 17, 33, 17, 19, 16, 21, 2, 17, 19, 65]))
			({
				p2 = Normalization.group_norm_params(1, 1, [1000], [0])
				({
					line!(Text.printed(List.concat(List.concat([2, 2, 32, 13, 14, 15, 2, 3, 69, 2], show_all(Normalization.group_norm(p2, [2000, 2000, 2000, 2000], 1, 4))), [2, 2, 2, 14, 21, 25, 13, 2, 3, 2, 3, 2, 3, 2, 3])))
					({
						p3 = Normalization.group_norm_params(1, 1, [1000], [7])
						({
							line!(Text.printed(List.concat(List.concat([2, 2, 32, 13, 14, 15, 2, 10, 69, 2], show_all(Normalization.group_norm(p3, [2000, 2000, 2000, 2000], 1, 4))), [2, 2, 2, 14, 21, 25, 13, 2, 10, 2, 10, 2, 10, 2, 10])))
							line!(Text.printed([]))
							line!(Text.printed([29, 15, 26, 26, 15, 2, 19, 24, 15, 23, 13, 19, 2, 14, 20, 13, 2, 18, 16, 21, 26, 15, 23, 17, 38, 13, 22, 2, 33, 15, 23, 25, 13, 66, 2, 19, 16, 2, 22, 16, 25, 32, 23, 17, 18, 29, 2, 17, 14, 2, 22, 16, 25, 32, 23, 13, 19, 2, 14, 20, 13, 2, 15, 18, 19, 27, 13, 21, 69]))
							({
								p4 = Normalization.group_norm_params(1, 1, [2000], [0])
								({
									line!(Text.printed(List.concat(List.concat([2, 2, 29, 15, 26, 26, 15, 2, 5, 65, 3, 69, 2], show_all(Normalization.group_norm(p4, [0, 1000, 2000, 3000], 1, 4))), [2, 2, 2, 14, 21, 25, 13, 2, 73, 5, 9, 11, 6, 2, 73, 11, 12, 7, 2, 11, 12, 7, 2, 5, 9, 11, 6])))
									line!(Text.printed([]))
									line!(Text.printed([23, 15, 30, 13, 21, 73, 18, 16, 21, 26, 2, 24, 15, 21, 21, 17, 13, 22, 2, 14, 20, 13, 2, 17, 22, 13, 18, 14, 17, 24, 15, 23, 2, 22, 13, 28, 13, 24, 14, 2, 15, 18, 22, 2, 14, 20, 13, 2, 17, 22, 13, 18, 14, 17, 24, 15, 23, 2, 28, 17, 36, 69]))
									({
										p5 = Normalization.layer_norm_params(4, [1000, 1000, 1000, 1000], [0, 0, 0, 0])
										({
											line!(Text.printed(List.concat(List.concat([2, 2], show_all(Normalization.layer_norm_forward(p5, [0, 1000, 2000, 3000]))), [2, 2, 2, 14, 21, 25, 13, 2, 73, 4, 6, 7, 5, 2, 73, 7, 7, 10, 2, 7, 7, 10, 2, 4, 6, 7, 5])))
											line!(Text.printed([]))
											line!(Text.printed([19, 17, 23, 25, 2, 17, 19, 2, 36, 2, 78, 2, 19, 17, 29, 26, 16, 17, 22, 74, 36, 75, 65, 2, 43, 14, 19, 2, 19, 17, 29, 26, 16, 17, 22, 2, 25, 19, 13, 22, 2, 14, 16, 2, 32, 13, 2, 15, 2, 31, 21, 17, 33, 15, 14, 13, 2, 24, 16, 31, 30, 2, 16, 28]))
											line!(Text.printed([14, 20, 13, 2, 16, 18, 13, 2, 17, 18, 2, 41, 24, 14, 17, 33, 15, 14, 17, 16, 18, 66, 2, 32, 30, 14, 13, 2, 28, 16, 21, 2, 32, 30, 14, 13, 66, 2, 15, 18, 22, 2, 24, 15, 21, 21, 17, 13, 22, 2, 14, 20, 13, 2, 19, 15, 26, 13, 2, 22, 13, 28, 13, 24, 14, 70]))
											line!(Text.printed([17, 14, 2, 18, 16, 27, 2, 22, 13, 23, 13, 29, 15, 14, 13, 19, 66, 2, 19, 16, 2, 14, 20, 13, 21, 13, 2, 17, 19, 2, 16, 18, 13, 2, 19, 17, 29, 26, 16, 17, 22, 2, 17, 18, 2, 14, 20, 13, 2, 37, 25, 17, 21, 13, 65]))
											line!(Text.printed(List.concat(List.concat([2, 2, 19, 17, 23, 25, 2, 4, 3, 3, 3, 69, 2], show_all(Normalization.silu_forward([1000]))), [2, 2, 2, 14, 21, 25, 13, 2, 10, 6, 4])))
											line!(Text.printed(List.concat(List.concat([2, 2, 19, 17, 23, 25, 2, 6, 3, 3, 3, 69, 2], show_all(Normalization.silu_forward([3000]))), [2, 2, 2, 14, 21, 25, 13, 2, 5, 11, 8, 11])))
											line!(Text.printed(List.concat(List.concat([2, 2, 19, 17, 23, 25, 2, 8, 3, 3, 3, 69, 2], show_all(Normalization.silu_forward([5000]))), [2, 2, 2, 14, 21, 25, 13, 2, 7, 12, 9, 10])))
											line!(Text.printed(List.concat(List.concat([2, 2, 19, 17, 23, 25, 2, 73, 4, 3, 3, 3, 69, 2], show_all(Normalization.silu_forward([(0 - 1000)]))), [2, 2, 2, 14, 21, 25, 13, 2, 73, 5, 9, 12])))
										})
									})
								})
							})
						})
					})
				})
			})
		})
	})
	Ok({})
}
