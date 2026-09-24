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
	line!(Text.printed(Text.concat("int-abs -42: ", Text.show_int(IntOps.int_abs((0 - 42))))))
	line!(Text.printed(Text.concat("int-sign -7: ", Text.show_int(IntOps.int_sign((0 - 7))))))
	line!(Text.printed(Text.concat("int-min 3 5: ", Text.show_int(IntOps.int_min(3, 5)))))
	line!(Text.printed(Text.concat("int-max 3 5: ", Text.show_int(IntOps.int_max(3, 5)))))
	line!(Text.printed(Text.concat("int-clamp 0 10 15: ", Text.show_int(IntOps.int_clamp(0, 10, 15)))))
	line!(Text.printed(Text.concat("is-even 4: ", (if IntOps.is_even(4) { "True" } else { "False" }))))
	line!(Text.printed(Text.concat("is-odd 7: ", (if IntOps.is_odd(7) { "True" } else { "False" }))))
	line!(Text.printed(Text.concat("bit-popcount 255: ", Text.show_int(BitOps.bit_popcount(255)))))
	line!(Text.printed(Text.concat("bit-ctz 8: ", Text.show_int(BitOps.bit_ctz(8)))))
	line!(Text.printed(Text.concat("is-power-of-two 16: ", (if BitOps.is_power_of_two(16) { "True" } else { "False" }))))
	line!(Text.printed(Text.concat("next-power-of-two 5: ", Text.show_int(BitOps.next_power_of_two(5)))))
	line!(Text.printed(Text.concat("byte-swap-32 #01020304: ", Text.show_int(BitOps.byte_swap_32(16909060)))))
	line!(Text.printed(Text.concat("extract-byte #AABB 0: ", Text.show_int(BitOps.extract_byte(43707, 0)))))
	line!(Text.printed(Text.concat("sat-add-u8 200 100: ", Text.show_int(Saturate.sat_add_u8(200, 100)))))
	line!(Text.printed(Text.concat("sat-sub-u8 10 20: ", Text.show_int(Saturate.sat_sub_u8(10, 20)))))
	line!(Text.printed(Text.concat("lerp 0 100 1 2: ", Text.show_int(FastMath.lerp(0, 100, 1, 2)))))
	line!(Text.printed(Text.concat("step 5 3: ", Text.show_int(FastMath.step(5, 3)))))
	line!(Text.printed(Text.concat("step 5 7: ", Text.show_int(FastMath.step(5, 7)))))
	line!(Text.printed(Text.concat("int-sqrt 144: ", Text.show_int(FastMath.int_sqrt(144)))))
	line!(Text.printed(Text.concat("int-pow 2 10: ", Text.show_int(FastMath.int_pow(2, 10)))))
	line!(Text.printed(Text.concat("int-log2 256: ", Text.show_int(FastMath.int_log2(256)))))
	line!(Text.printed(Text.concat("fast-sin 0: ", Text.show_int(Trig.fast_sin(0)))))
	line!(Text.printed(Text.concat("fast-sin 90000: ", Text.show_int(Trig.fast_sin(90000)))))
	line!(Text.printed(Text.concat("fast-cos 0: ", Text.show_int(Trig.fast_cos(0)))))
	line!(Text.printed(Text.concat("rgba-r (rgba-pack 128 64 32 255): ", Text.show_int(ColorOps.rgba_r(ColorOps.rgba_pack(128, 64, 32, 255))))))
	line!(Text.printed(Text.concat("rgba-g (rgba-pack 128 64 32 255): ", Text.show_int(ColorOps.rgba_g(ColorOps.rgba_pack(128, 64, 32, 255))))))
	line!(Text.printed(Text.concat("rgba-b (rgba-pack 128 64 32 255): ", Text.show_int(ColorOps.rgba_b(ColorOps.rgba_pack(128, 64, 32, 255))))))
	line!(Text.printed(Text.concat("rgb-luminance-packed white: ", Text.show_int(ColorOps.rgb_luminance_packed(ColorOps.rgba_pack(255, 255, 255, 255))))))
	line!(Text.printed(Text.concat("dot-2d 3 4 3 4: ", Text.show_int(Kinematic.dot_2d(3, 4, 3, 4)))))
	line!(Text.printed(Text.concat("cross-2d 1 0 0 1: ", Text.show_int(Kinematic.cross_2d(1, 0, 0, 1)))))
	line!(Text.printed(Text.concat("distance-sq-2d 0 0 3 4: ", Text.show_int(Kinematic.distance_sq_2d(0, 0, 3, 4)))))
	line!(Text.printed(Text.concat("manhattan-2d 0 0 3 4: ", Text.show_int(Kinematic.manhattan_2d(0, 0, 3, 4)))))
	line!(Text.printed(Text.concat("to-big-endian-16 #0102: ", Text.show_int(Endian.to_big_endian_16(258)))))
	line!(Text.printed(Text.concat("from-big-endian-16 #0201: ", Text.show_int(Endian.from_big_endian_16(513)))))
	Ok({})
}
