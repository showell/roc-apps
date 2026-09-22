# lib@linalg-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@linalg-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     id-00=1000
#     id-01=0
#     id-11=1000
#     mul-00=2500
#     mul-01=2000
#     mul-10=1500
#     mul-11=6000
#     det=6000
#     trans-01=0
#     trans-10=1000
#     add-00=3000

app [main!] { cdx: "./codex/main.roc" }

import cdx.LinearAlgebra
import cdx.Text

# LinAlgTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

la_a : LinearAlgebra.Matrix
la_a = LinearAlgebra.mat_from_list(2, 2, [2000, 1000, 0, 3000])

la_b : LinearAlgebra.Matrix
la_b = LinearAlgebra.mat_from_list(2, 2, [1000, 0, 500, 2000])

la_id : I64, I64 -> List(U8)
la_id = |r, c| Text.show_int(LinearAlgebra.mat_get(LinearAlgebra.mat_identity(3), r, c))

la_mul : I64, I64 -> List(U8)
la_mul = |r, c| Text.show_int(LinearAlgebra.mat_get(LinearAlgebra.mat_mul(la_a, la_b), r, c))

la_trans : I64, I64 -> List(U8)
la_trans = |r, c| Text.show_int(LinearAlgebra.mat_get(LinearAlgebra.mat_transpose(la_a), r, c))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([17, 22, 73, 3, 3, 77], la_id(0, 0))))
	line!(Text.printed(List.concat([17, 22, 73, 3, 4, 77], la_id(0, 1))))
	line!(Text.printed(List.concat([17, 22, 73, 4, 4, 77], la_id(1, 1))))
	line!(Text.printed(List.concat([26, 25, 23, 73, 3, 3, 77], la_mul(0, 0))))
	line!(Text.printed(List.concat([26, 25, 23, 73, 3, 4, 77], la_mul(0, 1))))
	line!(Text.printed(List.concat([26, 25, 23, 73, 4, 3, 77], la_mul(1, 0))))
	line!(Text.printed(List.concat([26, 25, 23, 73, 4, 4, 77], la_mul(1, 1))))
	line!(Text.printed(List.concat([22, 13, 14, 77], Text.show_int(LinearAlgebra.mat_det(la_a)))))
	line!(Text.printed(List.concat([14, 21, 15, 18, 19, 73, 3, 4, 77], la_trans(0, 1))))
	line!(Text.printed(List.concat([14, 21, 15, 18, 19, 73, 4, 3, 77], la_trans(1, 0))))
	line!(Text.printed(List.concat([15, 22, 22, 73, 3, 3, 77], Text.show_int(LinearAlgebra.mat_get(LinearAlgebra.mat_add(la_a, la_b), 0, 0)))))
	Ok({})
}
