# prose-consistency
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/prose-consistency.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Alice:100
#     Bob:250
#     size=16
#     status=active
#     total=350

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ProseConsistency -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Account : { balance : I64, name : List(U8) }
Status : [Active, Closed]

make_account : List(U8), I64 -> Account
make_account = |name, amount| { balance: amount, name: name }

show_account : Account -> List(U8)
show_account = |acct| List.concat(List.concat(acct.name, [69]), Text.show_int(acct.balance))

show_status : Status -> List(U8)
show_status = |s| (match s {
	Active => [15, 24, 14, 17, 33, 13]
	Closed => [24, 23, 16, 19, 13, 22]
})

account_size : I64
account_size = 16

sum_balances : List(Account), I64, I64 -> I64
sum_balances = |accounts, i, acc| (if (i >= U64.to_i64_wrap(List.len(accounts))) { acc } else { sum_balances(accounts, (i + 1), (acc + (List.get(accounts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).balance)) })

eq_Status : Status, Status -> Bool
eq_Status = |ex, ey| (match ex {
	Active => (match ey {
		Active => True
		_ => False
	})
	Closed => (match ey {
		Closed => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	({
		a1 = make_account([41, 23, 17, 24, 13], 100)
		a2 = make_account([58, 16, 32], 250)
		({
			line!(Text.printed(show_account(a1)))
			line!(Text.printed(show_account(a2)))
			line!(Text.printed(List.concat([19, 17, 38, 13, 77], Text.show_int(account_size))))
			line!(Text.printed(List.concat([19, 14, 15, 14, 25, 19, 77], show_status(Active))))
			line!(Text.printed(List.concat([14, 16, 14, 15, 23, 77], Text.show_int(sum_balances([a1, a2], 0, 0)))))
		})
	})
	Ok({})
}
