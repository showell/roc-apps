## These are Trees' checks: the conifers' colours and sizes, and the
## pairs a segment is planted with.
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import Scenery
import Trees

colour_got : List(I64)
colour_got = [Trees.conifer_green, Trees.conifer_gold, Trees.conifer_red, Trees.max_trees]

colour_want : List(I64)
colour_want = [1858082, 13605400, 11680298, 96]

dim_got : List(F64)
dim_got = [Trees.small_height, Trees.big_scale, Trees.tree_spacing, Trees.tree_road_offset, Trees.tree_start_inset, Trees.tree_end_inset]

dim_want : List(F64)
dim_want = [4.5, 1.3, 30.0, 1.5, 6.0, 85.0]

accent_got : List(I64)
accent_got = [AllGreen, YellowGreen, RedGreen].map(|scheme| Trees.color(Trees.accent(scheme)))

accent_want : List(I64)
accent_want = [1858082, 13605400, 11680298]

hx_got : List(F64)
hx_got = List.concat(
	[Green, Red, Gold].join_map(|conifer| [Trees.height({ conifer, size: Big }), Trees.height({ conifer, size: Small })]),
	[Green, Red, Gold].map(Trees.across),
)

hx_want : List(F64)
hx_want = [5.8500000000000005, 4.5, 11.700000000000001, 9.0, 17.55, 13.5, 3.5, 3.5, 8.0]

filled : List(Scenery.Tree)
filled = Trees.plant({ scheme: YellowGreen, length: 300.0 })

along_got : List(F64)
along_got = filled.map(|tree| tree.along)

along_want : List(F64)
along_want = [6.0, 6.0, 36.0, 36.0, 66.0, 66.0, 96.0, 96.0, 126.0, 126.0, 156.0, 156.0, 186.0, 186.0]

across_got : List(F64)
across_got = filled.map(|tree| tree.across)

across_want : List(F64)
across_want = [(-3.5), 3.5, (-8.0), 8.0, (-3.5), 3.5, (-8.0), 8.0, (-3.5), 3.5, (-8.0), 8.0, (-3.5), 3.5]

colours_got : List(I64)
colours_got = filled.map(|tree| tree.color)

colours_want : List(I64)
colours_want = [1858082, 1858082, 13605400, 13605400, 1858082, 1858082, 13605400, 13605400, 1858082, 1858082, 13605400, 13605400, 1858082, 1858082]

heights_got : List(F64)
heights_got = filled.map(|tree| tree.height)

heights_want : List(F64)
heights_want = [5.8500000000000005, 5.8500000000000005, 13.5, 13.5, 5.8500000000000005, 5.8500000000000005, 13.5, 13.5, 5.8500000000000005, 5.8500000000000005, 13.5, 13.5, 5.8500000000000005, 5.8500000000000005]

stops_got : List(I64)
stops_got = List.concat([filled.len().to_i64_wrap()], [100.0, 5000.0, 50.0].map(|length| Trees.plant({ scheme: AllGreen, length }).len().to_i64_wrap()))

stops_want : List(I64)
stops_want = [14, 2, 96, 0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "tr-colour",
			got: colour_got,
			want: colour_want,
		}),
		Grade.reals({
			name: "tr-dim   ",
			got: dim_got,
			want: dim_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tr-accent",
			got: accent_got,
			want: accent_want,
		}),
		Grade.reals({
			name: "tr-hx    ",
			got: hx_got,
			want: hx_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-along ",
			got: along_got,
			want: along_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-across",
			got: across_got,
			want: across_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tr-colours",
			got: colours_got,
			want: colours_want,
		}),
		Grade.reals({
			name: "tr-height",
			got: heights_got,
			want: heights_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tr-stops ",
			got: stops_got,
			want: stops_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
