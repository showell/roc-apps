# tco-shuffle-spill
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tco-shuffle-spill.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     turns=4

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# TcoShuffleSpill -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Cfg := { width : I64, nplayers : I64, limit : I64, data : List(I64) }.{
	is_eq : Cfg, Cfg -> Bool
	is_eq = |a, b| eq_Cfg(a, b)
}
Rng := { state : I64 }.{
	is_eq : Rng, Rng -> Bool
	is_eq = |a, b| eq_Rng(a, b)
}

rng_bump : Rng -> Rng
rng_bump = |r| Rng.{ state: (r.state + 1) }

md : I64, I64 -> I64
md = |a, b| Prelude.int_mod(a, b)

turn5 : List(I64), List(I64), I64, I64, Rng -> List(I64)
turn5 = |units, _data, _active, _w, _r| units

loop5 : Cfg, Rng, List(I64), I64, I64 -> I64
loop5 = |cfg, r, units, turn, active| (if (r.state >= 8) { turn } else { ({
	r2 = rng_bump(r)
	units2 : List(I64)
	units2 = turn5(units, cfg.data, active, cfg.width, r2)
	next_player : I64
	next_player = md((active + 1), cfg.nplayers)
	next_turn : I64
	next_turn = (if (next_player == 0) { (turn + 1) } else { turn })
	loop5(cfg, r2, units2, next_turn, next_player)
}) })

eq_Cfg : Cfg, Cfg -> Bool
eq_Cfg = |ex, ey| ((((ex.width == ey.width) and (ex.nplayers == ey.nplayers)) and (ex.limit == ey.limit)) and (ex.data == ey.data))

eq_Rng : Rng, Rng -> Bool
eq_Rng = |ex, ey| (ex.state == ey.state)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("turns=", CceText.show_int(loop5(Cfg.{ width: 4, nplayers: 2, limit: 3, data: [1, 2] }, Rng.{ state: 0 }, [7, 8], 0, 0)))))
	Ok({})
}
