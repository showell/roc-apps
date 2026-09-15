# Hpet -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Machine

Hpet :: [].{

	hpet_base : I64
	hpet_base = 4275044352

	hpet_off_caps_period : I64
	hpet_off_caps_period = 4

	hpet_off_config : I64
	hpet_off_config = 16

	hpet_off_counter_lo : I64
	hpet_off_counter_lo = 240

	hpet_off_counter_hi : I64
	hpet_off_counter_hi = 244

	hpet_config_enable : I64
	hpet_config_enable = 1

	hpet_reg! : Machine.Machine, I64 => (Machine.Machine, I64)
	hpet_reg! = |machine, off| ({
		(machine1, machine__3) = Machine.load!(machine, (hpet_base + off), 0, 4)
		(machine1, I64.bitwise_and(machine__3, 4294967295))
	})

	hpet_start! : Machine.Machine => (Machine.Machine, I64)
	hpet_start! = |machine| ({
		(machine1, cfg) = hpet_reg!(machine, hpet_off_config)
		(if (I64.bitwise_and(cfg, hpet_config_enable) != 0) { (machine1, cfg) } else { Machine.store!(machine1, (hpet_base + hpet_off_config), 0, I64.bitwise_or(cfg, hpet_config_enable), 4) })
	})

	hpet_ticks! : Machine.Machine => (Machine.Machine, I64)
	hpet_ticks! = |machine| ({
		(machine6, machine__6) = ({
		(machine1, hi1) = hpet_reg!(machine, hpet_off_counter_hi)
		(machine2, lo) = hpet_reg!(machine1, hpet_off_counter_lo)
		(machine3, hi2) = hpet_reg!(machine2, hpet_off_counter_hi)
		({
			(machine5, machine__5) = (if (hi1 == hi2) { (machine3, I64.bitwise_or(I64.shl_wrap(hi1, I64.to_u8_wrap(32)), lo)) } else { ({
			(machine4, machine__4) = hpet_reg!(machine3, hpet_off_counter_lo)
			(machine4, I64.bitwise_or(I64.shl_wrap(hi2, I64.to_u8_wrap(32)), machine__4))
		}) })
			(machine5, machine__5)
		})
	})
		(machine6, machine__6)
	})

	hpet_femtoseconds_per_second : I64
	hpet_femtoseconds_per_second = 1000000000000000

	hpet_ticks_per_second! : Machine.Machine => (Machine.Machine, I64)
	hpet_ticks_per_second! = |machine| ({
		(machine2, machine__7) = ({
		(machine1, period) = hpet_reg!(machine, hpet_off_caps_period)
		(machine1, (if (period <= 0) { 0 } else { I64.div_trunc_by(hpet_femtoseconds_per_second, period) }))
	})
		(machine2, machine__7)
	})

	hpet_seconds! : Machine.Machine => (Machine.Machine, I64)
	hpet_seconds! = |machine| ({
		(machine5, machine__10) = ({
		(machine1, _started) = hpet_start!(machine)
		(machine2, rate) = hpet_ticks_per_second!(machine1)
		({
			(machine4, machine__9) = (if (rate <= 0) { (machine2, 0) } else { ({
			(machine3, machine__8) = hpet_ticks!(machine2)
			(machine3, I64.div_trunc_by(machine__8, rate))
		}) })
			(machine4, machine__9)
		})
	})
		(machine5, machine__10)
	})
}
