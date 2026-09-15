# E1000e -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Hpet
import Machine
import Maybe
import MemoryMap
import Pci
import Prelude

E1000e :: [].{
	E1000Device : { e_mmio : I64, e_rx_ring : I64, e_tx_ring : I64, e_rx_bufs : I64, e_tx_bufs : I64, e_ctrl_blk : I64, e_present : Bool, e_mac : List(I64), e_mac_valid : Bool, e_pch : I64, e_ulp : I64 }
	K1Step : { k1_value : I64, k1_owned : Bool }
	E1000RecvResult : { r_frame : List(I64), r_has_frame : Bool }

	e1000_vendor_intel : I64
	e1000_vendor_intel = 32902

	e1000_class_network : I64
	e1000_class_network = 2

	e1000_subclass_ethernet : I64
	e1000_subclass_ethernet = 0

	e1000_find : Pci.PciScanResult -> Maybe.Maybe(Pci.PciDevice)
	e1000_find = |scan| e1000_find_loop(scan.devices, 0, scan.count)

	e1000_find_loop : List(Pci.PciDevice), I64, I64 -> Maybe.Maybe(Pci.PciDevice)
	e1000_find_loop = |devs, i, len| (if (i >= len) { None } else { ({
		d = (List.get(devs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if e1000_is_candidate(d) { Just(d) } else { e1000_find_loop(devs, (i + 1), len) })
	}) })

	e1000_is_candidate : Pci.PciDevice -> Bool
	e1000_is_candidate = |d| (if (d.pci_vendor != e1000_vendor_intel) { False } else { (if (d.pci_class != e1000_class_network) { False } else { (d.pci_subclass == e1000_subclass_ethernet) }) })

	e1000_reg_ctrl : I64
	e1000_reg_ctrl = 0

	e1000_reg_status : I64
	e1000_reg_status = 8

	e1000_reg_ctrl_ext : I64
	e1000_reg_ctrl_ext = 24

	e1000_reg_icr : I64
	e1000_reg_icr = 192

	e1000_reg_imc : I64
	e1000_reg_imc = 216

	e1000_reg_rctl : I64
	e1000_reg_rctl = 256

	e1000_reg_tctl : I64
	e1000_reg_tctl = 1024

	e1000_reg_tipg : I64
	e1000_reg_tipg = 1040

	e1000_reg_rdbal : I64
	e1000_reg_rdbal = 10240

	e1000_reg_rdbah : I64
	e1000_reg_rdbah = 10244

	e1000_reg_rdlen : I64
	e1000_reg_rdlen = 10248

	e1000_reg_rdh : I64
	e1000_reg_rdh = 10256

	e1000_reg_rdt : I64
	e1000_reg_rdt = 10264

	e1000_reg_tdbal : I64
	e1000_reg_tdbal = 14336

	e1000_reg_tdbah : I64
	e1000_reg_tdbah = 14340

	e1000_reg_tdlen : I64
	e1000_reg_tdlen = 14344

	e1000_reg_tdh : I64
	e1000_reg_tdh = 14352

	e1000_reg_tdt : I64
	e1000_reg_tdt = 14360

	e1000_reg_mta : I64
	e1000_reg_mta = 20992

	e1000_reg_ral : I64
	e1000_reg_ral = 21504

	e1000_reg_rah : I64
	e1000_reg_rah = 21508

	e1000_reg_mdic : I64
	e1000_reg_mdic = 32

	e1000_reg_crcerrs : I64
	e1000_reg_crcerrs = 16384

	e1000_reg_mpc : I64
	e1000_reg_mpc = 16400

	e1000_reg_gprc : I64
	e1000_reg_gprc = 16500

	e1000_reg_rnbc : I64
	e1000_reg_rnbc = 16544

	e1000_ctrl_slu : I64
	e1000_ctrl_slu = 64

	e1000_ctrl_asde : I64
	e1000_ctrl_asde = 32

	e1000_ctrl_rst : I64
	e1000_ctrl_rst = 67108864

	e1000_clear_asde : I64
	e1000_clear_asde = (4294967295 - e1000_ctrl_asde)

	e1000_status_lu : I64
	e1000_status_lu = 2

	e1000_rctl_en : I64
	e1000_rctl_en = 2

	e1000_rctl_upe : I64
	e1000_rctl_upe = 8

	e1000_rctl_mpe : I64
	e1000_rctl_mpe = 16

	e1000_rctl_bam : I64
	e1000_rctl_bam = 32768

	e1000_rctl_secrc : I64
	e1000_rctl_secrc = 67108864

	e1000_tctl_en : I64
	e1000_tctl_en = 2

	e1000_tctl_psp : I64
	e1000_tctl_psp = 8

	e1000_tctl_ct : I64
	e1000_tctl_ct = 240

	e1000_tctl_cold : I64
	e1000_tctl_cold = 262144

	e1000_tipg_default : I64
	e1000_tipg_default = 6299658

	e1000_rx_status_dd : I64
	e1000_rx_status_dd = 1

	e1000_rx_status_eop : I64
	e1000_rx_status_eop = 2

	e1000_tx_cmd_eop : I64
	e1000_tx_cmd_eop = 1

	e1000_tx_cmd_ifcs : I64
	e1000_tx_cmd_ifcs = 2

	e1000_tx_cmd_rs : I64
	e1000_tx_cmd_rs = 8

	e1000_tx_status_dd : I64
	e1000_tx_status_dd = 1

	e1000_desc_size : I64
	e1000_desc_size = 16

	e1000_rx_count : I64
	e1000_rx_count = 16

	e1000_tx_count : I64
	e1000_tx_count = 16

	e1000_buf_size : I64
	e1000_buf_size = 2048

	e1000_max_frame : I64
	e1000_max_frame = 1522

	e1000_window_lo : I64
	e1000_window_lo = MemoryMap.bare_metal_device_window_lo

	e1000_window_hi : I64
	e1000_window_hi = MemoryMap.bare_metal_device_window_hi

	e1000_bar_ok : I64
	e1000_bar_ok = 0

	e1000_bar_is_io : I64
	e1000_bar_is_io = 1

	e1000_bar_below_window : I64
	e1000_bar_below_window = 2

	e1000_bar_above_window : I64
	e1000_bar_above_window = 3

	e1000_bar_zero : I64
	e1000_bar_zero = 4

	e1000_bar_verdict : Pci.PciBar -> I64
	e1000_bar_verdict = |bar| (if bar.bar_is_io { e1000_bar_is_io } else { (if (bar.bar_base == 0) { e1000_bar_zero } else { (if (bar.bar_base >= e1000_window_hi) { e1000_bar_above_window } else { (if (bar.bar_base < e1000_window_lo) { e1000_bar_below_window } else { e1000_bar_ok }) }) }) })

	e1000_cb_rx_next : I64
	e1000_cb_rx_next = 0

	e1000_cb_tx_next : I64
	e1000_cb_tx_next = 4

	e1000_cb_size : I64
	e1000_cb_size = 16

	e1000_read! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_read! = |machine, mmio, off| ({
		(machine1, machine__23) = Machine.load!(machine, (mmio + off), 0, 4)
		(machine1, I64.bitwise_and(machine__23, 4294967295))
	})

	e1000_write! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	e1000_write! = |machine, mmio, off, v| Machine.store!(machine, (mmio + off), 0, v, 4)

	e1000_align : I64, I64 -> I64
	e1000_align = |addr, n| ({
		r = Prelude.int_mod(addr, n)
		(if (r == 0) { addr } else { (addr + (n - r)) })
	})

	e1000_alloc_aligned! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_alloc_aligned! = |machine, bytes, align| ({
		(machine2, machine__24) = ({
		(machine1, raw) = Machine.alloc(machine, (bytes + align))
		(machine1, e1000_align(raw, align))
	})
		(machine2, machine__24)
	})

	e1000_zero_words! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	e1000_zero_words! = |machine, base, count, i| (if (i >= count) { (machine, 0) } else { ({
		(machine1, _w) = Machine.store!(machine, (base + (i * 4)), 0, 0, 4)
		e1000_zero_words!(machine1, base, count, (i + 1))
	}) })

	e1000_reset! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_reset! = |machine, mmio| ({
		(machine8, machine__25) = ({
		(machine1, _m1) = e1000_write!(machine, mmio, e1000_reg_imc, 4294967295)
		(machine2, ctrl) = e1000_read!(machine1, mmio, e1000_reg_ctrl)
		(machine3, _r) = e1000_write!(machine2, mmio, e1000_reg_ctrl, I64.bitwise_or(ctrl, e1000_ctrl_rst))
		(machine4, settled) = e1000_await_reset!(machine3, mmio, 0)
		(machine5, _waited) = e1000_settle_mdio!(machine4, mmio)
		(machine6, _m2) = e1000_write!(machine5, mmio, e1000_reg_imc, 4294967295)
		(machine7, _cleared) = e1000_read!(machine6, mmio, e1000_reg_icr)
		(machine7, settled)
	})
		(machine8, machine__25)
	})

	e1000_reset_fuel : I64
	e1000_reset_fuel = 1000000

	e1000_await_reset! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_await_reset! = |machine, mmio, i| (if (i >= e1000_reset_fuel) { (machine, 0) } else { ({
		(machine1, machine__26) = e1000_read!(machine, mmio, e1000_reg_ctrl)
		(if (I64.bitwise_and(machine__26, e1000_ctrl_rst) == 0) { (machine1, 1) } else { e1000_await_reset!(machine1, mmio, (i + 1)) })
	}) })

	e1000_mdio_window_ms : I64
	e1000_mdio_window_ms = 10

	e1000_settle_ticks_fuel : I64
	e1000_settle_ticks_fuel = 200000

	e1000_settle_spin_fuel : I64
	e1000_settle_spin_fuel = 100000

	e1000_settle_mdio! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_settle_mdio! = |machine, mmio| ({
		(machine1, _started) = Hpet.hpet_start!(machine)
		(machine2, rate) = Hpet.hpet_ticks_per_second!(machine1)
		(if (rate <= 0) { e1000_settle_spin!(machine2, mmio, e1000_settle_spin_fuel) } else { ({
			(machine3, machine__27) = Hpet.hpet_ticks!(machine2)
			e1000_await_ticks!(machine3, machine__27, I64.div_trunc_by((rate * e1000_mdio_window_ms), 1000), 0)
		}) })
	})

	e1000_await_ticks! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	e1000_await_ticks! = |machine, start, want, i| (if (i >= e1000_settle_ticks_fuel) { (machine, 0) } else { ({
		(machine1, machine__28) = Hpet.hpet_ticks!(machine)
		(if ((machine__28 - start) >= want) { (machine1, 1) } else { e1000_await_ticks!(machine1, start, want, (i + 1)) })
	}) })

	e1000_settle_spin! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_settle_spin! = |machine, mmio, i| (if (i <= 0) { (machine, 0) } else { ({
		(machine1, _v) = e1000_read!(machine, mmio, e1000_reg_status)
		e1000_settle_spin!(machine1, mmio, (i - 1))
	}) })

	e1000_link_fuel : I64
	e1000_link_fuel = 4000000

	e1000_mdic_op_read : I64
	e1000_mdic_op_read = 134217728

	e1000_mdic_op_write : I64
	e1000_mdic_op_write = 67108864

	e1000_mdic_r : I64
	e1000_mdic_r = 268435456

	e1000_mdic_e : I64
	e1000_mdic_e = 1073741824

	e1000_mdic_data : I64
	e1000_mdic_data = 65535

	e1000_mdic_fuel : I64
	e1000_mdic_fuel = 100000

	e1000_phy_addr : I64
	e1000_phy_addr = 1

	e1000_phy_bmcr : I64
	e1000_phy_bmcr = 0

	e1000_phy_bmsr : I64
	e1000_phy_bmsr = 1

	e1000_phy_id1 : I64
	e1000_phy_id1 = 2

	e1000_bmcr_reset : I64
	e1000_bmcr_reset = 32768

	e1000_bmcr_aneg_en : I64
	e1000_bmcr_aneg_en = 4096

	e1000_bmcr_aneg_rst : I64
	e1000_bmcr_aneg_rst = 512

	e1000_bmsr_aneg_done : I64
	e1000_bmsr_aneg_done = 32

	e1000_mdic_frame : I64, I64, I64, I64 -> I64
	e1000_mdic_frame = |op, phy, reg, data| I64.bitwise_or(op, I64.bitwise_or(I64.shl_wrap(phy, I64.to_u8_wrap(21)), I64.bitwise_or(I64.shl_wrap(reg, I64.to_u8_wrap(16)), I64.bitwise_and(data, e1000_mdic_data))))

	e1000_phy_read_at! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	e1000_phy_read_at! = |machine, mmio, phy, reg| ({
		f = e1000_mdic_frame(e1000_mdic_op_read, phy, reg, 0)
		(machine1, _w) = e1000_write!(machine, mmio, e1000_reg_mdic, f)
		e1000_await_mdic!(machine1, mmio, 0)
	})

	e1000_phy_read! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_phy_read! = |machine, mmio, reg| e1000_phy_read_at!(machine, mmio, e1000_phy_addr, reg)

	e1000_phy_write! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	e1000_phy_write! = |machine, mmio, reg, data| ({
		f = e1000_mdic_frame(e1000_mdic_op_write, e1000_phy_addr, reg, data)
		(machine1, _w) = e1000_write!(machine, mmio, e1000_reg_mdic, f)
		e1000_await_mdic!(machine1, mmio, 0)
	})

	e1000_await_mdic! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_await_mdic! = |machine, mmio, i| (if (i >= e1000_mdic_fuel) { (machine, (0 - 1)) } else { ({
		(machine1, v) = e1000_read!(machine, mmio, e1000_reg_mdic)
		(if (I64.bitwise_and(v, e1000_mdic_e) != 0) { (machine1, (0 - 1)) } else { (if (I64.bitwise_and(v, e1000_mdic_r) != 0) { (machine1, I64.bitwise_and(v, e1000_mdic_data)) } else { e1000_await_mdic!(machine1, mmio, (i + 1)) }) })
	}) })

	e1000_phy_page_reg : I64
	e1000_phy_page_reg = 31

	e1000_phy_port_page : I64
	e1000_phy_port_page = 769

	e1000_phy_custom_mode : I64
	e1000_phy_custom_mode = 16

	e1000_phy_mdio_slow : I64
	e1000_phy_mdio_slow = 1024

	e1000_phy_set_page! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_phy_set_page! = |machine, mmio, page| e1000_phy_write!(machine, mmio, e1000_phy_page_reg, I64.shl_wrap(page, I64.to_u8_wrap(5)))

	e1000_phy_slow_mode! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_phy_slow_mode! = |machine, mmio| ({
		(machine9, machine__33) = ({
		(machine1, p) = e1000_phy_set_page!(machine, mmio, e1000_phy_port_page)
		({
			(machine8, machine__32) = (if (p < 0) { (machine1, 0) } else { ({
			(machine7, machine__31) = ({
			(machine2, cur) = e1000_phy_read!(machine1, mmio, e1000_phy_custom_mode)
			({
				(machine6, machine__30) = (if (cur < 0) { (machine2, 0) } else { ({
				(machine5, machine__29) = ({
				want = I64.bitwise_or(cur, e1000_phy_mdio_slow)
				(machine3, w) = e1000_phy_write!(machine2, mmio, e1000_phy_custom_mode, want)
				(machine4, _back) = e1000_phy_set_page!(machine3, mmio, 0)
				(machine4, (if (w < 0) { 0 } else { 1 }))
			})
				(machine5, machine__29)
			}) })
				(machine6, machine__30)
			})
		})
			(machine7, machine__31)
		}) })
			(machine8, machine__32)
		})
	})
		(machine9, machine__33)
	})

	e1000_phy_bring_up! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_phy_bring_up! = |machine, mmio| ({
		(machine1, r) = e1000_phy_write!(machine, mmio, e1000_phy_bmcr, e1000_bmcr_reset)
		(if (r < 0) { (machine1, 0) } else { ({
			(machine2, _s) = e1000_phy_slow_mode!(machine1, mmio)
			mode = I64.bitwise_or(e1000_bmcr_aneg_en, e1000_bmcr_aneg_rst)
			(machine3, a) = e1000_phy_write!(machine2, mmio, e1000_phy_bmcr, mode)
			(if (a < 0) { (machine3, 0) } else { e1000_await_aneg!(machine3, mmio, 0) })
		}) })
	})

	e1000_aneg_fuel : I64
	e1000_aneg_fuel = 1000000

	e1000_aneg_ms : I64
	e1000_aneg_ms = 3000

	e1000_aneg_ticks : I64 -> I64
	e1000_aneg_ticks = |rate| I64.div_trunc_by((rate * e1000_aneg_ms), 1000)

	e1000_await_aneg! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_await_aneg! = |machine, mmio, i| ({
		(machine1, rate) = Hpet.hpet_ticks_per_second!(machine)
		(if (rate <= 0) { e1000_await_aneg_counted!(machine1, mmio, i) } else { ({
			(machine2, machine__34) = Hpet.hpet_ticks!(machine1)
			e1000_await_aneg_timed!(machine2, mmio, machine__34, e1000_aneg_ticks(rate), i)
		}) })
	})

	e1000_await_aneg_counted! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_await_aneg_counted! = |machine, mmio, i| (if (i >= e1000_aneg_fuel) { (machine, 0) } else { ({
		(machine1, s) = e1000_phy_read!(machine, mmio, e1000_phy_bmsr)
		(if (s < 0) { (machine1, 0) } else { (if (I64.bitwise_and(s, e1000_bmsr_aneg_done) != 0) { (machine1, 1) } else { e1000_await_aneg_counted!(machine1, mmio, (i + 1)) }) })
	}) })

	e1000_await_aneg_timed! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	e1000_await_aneg_timed! = |machine, mmio, start, want, i| (if (i >= e1000_aneg_fuel) { (machine, 0) } else { ({
		(machine1, s) = e1000_phy_read!(machine, mmio, e1000_phy_bmsr)
		(if (s < 0) { (machine1, 0) } else { (if (I64.bitwise_and(s, e1000_bmsr_aneg_done) != 0) { (machine1, 1) } else { ({
			(machine2, machine__35) = Hpet.hpet_ticks!(machine1)
			(if ((machine__35 - start) >= want) { (machine2, 0) } else { e1000_await_aneg_timed!(machine2, mmio, start, want, (i + 1)) })
		}) }) })
	}) })

	e1000_link_up! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_link_up! = |machine, mmio| ({
		(machine1, _p) = e1000_phy_bring_up!(machine, mmio)
		(machine2, ctrl) = e1000_read!(machine1, mmio, e1000_reg_ctrl)
		(machine3, _w) = e1000_write!(machine2, mmio, e1000_reg_ctrl, I64.bitwise_and(I64.bitwise_or(ctrl, e1000_ctrl_slu), e1000_clear_asde))
		e1000_link_wait!(machine3, mmio)
	})

	e1000_link_window_ms : I64
	e1000_link_window_ms = 5000

	e1000_link_batch : I64
	e1000_link_batch = 4096

	e1000_link_batch_fuel : I64
	e1000_link_batch_fuel = 100000

	e1000_link_ticks : I64 -> I64
	e1000_link_ticks = |rate| I64.div_trunc_by((rate * e1000_link_window_ms), 1000)

	e1000_link_wait! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_link_wait! = |machine, mmio| ({
		(machine1, _started) = Hpet.hpet_start!(machine)
		(machine2, rate) = Hpet.hpet_ticks_per_second!(machine1)
		(if (rate <= 0) { e1000_await_link!(machine2, mmio, 0) } else { ({
			(machine3, machine__36) = Hpet.hpet_ticks!(machine2)
			e1000_await_link_clocked!(machine3, mmio, machine__36, e1000_link_ticks(rate), e1000_link_batch_fuel)
		}) })
	})

	e1000_await_link_batch! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_await_link_batch! = |machine, mmio, i| (if (i <= 0) { (machine, 0) } else { ({
		(machine1, machine__37) = e1000_read!(machine, mmio, e1000_reg_status)
		(if (I64.bitwise_and(machine__37, e1000_status_lu) != 0) { (machine1, 1) } else { e1000_await_link_batch!(machine1, mmio, (i - 1)) })
	}) })

	e1000_await_link_clocked! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	e1000_await_link_clocked! = |machine, mmio, start, want, fuel| ({
		(machine1, machine__38) = e1000_await_link_batch!(machine, mmio, e1000_link_batch)
		(if (machine__38 == 1) { (machine1, 1) } else { (if (fuel <= 0) { (machine1, 0) } else { ({
		(machine2, machine__39) = Hpet.hpet_ticks!(machine1)
		(if ((machine__39 - start) >= want) { (machine2, 0) } else { e1000_await_link_clocked!(machine2, mmio, start, want, (fuel - 1)) })
	}) }) })
	})

	e1000_await_link! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_await_link! = |machine, mmio, i| (if (i >= e1000_link_fuel) { (machine, 0) } else { ({
		(machine1, machine__40) = e1000_read!(machine, mmio, e1000_reg_status)
		(if (I64.bitwise_and(machine__40, e1000_status_lu) != 0) { (machine1, 1) } else { e1000_await_link!(machine1, mmio, (i + 1)) })
	}) })

	e1000_has_link! : Machine.Machine, E1000e.E1000Device => (Machine.Machine, Bool)
	e1000_has_link! = |machine, d| ({
		(machine2, machine__42) = (if d.e_present { ({
		(machine1, machine__41) = e1000_read!(machine, d.e_mmio, e1000_reg_status)
		(machine1, (I64.bitwise_and(machine__41, e1000_status_lu) != 0))
	}) } else { (machine, False) })
		(machine2, machine__42)
	})

	e1000_rah_av : I64
	e1000_rah_av = 2147483648

	e1000_mac_present! : Machine.Machine, I64 => (Machine.Machine, Bool)
	e1000_mac_present! = |machine, mmio| ({
		(machine1, machine__43) = e1000_read!(machine, mmio, e1000_reg_rah)
		(machine1, (I64.bitwise_and(machine__43, e1000_rah_av) != 0))
	})

	e1000_read_mac! : Machine.Machine, I64 => (Machine.Machine, List(I64))
	e1000_read_mac! = |machine, mmio| ({
		(machine3, machine__44) = ({
		(machine1, lo) = e1000_read!(machine, mmio, e1000_reg_ral)
		(machine2, hi) = e1000_read!(machine1, mmio, e1000_reg_rah)
		(machine2, [I64.bitwise_and(lo, 255), I64.bitwise_and(I64.shr_zf_wrap(lo, I64.to_u8_wrap(8)), 255), I64.bitwise_and(I64.shr_zf_wrap(lo, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(lo, I64.to_u8_wrap(24)), 255), I64.bitwise_and(hi, 255), I64.bitwise_and(I64.shr_zf_wrap(hi, I64.to_u8_wrap(8)), 255)])
	})
		(machine3, machine__44)
	})

	e1000_setup_rx! : Machine.Machine, E1000e.E1000Device => (Machine.Machine, I64)
	e1000_setup_rx! = |machine, d| ({
		mmio = d.e_mmio
		(machine1, _built) = e1000_build_rx_descs!(machine, d, 0)
		(machine2, _bl) = e1000_write!(machine1, mmio, e1000_reg_rdbal, I64.bitwise_and(d.e_rx_ring, 4294967295))
		(machine3, _bh) = e1000_write!(machine2, mmio, e1000_reg_rdbah, I64.shr_zf_wrap(d.e_rx_ring, I64.to_u8_wrap(32)))
		(machine4, _ln) = e1000_write!(machine3, mmio, e1000_reg_rdlen, (e1000_rx_count * e1000_desc_size))
		(machine5, _h) = e1000_write!(machine4, mmio, e1000_reg_rdh, 0)
		(machine6, _t) = e1000_write!(machine5, mmio, e1000_reg_rdt, (e1000_rx_count - 1))
		(machine7, _cur) = Machine.store!(machine6, (d.e_ctrl_blk + e1000_cb_rx_next), 0, 0, 4)
		promisc = I64.bitwise_or(e1000_rctl_upe, e1000_rctl_mpe)
		flags = I64.bitwise_or(e1000_rctl_secrc, promisc)
		rctl = I64.bitwise_or(e1000_rctl_en, I64.bitwise_or(e1000_rctl_bam, flags))
		e1000_write!(machine7, mmio, e1000_reg_rctl, rctl)
	})

	e1000_build_rx_descs! : Machine.Machine, E1000e.E1000Device, I64 => (Machine.Machine, I64)
	e1000_build_rx_descs! = |machine, d, i| (if (i >= e1000_rx_count) { (machine, 0) } else { ({
		desc = (d.e_rx_ring + (i * e1000_desc_size))
		buf = (d.e_rx_bufs + (i * e1000_buf_size))
		(machine1, _lo) = Machine.store!(machine, desc, 0, I64.bitwise_and(buf, 4294967295), 4)
		(machine2, _hi) = Machine.store!(machine1, (desc + 4), 0, I64.shr_zf_wrap(buf, I64.to_u8_wrap(32)), 4)
		(machine3, _mid) = Machine.store!(machine2, (desc + 8), 0, 0, 4)
		(machine4, _top) = Machine.store!(machine3, (desc + 12), 0, 0, 4)
		e1000_build_rx_descs!(machine4, d, (i + 1))
	}) })

	e1000_setup_tx! : Machine.Machine, E1000e.E1000Device => (Machine.Machine, I64)
	e1000_setup_tx! = |machine, d| ({
		mmio = d.e_mmio
		(machine1, _cleared) = e1000_zero_words!(machine, d.e_tx_ring, (e1000_tx_count * 4), 0)
		(machine2, _bl) = e1000_write!(machine1, mmio, e1000_reg_tdbal, I64.bitwise_and(d.e_tx_ring, 4294967295))
		(machine3, _bh) = e1000_write!(machine2, mmio, e1000_reg_tdbah, I64.shr_zf_wrap(d.e_tx_ring, I64.to_u8_wrap(32)))
		(machine4, _ln) = e1000_write!(machine3, mmio, e1000_reg_tdlen, (e1000_tx_count * e1000_desc_size))
		(machine5, _h) = e1000_write!(machine4, mmio, e1000_reg_tdh, 0)
		(machine6, _t) = e1000_write!(machine5, mmio, e1000_reg_tdt, 0)
		(machine7, _cur) = Machine.store!(machine6, (d.e_ctrl_blk + e1000_cb_tx_next), 0, 0, 4)
		(machine8, _g) = e1000_write!(machine7, mmio, e1000_reg_tipg, e1000_tipg_default)
		coll = I64.bitwise_or(e1000_tctl_ct, e1000_tctl_cold)
		tctl = I64.bitwise_or(e1000_tctl_en, I64.bitwise_or(e1000_tctl_psp, coll))
		e1000_write!(machine8, mmio, e1000_reg_tctl, tctl)
	})

	e1000_clear_mta! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_clear_mta! = |machine, mmio, i| (if (i >= 128) { (machine, 0) } else { ({
		(machine1, _w) = e1000_write!(machine, mmio, (e1000_reg_mta + (i * 4)), 0)
		e1000_clear_mta!(machine1, mmio, (i + 1))
	}) })

	e1000_absent : E1000e.E1000Device
	e1000_absent = { e_mmio: 0, e_rx_ring: 0, e_tx_ring: 0, e_rx_bufs: 0, e_tx_bufs: 0, e_ctrl_blk: 0, e_present: False, e_mac: [], e_mac_valid: False, e_pch: 0, e_ulp: 0 }

	e1000_dev_i219_v : I64
	e1000_dev_i219_v = 5560

	e1000_pch_part : I64 -> Bool
	e1000_pch_part = |dev_id| (dev_id == e1000_dev_i219_v)

	e1000_reg_extcnf_ctrl : I64
	e1000_reg_extcnf_ctrl = 3840

	e1000_extcnf_sw_own : I64
	e1000_extcnf_sw_own = 32

	e1000_extcnf_hw_own : I64
	e1000_extcnf_hw_own = 64

	e1000_extcnf_mng_own : I64
	e1000_extcnf_mng_own = 128

	e1000_extcnf_own_mask : I64
	e1000_extcnf_own_mask = 224

	e1000_swflag_fuel : I64
	e1000_swflag_fuel = 64

	e1000_swflag_window_us : I64
	e1000_swflag_window_us = 100

	e1000_swflag_spin_fuel : I64
	e1000_swflag_spin_fuel = 32

	e1000_swflag_held! : Machine.Machine, I64 => (Machine.Machine, Bool)
	e1000_swflag_held! = |machine, mmio| ({
		(machine1, machine__45) = e1000_read!(machine, mmio, e1000_reg_extcnf_ctrl)
		(machine1, (I64.bitwise_and(machine__45, e1000_extcnf_sw_own) != 0))
	})

	e1000_swflag_request! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_swflag_request! = |machine, mmio| ({
		(machine1, cur) = e1000_read!(machine, mmio, e1000_reg_extcnf_ctrl)
		keep = I64.bitwise_and(cur, I64.bitwise_not(e1000_extcnf_own_mask))
		e1000_write!(machine1, mmio, e1000_reg_extcnf_ctrl, I64.bitwise_or(keep, e1000_extcnf_sw_own))
	})

	e1000_swflag_pause! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_swflag_pause! = |machine, mmio| ({
		(machine1, _started) = Hpet.hpet_start!(machine)
		(machine2, rate) = Hpet.hpet_ticks_per_second!(machine1)
		(if (rate <= 0) { e1000_settle_spin!(machine2, mmio, e1000_swflag_spin_fuel) } else { ({
			(machine3, machine__46) = Hpet.hpet_ticks!(machine2)
			e1000_await_ticks!(machine3, machine__46, I64.div_trunc_by((rate * e1000_swflag_window_us), 1000000), 0)
		}) })
	})

	e1000_swflag_acquire! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_swflag_acquire! = |machine, mmio, fuel| (if (fuel <= 0) { (machine, 0) } else { ({
		(machine1, _w) = e1000_swflag_request!(machine, mmio)
		({
			(machine2, machine__47) = e1000_swflag_held!(machine1, mmio)
			(if machine__47 { (machine2, 1) } else { ({
			(machine3, _d) = e1000_swflag_pause!(machine2, mmio)
			e1000_swflag_acquire!(machine3, mmio, (fuel - 1))
		}) })
		})
	}) })

	e1000_swflag_release! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_swflag_release! = |machine, mmio| ({
		(machine1, cur) = e1000_read!(machine, mmio, e1000_reg_extcnf_ctrl)
		e1000_write!(machine1, mmio, e1000_reg_extcnf_ctrl, I64.bitwise_and(cur, I64.bitwise_not(e1000_extcnf_own_mask)))
	})

	e1000_pch_swflag_required : Bool
	e1000_pch_swflag_required = True

	e1000_phy_pcie_pm_page : I64
	e1000_phy_pcie_pm_page = 770

	e1000_phy_pcie_pm_reg : I64
	e1000_phy_pcie_pm_reg = 17

	e1000_k1_giga_disable : I64
	e1000_k1_giga_disable = 8192

	e1000_k1_enable_bit : I64
	e1000_k1_enable_bit = 16384

	e1000_ulp_page : I64
	e1000_ulp_page = 779

	e1000_ulp_reg : I64
	e1000_ulp_reg = 16

	e1000_ulp_sticky : I64
	e1000_ulp_sticky = 16

	e1000_ulp_lanphypc : I64
	e1000_ulp_lanphypc = 1024

	e1000_ulp_entry_bits : I64
	e1000_ulp_entry_bits = 1040

	e1000_ulp_disable! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_ulp_disable! = |machine, mmio| ({
		(machine10, machine__51) = ({
		(machine1, _p) = e1000_phy_set_page!(machine, mmio, e1000_ulp_page)
		(machine2, v0) = e1000_phy_read!(machine1, mmio, e1000_ulp_reg)
		({
			(machine9, machine__50) = (if (v0 < 0) { ({
			(machine4, machine__48) = ({
			(machine3, _restore0) = e1000_phy_set_page!(machine2, mmio, 0)
			(machine3, (0 - 1))
		})
			(machine4, machine__48)
		}) } else { ({
			(machine8, machine__49) = ({
			v1 = I64.bitwise_and(v0, I64.bitwise_not(e1000_ulp_entry_bits))
			(machine5, _w) = e1000_phy_write!(machine2, mmio, e1000_ulp_reg, v1)
			(machine6, back) = e1000_phy_read!(machine5, mmio, e1000_ulp_reg)
			(machine7, _restore) = e1000_phy_set_page!(machine6, mmio, 0)
			(machine7, back)
		})
			(machine8, machine__49)
		}) })
			(machine9, machine__50)
		})
	})
		(machine10, machine__51)
	})

	e1000_pch_ulp_required : Bool
	e1000_pch_ulp_required = False

	e1000_ulp_step! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_ulp_step! = |machine, mmio, dev_id| ({
		(machine4, machine__54) = (if (e1000_pch_ulp_required == False) { (machine, 0) } else { ({
		(machine3, machine__53) = (if (e1000_pch_part(dev_id) == False) { (machine, 0) } else { ({
		(machine2, machine__52) = ({
		(machine1, v) = e1000_ulp_disable!(machine, mmio)
		(machine1, (if (v < 0) { (0 - 1) } else { (if (I64.bitwise_and(v, e1000_ulp_entry_bits) == 0) { 1 } else { 2 }) }))
	})
		(machine2, machine__52)
	}) })
		(machine3, machine__53)
	}) })
		(machine4, machine__54)
	})

	e1000_k1_configure! : Machine.Machine, I64, Bool => (Machine.Machine, I64)
	e1000_k1_configure! = |machine, mmio, enable| ({
		(machine6, machine__55) = ({
		(machine1, _p) = e1000_phy_set_page!(machine, mmio, e1000_phy_pcie_pm_page)
		(machine2, v0) = e1000_phy_read!(machine1, mmio, e1000_phy_pcie_pm_reg)
		v1 = (if enable { I64.bitwise_and(v0, I64.bitwise_not(e1000_k1_giga_disable)) } else { I64.bitwise_or(v0, e1000_k1_giga_disable) })
		(machine3, _w) = e1000_phy_write!(machine2, mmio, e1000_phy_pcie_pm_reg, v1)
		(machine4, back) = e1000_phy_read!(machine3, mmio, e1000_phy_pcie_pm_reg)
		(machine5, _restore) = e1000_phy_set_page!(machine4, mmio, 0)
		(machine5, back)
	})
		(machine6, machine__55)
	})

	e1000_pch_k1_required : Bool
	e1000_pch_k1_required = True

	e1000_k1_configure_guarded! : Machine.Machine, I64 => (Machine.Machine, E1000e.K1Step)
	e1000_k1_configure_guarded! = |machine, mmio| ({
		(machine6, machine__58) = (if (e1000_pch_swflag_required == False) { ({
		(machine1, machine__56) = e1000_k1_configure!(machine, mmio, False)
		(machine1, { k1_value: machine__56, k1_owned: True })
	}) } else { ({
		(machine5, machine__57) = ({
		(machine2, got) = e1000_swflag_acquire!(machine, mmio, e1000_swflag_fuel)
		(machine3, v) = e1000_k1_configure!(machine2, mmio, False)
		(machine4, _rel) = e1000_swflag_release!(machine3, mmio)
		(machine4, { k1_value: v, k1_owned: (got != 0) })
	})
		(machine5, machine__57)
	}) })
		(machine6, machine__58)
	})

	e1000_pch_prepare! : Machine.Machine, I64, I64, Bool => (Machine.Machine, I64)
	e1000_pch_prepare! = |machine, mmio, dev_id, do_k1| ({
		(machine4, machine__61) = (if (e1000_pch_part(dev_id) == False) { (machine, 0) } else { ({
		(machine3, machine__60) = (if (do_k1 == False) { (machine, 1) } else { ({
		(machine2, machine__59) = ({
		(machine1, step) = e1000_k1_configure_guarded!(machine, mmio)
		(machine1, (if (step.k1_value < 0) { (if step.k1_owned { 6 } else { 7 }) } else { ({
			stuck = (I64.bitwise_and(step.k1_value, e1000_k1_giga_disable) != 0)
			(if step.k1_owned { (if stuck { 3 } else { 2 }) } else { (if stuck { 5 } else { 4 }) })
		}) }))
	})
		(machine2, machine__59)
	}) })
		(machine3, machine__60)
	}) })
		(machine4, machine__61)
	})

	e1000_pch_lcd_reload_required : Bool
	e1000_pch_lcd_reload_required = False

	e1000_lcd_reload! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_lcd_reload! = |machine, mmio, dev_id| (if (e1000_pch_lcd_reload_required == False) { (machine, 0) } else { e1000_pch_prepare!(machine, mmio, dev_id, e1000_pch_k1_required) })

	e1000_init! : Machine.Machine, Pci.PciDevice => (Machine.Machine, E1000e.E1000Device)
	e1000_init! = |machine, pci_dev| ({
		(machine8, machine__64) = ({
		(machine1, _enabled) = Pci.pci_enable_device!(machine, pci_dev)
		(machine2, bar) = Pci.pci_parse_bar!(machine1, pci_dev.pci_bus, pci_dev.pci_dev, pci_dev.pci_func, 0)
		({
			(machine7, machine__63) = (if (e1000_bar_verdict(bar) != e1000_bar_ok) { (machine2, e1000_absent) } else { ({
			(machine6, machine__62) = ({
			(machine3, d) = e1000_init_at!(machine2, bar.bar_base)
			(machine4, ulp) = e1000_ulp_step!(machine3, bar.bar_base, pci_dev.pci_device_id)
			(machine5, pch) = e1000_pch_prepare!(machine4, bar.bar_base, pci_dev.pci_device_id, e1000_pch_k1_required)
			(machine5, { ..{ ..d, e_pch: pch }, e_ulp: ulp })
		})
			(machine6, machine__62)
		}) })
			(machine7, machine__63)
		})
	})
		(machine8, machine__64)
	})

	e1000_init_at! : Machine.Machine, I64 => (Machine.Machine, E1000e.E1000Device)
	e1000_init_at! = |machine, mmio| ({
		(machine1, machine__65) = e1000_reset!(machine, mmio)
		(if (machine__65 == 0) { (machine1, e1000_absent) } else { e1000_init_after_reset!(machine1, mmio) })
	})

	e1000_quiesce_ms : I64
	e1000_quiesce_ms = 10

	e1000_quiesce! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_quiesce! = |machine, mmio| ({
		(machine1, _r) = e1000_write!(machine, mmio, e1000_reg_rctl, 0)
		(machine2, _t) = e1000_write!(machine1, mmio, e1000_reg_tctl, 0)
		(machine3, _started) = Hpet.hpet_start!(machine2)
		(machine4, rate) = Hpet.hpet_ticks_per_second!(machine3)
		(if (rate <= 0) { e1000_settle_spin!(machine4, mmio, e1000_settle_spin_fuel) } else { ({
			(machine5, machine__66) = Hpet.hpet_ticks!(machine4)
			e1000_await_ticks!(machine5, machine__66, I64.div_trunc_by((rate * e1000_quiesce_ms), 1000), 0)
		}) })
	})

	e1000_init_after_reset! : Machine.Machine, I64 => (Machine.Machine, E1000e.E1000Device)
	e1000_init_after_reset! = |machine, mmio| ({
		(machine16, machine__67) = ({
		(machine1, _quiet) = e1000_quiesce!(machine, mmio)
		(machine2, rx_ring) = e1000_alloc_aligned!(machine1, (e1000_rx_count * e1000_desc_size), 16)
		(machine3, tx_ring) = e1000_alloc_aligned!(machine2, (e1000_tx_count * e1000_desc_size), 16)
		(machine4, rx_bufs) = e1000_alloc_aligned!(machine3, (e1000_rx_count * e1000_buf_size), 16)
		(machine5, tx_bufs) = e1000_alloc_aligned!(machine4, (e1000_tx_count * e1000_buf_size), 16)
		(machine6, ctrl_blk) = e1000_alloc_aligned!(machine5, e1000_cb_size, 8)
		(machine7, _cb_clear) = e1000_zero_words!(machine6, ctrl_blk, I64.div_trunc_by(e1000_cb_size, 4), 0)
		(machine8, _mta) = e1000_clear_mta!(machine7, mmio, 0)
		(machine9, mac_ok) = e1000_mac_present!(machine8, mmio)
		(machine10, mac) = (if mac_ok { e1000_read_mac!(machine9, mmio) } else { (machine9, []) })
		d = { e_mmio: mmio, e_rx_ring: rx_ring, e_tx_ring: tx_ring, e_rx_bufs: rx_bufs, e_tx_bufs: tx_bufs, e_ctrl_blk: ctrl_blk, e_present: True, e_mac: mac, e_mac_valid: mac_ok, e_pch: 0, e_ulp: 0 }
		(machine11, _rx) = e1000_setup_rx!(machine10, d)
		(machine12, _tx) = e1000_setup_tx!(machine11, d)
		(machine13, _sem) = (if e1000_pch_swflag_required { e1000_swflag_acquire!(machine12, mmio, e1000_swflag_fuel) } else { (machine12, 1) })
		(machine14, _link) = e1000_link_up!(machine13, mmio)
		(machine15, _rel) = (if e1000_pch_swflag_required { e1000_swflag_release!(machine14, mmio) } else { (machine14, 0) })
		(machine15, d)
	})
		(machine16, machine__67)
	})

	e1000_no_frame : E1000e.E1000RecvResult
	e1000_no_frame = { r_frame: [], r_has_frame: False }

	e1000_poll_frame! : Machine.Machine, E1000e.E1000Device => (Machine.Machine, E1000e.E1000RecvResult)
	e1000_poll_frame! = |machine, d| (if (d.e_present == False) { (machine, e1000_no_frame) } else { e1000_poll_raw!(machine, d.e_mmio, d.e_rx_ring, d.e_rx_bufs, d.e_ctrl_blk) })

	e1000_poll_raw! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, E1000e.E1000RecvResult)
	e1000_poll_raw! = |machine, mmio, rx_ring, rx_bufs, ctrl_blk| (if (mmio == 0) { (machine, e1000_no_frame) } else { ({
		(machine1, machine__68) = Machine.load!(machine, (ctrl_blk + e1000_cb_rx_next), 0, 4)
		idx = I64.bitwise_and(machine__68, 4294967295)
		desc = (rx_ring + (idx * e1000_desc_size))
		(machine2, status) = Machine.load!(machine1, desc, 12, 1)
		(if (I64.bitwise_and(status, e1000_rx_status_dd) == 0) { (machine2, e1000_no_frame) } else { e1000_take_frame!(machine2, mmio, rx_bufs, ctrl_blk, idx, desc, status) })
	}) })

	e1000_take_frame! : Machine.Machine, I64, I64, I64, I64, I64, I64 => (Machine.Machine, E1000e.E1000RecvResult)
	e1000_take_frame! = |machine, mmio, rx_bufs, ctrl_blk, idx, desc, status| ({
		(machine5, machine__71) = ({
		(machine1, machine__69) = Machine.load!(machine, desc, 8, 1)
		(machine2, machine__70) = Machine.load!(machine1, desc, 9, 1)
		len = I64.bitwise_or(machine__69, I64.shl_wrap(machine__70, I64.to_u8_wrap(8)))
		buf = (rx_bufs + (idx * e1000_buf_size))
		capped = (if (len > e1000_max_frame) { e1000_max_frame } else { len })
		whole = (I64.bitwise_and(status, e1000_rx_status_eop) != 0)
		(machine3, frame) = (if whole { e1000_read_bytes!(machine2, buf, 0, capped, []) } else { (machine2, []) })
		(machine4, _recycled) = e1000_recycle_rx!(machine3, mmio, ctrl_blk, idx, desc)
		(machine4, { r_frame: frame, r_has_frame: whole })
	})
		(machine5, machine__71)
	})

	e1000_recycle_rx! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	e1000_recycle_rx! = |machine, mmio, ctrl_blk, idx, desc| ({
		(machine1, _cleared) = Machine.store!(machine, (desc + 8), 0, 0, 4)
		(machine2, _top) = Machine.store!(machine1, (desc + 12), 0, 0, 4)
		next = Prelude.int_mod((idx + 1), e1000_rx_count)
		(machine3, _saved) = Machine.store!(machine2, (ctrl_blk + e1000_cb_rx_next), 0, next, 4)
		e1000_write!(machine3, mmio, e1000_reg_rdt, idx)
	})

	e1000_read_bytes! : Machine.Machine, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	e1000_read_bytes! = |machine, base, i, len, acc| (if (i >= len) { (machine, acc) } else { ({
		(machine1, machine__72) = Machine.load!(machine, base, i, 1)
		e1000_read_bytes!(machine1, base, (i + 1), len, List.append(acc, machine__72))
	}) })

	e1000_send_frame! : Machine.Machine, E1000e.E1000Device, List(I64) => (Machine.Machine, I64)
	e1000_send_frame! = |machine, d, frame| (if (d.e_present == False) { (machine, 0) } else { ({
		len = U64.to_i64_wrap(List.len(frame))
		(if (len <= 0) { (machine, 0) } else { (if (len > e1000_max_frame) { (machine, 0) } else { e1000_send_at!(machine, d, frame, len) }) })
	}) })

	e1000_send_at! : Machine.Machine, E1000e.E1000Device, List(I64), I64 => (Machine.Machine, I64)
	e1000_send_at! = |machine, d, frame, len| ({
		(machine1, machine__73) = Machine.load!(machine, (d.e_ctrl_blk + e1000_cb_tx_next), 0, 4)
		idx = I64.bitwise_and(machine__73, 4294967295)
		desc = (d.e_tx_ring + (idx * e1000_desc_size))
		buf = (d.e_tx_bufs + (idx * e1000_buf_size))
		(machine2, _staged) = e1000_write_bytes!(machine1, buf, frame, 0, len)
		(machine3, _lo) = Machine.store!(machine2, desc, 0, I64.bitwise_and(buf, 4294967295), 4)
		(machine4, _hi) = Machine.store!(machine3, (desc + 4), 0, I64.shr_zf_wrap(buf, I64.to_u8_wrap(32)), 4)
		(machine5, _mid) = Machine.store!(machine4, (desc + 8), 0, I64.bitwise_or(I64.bitwise_and(len, 65535), I64.shl_wrap(e1000_tx_cmd_all, I64.to_u8_wrap(24))), 4)
		(machine6, _top) = Machine.store!(machine5, (desc + 12), 0, 0, 4)
		next = Prelude.int_mod((idx + 1), e1000_tx_count)
		(machine7, _saved) = Machine.store!(machine6, (d.e_ctrl_blk + e1000_cb_tx_next), 0, next, 4)
		(machine8, _kick) = e1000_write!(machine7, d.e_mmio, e1000_reg_tdt, next)
		e1000_await_tx!(machine8, desc)
	})

	e1000_tx_cmd_all : I64
	e1000_tx_cmd_all = I64.bitwise_or(e1000_tx_cmd_eop, I64.bitwise_or(e1000_tx_cmd_ifcs, e1000_tx_cmd_rs))

	e1000_tx_fuel : I64
	e1000_tx_fuel = 1000000

	e1000_tx_window_ms : I64
	e1000_tx_window_ms = 20

	e1000_tx_batch : I64
	e1000_tx_batch = 4096

	e1000_tx_batch_fuel : I64
	e1000_tx_batch_fuel = 100000

	e1000_await_tx_batch! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_await_tx_batch! = |machine, desc, i| (if (i <= 0) { (machine, 0) } else { ({
		(machine1, machine__74) = Machine.load!(machine, desc, 12, 1)
		(if (I64.bitwise_and(machine__74, e1000_tx_status_dd) != 0) { (machine1, 1) } else { e1000_await_tx_batch!(machine1, desc, (i - 1)) })
	}) })

	e1000_await_tx_clocked! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	e1000_await_tx_clocked! = |machine, desc, start, want, fuel| ({
		(machine1, machine__75) = e1000_await_tx_batch!(machine, desc, e1000_tx_batch)
		(if (machine__75 == 1) { (machine1, 1) } else { (if (fuel <= 0) { (machine1, 0) } else { ({
		(machine2, machine__76) = Hpet.hpet_ticks!(machine1)
		(if ((machine__76 - start) >= want) { (machine2, 0) } else { e1000_await_tx_clocked!(machine2, desc, start, want, (fuel - 1)) })
	}) }) })
	})

	e1000_await_tx_spin! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	e1000_await_tx_spin! = |machine, desc, i| (if (i >= e1000_tx_fuel) { (machine, 0) } else { ({
		(machine1, machine__77) = Machine.load!(machine, desc, 12, 1)
		(if (I64.bitwise_and(machine__77, e1000_tx_status_dd) != 0) { (machine1, 1) } else { e1000_await_tx_spin!(machine1, desc, (i + 1)) })
	}) })

	e1000_await_tx! : Machine.Machine, I64 => (Machine.Machine, I64)
	e1000_await_tx! = |machine, desc| ({
		(machine1, _started) = Hpet.hpet_start!(machine)
		(machine2, rate) = Hpet.hpet_ticks_per_second!(machine1)
		(if (rate <= 0) { e1000_await_tx_spin!(machine2, desc, 0) } else { ({
			(machine3, machine__78) = Hpet.hpet_ticks!(machine2)
			e1000_await_tx_clocked!(machine3, desc, machine__78, I64.div_trunc_by((rate * e1000_tx_window_ms), 1000), e1000_tx_batch_fuel)
		}) })
	})

	e1000_write_bytes! : Machine.Machine, I64, List(I64), I64, I64 => (Machine.Machine, I64)
	e1000_write_bytes! = |machine, base, bs, i, len| (if (i >= len) { (machine, 0) } else { ({
		(machine1, _w) = Machine.store!(machine, base, i, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1)
		e1000_write_bytes!(machine1, base, bs, (i + 1), len)
	}) })
}
