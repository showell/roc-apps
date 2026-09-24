# klondike-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/klondike-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     piles=1,2,3,4,5,6,7 stock=24
#     Stock:(24) Waste:[] Found:[S] [H] [D] [C] Moves:0
#     0: TS
#     1: ## AS
#     6: ## ## ## ## ## ## 3S
#     draw-ok waste=[JH]
#     found=0 won=False
#     after-2-draws stock=22 waste=2

app [main!] { cdx: "./codex/main.roc" }

import cdx.Klondike
import cdx.Text

# KlondikeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_deal : Text
test_deal = ({
	st = Klondike.klondike_new(42)
	tab_sizes = Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.show_int(Klondike.pile_size((List.get(st.kl_tableau, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))), ","), Text.show_int(Klondike.pile_size((List.get(st.kl_tableau, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))))), ","), Text.show_int(Klondike.pile_size((List.get(st.kl_tableau, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))), ","), Text.show_int(Klondike.pile_size((List.get(st.kl_tableau, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))))), ","), Text.show_int(Klondike.pile_size((List.get(st.kl_tableau, I64.to_u64_wrap(4)) ?? crash("list-at out of range"))))), ","), Text.show_int(Klondike.pile_size((List.get(st.kl_tableau, I64.to_u64_wrap(5)) ?? crash("list-at out of range"))))), ","), Text.show_int(Klondike.pile_size((List.get(st.kl_tableau, I64.to_u64_wrap(6)) ?? crash("list-at out of range")))))
	Text.concat(Text.concat(Text.concat("piles=", tab_sizes), " stock="), Text.show_int(U64.to_i64_wrap(List.len(st.kl_stock))))
})

test_display : Text
test_display = ({
	st = Klondike.klondike_new(42)
	Klondike.kl_format_state(st)
})

test_tableau : Text
test_tableau = ({
	st = Klondike.klondike_new(42)
	Text.concat(Text.concat(Text.concat(Text.concat(Klondike.kl_format_tableau(st, 0), "\n"), Klondike.kl_format_tableau(st, 1)), "\n"), Klondike.kl_format_tableau(st, 6))
})

test_draw : Text
test_draw = ({
	st = Klondike.klondike_new(42)
	r = Klondike.kl_draw(st)
	(match r {
		MoveOk(st2) => Text.concat("draw-ok waste=", Klondike.kl_format_waste(st2))
		MoveErr(msg) => Text.concat("draw-err=", msg)
	})
})

test_foundation : Text
test_foundation = ({
	st = Klondike.klondike_new(42)
	Text.concat(Text.concat(Text.concat("found=", Text.show_int(Klondike.kl_foundation_count(st))), " won="), (if Klondike.kl_is_won(st) { "True" } else { "False" }))
})

test_moves : Text
test_moves = ({
	st = Klondike.klondike_new(42)
	r1 = Klondike.kl_draw(st)
	(match r1 {
		MoveOk(st2) => ({
			r2 = Klondike.kl_draw(st2)
			(match r2 {
				MoveOk(st3) => Text.concat(Text.concat(Text.concat("after-2-draws stock=", Text.show_int(U64.to_i64_wrap(List.len(st3.kl_stock)))), " waste="), Text.show_int(U64.to_i64_wrap(List.len(st3.kl_waste))))
				MoveErr(msg) => Text.concat("err2=", msg)
			})
		})
		MoveErr(msg) => Text.concat("err1=", msg)
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_deal))
	line!(Text.printed(test_display))
	line!(Text.printed(test_tableau))
	line!(Text.printed(test_draw))
	line!(Text.printed(test_foundation))
	line!(Text.printed(test_moves))
	Ok({})
}
