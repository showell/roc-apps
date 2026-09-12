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

app [main!] {}

# ProseConsistency -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Account : { balance : I64, name : Str }
Status : [Active, Closed]

make_account : Str, I64 -> Account
make_account = |name, amount| { balance: amount, name: name }

show_account : Account -> Str
show_account = |acct| Str.concat(Str.concat(acct.name, ":"), I64.to_str(acct.balance))

show_status : Status -> Str
show_status = |s| (match s {
	Active => "active"
	Closed => "closed"
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
		a1 = make_account("Alice", 100)
		a2 = make_account("Bob", 250)
		({
			line!(show_account(a1))
			line!(show_account(a2))
			line!(Str.concat("size=", I64.to_str(account_size)))
			line!(Str.concat("status=", show_status(Active)))
			line!(Str.concat("total=", I64.to_str(sum_balances([a1, a2], 0, 0))))
		})
	})
	Ok({})
}
