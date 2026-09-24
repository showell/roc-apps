# examples@eight-queens
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/examples@eight-queens.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Q . . . . . . .
#     . . . . Q . . .
#     . . . . . . . Q
#     . . . . . Q . .
#     . . Q . . . . .
#     . . . . . . Q .
#     . Q . . . . . .
#     . . . Q . . . .

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# EightQueens -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Answer : [Found(List(I64)), Miss]

n : I64
n = 8

int_abs : I64 -> I64
int_abs = |k| (if (k < 0) { (0 - k) } else { k })

copy_push : List(I64), I64 -> List(I64)
copy_push = |xs, v| copy_push_loop(xs, v, 0, U64.to_i64_wrap(List.len(xs)), [])

copy_push_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
copy_push_loop = |xs, v, i, len, acc| (if (i >= len) { List.append(acc, v) } else { copy_push_loop(xs, v, (i + 1), len, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

safe : List(I64), I64 -> Bool
safe = |qs, col| safe_loop(qs, col, U64.to_i64_wrap(List.len(qs)), 0)

safe_loop : List(I64), I64, I64, I64 -> Bool
safe_loop = |qs, col, row, i| (if (i >= row) { True } else { ({
	c : I64
	c = (List.get(qs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	(if (c == col) { False } else { (if (int_abs((c - col)) == (row - i)) { False } else { safe_loop(qs, col, row, (i + 1)) }) })
}) })

place : List(I64) -> Answer
place = |qs| (if (U64.to_i64_wrap(List.len(qs)) == n) { Found(qs) } else { try_col(qs, 0) })

try_col : List(I64), I64 -> Answer
try_col = |qs, col| (if (col >= n) { Miss } else { (if (safe(qs, col) == False) { try_col(qs, (col + 1)) } else { ({
	ans = place(copy_push(qs, col))
	(match ans {
		Found(sol) => Found(sol)
		Miss => try_col(qs, (col + 1))
	})
}) }) })

cell : List(I64), I64, I64 -> CceText
cell = |qs, row, col| (if ((List.get(qs, I64.to_u64_wrap(row)) ?? crash("list-at out of range")) == col) { "Q" } else { "." })

row_line : List(I64), I64, I64 -> CceText
row_line = |qs, row, col| (if (col >= n) { "" } else { (if (col == 0) { CceText.concat(cell(qs, row, col), row_line(qs, row, (col + 1))) } else { CceText.concat(CceText.concat(" ", cell(qs, row, col)), row_line(qs, row, (col + 1))) }) })

board_text : List(I64), I64 -> CceText
board_text = |qs, row| (if (row >= n) { "" } else { (if (row == (n - 1)) { row_line(qs, row, 0) } else { CceText.concat(CceText.concat(row_line(qs, row, 0), "\n"), board_text(qs, (row + 1))) }) })

render : Answer -> CceText
render = |ans| (match ans {
	Found(qs) => board_text(qs, 0)
	Miss => "no solution"
})

eq_Answer : Answer, Answer -> Bool
eq_Answer = |ex, ey| (match ex {
	Found(exf0) => (match ey {
		Found(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Miss => (match ey {
		Miss => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(render(place([]))))
	Ok({})
}
