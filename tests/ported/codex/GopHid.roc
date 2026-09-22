# GopHid -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem

GopHid :: [].{

	hid_letter_sc : I64 -> I64
	hid_letter_sc = |u| (if (u == 4) { 30 } else { (if (u == 5) { 48 } else { (if (u == 6) { 46 } else { (if (u == 7) { 32 } else { (if (u == 8) { 18 } else { (if (u == 9) { 33 } else { (if (u == 10) { 34 } else { (if (u == 11) { 35 } else { (if (u == 12) { 23 } else { (if (u == 13) { 36 } else { (if (u == 14) { 37 } else { (if (u == 15) { 38 } else { (if (u == 16) { 50 } else { (if (u == 17) { 49 } else { (if (u == 18) { 24 } else { (if (u == 19) { 25 } else { (if (u == 20) { 16 } else { (if (u == 21) { 19 } else { (if (u == 22) { 31 } else { (if (u == 23) { 20 } else { (if (u == 24) { 22 } else { (if (u == 25) { 47 } else { (if (u == 26) { 17 } else { (if (u == 27) { 45 } else { (if (u == 28) { 21 } else { (if (u == 29) { 44 } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	hid_digit_sc : I64 -> I64
	hid_digit_sc = |u| (if (u == 30) { 2 } else { (if (u == 31) { 3 } else { (if (u == 32) { 4 } else { (if (u == 33) { 5 } else { (if (u == 34) { 6 } else { (if (u == 35) { 7 } else { (if (u == 36) { 8 } else { (if (u == 37) { 9 } else { (if (u == 38) { 10 } else { (if (u == 39) { 11 } else { 0 }) }) }) }) }) }) }) }) }) })

	hid_punct_sc : I64 -> I64
	hid_punct_sc = |u| (if (u == 40) { 28 } else { (if (u == 41) { 1 } else { (if (u == 42) { 14 } else { (if (u == 43) { 15 } else { (if (u == 44) { 57 } else { (if (u == 45) { 12 } else { (if (u == 46) { 13 } else { (if (u == 47) { 26 } else { (if (u == 48) { 27 } else { (if (u == 49) { 43 } else { (if (u == 51) { 39 } else { (if (u == 52) { 40 } else { (if (u == 53) { 41 } else { (if (u == 54) { 51 } else { (if (u == 55) { 52 } else { (if (u == 56) { 53 } else { (if (u == 57) { 58 } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	hid_fn_sc : I64 -> I64
	hid_fn_sc = |u| (if ((u >= 58) and (u <= 67)) { (59 + (u - 58)) } else { (if (u == 68) { 87 } else { (if (u == 69) { 88 } else { 0 }) }) })

	hid_nav_sc : I64 -> I64
	hid_nav_sc = |u| (if (u == 79) { 77 } else { (if (u == 80) { 75 } else { (if (u == 81) { 80 } else { (if (u == 82) { 72 } else { (if (u == 73) { 71 } else { (if (u == 74) { 73 } else { (if (u == 75) { 83 } else { (if (u == 77) { 79 } else { (if (u == 78) { 81 } else { 0 }) }) }) }) }) }) }) }) })

	hid_usage_sc : I64 -> I64
	hid_usage_sc = |u| ({
		a = hid_letter_sc(u)
		(if (a != 0) { a } else { ({
			b = hid_digit_sc(u)
			(if (b != 0) { b } else { ({
				c = hid_punct_sc(u)
				(if (c != 0) { c } else { ({
					d = hid_fn_sc(u)
					(if (d != 0) { d } else { hid_nav_sc(u) })
				}) })
			}) })
		}) })
	})

	hid_mod_sc : I64 -> I64
	hid_mod_sc = |b| (if (b == 0) { 29 } else { (if (b == 1) { 42 } else { (if (b == 2) { 56 } else { (if (b == 5) { 54 } else { 0 }) }) }) })

	hid_bit : I64 -> I64
	hid_bit = |b| I64.shl_wrap(1, I64.to_u8_wrap(b))

	hid_mod_set! : Mem.Mem, I64, I64 => (Mem.Mem, Bool)
	hid_mod_set! = |mem, buf, b| ({
		(mem1, mem__1) = Mem.load!(mem, buf, 0, 1)
		(mem1, (I64.bitwise_and(mem__1, hid_bit(b)) != 0))
	})

	hid_slot_live : I64 -> Bool
	hid_slot_live = |u| (u > 3)

	hid_holds! : Mem.Mem, I64, I64, I64 => (Mem.Mem, Bool)
	hid_holds! = |mem, buf, u, i| (if (i > 7) { (mem, False) } else { ({
		(mem1, mem__1) = Mem.load!(mem, buf, i, 1)
		(if (mem__1 == u) { (mem1, True) } else { hid_holds!(mem1, buf, u, (i + 1)) })
	}) })

	hid_has_rollover! : Mem.Mem, I64, I64 => (Mem.Mem, Bool)
	hid_has_rollover! = |mem, cur, i| (if (i > 7) { (mem, False) } else { ({
		(mem1, mem__1) = Mem.load!(mem, cur, i, 1)
		(if (mem__1 == 1) { (mem1, True) } else { hid_has_rollover!(mem1, cur, (i + 1)) })
	}) })

	hid_find_mod_press! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	hid_find_mod_press! = |mem, prev, cur, b| (if (b > 7) { (mem, (-1)) } else { ({
		(mem1, mem__1) = hid_mod_set!(mem, cur, b)
		(mem3, mem__3) = (if mem__1 { ({
		(mem2, mem__2) = hid_mod_set!(mem1, prev, b)
		(mem2, (mem__2 == False))
	}) } else { (mem1, False) })
		(if mem__3 { (mem3, b) } else { hid_find_mod_press!(mem3, prev, cur, (b + 1)) })
	}) })

	hid_find_mod_release! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	hid_find_mod_release! = |mem, prev, cur, b| (if (b > 7) { (mem, (-1)) } else { ({
		(mem1, mem__1) = hid_mod_set!(mem, prev, b)
		(mem3, mem__3) = (if mem__1 { ({
		(mem2, mem__2) = hid_mod_set!(mem1, cur, b)
		(mem2, (mem__2 == False))
	}) } else { (mem1, False) })
		(if mem__3 { (mem3, b) } else { hid_find_mod_release!(mem3, prev, cur, (b + 1)) })
	}) })

	hid_find_key_press! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	hid_find_key_press! = |mem, prev, cur, i| (if (i > 7) { (mem, (-1)) } else { ({
		(mem1, u) = Mem.load!(mem, cur, i, 1)
		({
			(mem3, mem__2) = (if hid_slot_live(u) { ({
			(mem2, mem__1) = hid_holds!(mem1, prev, u, 2)
			(mem2, (mem__1 == False))
		}) } else { (mem1, False) })
			(if mem__2 { (mem3, u) } else { hid_find_key_press!(mem3, prev, cur, (i + 1)) })
		})
	}) })

	hid_find_key_release! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	hid_find_key_release! = |mem, prev, cur, i| (if (i > 7) { (mem, (-1)) } else { ({
		(mem1, u) = Mem.load!(mem, prev, i, 1)
		({
			(mem3, mem__2) = (if hid_slot_live(u) { ({
			(mem2, mem__1) = hid_holds!(mem1, cur, u, 2)
			(mem2, (mem__1 == False))
		}) } else { (mem1, False) })
			(if mem__2 { (mem3, i) } else { hid_find_key_release!(mem3, prev, cur, (i + 1)) })
		})
	}) })

	hid_free_slot! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	hid_free_slot! = |mem, prev, i| (if (i > 7) { (mem, (-1)) } else { ({
		(mem1, mem__1) = Mem.load!(mem, prev, i, 1)
		(if (hid_slot_live(mem__1) == False) { (mem1, i) } else { hid_free_slot!(mem1, prev, (i + 1)) })
	}) })

	hid_unmapped : I64
	hid_unmapped = (-1)

	hid_do_mod_press! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	hid_do_mod_press! = |mem, prev, b| ({
		(mem3, mem__2) = ({
		(mem2, _p) = ({
			(mem1, mem__1) = Mem.load!(mem, prev, 0, 1)
			Mem.store!(mem1, prev, 0, I64.bitwise_or(mem__1, hid_bit(b)), 1)
		})
		sc = hid_mod_sc(b)
		(mem2, (if (sc == 0) { hid_unmapped } else { sc }))
	})
		(mem3, mem__2)
	})

	hid_do_mod_release! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	hid_do_mod_release! = |mem, prev, b| ({
		(mem3, mem__2) = ({
		(mem2, _p) = ({
			(mem1, mem__1) = Mem.load!(mem, prev, 0, 1)
			Mem.store!(mem1, prev, 0, I64.bitwise_and(mem__1, (255 - hid_bit(b))), 1)
		})
		sc = hid_mod_sc(b)
		(mem2, (if (sc == 0) { hid_unmapped } else { I64.bitwise_or(sc, 128) }))
	})
		(mem3, mem__2)
	})

	hid_do_key_press! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	hid_do_key_press! = |mem, prev, u| ({
		(mem5, mem__3) = ({
		(mem1, s) = hid_free_slot!(mem, prev, 2)
		({
			(mem4, mem__2) = (if (s < 0) { (mem1, 0) } else { ({
			(mem3, mem__1) = ({
			(mem2, _p) = Mem.store!(mem1, prev, s, u, 1)
			sc = hid_usage_sc(u)
			(mem2, (if (sc == 0) { hid_unmapped } else { sc }))
		})
			(mem3, mem__1)
		}) })
			(mem4, mem__2)
		})
	})
		(mem5, mem__3)
	})

	hid_do_key_release! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	hid_do_key_release! = |mem, prev, i| ({
		(mem3, mem__1) = ({
		(mem1, u) = Mem.load!(mem, prev, i, 1)
		(mem2, _p) = Mem.store!(mem1, prev, i, 0, 1)
		sc = hid_usage_sc(u)
		(mem2, (if (sc == 0) { hid_unmapped } else { I64.bitwise_or(sc, 128) }))
	})
		(mem3, mem__1)
	})

	hid_apply_one! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	hid_apply_one! = |mem, prev, cur| ({
		(mem1, mp) = hid_find_mod_press!(mem, prev, cur, 0)
		(if (mp >= 0) { hid_do_mod_press!(mem1, prev, mp) } else { ({
			(mem2, kp) = hid_find_key_press!(mem1, prev, cur, 2)
			(if (kp >= 0) { hid_do_key_press!(mem2, prev, kp) } else { ({
				(mem3, kr) = hid_find_key_release!(mem2, prev, cur, 2)
				(if (kr >= 0) { hid_do_key_release!(mem3, prev, kr) } else { ({
					(mem4, mr) = hid_find_mod_release!(mem3, prev, cur, 0)
					(if (mr >= 0) { hid_do_mod_release!(mem4, prev, mr) } else { (mem4, 0) })
				}) })
			}) })
		}) })
	})

	hid_step_fuel! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	hid_step_fuel! = |mem, prev, cur, fuel| (if (fuel <= 0) { (mem, 0) } else { ({
		(mem1, r) = hid_apply_one!(mem, prev, cur)
		(if (r == hid_unmapped) { hid_step_fuel!(mem1, prev, cur, (fuel - 1)) } else { (mem1, r) })
	}) })

	hid_step! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	hid_step! = |mem, prev, cur| ({
		(mem1, mem__1) = hid_has_rollover!(mem, cur, 2)
		(if mem__1 { (mem1, 0) } else { hid_step_fuel!(mem1, prev, cur, 32) })
	})
}
