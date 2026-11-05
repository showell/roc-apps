## These are Pigs' checks: the pig that catches the rider's eye, the big
## herd's size and places, and the two rows.
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import Pigs
import Scenery

gaze : Scenery.Critter
gaze = Pigs.gaze_pig(1000.0)

gaze_got : List(F64)
gaze_got = [
	gaze.along,
	gaze.across,
	gaze.height,
	Pigs.pig_height,
	Pigs.pig_dist_before_end,
	Pigs.gaze_pig_along_offset,
]

gaze_got_want : List(F64)
gaze_got_want = [942.0, 12.0, 1.1, 1.1, 60.0, 2.0]

gaze_kind_got : List(I64)
gaze_kind_got = [
	gaze.codepoint,
	Pigs.pig_codepoint,
	Pigs.pig_novelty_count.to_i64(),
	Pigs.big_herd_cols,
	Pigs.big_herd_rows,
]

gaze_kind_want : List(I64)
gaze_kind_want = [128022, 128022, 2, 7, 7]

gaze_face_got : List(Bool)
gaze_face_got = [gaze.face_right]

gaze_face_want : List(Bool)
gaze_face_want = [False]

herd : List(Scenery.Critter)
herd = Pigs.fill_pig_herd(1000.0)

herd_pig_at : U64 -> Scenery.Critter
herd_pig_at = |i| herd.get(i) ?? crash "PigsSpec: the big herd has 49 pigs"

herd_count_got : List(I64)
herd_count_got = [herd.len().to_i64_wrap(), Pigs.fill_pig_herd(500.0).len().to_i64_wrap()]

herd_count_want : List(I64)
herd_count_want = [49, 49]

## Where each pig of the herd's row `row` is along the road.
row_alongs : U64 -> List(F64)
row_alongs = |row| [0, 1, 2, 3, 4, 5, 6].map(|column| herd_pig_at(((row * 7) + column)).along)

herd_along_got : List(F64)
herd_along_got = [0, 3, 6].join_map(row_alongs)

herd_along_want : List(F64)
herd_along_want = [
	934.0,
	938.0,
	942.0,
	946.0,
	950.0,
	954.0,
	958.0,
	952.0,
	956.0,
	960.0,
	964.0,
	968.0,
	972.0,
	976.0,
	970.0,
	974.0,
	978.0,
	982.0,
	986.0,
	990.0,
	994.0,
]

herd_across_got : List(F64)
herd_across_got = [0, 6, 7, 13, 14, 21, 28, 35, 42, 48].map(|i| herd_pig_at(i).across)

herd_across_want : List(F64)
herd_across_want = [12.0, 12.0, 18.0, 18.0, 24.0, 30.0, 36.0, 42.0, 48.0, 48.0]

herd_kind_got : List(I64)
herd_kind_got = [herd_pig_at(0).codepoint, herd_pig_at(48).codepoint]

herd_kind_want : List(I64)
herd_kind_want = [128022, 128022]

row : List(Scenery.Critter)
row = Pigs.fill_pig_row(1000.0)

row_count_got : List(I64)
row_count_got = [
	row.len().to_i64_wrap(),
	Pigs.pig_row_front.len().to_i64_wrap(),
	Pigs.pig_row_back.len().to_i64_wrap(),
]

row_count_want : List(I64)
row_count_want = [10, 4, 6]

row_along_got : List(F64)
row_along_got = row.map(|pig| pig.along)

row_along_want : List(F64)
row_along_want = [934.0, 938.0, 942.0, 946.0, 930.0, 934.0, 938.0, 942.0, 946.0, 950.0]

row_across_got : List(F64)
row_across_got = row.map(|pig| pig.across)

row_across_want : List(F64)
row_across_want = [12.0, 12.0, 12.0, 12.0, 18.0, 18.0, 18.0, 18.0, 18.0, 18.0]

offsets_got : List(F64)
offsets_got = List.join([
	Pigs.pig_row_front,
	Pigs.pig_row_back,
	[
		Pigs.pig_back_row_offset,
		Pigs.pig_herd_first_col,
		Pigs.pig_col_spacing,
		Pigs.pig_row_depth,
		Pigs.pig_jitter_along,
		Pigs.pig_jitter_across,
	],
])

offsets_want : List(F64)
offsets_want = [
	(-6.0),
	(-2.0),
	2.0,
	6.0,
	(-10.0),
	(-6.0),
	(-2.0),
	2.0,
	6.0,
	10.0,
	6.0,
	(-6.0),
	4.0,
	6.0,
	1.2,
	1.0,
]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "pg-gaze  ",
			got: gaze_got,
			want: gaze_got_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "pg-kind  ",
			got: gaze_kind_got,
			want: gaze_kind_want,
		}),
		Grade.bools({
			name: "pg-face  ",
			got: gaze_face_got,
			want: gaze_face_want,
		}),
		Grade.ints({
			name: "pg-nherd ",
			got: herd_count_got,
			want: herd_count_want,
		}),
		Grade.ints({
			name: "pg-hkind ",
			got: herd_kind_got,
			want: herd_kind_want,
		}),
		Grade.ints({
			name: "pg-nrow  ",
			got: row_count_got,
			want: row_count_want,
		}),
		Grade.reals({
			name: "pg-rowa  ",
			got: row_along_got,
			want: row_along_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "pg-rowx  ",
			got: row_across_got,
			want: row_across_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "pg-offs  ",
			got: offsets_got,
			want: offsets_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "pg-herda ",
			got: herd_along_got,
			want: herd_along_want,
			tol: 1.2,
		}),
		Grade.reals({
			name: "pg-herdx ",
			got: herd_across_got,
			want: herd_across_want,
			tol: 1.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
