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

dump : List(I64), I64, I64, Text -> Text
dump = |xs, i, n, acc| (if (i >= n) { acc } else { dump(xs, (i + 1), n, Text.concat(Text.concat(acc, (if (i > 0) { " " } else { "" })), Text.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

show_all : List(I64) -> Text
show_all = |xs| dump(xs, 0, U64.to_i64_wrap(List.len(xs)), "")

# --- Entry ---

main! = |_args| {
	line!(Text.printed("group-norm, 1 group, 1 channel, spatial 4, values 0 1 2 3:"))
	({
		p = Normalization.group_norm_params(1, 1, [1000], [0])
		({
			line!(Text.printed(Text.concat(Text.concat("  ", show_all(Normalization.group_norm(p, [0, 1000, 2000, 3000], 1, 4))), "   true -1342 -447 447 1342")))
			line!(Text.printed(""))
			line!(Text.printed("control: all values equal, so every deviation is zero and the"))
			line!(Text.printed("answer is beta no matter what the divisor is."))
			({
				p2 = Normalization.group_norm_params(1, 1, [1000], [0])
				({
					line!(Text.printed(Text.concat(Text.concat("  beta 0: ", show_all(Normalization.group_norm(p2, [2000, 2000, 2000, 2000], 1, 4))), "   true 0 0 0 0")))
					({
						p3 = Normalization.group_norm_params(1, 1, [1000], [7])
						({
							line!(Text.printed(Text.concat(Text.concat("  beta 7: ", show_all(Normalization.group_norm(p3, [2000, 2000, 2000, 2000], 1, 4))), "   true 7 7 7 7")))
							line!(Text.printed(""))
							line!(Text.printed("gamma scales the normalized value, so doubling it doubles the answer:"))
							({
								p4 = Normalization.group_norm_params(1, 1, [2000], [0])
								({
									line!(Text.printed(Text.concat(Text.concat("  gamma 2.0: ", show_all(Normalization.group_norm(p4, [0, 1000, 2000, 3000], 1, 4))), "   true -2683 -894 894 2683")))
									line!(Text.printed(""))
									line!(Text.printed("layer-norm carried the identical defect and the identical fix:"))
									({
										p5 = Normalization.layer_norm_params(4, [1000, 1000, 1000, 1000], [0, 0, 0, 0])
										({
											line!(Text.printed(Text.concat(Text.concat("  ", show_all(Normalization.layer_norm_forward(p5, [0, 1000, 2000, 3000]))), "   true -1342 -447 447 1342")))
											line!(Text.printed(""))
											line!(Text.printed("silu is x * sigmoid(x). Its sigmoid used to be a private copy of"))
											line!(Text.printed("the one in Activation, byte for byte, and carried the same defect;"))
											line!(Text.printed("it now delegates, so there is one sigmoid in the quire."))
											line!(Text.printed(Text.concat(Text.concat("  silu 1000: ", show_all(Normalization.silu_forward([1000]))), "   true 731")))
											line!(Text.printed(Text.concat(Text.concat("  silu 3000: ", show_all(Normalization.silu_forward([3000]))), "   true 2858")))
											line!(Text.printed(Text.concat(Text.concat("  silu 5000: ", show_all(Normalization.silu_forward([5000]))), "   true 4967")))
											line!(Text.printed(Text.concat(Text.concat("  silu -1000: ", show_all(Normalization.silu_forward([(0 - 1000)]))), "   true -269")))
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
