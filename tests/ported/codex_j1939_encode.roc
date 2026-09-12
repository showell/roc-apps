# j1939-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/j1939-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     5

app [main!] { cdx: "./codex/main.roc" }

import cdx.J1939

# J1939EncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_can_id : I64
check_can_id = flag((J1939.j1939_can_id(6, 254, 229, 0) == 419357952))

check_pgn_pdu2 : I64
check_pgn_pdu2 = flag((J1939.j1939_pgn(J1939.j1939_can_id(6, 254, 229, 0)) == 65253))

check_priority : I64
check_priority = flag((J1939.j1939_priority(419357952) == 6))

check_source_addr : I64
check_source_addr = flag((J1939.j1939_source_addr(419357953) == 1))

check_pgn_pdu1 : I64
check_pgn_pdu1 = flag((if (J1939.j1939_pgn(J1939.j1939_can_id(6, 234, 33, 0)) == 59904) { (J1939.j1939_ps(J1939.j1939_can_id(6, 234, 33, 0)) == 33) } else { False }))

# --- Entry ---

main! = |_args| {
	a = check_can_id
	b = check_pgn_pdu2
	c = check_priority
	d = check_source_addr
	e = check_pgn_pdu1
	line!(I64.to_str(((((a + b) + c) + d) + e)))
	Ok({})
}
