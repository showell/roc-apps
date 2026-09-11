# LensSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Lens
import ListUtils
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

base_got : List(F64)
base_got = [Lens.camera_w, Lens.fov_deg, Lens.focal]

base_want : List(F64)
base_want = [960.0, 70.0, 685.5110432362151]

lean_in : List(F64)
lean_in = [0.0, 0.25, 0.5, 0.75, 1.0]

lean_want : List(F64)
lean_want = [685.5110432362151, 657.6621571047439, 574.1154987103301, 434.8710680529739, 239.92886513267527]

gaze_in : List(F64)
gaze_in = [0.0, 0.5, 1.0, 1.5]

gaze_want : List(F64)
gaze_want = [685.5110432362151, 551.8363898051531, 418.16173637409116, 284.4870829430293]

cam_lean : List(F64)
cam_lean = [0.0, 1.0, 0.0, 0.5, 0.9, 0.6]

cam_gaze : List(F64)
cam_gaze = [0.0, 0.0, 1.0, 0.3, 1.4, 0.5]

cam_want : List(F64)
cam_want = [685.5110432362151, 239.92886513267527, 418.16173637409116, 574.1154987103301, 311.2220136292417, 525.1014591189407]

# cam_walk builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
cam_walk : I64 -> List(F64)
cam_walk = |i| cam_walk_acc(i, [])

cam_walk_acc : I64, List(F64) -> List(F64)
cam_walk_acc = |i, acc| (if (i >= U64.to_i64_wrap(List.len(cam_lean))) { acc } else { cam_walk_acc((i + 1), List.append(acc, Lens.cam_focal((List.get(cam_lean, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(cam_gaze, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_rel("l-base ", base_got, base_want, F64.from_bits(4472406533629990549)))
	line!(Grade.grade_rel("l-lean ", ListUtils.list_map(Lens.focal_for_lean, lean_in), lean_want, F64.from_bits(4472406533629990549)))
	line!(Grade.grade_rel("l-gaze ", ListUtils.list_map(Lens.focal_for_gaze, gaze_in), gaze_want, F64.from_bits(4472406533629990549)))
	line!(Grade.grade_rel("l-cam  ", cam_walk(0), cam_want, F64.from_bits(4472406533629990549)))
	Ok({})
}
