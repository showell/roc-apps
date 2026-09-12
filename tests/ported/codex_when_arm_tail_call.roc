# when-arm-tail-call
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/when-arm-tail-call.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     01 start
#     02 if-tail 10
#     03 when-nontail 10
#     04 when-tail 10
#     05 when-bare 10
#     06 done

app [main!] {}

# WhenArmTailCallTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Step : [Go(I64), Stop]

by_if : I64, I64 -> I64
by_if = |n, acc| (if (n <= 0) { acc } else { by_if((n - 1), (acc + 1)) })

by_when_nontail : Step -> I64
by_when_nontail = |s| (match s {
	Go(n) => (1 + (if (n <= 1) { 0 } else { by_when_nontail(Go((n - 1))) }))
	Stop => 0
})

by_when_tail : Step, I64 -> I64
by_when_tail = |s, acc| (match s {
	Go(n) => (if (n <= 0) { acc } else { by_when_tail(Go((n - 1)), (acc + 1)) })
	Stop => acc
})

by_when_bare : Step, I64 -> I64
by_when_bare = |s, acc| (match s {
	Go(n) => by_when_bare((if (n <= 1) { Stop } else { Go((n - 1)) }), (acc + 1))
	Stop => acc
})

eq_Step : Step, Step -> Bool
eq_Step = |ex, ey| (match ex {
	Go(exf0) => (match ey {
		Go(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Stop => (match ey {
		Stop => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!("01 start")
	line!(Str.concat("02 if-tail ", I64.to_str(by_if(10, 0))))
	line!(Str.concat("03 when-nontail ", I64.to_str(by_when_nontail(Go(10)))))
	line!(Str.concat("04 when-tail ", I64.to_str(by_when_tail(Go(10), 0))))
	line!(Str.concat("05 when-bare ", I64.to_str(by_when_bare(Go(10), 0))))
	line!("06 done")
	Ok({})
}
