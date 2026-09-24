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

import cdx.List_
import cdx.Text

# ListTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Person : { name : Text, age : I64 }

double : I64 -> I64
double = |n| (n * 2)

is_even : I64 -> Bool
is_even = |n| ((I64.div_trunc_by(n, 2) * 2) == n)

add : I64, I64 -> I64
add = |a, b| (a + b)

show_list : List_.ConsList(I64) -> Text
show_list = |xs| (match xs {
	Cons(h, t) => (if List_.cl_is_empty(t) { Text.show_int(h) } else { Text.concat(Text.concat(Text.show_int(h), ", "), show_list(t)) })
	Nil => ""
})

check : Text, Text, Text -> Text
check = |name, actual, expected| (if (actual == expected) { Text.concat("PASS: ", name) } else { Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("FAIL: ", name), " expected ["), expected), "] got ["), actual), "]") })

nums : List_.ConsList(I64)
nums = List_.cl_cons(1, List_.cl_cons(2, List_.cl_cons(3, List_.cl_cons(4, List_.cl_cons(5, List_.cl_nil)))))

ages_sum : List(Person), I64, I64 -> I64
ages_sum = |ps, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { ages_sum(ps, (i + 1), (acc + (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).age)) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed("=== ConsList Prelude Module ==="))
	line!(Text.printed(""))
	line!(Text.printed(check("length", Text.show_int(List_.cl_length(nums)), "5")))
	line!(Text.printed(check("head", Text.show_int(List_.cl_head(nums)), "1")))
	line!(Text.printed(check("tail length", Text.show_int(List_.cl_length(List_.cl_tail(nums))), "4")))
	line!(Text.printed(check("map double", show_list(List_.cl_map(double, nums)), "2, 4, 6, 8, 10")))
	line!(Text.printed(check("filter even", show_list(List_.cl_filter(is_even, nums)), "2, 4")))
	line!(Text.printed(check("foldl sum", Text.show_int(List_.cl_foldl(add, 0, nums)), "15")))
	line!(Text.printed(check("reverse", show_list(List_.cl_reverse(nums)), "5, 4, 3, 2, 1")))
	line!(Text.printed(check("append", show_list(List_.cl_append(List_.cl_cons(1, List_.cl_cons(2, List_.cl_nil)), List_.cl_cons(3, List_.cl_cons(4, List_.cl_nil)))), "1, 2, 3, 4")))
	line!(Text.printed(check("take 3", show_list(List_.cl_take(3, nums)), "1, 2, 3")))
	line!(Text.printed(check("drop 3", show_list(List_.cl_drop(3, nums)), "4, 5")))
	line!(Text.printed(check("any even", (if List_.cl_any(is_even, nums) { "True" } else { "False" }), "True")))
	line!(Text.printed(check("all even", (if List_.cl_all(is_even, nums) { "True" } else { "False" }), "False")))
	line!(Text.printed(check("sum", Text.show_int(List_.cl_sum(nums)), "15")))
	line!(Text.printed(check("is-empty nil", (if List_.cl_is_empty(List_.cl_nil) { "True" } else { "False" }), "True")))
	line!(Text.printed(check("is-empty cons", (if List_.cl_is_empty(nums) { "True" } else { "False" }), "False")))
	line!(Text.printed(""))
	line!(Text.printed("=== Array-List Operations ==="))
	({
		xs = [10, 20, 30]
		ys = (List.set(xs, I64.to_u64_wrap(1), 99) ?? crash("list-set-at past the end"))
		({
			line!(Text.printed(check("set-at", Text.concat(Text.concat(Text.concat(Text.concat(Text.show_int((List.get(ys, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "/"), Text.show_int((List.get(ys, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "/"), Text.show_int((List.get(ys, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "10/99/30")))
			({
				xs2 = [1, 2, 4, 5]
				ys2 = (List.insert(xs2, I64.to_u64_wrap(2), 3) ?? crash("list-insert-at past the end"))
				({
					line!(Text.printed(check("insert-at", Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.show_int((List.get(ys2, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "/"), Text.show_int((List.get(ys2, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "/"), Text.show_int((List.get(ys2, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "/"), Text.show_int((List.get(ys2, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))), "/"), Text.show_int((List.get(ys2, I64.to_u64_wrap(4)) ?? crash("list-at out of range")))), "1/2/3/4/5")))
					line!(Text.printed(check("empty-direct", Text.show_int(U64.to_i64_wrap(List.len((if True { [] } else { [1] })))), "0")))
					line!(Text.printed(check("empty-let", Text.show_int(U64.to_i64_wrap(List.len((if True { [] } else { [1] })))), "0")))
					({
						people = [{ name: "Alice", age: 30 }, { name: "Bob", age: 25 }, { name: "Carol", age: 40 }]
						line!(Text.printed(check("list-of-records", Text.show_int(ages_sum(people, 0, 0)), "95")))
					})
				})
			})
		})
	})
	Ok({})
}
