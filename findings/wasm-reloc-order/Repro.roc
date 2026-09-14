app [main!] { pf: platform "../../machine/batch/platform/main.roc" }

import pf.Echo

Faults : { no_reset : Bool, no_link : Bool, no_mac : Bool, bme_clear : Bool }

Inner : { present : Bool, faults : Faults, phy : List(U64), page : U64, reset_at : [NotReset, ResetAt(U64)], cursor : U64 }

R : { a : Bool, b : Bool, c : Bool, d : Bool, words : List(Str), x : Inner, y : Inner, lease : U64 }

inner : Inner
inner = { present: False, faults: { no_reset: False, no_link: False, no_mac: False, bme_clear: False }, phy: [0, 0], page: 0, reset_at: NotReset, cursor: 0 }

step : List(Str), U64, R -> R
step = |args, n, r|
	match List.get(args, n) {
		Err(_) => r
		Ok(w) =>
			if w == "a" {
				step(args, n + 1, { ..r, a: True })
			} else if w == "b" {
				step(args, n + 1, { ..r, b: True })
			} else if w == "c" {
				step(args, n + 1, { ..r, c: True })
			} else if w == "lease" {
				k = U64.from_str(List.get(args, n + 1) ?? "") ?? crash("lease wants a number")
				step(args, n + 2, { ..r, lease: k })
			} else if w == "ab" {
				step(args, n + 1, { ..r, a: True, b: True })
			} else if w == "w" {
				step(args, n + 1, { ..r, words: List.set(r.words, 0, w) ?? crash("no word") })
			} else {
				crash("no such word: ${w}")
			}
	}

main! = |args| {
	r = step(args, 0, { a: False, b: False, c: False, d: False, words: ["", ""], x: inner, y: inner, lease: 3600 })
	Echo.line!("repro ${U64.to_str(r.lease + List.len(r.x.phy))}\n")
	Ok({})
}
