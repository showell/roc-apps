import sys
kind, n = sys.argv[1], int(sys.argv[2])
def lit(i):
    s = f"w{i}"
    if kind == "units": return "T.from_units([" + ", ".join(str(ord(c)) for c in s) + "])"
    return '"' + s + '"'
ty = "Str" if kind == "str" else "T"
items = ",\n\t\t".join(lit(i) for i in range(n))
size = "Str.count_utf8_bytes(x)" if kind == "str" else "T.len(x)"
print(f"""app [main!] {{}}

import T

words : List({ty})
words = [
		{items}
	]

main! = |args| {{
	total = List.fold(words, 0 + 0 * List.len(args), |acc, x| acc + {size})
	echo!(Str.concat(U64.to_str(total), "\\n"))
	Ok({{}})
}}""")
