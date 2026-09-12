# rv-frameless-imm
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/rv-frameless-imm.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     254
#     65024
#     65253
#     42496
#     399
#     254
#     1278
#     241

app [main!] {}

# RvFramelessImm -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pf_of : I64 -> I64
pf_of = |id| I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(id), U64.pow(2, I64.to_u64_wrap(16)))), 255)

shl_let : I64 -> I64
shl_let = |id| ({
	pf = I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(id), U64.pow(2, I64.to_u64_wrap(16)))), 255)
	U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(pf), U64.pow(2, I64.to_u64_wrap(8))))
})

shl_let_if : I64 -> I64
shl_let_if = |id| ({
	pf = I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(id), U64.pow(2, I64.to_u64_wrap(16)))), 255)
	(if (pf < 240) { U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(pf), U64.pow(2, I64.to_u64_wrap(8)))) } else { I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(pf), U64.pow(2, I64.to_u64_wrap(8)))), I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(id), U64.pow(2, I64.to_u64_wrap(8)))), 255)) })
})

shru_let : I64 -> I64
shru_let = |id| ({
	pf = I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(id), U64.pow(2, I64.to_u64_wrap(16)))), 65535)
	U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(pf), U64.pow(2, I64.to_u64_wrap(4))))
})

and_let : I64 -> I64
and_let = |id| ({
	pf = U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(id), U64.pow(2, I64.to_u64_wrap(16))))
	I64.bitwise_and(pf, 255)
})

or_let : I64 -> I64
or_let = |id| ({
	pf = I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(id), U64.pow(2, I64.to_u64_wrap(16)))), 255)
	I64.bitwise_or(pf, 1024)
})

xor_let : I64 -> I64
xor_let = |id| ({
	pf = I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(id), U64.pow(2, I64.to_u64_wrap(16)))), 255)
	I64.bitwise_xor(pf, 15)
})

# --- Entry ---

main! = |_args| {
	line!(I64.to_str(pf_of(419357952)))
	line!(I64.to_str(shl_let(419357952)))
	line!(I64.to_str(shl_let_if(419357952)))
	line!(I64.to_str(shl_let_if(111550464)))
	line!(I64.to_str(shru_let(419357952)))
	line!(I64.to_str(and_let(419357952)))
	line!(I64.to_str(or_let(419357952)))
	line!(I64.to_str(xor_let(419357952)))
	Ok({})
}
