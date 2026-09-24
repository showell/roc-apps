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

ls_mse : Text
ls_mse = (if (Loss.loss_mse(ls_pred, ls_target) > 0) { "positive" } else { "zero" })

ls_hinge : Text
ls_hinge = (if (Loss.loss_hinge([500, 800], [1000, (0 - 1000)]) >= 0) { "non-neg" } else { "negative" })

ls_huber : Text
ls_huber = (if (Loss.loss_huber(ls_pred, ls_target, 500) > 0) { "positive" } else { "zero" })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("mse=", ls_mse)))
	line!(Text.printed(Text.concat("hinge=", ls_hinge)))
	line!(Text.printed(Text.concat("huber=", ls_huber)))
	line!(Text.printed(Text.concat("perfect-mse=", Text.show_int(Loss.loss_mse([500, 500], [500, 500])))))
	line!(Text.printed(Text.concat("clamp-lo=", Text.show_int(Loss.loss_clamp((0 - 5), 0, 100)))))
	line!(Text.printed(Text.concat("clamp-hi=", Text.show_int(Loss.loss_clamp(200, 0, 100)))))
	line!(Text.printed(Text.concat("clamp-mid=", Text.show_int(Loss.loss_clamp(50, 0, 100)))))
	Ok({})
}
