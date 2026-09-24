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

import cdx.CceText
import cdx.NumberTheory

# NumberTheoryTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_bool : Bool -> CceText
show_bool = |b| (if b { "true" } else { "false" })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("gcd(12,8)=", CceText.show_int(NumberTheory.gcd(12, 8)))))
	line!(CceText.printed(CceText.concat("gcd(17,13)=", CceText.show_int(NumberTheory.gcd(17, 13)))))
	line!(CceText.printed(CceText.concat("lcm(4,6)=", CceText.show_int(NumberTheory.lcm(4, 6)))))
	line!(CceText.printed(CceText.concat("lcm(7,5)=", CceText.show_int(NumberTheory.lcm(7, 5)))))
	line!(CceText.printed(CceText.concat("mod-exp(2,10,1000)=", CceText.show_int(NumberTheory.mod_exp(2, 10, 1000)))))
	line!(CceText.printed(CceText.concat("mod-exp(3,7,100)=", CceText.show_int(NumberTheory.mod_exp(3, 7, 100)))))
	line!(CceText.printed(CceText.concat("is-prime(2)=", show_bool(NumberTheory.is_prime(2)))))
	line!(CceText.printed(CceText.concat("is-prime(17)=", show_bool(NumberTheory.is_prime(17)))))
	line!(CceText.printed(CceText.concat("is-prime(15)=", show_bool(NumberTheory.is_prime(15)))))
	line!(CceText.printed(CceText.concat("is-prime(1)=", show_bool(NumberTheory.is_prime(1)))))
	line!(CceText.printed(CceText.concat("primes=", CceText.show_int(U64.to_i64_wrap(List.len(NumberTheory.primes_up_to(30)))))))
	line!(CceText.printed(CceText.concat("totient(12)=", CceText.show_int(NumberTheory.euler_totient(12)))))
	line!(CceText.printed(CceText.concat("factors(60)=", CceText.show_int(U64.to_i64_wrap(List.len(NumberTheory.factor(60)))))))
	line!(CceText.printed(CceText.concat("mod-inv(3,7)=", CceText.show_int(NumberTheory.mod_inverse(3, 7)))))
	Ok({})
}
