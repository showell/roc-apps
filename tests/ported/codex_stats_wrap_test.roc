# stats-wrap-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/stats-wrap-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     mean=30
#     median=5
#     stddev=2
#     p50=5
#     hist=1,2,3,2,1
#     range=8
#     wrap=the quick brown
#     fox jumps over
#     the lazy dog
#     trunc=hello...
#     center=[    hi]
#     +------------+
#     | Hello      |
#     +------------+

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Statistics
import cdx.TextWrap

# StatsWrapTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_mean : CceText
test_mean = CceText.concat("mean=", CceText.show_int(Statistics.stat_mean([10, 20, 30, 40, 50])))

test_median : CceText
test_median = CceText.concat("median=", CceText.show_int(Statistics.stat_median([5, 1, 9, 3, 7])))

test_stddev : CceText
test_stddev = CceText.concat("stddev=", CceText.show_int(Statistics.stat_std_dev([2, 4, 4, 4, 5, 5, 7, 9])))

test_percentile : CceText
test_percentile = CceText.concat("p50=", CceText.show_int(Statistics.stat_percentile([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 50)))

test_histogram : CceText
test_histogram = ({
	hist = Statistics.stat_histogram([1, 2, 2, 3, 3, 3, 4, 4, 5], 5)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("hist=", CceText.show_int((List.get(hist, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))), ","), CceText.show_int((List.get(hist, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), ","), CceText.show_int((List.get(hist, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), ","), CceText.show_int((List.get(hist, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))), ","), CceText.show_int((List.get(hist, I64.to_u64_wrap(4)) ?? crash("list-at out of range"))))
})

test_range : CceText
test_range = CceText.concat("range=", CceText.show_int(Statistics.stat_range([3, 1, 7, 2, 9])))

test_wrap : CceText
test_wrap = ({
	wrapped = TextWrap.text_wrap("the quick brown fox jumps over the lazy dog", 15)
	CceText.concat("wrap=", wrapped)
})

test_truncate : CceText
test_truncate = CceText.concat("trunc=", TextWrap.text_truncate("hello world", 8, "..."))

test_center : CceText
test_center = CceText.concat(CceText.concat("center=[", TextWrap.text_center("hi", 10)), "]")

test_box : CceText
test_box = TextWrap.text_box("Hello", 10)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_mean))
	line!(CceText.printed(test_median))
	line!(CceText.printed(test_stddev))
	line!(CceText.printed(test_percentile))
	line!(CceText.printed(test_histogram))
	line!(CceText.printed(test_range))
	line!(CceText.printed(test_wrap))
	line!(CceText.printed(test_truncate))
	line!(CceText.printed(test_center))
	line!(CceText.printed(test_box))
	Ok({})
}
