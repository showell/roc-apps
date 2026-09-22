# lib@loss-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@loss-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     mse=positive
#     hinge=non-neg
#     huber=positive
#     perfect-mse=0
#     clamp-lo=0
#     clamp-hi=100
#     clamp-mid=50

app [main!] { cdx: "./codex/main.roc" }

import cdx.Loss
import cdx.Text

# LossTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ls_pred : List(I64)
ls_pred = [800, 600, 400, 200]

ls_target : List(I64)
ls_target = [1000, 500, 300, 100]

ls_mse : List(U8)
ls_mse = (if (Loss.loss_mse(ls_pred, ls_target) > 0) { [31, 16, 19, 17, 14, 17, 33, 13] } else { [38, 13, 21, 16] })

ls_hinge : List(U8)
ls_hinge = (if (Loss.loss_hinge([500, 800], [1000, (0 - 1000)]) >= 0) { [18, 16, 18, 73, 18, 13, 29] } else { [18, 13, 29, 15, 14, 17, 33, 13] })

ls_huber : List(U8)
ls_huber = (if (Loss.loss_huber(ls_pred, ls_target, 500) > 0) { [31, 16, 19, 17, 14, 17, 33, 13] } else { [38, 13, 21, 16] })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([26, 19, 13, 77], ls_mse)))
	line!(Text.printed(List.concat([20, 17, 18, 29, 13, 77], ls_hinge)))
	line!(Text.printed(List.concat([20, 25, 32, 13, 21, 77], ls_huber)))
	line!(Text.printed(List.concat([31, 13, 21, 28, 13, 24, 14, 73, 26, 19, 13, 77], Text.show_int(Loss.loss_mse([500, 500], [500, 500])))))
	line!(Text.printed(List.concat([24, 23, 15, 26, 31, 73, 23, 16, 77], Text.show_int(Loss.loss_clamp((0 - 5), 0, 100)))))
	line!(Text.printed(List.concat([24, 23, 15, 26, 31, 73, 20, 17, 77], Text.show_int(Loss.loss_clamp(200, 0, 100)))))
	line!(Text.printed(List.concat([24, 23, 15, 26, 31, 73, 26, 17, 22, 77], Text.show_int(Loss.loss_clamp(50, 0, 100)))))
	Ok({})
}
