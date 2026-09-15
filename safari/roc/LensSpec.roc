# LensSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Lens
import ListUtils
import Text

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

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_rel([23, 73, 32, 15, 19, 13, 2], base_got, base_want, F64.from_bits(4472406533629990549))))
	line!(Text.printed(Grade.grade_rel([23, 73, 23, 13, 15, 18, 2], ListUtils.list_map(Lens.focal_for_lean, lean_in), lean_want, F64.from_bits(4472406533629990549))))
	line!(Text.printed(Grade.grade_rel([23, 73, 29, 15, 38, 13, 2], ListUtils.list_map(Lens.focal_for_gaze, gaze_in), gaze_want, F64.from_bits(4472406533629990549))))
	line!(Text.printed(Grade.grade_rel([23, 73, 24, 15, 26, 2, 2], cam_walk(0), cam_want, F64.from_bits(4472406533629990549))))
	Ok({})
}
