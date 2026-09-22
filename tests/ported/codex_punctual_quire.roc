# punctual-quire
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/punctual-quire.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     int-abs -42: 42
#     int-sign -7: -1
#     int-min 3 5: 3
#     int-max 3 5: 5
#     int-clamp 0 10 15: 10
#     is-even 4: True
#     is-odd 7: True
#     bit-popcount 255: 8
#     bit-ctz 8: 3
#     is-power-of-two 16: True
#     next-power-of-two 5: 8
#     byte-swap-32 #01020304: 67305985
#     extract-byte #AABB 0: 187
#     sat-add-u8 200 100: 255
#     sat-sub-u8 10 20: 0
#     lerp 0 100 1 2: 50
#     step 5 3: 0
#     step 5 7: 1
#     int-sqrt 144: 12
#     int-pow 2 10: 1024
#     int-log2 256: 8
#     fast-sin 0: 0
#     fast-sin 90000: 10000
#     fast-cos 0: 10000
#     rgba-r (rgba-pack 128 64 32 255): 128
#     rgba-g (rgba-pack 128 64 32 255): 64
#     rgba-b (rgba-pack 128 64 32 255): 32
#     rgb-luminance-packed white: 255
#     dot-2d 3 4 3 4: 25
#     cross-2d 1 0 0 1: 1
#     distance-sq-2d 0 0 3 4: 25
#     manhattan-2d 0 0 3 4: 7
#     to-big-endian-16 #0102: 513
#     from-big-endian-16 #0201: 258

app [main!] { cdx: "./codex/main.roc" }

import cdx.BitOps
import cdx.ColorOps
import cdx.Endian
import cdx.FastMath
import cdx.IntOps
import cdx.Kinematic
import cdx.Saturate
import cdx.Text
import cdx.Trig

# PunctualQuire -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([17, 18, 14, 73, 15, 32, 19, 2, 73, 7, 5, 69, 2], Text.show_int(IntOps.int_abs((0 - 42))))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 19, 17, 29, 18, 2, 73, 10, 69, 2], Text.show_int(IntOps.int_sign((0 - 7))))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 26, 17, 18, 2, 6, 2, 8, 69, 2], Text.show_int(IntOps.int_min(3, 5)))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 26, 15, 36, 2, 6, 2, 8, 69, 2], Text.show_int(IntOps.int_max(3, 5)))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 24, 23, 15, 26, 31, 2, 3, 2, 4, 3, 2, 4, 8, 69, 2], Text.show_int(IntOps.int_clamp(0, 10, 15)))))
	line!(Text.printed(List.concat([17, 19, 73, 13, 33, 13, 18, 2, 7, 69, 2], (if IntOps.is_even(4) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([17, 19, 73, 16, 22, 22, 2, 10, 69, 2], (if IntOps.is_odd(7) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([32, 17, 14, 73, 31, 16, 31, 24, 16, 25, 18, 14, 2, 5, 8, 8, 69, 2], Text.show_int(BitOps.bit_popcount(255)))))
	line!(Text.printed(List.concat([32, 17, 14, 73, 24, 14, 38, 2, 11, 69, 2], Text.show_int(BitOps.bit_ctz(8)))))
	line!(Text.printed(List.concat([17, 19, 73, 31, 16, 27, 13, 21, 73, 16, 28, 73, 14, 27, 16, 2, 4, 9, 69, 2], (if BitOps.is_power_of_two(16) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([18, 13, 36, 14, 73, 31, 16, 27, 13, 21, 73, 16, 28, 73, 14, 27, 16, 2, 8, 69, 2], Text.show_int(BitOps.next_power_of_two(5)))))
	line!(Text.printed(List.concat([32, 30, 14, 13, 73, 19, 27, 15, 31, 73, 6, 5, 2, 83, 3, 4, 3, 5, 3, 6, 3, 7, 69, 2], Text.show_int(BitOps.byte_swap_32(16909060)))))
	line!(Text.printed(List.concat([13, 36, 14, 21, 15, 24, 14, 73, 32, 30, 14, 13, 2, 83, 41, 41, 58, 58, 2, 3, 69, 2], Text.show_int(BitOps.extract_byte(43707, 0)))))
	line!(Text.printed(List.concat([19, 15, 14, 73, 15, 22, 22, 73, 25, 11, 2, 5, 3, 3, 2, 4, 3, 3, 69, 2], Text.show_int(Saturate.sat_add_u8(200, 100)))))
	line!(Text.printed(List.concat([19, 15, 14, 73, 19, 25, 32, 73, 25, 11, 2, 4, 3, 2, 5, 3, 69, 2], Text.show_int(Saturate.sat_sub_u8(10, 20)))))
	line!(Text.printed(List.concat([23, 13, 21, 31, 2, 3, 2, 4, 3, 3, 2, 4, 2, 5, 69, 2], Text.show_int(FastMath.lerp(0, 100, 1, 2)))))
	line!(Text.printed(List.concat([19, 14, 13, 31, 2, 8, 2, 6, 69, 2], Text.show_int(FastMath.step(5, 3)))))
	line!(Text.printed(List.concat([19, 14, 13, 31, 2, 8, 2, 10, 69, 2], Text.show_int(FastMath.step(5, 7)))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 19, 37, 21, 14, 2, 4, 7, 7, 69, 2], Text.show_int(FastMath.int_sqrt(144)))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 31, 16, 27, 2, 5, 2, 4, 3, 69, 2], Text.show_int(FastMath.int_pow(2, 10)))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 23, 16, 29, 5, 2, 5, 8, 9, 69, 2], Text.show_int(FastMath.int_log2(256)))))
	line!(Text.printed(List.concat([28, 15, 19, 14, 73, 19, 17, 18, 2, 3, 69, 2], Text.show_int(Trig.fast_sin(0)))))
	line!(Text.printed(List.concat([28, 15, 19, 14, 73, 19, 17, 18, 2, 12, 3, 3, 3, 3, 69, 2], Text.show_int(Trig.fast_sin(90000)))))
	line!(Text.printed(List.concat([28, 15, 19, 14, 73, 24, 16, 19, 2, 3, 69, 2], Text.show_int(Trig.fast_cos(0)))))
	line!(Text.printed(List.concat([21, 29, 32, 15, 73, 21, 2, 74, 21, 29, 32, 15, 73, 31, 15, 24, 34, 2, 4, 5, 11, 2, 9, 7, 2, 6, 5, 2, 5, 8, 8, 75, 69, 2], Text.show_int(ColorOps.rgba_r(ColorOps.rgba_pack(128, 64, 32, 255))))))
	line!(Text.printed(List.concat([21, 29, 32, 15, 73, 29, 2, 74, 21, 29, 32, 15, 73, 31, 15, 24, 34, 2, 4, 5, 11, 2, 9, 7, 2, 6, 5, 2, 5, 8, 8, 75, 69, 2], Text.show_int(ColorOps.rgba_g(ColorOps.rgba_pack(128, 64, 32, 255))))))
	line!(Text.printed(List.concat([21, 29, 32, 15, 73, 32, 2, 74, 21, 29, 32, 15, 73, 31, 15, 24, 34, 2, 4, 5, 11, 2, 9, 7, 2, 6, 5, 2, 5, 8, 8, 75, 69, 2], Text.show_int(ColorOps.rgba_b(ColorOps.rgba_pack(128, 64, 32, 255))))))
	line!(Text.printed(List.concat([21, 29, 32, 73, 23, 25, 26, 17, 18, 15, 18, 24, 13, 73, 31, 15, 24, 34, 13, 22, 2, 27, 20, 17, 14, 13, 69, 2], Text.show_int(ColorOps.rgb_luminance_packed(ColorOps.rgba_pack(255, 255, 255, 255))))))
	line!(Text.printed(List.concat([22, 16, 14, 73, 5, 22, 2, 6, 2, 7, 2, 6, 2, 7, 69, 2], Text.show_int(Kinematic.dot_2d(3, 4, 3, 4)))))
	line!(Text.printed(List.concat([24, 21, 16, 19, 19, 73, 5, 22, 2, 4, 2, 3, 2, 3, 2, 4, 69, 2], Text.show_int(Kinematic.cross_2d(1, 0, 0, 1)))))
	line!(Text.printed(List.concat([22, 17, 19, 14, 15, 18, 24, 13, 73, 19, 37, 73, 5, 22, 2, 3, 2, 3, 2, 6, 2, 7, 69, 2], Text.show_int(Kinematic.distance_sq_2d(0, 0, 3, 4)))))
	line!(Text.printed(List.concat([26, 15, 18, 20, 15, 14, 14, 15, 18, 73, 5, 22, 2, 3, 2, 3, 2, 6, 2, 7, 69, 2], Text.show_int(Kinematic.manhattan_2d(0, 0, 3, 4)))))
	line!(Text.printed(List.concat([14, 16, 73, 32, 17, 29, 73, 13, 18, 22, 17, 15, 18, 73, 4, 9, 2, 83, 3, 4, 3, 5, 69, 2], Text.show_int(Endian.to_big_endian_16(258)))))
	line!(Text.printed(List.concat([28, 21, 16, 26, 73, 32, 17, 29, 73, 13, 18, 22, 17, 15, 18, 73, 4, 9, 2, 83, 3, 5, 3, 4, 69, 2], Text.show_int(Endian.from_big_endian_16(513)))))
	Ok({})
}
