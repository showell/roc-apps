#!/usr/bin/env python3
"""Write Probe.roc: does updating one field of a record copy a large sub-record
stored inline beside it? A loop bumps `hot` N times over three record shapes,
through a function call or inline, chosen on the command line so nothing is
evaluated at compile time."""

FIELDS = 64
cold_type = "{ " + ", ".join(f"a{i} : U64" for i in range(FIELDS)) + " }"
cold_value = "{ " + ", ".join(f"a{i}: {i}" for i in range(FIELDS)) + " }"

src = f"""Cold : {cold_type}

Bare : {{ hot : U64 }}
Wide : {{ hot : U64, cold : Cold }}
Boxed : {{ hot : U64, cold : List(Cold) }}
Boxy : {{ hot : U64, cold : Box(Cold) }}

cold0 : U64 -> Cold
cold0 = |_z| {cold_value}

bump_bare : Bare -> Bare
bump_bare = |r| {{ ..r, hot: r.hot + 1 }}

bump_wide : Wide -> Wide
bump_wide = |r| {{ ..r, hot: r.hot + 1 }}

bump_boxed : Boxed -> Boxed
bump_boxed = |r| {{ ..r, hot: r.hot + 1 }}

bump_boxy : Boxy -> Boxy
bump_boxy = |r| {{ ..r, hot: r.hot + 1 }}

main! = |args| {{
	n = U64.from_str(List.get(args, 0) ?? "") ?? 1000
	shape = List.get(args, 1) ?? "bare"
	how = List.get(args, 2) ?? "call"
	z = List.len(args)
	result =
		if shape == "bare" and how == "call" {{
			var $r = {{ hot: z }}
			var $i = 0
			while $i < n {{
				$r = bump_bare($r)
				$i = $i + 1
			}}
			$r.hot
		}} else if shape == "bare" {{
			var $r = {{ hot: z }}
			var $i = 0
			while $i < n {{
				$r = {{ ..$r, hot: $r.hot + 1 }}
				$i = $i + 1
			}}
			$r.hot
		}} else if shape == "wide" and how == "call" {{
			var $r = {{ hot: z, cold: cold0(z) }}
			var $i = 0
			while $i < n {{
				$r = bump_wide($r)
				$i = $i + 1
			}}
			$r.hot + $r.cold.a63
		}} else if shape == "wide" {{
			var $r = {{ hot: z, cold: cold0(z) }}
			var $i = 0
			while $i < n {{
				$r = {{ ..$r, hot: $r.hot + 1 }}
				$i = $i + 1
			}}
			$r.hot + $r.cold.a63
		}} else if shape == "box" and how == "call" {{
			var $r = {{ hot: z, cold: Box.box(cold0(z)) }}
			var $i = 0
			while $i < n {{
				$r = bump_boxy($r)
				$i = $i + 1
			}}
			$r.hot + Box.unbox($r.cold).a63
		}} else if shape == "box" {{
			var $r = {{ hot: z, cold: Box.box(cold0(z)) }}
			var $i = 0
			while $i < n {{
				$r = {{ ..$r, hot: $r.hot + 1 }}
				$i = $i + 1
			}}
			$r.hot + Box.unbox($r.cold).a63
		}} else if how == "call" {{
			var $r = {{ hot: z, cold: [cold0(z)] }}
			var $i = 0
			while $i < n {{
				$r = bump_boxed($r)
				$i = $i + 1
			}}
			$r.hot + List.len($r.cold)
		}} else {{
			var $r = {{ hot: z, cold: [cold0(z)] }}
			var $i = 0
			while $i < n {{
				$r = {{ ..$r, hot: $r.hot + 1 }}
				$i = $i + 1
			}}
			$r.hot + List.len($r.cold)
		}}
	echo!(Str.concat(U64.to_str(result), "\\n"))
	Ok({{}})
}}
"""
open("Probe.roc", "w").write(src)
