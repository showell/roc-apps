# PondSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import ListUtils
import Pond

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

size_got : List(I64)
size_got = [U64.to_i64_wrap(List.len(Pond.water_outline)), U64.to_i64_wrap(List.len(Pond.bank)), U64.to_i64_wrap(List.len(Pond.ducks)), Pond.water_color, Pond.bank_color, Pond.duck_codepoint]

size_want : List(I64)
size_want = [7, 6, 6, 3112588, 12759680, 129414]

spot_got : List(F64)
spot_got = [(List.get(Pond.water_outline, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).cu, (List.get(Pond.water_outline, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).cv, (List.get(Pond.water_outline, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).cu, (List.get(Pond.water_outline, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).cv, (List.get(Pond.bank, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).cu, (List.get(Pond.bank, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).cv, Pond.duck_height]

spot_want : List(F64)
spot_want = [(-2.0), 3.0, (-15.0), 32.0, (-5.0), 29.0, 0.9]

inside : Pond.Duck -> Bool
inside = |d| (if (d.p.cu > (-1.0)) { False } else { (if (d.p.cu < (-31.0)) { False } else { (if (d.p.cv < 3.0) { False } else { (if (d.p.cv > 32.0) { False } else { True }) }) }) })

inside_got : List(Bool)
inside_got = ListUtils.list_map(inside, Pond.ducks)

inside_want : List(Bool)
inside_want = [True, True, True, True, True, True]

face_got : List(Bool)
face_got = [(List.get(Pond.ducks, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).face_right, (List.get(Pond.ducks, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).face_right, (List.get(Pond.ducks, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).face_right, (List.get(Pond.ducks, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).face_right, (List.get(Pond.ducks, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).face_right, (List.get(Pond.ducks, I64.to_u64_wrap(5)) ?? crash("list-at out of range")).face_right]

face_want : List(Bool)
face_want = [True, False, True, True, False, True]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_ints("pd-size", size_got, size_want))
	line!(Grade.grade_reals("pd-spot", spot_got, spot_want, 0.0))
	line!(Grade.grade_bools("pd-in  ", inside_got, inside_want))
	line!(Grade.grade_bools("pd-face", face_got, face_want))
	Ok({})
}
