# wavelet-sort-aliasing
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/wavelet-sort-aliasing.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     1
#     2
#     3
#     4
#     5
#     done

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.Wavelet

# WaveletSortAliasing -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

print_list! : List(I64), I64, I64 => {}
print_list! = |xs, i, len| ({
	(if (i >= len) { line!(Text.printed([22, 16, 18, 13])) } else { ({
		line!(Text.printed(Text.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
		print_list!(xs, (i + 1), len)
	}) })
})

# --- Entry ---

main! = |_args| {
	print_list!(Wavelet.dwt_insertion_sort([5, 3, 4, 1, 2], 0, 5), 0, 5)
	Ok({})
}
