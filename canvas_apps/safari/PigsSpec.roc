# PigsSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Grade
import ListUtils
import Pigs
import Scenery

gaze : Scenery.Critter
gaze = Pigs.gaze_pig(1000.0, 2.0)

gaze_got : List(F64)
gaze_got = [gaze.along, gaze.across, gaze.height, Pigs.pig_height, Pigs.pig_dist_before_end, Pigs.gaze_pig_along_offset]

gaze_got_want : List(F64)
gaze_got_want = [942.0, 12.0, 1.1, 1.1, 60.0, 2.0]

gaze_kind_got : List(I64)
gaze_kind_got = [gaze.codepoint, Pigs.pig_cp, Pigs.pig_novelty_count, Pigs.big_herd_cols, Pigs.big_herd_rows]

gaze_kind_want : List(I64)
gaze_kind_want = [128022, 128022, 2, 7, 7]

gaze_face_got : List(Bool)
gaze_face_got = [gaze.face_right]

gaze_face_want : List(Bool)
gaze_face_want = [False]

herd : List(Scenery.Critter)
herd = Pigs.fill_pig_herd(1000.0)

herd_count_got : List(I64)
herd_count_got = [U64.to_i64_wrap(List.len(herd)), U64.to_i64_wrap(List.len(Pigs.fill_pig_herd(500.0)))]

herd_count_want : List(I64)
herd_count_want = [49, 49]

along_of : I64, I64 -> F64
along_of = |r, c| (List.get(herd, I64.to_u64_wrap(((r * 7) + c))) ?? crash("list-at out of range")).along

row_alongs : I64 -> List(F64)
row_alongs = |r| [along_of(r, 0), along_of(r, 1), along_of(r, 2), along_of(r, 3), along_of(r, 4), along_of(r, 5), along_of(r, 6)]

herd_along_got : List(F64)
herd_along_got = List.concat(List.concat(row_alongs(0), row_alongs(3)), row_alongs(6))

herd_along_want : List(F64)
herd_along_want = [934.0, 938.0, 942.0, 946.0, 950.0, 954.0, 958.0, 952.0, 956.0, 960.0, 964.0, 968.0, 972.0, 976.0, 970.0, 974.0, 978.0, 982.0, 986.0, 990.0, 994.0]

herd_across_got : List(F64)
herd_across_got = [(List.get(herd, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(6)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(7)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(13)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(14)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(21)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(28)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(35)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(42)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(48)) ?? crash("list-at out of range")).across]

herd_across_want : List(F64)
herd_across_want = [12.0, 12.0, 18.0, 18.0, 24.0, 30.0, 36.0, 42.0, 48.0, 48.0]

herd_kind_got : List(I64)
herd_kind_got = [(List.get(herd, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).codepoint, (List.get(herd, I64.to_u64_wrap(48)) ?? crash("list-at out of range")).codepoint]

herd_kind_want : List(I64)
herd_kind_want = [128022, 128022]

row : List(Scenery.Critter)
row = Pigs.fill_pig_row(1000.0)

row_count_got : List(I64)
row_count_got = [U64.to_i64_wrap(List.len(row)), U64.to_i64_wrap(List.len(Pigs.pig_row_front)), U64.to_i64_wrap(List.len(Pigs.pig_row_back))]

row_count_want : List(I64)
row_count_want = [10, 4, 6]

row_along_got : List(F64)
row_along_got = ListUtils.list_map(lam_0, row)

row_along_want : List(F64)
row_along_want = [934.0, 938.0, 942.0, 946.0, 930.0, 934.0, 938.0, 942.0, 946.0, 950.0]

row_across_got : List(F64)
row_across_got = ListUtils.list_map(lam_1, row)

row_across_want : List(F64)
row_across_want = [12.0, 12.0, 12.0, 12.0, 18.0, 18.0, 18.0, 18.0, 18.0, 18.0]

offsets_got : List(F64)
offsets_got = List.concat(List.concat(Pigs.pig_row_front, Pigs.pig_row_back), [Pigs.pig_back_row_offset, Pigs.pig_herd_first_col, Pigs.pig_col_spacing, Pigs.pig_row_depth, Pigs.pig_jitter_along, Pigs.pig_jitter_across])

offsets_want : List(F64)
offsets_want = [(-6.0), (-2.0), 2.0, 6.0, (-10.0), (-6.0), (-2.0), 2.0, 6.0, 10.0, 6.0, (-6.0), 4.0, 6.0, 1.2, 1.0]

lam_0 : Scenery.Critter -> F64
lam_0 = |p| p.along

lam_1 : Scenery.Critter -> F64
lam_1 = |p| p.across

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
