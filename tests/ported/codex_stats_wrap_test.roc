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

test_mean : Text
test_mean = Text.concat("mean=", Text.show_int(Statistics.stat_mean([10, 20, 30, 40, 50])))

test_median : Text
test_median = Text.concat("median=", Text.show_int(Statistics.stat_median([5, 1, 9, 3, 7])))

test_stddev : Text
test_stddev = Text.concat("stddev=", Text.show_int(Statistics.stat_std_dev([2, 4, 4, 4, 5, 5, 7, 9])))

test_percentile : Text
test_percentile = Text.concat("p50=", Text.show_int(Statistics.stat_percentile([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 50)))

test_histogram : Text
test_histogram = ({
	hist = Statistics.stat_histogram([1, 2, 2, 3, 3, 3, 4, 4, 5], 5)
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("hist=", Text.show_int((List.get(hist, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))), ","), Text.show_int((List.get(hist, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), ","), Text.show_int((List.get(hist, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), ","), Text.show_int((List.get(hist, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))), ","), Text.show_int((List.get(hist, I64.to_u64_wrap(4)) ?? crash("list-at out of range"))))
})

test_range : Text
test_range = Text.concat("range=", Text.show_int(Statistics.stat_range([3, 1, 7, 2, 9])))

test_wrap : Text
test_wrap = ({
	wrapped = TextWrap.text_wrap("the quick brown fox jumps over the lazy dog", 15)
	Text.concat("wrap=", wrapped)
})

test_truncate : Text
test_truncate = Text.concat("trunc=", TextWrap.text_truncate("hello world", 8, "..."))

test_center : Text
test_center = Text.concat(Text.concat("center=[", TextWrap.text_center("hi", 10)), "]")

test_box : Text
test_box = TextWrap.text_box("Hello", 10)

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
