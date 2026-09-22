# lib@number-theory-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@number-theory-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     gcd(12,8)=4
#     gcd(17,13)=1
#     lcm(4,6)=12
#     lcm(7,5)=35
#     mod-exp(2,10,1000)=24
#     mod-exp(3,7,100)=87
#     is-prime(2)=true
#     is-prime(17)=true
#     is-prime(15)=false
#     is-prime(1)=false
#     primes=10
#     totient(12)=4
#     factors(60)=3
#     mod-inv(3,7)=5

app [main!] { cdx: "./codex/main.roc" }

import cdx.NumberTheory
import cdx.Text

# NumberTheoryTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_bool : Bool -> List(U8)
show_bool = |b| (if b { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([29, 24, 22, 74, 4, 5, 66, 11, 75, 77], Text.show_int(NumberTheory.gcd(12, 8)))))
	line!(Text.printed(List.concat([29, 24, 22, 74, 4, 10, 66, 4, 6, 75, 77], Text.show_int(NumberTheory.gcd(17, 13)))))
	line!(Text.printed(List.concat([23, 24, 26, 74, 7, 66, 9, 75, 77], Text.show_int(NumberTheory.lcm(4, 6)))))
	line!(Text.printed(List.concat([23, 24, 26, 74, 10, 66, 8, 75, 77], Text.show_int(NumberTheory.lcm(7, 5)))))
	line!(Text.printed(List.concat([26, 16, 22, 73, 13, 36, 31, 74, 5, 66, 4, 3, 66, 4, 3, 3, 3, 75, 77], Text.show_int(NumberTheory.mod_exp(2, 10, 1000)))))
	line!(Text.printed(List.concat([26, 16, 22, 73, 13, 36, 31, 74, 6, 66, 10, 66, 4, 3, 3, 75, 77], Text.show_int(NumberTheory.mod_exp(3, 7, 100)))))
	line!(Text.printed(List.concat([17, 19, 73, 31, 21, 17, 26, 13, 74, 5, 75, 77], show_bool(NumberTheory.is_prime(2)))))
	line!(Text.printed(List.concat([17, 19, 73, 31, 21, 17, 26, 13, 74, 4, 10, 75, 77], show_bool(NumberTheory.is_prime(17)))))
	line!(Text.printed(List.concat([17, 19, 73, 31, 21, 17, 26, 13, 74, 4, 8, 75, 77], show_bool(NumberTheory.is_prime(15)))))
	line!(Text.printed(List.concat([17, 19, 73, 31, 21, 17, 26, 13, 74, 4, 75, 77], show_bool(NumberTheory.is_prime(1)))))
	line!(Text.printed(List.concat([31, 21, 17, 26, 13, 19, 77], Text.show_int(U64.to_i64_wrap(List.len(NumberTheory.primes_up_to(30)))))))
	line!(Text.printed(List.concat([14, 16, 14, 17, 13, 18, 14, 74, 4, 5, 75, 77], Text.show_int(NumberTheory.euler_totient(12)))))
	line!(Text.printed(List.concat([28, 15, 24, 14, 16, 21, 19, 74, 9, 3, 75, 77], Text.show_int(U64.to_i64_wrap(List.len(NumberTheory.factor(60)))))))
	line!(Text.printed(List.concat([26, 16, 22, 73, 17, 18, 33, 74, 6, 66, 10, 75, 77], Text.show_int(NumberTheory.mod_inverse(3, 7)))))
	Ok({})
}
