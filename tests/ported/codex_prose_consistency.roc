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

import cdx.CceText

# ProseConsistency -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Account := { balance : I64, name : CceText }.{
	is_eq : Account, Account -> Bool
	is_eq = |a, b| eq_Account(a, b)
}
Status : [Active, Closed]

make_account : CceText, I64 -> Account
make_account = |name, amount| Account.{ balance: amount, name: name }

show_account : Account -> CceText
show_account = |acct| CceText.concat(CceText.concat(acct.name, ":"), CceText.show_int(acct.balance))

show_status : Status -> CceText
show_status = |s| (match s {
	Active => "active"
	Closed => "closed"
})

account_size : I64
account_size = 16

sum_balances : List(Account), I64, I64 -> I64
sum_balances = |accounts, i, acc| (if (i >= U64.to_i64_wrap(List.len(accounts))) { acc } else { sum_balances(accounts, (i + 1), (acc + (List.get(accounts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).balance)) })

eq_Account : Account, Account -> Bool
eq_Account = |ex, ey| ((ex.balance == ey.balance) and (ex.name == ey.name))

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
		a1 = make_account("Alice", 100)
		a2 = make_account("Bob", 250)
		({
			line!(CceText.printed(show_account(a1)))
			line!(CceText.printed(show_account(a2)))
			line!(CceText.printed(CceText.concat("size=", CceText.show_int(account_size))))
			line!(CceText.printed(CceText.concat("status=", show_status(Active))))
			line!(CceText.printed(CceText.concat("total=", CceText.show_int(sum_balances([a1, a2], 0, 0)))))
		})
	})
	Ok({})
}
