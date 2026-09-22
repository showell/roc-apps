# particle-spread
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/particle-spread.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     emitted=200
#     modal-dy-share-sp64=1
#     modal-dy-share-sp100=2
#     sample-dy=8 22 -40
#     independent=yes

app [main!] { cdx: "./codex/main.roc" }

import cdx.ParticleSystem
import cdx.Text

# ParticleSpread -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

sys_for : I64 -> ParticleSystem.ParticleSystem
sys_for = |spread| ParticleSystem.psys_emit(ParticleSystem.psys_new(400), ParticleSystem.emitter_new(0, 0, 0, 0, 0, 0, spread, 100, 0), 200, 12345)

dy_at : ParticleSystem.ParticleSystem, I64 -> I64
dy_at = |sys, i| ({
	p = (List.get(sys.particles, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	(p.part_vy - p.part_vx)
})

share : ParticleSystem.ParticleSystem, I64, I64, I64, I64 -> I64
share = |sys, target, i, n, acc| (if (i >= n) { acc } else { share(sys, target, (i + 1), n, (acc + (if (dy_at(sys, i) == target) { 1 } else { 0 }))) })

modal : I64 -> I64
modal = |spread| ({
	s = sys_for(spread)
	share(s, dy_at(s, 0), 0, 200, 0)
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([13, 26, 17, 14, 14, 13, 22, 77], Text.show_int(ParticleSystem.psys_count(sys_for(100))))))
	line!(Text.printed(List.concat([26, 16, 22, 15, 23, 73, 22, 30, 73, 19, 20, 15, 21, 13, 73, 19, 31, 9, 7, 77], Text.show_int(modal(64)))))
	line!(Text.printed(List.concat([26, 16, 22, 15, 23, 73, 22, 30, 73, 19, 20, 15, 21, 13, 73, 19, 31, 4, 3, 3, 77], Text.show_int(modal(100)))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat([19, 15, 26, 31, 23, 13, 73, 22, 30, 77], Text.show_int(dy_at(sys_for(100), 0))), [2]), Text.show_int(dy_at(sys_for(100), 1))), [2]), Text.show_int(dy_at(sys_for(100), 2)))))
	line!(Text.printed(List.concat([17, 18, 22, 13, 31, 13, 18, 22, 13, 18, 14, 77], (if (modal(100) < 20) { [30, 13, 19] } else { [18, 16] }))))
	Ok({})
}
