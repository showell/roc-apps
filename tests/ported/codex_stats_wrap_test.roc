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

import cdx.Statistics
import cdx.Text
import cdx.TextWrap

# StatsWrapTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_mean : List(U8)
test_mean = List.concat([26, 13, 15, 18, 77], Text.show_int(Statistics.stat_mean([10, 20, 30, 40, 50])))

test_median : List(U8)
test_median = List.concat([26, 13, 22, 17, 15, 18, 77], Text.show_int(Statistics.stat_median([5, 1, 9, 3, 7])))

test_stddev : List(U8)
test_stddev = List.concat([19, 14, 22, 22, 13, 33, 77], Text.show_int(Statistics.stat_std_dev([2, 4, 4, 4, 5, 5, 7, 9])))

test_percentile : List(U8)
test_percentile = List.concat([31, 8, 3, 77], Text.show_int(Statistics.stat_percentile([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 50)))

test_histogram : List(U8)
test_histogram = ({
	hist = Statistics.stat_histogram([1, 2, 2, 3, 3, 3, 4, 4, 5], 5)
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([20, 17, 19, 14, 77], Text.show_int((List.get(hist, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))), [66]), Text.show_int((List.get(hist, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), [66]), Text.show_int((List.get(hist, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), [66]), Text.show_int((List.get(hist, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))), [66]), Text.show_int((List.get(hist, I64.to_u64_wrap(4)) ?? crash("list-at out of range"))))
})

test_range : List(U8)
test_range = List.concat([21, 15, 18, 29, 13, 77], Text.show_int(Statistics.stat_range([3, 1, 7, 2, 9])))

test_wrap : List(U8)
test_wrap = ({
	wrapped = TextWrap.text_wrap([14, 20, 13, 2, 37, 25, 17, 24, 34, 2, 32, 21, 16, 27, 18, 2, 28, 16, 36, 2, 35, 25, 26, 31, 19, 2, 16, 33, 13, 21, 2, 14, 20, 13, 2, 23, 15, 38, 30, 2, 22, 16, 29], 15)
	List.concat([27, 21, 15, 31, 77], wrapped)
})

test_truncate : List(U8)
test_truncate = List.concat([14, 21, 25, 18, 24, 77], TextWrap.text_truncate([20, 13, 23, 23, 16, 2, 27, 16, 21, 23, 22], 8, [65, 65, 65]))

test_center : List(U8)
test_center = List.concat(List.concat([24, 13, 18, 14, 13, 21, 77, 88], TextWrap.text_center([20, 17], 10)), [89])

test_box : List(U8)
test_box = TextWrap.text_box([46, 13, 23, 23, 16], 10)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_mean))
	line!(Text.printed(test_median))
	line!(Text.printed(test_stddev))
	line!(Text.printed(test_percentile))
	line!(Text.printed(test_histogram))
	line!(Text.printed(test_range))
	line!(Text.printed(test_wrap))
	line!(Text.printed(test_truncate))
	line!(Text.printed(test_center))
	line!(Text.printed(test_box))
	Ok({})
}
