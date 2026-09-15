# KeyInput -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import Machine

KeyInput :: [].{

	kbd_mod_addr : I64
	kbd_mod_addr = 36752

	key_named_base : I64
	key_named_base = 1048576

	key_is_named : I64 -> Bool
	key_is_named = |k| (k >= key_named_base)

	key_enter : I64
	key_enter = 1048577

	key_backspace : I64
	key_backspace = 1048578

	key_tab : I64
	key_tab = 1048579

	key_escape : I64
	key_escape = 1048580

	key_delete : I64
	key_delete = 1048581

	key_left : I64
	key_left = 1048583

	key_up : I64
	key_up = 1048584

	key_right : I64
	key_right = 1048585

	key_down : I64
	key_down = 1048586

	key_home : I64
	key_home = 1048587

	key_end : I64
	key_end = 1048588

	key_pgup : I64
	key_pgup = 1048589

	key_pgdn : I64
	key_pgdn = 1048590

	key_f1 : I64
	key_f1 = 1048597

	key_f2 : I64
	key_f2 = 1048598

	key_f3 : I64
	key_f3 = 1048599

	key_f4 : I64
	key_f4 = 1048600

	key_f5 : I64
	key_f5 = 1048601

	key_f6 : I64
	key_f6 = 1048602

	key_f7 : I64
	key_f7 = 1048603

	key_f8 : I64
	key_f8 = 1048604

	key_f9 : I64
	key_f9 = 1048605

	key_f10 : I64
	key_f10 = 1048606

	key_f11 : I64
	key_f11 = 1048607

	key_f12 : I64
	key_f12 = 1048608

	poll_key! : Machine.Machine => (Machine.Machine, I64)
	poll_key! = |machine| ({
		(machine1, ek) = Machine.uefi_read_key_ex!(machine)
		(if (ek == (-1)) { ({
			(machine2, sc) = Machine.uefi_read_key!(machine1)
			({
				(machine3, machine__1) = Machine.load_unguarded!(machine2, kbd_mod_addr, 0, 8)
				poll_key_decode!(machine3, sc, machine__1)
			})
		}) } else { (machine1, efi_key_decode(ek)) })
	})

	efi_key_decode : I64 -> I64
	efi_key_decode = |ek| ({
		ch = I64.bitwise_and(ek, 65535)
		(if (ch == 0) { efi_scan_decode(I64.bitwise_and(I64.shr_zf_wrap(ek, I64.to_u8_wrap(16)), 65535)) } else { (if (ch == 13) { key_enter } else { (if (ch == 8) { key_backspace } else { (if (ch == 9) { key_tab } else { ch }) }) }) })
	})

	efi_scan_decode : I64 -> I64
	efi_scan_decode = |sc| (if (sc == 1) { key_up } else { (if (sc == 2) { key_down } else { (if (sc == 3) { key_right } else { (if (sc == 4) { key_left } else { (if (sc == 5) { key_home } else { (if (sc == 6) { key_end } else { (if (sc == 8) { key_delete } else { (if (sc == 9) { key_pgup } else { (if (sc == 10) { key_pgdn } else { (if (sc == 11) { key_f1 } else { (if (sc == 12) { key_f2 } else { (if (sc == 13) { key_f3 } else { (if (sc == 14) { key_f4 } else { (if (sc == 15) { key_f5 } else { (if (sc == 16) { key_f6 } else { (if (sc == 17) { key_f7 } else { (if (sc == 18) { key_f8 } else { (if (sc == 19) { key_f9 } else { (if (sc == 20) { key_f10 } else { (if (sc == 21) { key_f11 } else { (if (sc == 22) { key_f12 } else { (if (sc == 23) { key_escape } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	poll_key_decode! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	poll_key_decode! = |machine, sc, mods| (if (sc == 0) { (machine, 0) } else { (if (sc == 42) { mod_set!(machine, mods, 1) } else { (if (sc == 54) { mod_set!(machine, mods, 1) } else { (if (sc == 170) { mod_clear!(machine, mods, 1) } else { (if (sc == 182) { mod_clear!(machine, mods, 1) } else { (if (sc == 29) { mod_set!(machine, mods, 2) } else { (if (sc == 157) { mod_clear!(machine, mods, 2) } else { (if (sc == 56) { mod_set!(machine, mods, 4) } else { (if (sc == 184) { mod_clear!(machine, mods, 4) } else { (if (sc == 58) { ({
		(machine2, machine__2) = ({
		(machine1, _d) = Machine.store_unguarded!(machine, kbd_mod_addr, 0, I64.bitwise_xor(mods, 8), 8)
		(machine1, 0)
	})
		(machine2, machine__2)
	}) } else { (if (sc == 186) { (machine, 0) } else { (if (sc == 69) { ({
		(machine4, machine__3) = ({
		(machine3, _d) = Machine.store_unguarded!(machine, kbd_mod_addr, 0, I64.bitwise_xor(mods, 16), 8)
		(machine3, 0)
	})
		(machine4, machine__3)
	}) } else { (if (sc == 197) { (machine, 0) } else { (if (sc == 224) { mod_set!(machine, mods, 32) } else { ({
		(machine5, machine__4) = decode_key!(machine, sc, mods)
		(machine5, key_emit(machine__4))
	}) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	key_emit : I64 -> I64
	key_emit = |k| (if (k <= 0) { 0 } else { (if (k >= key_named_base) { k } else { CCE.from_unicode(k) }) })

	poll_mods! : Machine.Machine => (Machine.Machine, I64)
	poll_mods! = |machine| ({
		(machine1, machine__5) = Machine.load_unguarded!(machine, kbd_mod_addr, 0, 8)
		(machine1, I64.bitwise_and(machine__5, 7))
	})

	decode_key! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	decode_key! = |machine, sc, mods| ({
		(machine2, machine__6) = ({
		e0 = I64.bitwise_and(mods, 32)
		cleared = I64.bitwise_xor(mods, I64.bitwise_and(mods, 32))
		(machine1, _d) = Machine.store_unguarded!(machine, kbd_mod_addr, 0, cleared, 8)
		(machine1, (if (e0 > 0) { apply_mods(scancode_to_keycode(sc), cleared) } else { numpad_or_default(sc, cleared) }))
	})
		(machine2, machine__6)
	})

	numpad_or_default : I64, I64 -> I64
	numpad_or_default = |sc, mods| (if (I64.bitwise_and(mods, 16) > 0) { (if is_numpad_digit(sc) { numpad_digit(sc) } else { apply_mods(scancode_to_keycode(sc), mods) }) } else { apply_mods(scancode_to_keycode(sc), mods) })

	is_numpad_digit : I64 -> Bool
	is_numpad_digit = |sc| (if (sc < 71) { False } else { (if (sc > 83) { False } else { (if (sc == 74) { False } else { (if (sc == 78) { False } else { True }) }) }) })

	numpad_digit : I64 -> I64
	numpad_digit = |sc| (if (sc == 71) { 55 } else { (if (sc == 72) { 56 } else { (if (sc == 73) { 57 } else { (if (sc == 75) { 52 } else { (if (sc == 76) { 53 } else { (if (sc == 77) { 54 } else { (if (sc == 79) { 49 } else { (if (sc == 80) { 50 } else { (if (sc == 81) { 51 } else { (if (sc == 82) { 48 } else { 46 }) }) }) }) }) }) }) }) }) })

	mod_set! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	mod_set! = |machine, mods, bit| ({
		(machine2, machine__7) = ({
		(machine1, _d) = Machine.store_unguarded!(machine, kbd_mod_addr, 0, I64.bitwise_or(mods, bit), 8)
		(machine1, 0)
	})
		(machine2, machine__7)
	})

	mod_clear! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	mod_clear! = |machine, mods, bit| ({
		(machine2, machine__8) = ({
		(machine1, _d) = Machine.store_unguarded!(machine, kbd_mod_addr, 0, I64.bitwise_xor(mods, I64.bitwise_and(mods, bit)), 8)
		(machine1, 0)
	})
		(machine2, machine__8)
	})

	key_upper : I64 -> I64
	key_upper = |k| (if (k >= 13) { (if (k <= 38) { (k + 26) } else { k }) } else { k })

	apply_mods : I64, I64 -> I64
	apply_mods = |k, mods| (if (k >= key_named_base) { k } else { (if (k >= 65) { (if (k <= 90) { apply_letter(k, mods) } else { apply_symbol(k, mods) }) } else { apply_symbol(k, mods) }) })

	apply_letter : I64, I64 -> I64
	apply_letter = |k, mods| ({
		shift = I64.bitwise_and(mods, 1)
		caps = I64.bitwise_and(mods, 8)
		(if (shift > 0) { (if (caps > 0) { (k + 32) } else { k }) } else { (if (caps > 0) { k } else { (k + 32) }) })
	})

	apply_symbol : I64, I64 -> I64
	apply_symbol = |k, mods| (if (I64.bitwise_and(mods, 1) > 0) { shifted_symbol(k) } else { k })

	shifted_symbol : I64 -> I64
	shifted_symbol = |k| (if (k == 49) { 33 } else { (if (k == 50) { 64 } else { (if (k == 51) { 35 } else { (if (k == 52) { 36 } else { (if (k == 53) { 37 } else { (if (k == 54) { 94 } else { (if (k == 55) { 38 } else { (if (k == 56) { 42 } else { (if (k == 57) { 40 } else { (if (k == 48) { 41 } else { (if (k == 45) { 95 } else { (if (k == 61) { 43 } else { (if (k == 91) { 123 } else { (if (k == 93) { 125 } else { (if (k == 92) { 124 } else { (if (k == 59) { 58 } else { (if (k == 39) { 34 } else { (if (k == 44) { 60 } else { (if (k == 46) { 62 } else { (if (k == 47) { 63 } else { (if (k == 96) { 126 } else { k }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	scancode_to_keycode : I64 -> I64
	scancode_to_keycode = |sc| (if (sc == 0) { 0 } else { (if (sc <= 15) { sk_low(sc) } else { (if (sc <= 41) { sk_row1(sc) } else { (if (sc <= 57) { sk_row2(sc) } else { sk_high(sc) }) }) }) })

	sk_low : I64 -> I64
	sk_low = |sc| (if (sc == 1) { key_escape } else { (if (sc == 14) { key_backspace } else { (if (sc == 15) { key_tab } else { (if (sc == 12) { 45 } else { (if (sc == 13) { 61 } else { (if (sc == 11) { 48 } else { (sc + 47) }) }) }) }) }) })

	sk_row1 : I64 -> I64
	sk_row1 = |sc| (if (sc == 28) { key_enter } else { (if (sc == 26) { 91 } else { (if (sc == 27) { 93 } else { (if (sc == 29) { 0 } else { (if (sc == 39) { 59 } else { (if (sc == 40) { 39 } else { (if (sc == 41) { 96 } else { (if (sc <= 25) { sk_qwerty(sc) } else { sk_asdf(sc) }) }) }) }) }) }) }) })

	sk_qwerty : I64 -> I64
	sk_qwerty = |sc| (if (sc == 16) { 81 } else { (if (sc == 17) { 87 } else { (if (sc == 18) { 69 } else { (if (sc == 19) { 82 } else { (if (sc == 20) { 84 } else { (if (sc == 21) { 89 } else { (if (sc == 22) { 85 } else { (if (sc == 23) { 73 } else { (if (sc == 24) { 79 } else { 80 }) }) }) }) }) }) }) }) })

	sk_asdf : I64 -> I64
	sk_asdf = |sc| (if (sc == 30) { 65 } else { (if (sc == 31) { 83 } else { (if (sc == 32) { 68 } else { (if (sc == 33) { 70 } else { (if (sc == 34) { 71 } else { (if (sc == 35) { 72 } else { (if (sc == 36) { 74 } else { (if (sc == 37) { 75 } else { 76 }) }) }) }) }) }) }) })

	sk_row2 : I64 -> I64
	sk_row2 = |sc| (if (sc == 57) { 32 } else { (if (sc == 43) { 92 } else { (if (sc == 51) { 44 } else { (if (sc == 52) { 46 } else { (if (sc == 53) { 47 } else { (if (sc == 55) { 42 } else { (if (sc == 42) { 0 } else { (if (sc == 54) { 0 } else { (if (sc == 56) { 0 } else { sk_zxcv(sc) }) }) }) }) }) }) }) }) })

	sk_zxcv : I64 -> I64
	sk_zxcv = |sc| (if (sc == 44) { 90 } else { (if (sc == 45) { 88 } else { (if (sc == 46) { 67 } else { (if (sc == 47) { 86 } else { (if (sc == 48) { 66 } else { (if (sc == 49) { 78 } else { 77 }) }) }) }) }) })

	sk_high : I64 -> I64
	sk_high = |sc| (if (sc == 71) { key_home } else { (if (sc == 72) { key_up } else { (if (sc == 73) { key_pgup } else { (if (sc == 75) { key_left } else { (if (sc == 77) { key_right } else { (if (sc == 79) { key_end } else { (if (sc == 80) { key_down } else { (if (sc == 81) { key_pgdn } else { (if (sc == 83) { key_delete } else { (if (sc == 87) { key_f11 } else { (if (sc == 88) { key_f12 } else { (if (sc == 74) { 45 } else { (if (sc == 78) { 43 } else { (if (sc >= 59) { sk_fkey(sc) } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) }) })

	sk_fkey : I64 -> I64
	sk_fkey = |sc| (if (sc <= 68) { (key_f1 + (sc - 59)) } else { 0 })
}
