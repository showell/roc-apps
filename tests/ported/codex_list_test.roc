# list-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/list-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     === ConsList Prelude Module ===
#     
#     PASS: length
#     PASS: head
#     PASS: tail length
#     PASS: map double
#     PASS: filter even
#     PASS: foldl sum
#     PASS: reverse
#     PASS: append
#     PASS: take 3
#     PASS: drop 3
#     PASS: any even
#     PASS: all even
#     PASS: sum
#     PASS: is-empty nil
#     PASS: is-empty cons
#     
#     === Array-List Operations ===
#     PASS: set-at
#     PASS: insert-at
#     PASS: empty-direct
#     PASS: empty-let
#     PASS: list-of-records

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.List_

# ListTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Person := { name : CceText, age : I64 }.{
	is_eq : Person, Person -> Bool
	is_eq = |a, b| eq_Person(a, b)
}

double : I64 -> I64
double = |n| (n * 2)

is_even : I64 -> Bool
is_even = |n| ((I64.div_trunc_by(n, 2) * 2) == n)

add : I64, I64 -> I64
add = |a, b| (a + b)

show_list : List_.ConsList(I64) -> CceText
show_list = |xs| (match xs {
	Cons(h, t) => (if List_.cl_is_empty(t) { CceText.show_int(h) } else { CceText.concat(CceText.concat(CceText.show_int(h), ", "), show_list(t)) })
	Nil => ""
})

check : CceText, CceText, CceText -> CceText
check = |name, actual, expected| (if (actual == expected) { CceText.concat("PASS: ", name) } else { CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("FAIL: ", name), " expected ["), expected), "] got ["), actual), "]") })

nums : List_.ConsList(I64)
nums = List_.cl_cons(1, List_.cl_cons(2, List_.cl_cons(3, List_.cl_cons(4, List_.cl_cons(5, List_.cl_nil)))))

ages_sum : List(Person), I64, I64 -> I64
ages_sum = |ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { ages_sum(ps, (i + 1), (acc + (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).age)) })

eq_Person : Person, Person -> Bool
eq_Person = |ex, ey| ((ex.name == ey.name) and (ex.age == ey.age))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed("=== ConsList Prelude Module ==="))
	line!(CceText.printed(""))
	line!(CceText.printed(check("length", CceText.show_int(List_.cl_length(nums)), "5")))
	line!(CceText.printed(check("head", CceText.show_int(List_.cl_head(nums)), "1")))
	line!(CceText.printed(check("tail length", CceText.show_int(List_.cl_length(List_.cl_tail(nums))), "4")))
	line!(CceText.printed(check("map double", show_list(List_.cl_map(double, nums)), "2, 4, 6, 8, 10")))
	line!(CceText.printed(check("filter even", show_list(List_.cl_filter(is_even, nums)), "2, 4")))
	line!(CceText.printed(check("foldl sum", CceText.show_int(List_.cl_foldl(add, 0, nums)), "15")))
	line!(CceText.printed(check("reverse", show_list(List_.cl_reverse(nums)), "5, 4, 3, 2, 1")))
	line!(CceText.printed(check("append", show_list(List_.cl_append(List_.cl_cons(1, List_.cl_cons(2, List_.cl_nil)), List_.cl_cons(3, List_.cl_cons(4, List_.cl_nil)))), "1, 2, 3, 4")))
	line!(CceText.printed(check("take 3", show_list(List_.cl_take(3, nums)), "1, 2, 3")))
	line!(CceText.printed(check("drop 3", show_list(List_.cl_drop(3, nums)), "4, 5")))
	line!(CceText.printed(check("any even", (if List_.cl_any(is_even, nums) { "True" } else { "False" }), "True")))
	line!(CceText.printed(check("all even", (if List_.cl_all(is_even, nums) { "True" } else { "False" }), "False")))
	line!(CceText.printed(check("sum", CceText.show_int(List_.cl_sum(nums)), "15")))
	line!(CceText.printed(check("is-empty nil", (if List_.cl_is_empty(List_.cl_nil) { "True" } else { "False" }), "True")))
	line!(CceText.printed(check("is-empty cons", (if List_.cl_is_empty(nums) { "True" } else { "False" }), "False")))
	line!(CceText.printed(""))
	line!(CceText.printed("=== Array-List Operations ==="))
	({
		xs : List(I64)
		xs = [10, 20, 30]
		xs_v1 : List(I64)
		xs_v1 = (List.set(xs, I64.to_u64_wrap(1), 99) ?? crash("list-set-at past the end"))
		ys : List(I64)
		ys = xs_v1
		({
			line!(CceText.printed(check("set-at", CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.show_int((List.get(ys, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "/"), CceText.show_int((List.get(ys, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "/"), CceText.show_int((List.get(ys, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "10/99/30")))
			({
				xs2 : List(I64)
				xs2 = [1, 2, 4, 5]
				ys2 : List(I64)
				ys2 = (List.insert(xs2, I64.to_u64_wrap(2), 3) ?? crash("list-insert-at past the end"))
				({
					line!(CceText.printed(check("insert-at", CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.show_int((List.get(ys2, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "/"), CceText.show_int((List.get(ys2, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "/"), CceText.show_int((List.get(ys2, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "/"), CceText.show_int((List.get(ys2, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))), "/"), CceText.show_int((List.get(ys2, I64.to_u64_wrap(4)) ?? crash("list-at out of range")))), "1/2/3/4/5")))
					line!(CceText.printed(check("empty-direct", CceText.show_int(U64.to_i64_wrap(List.len((if True { [] } else { [1] })))), "0")))
					({
						zs : List(I64)
						zs = (if True { [] } else { [1] })
						line!(CceText.printed(check("empty-let", CceText.show_int(U64.to_i64_wrap(List.len(zs))), "0")))
					})
					({
						people = [Person.{ name: "Alice", age: 30 }, Person.{ name: "Bob", age: 25 }, Person.{ name: "Carol", age: 40 }]
						line!(CceText.printed(check("list-of-records", CceText.show_int(ages_sum(people, 0, 0)), "95")))
					})
				})
			})
		})
	})
	Ok({})
}
