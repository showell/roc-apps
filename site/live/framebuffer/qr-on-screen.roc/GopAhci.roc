# GopAhci -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem
import Pci

GopAhci :: [].{
	AhciHba : { hba_ok : Bool, hba_abar : I64, hba_port : I64 }
	AhciRead : { ar_ok : Bool, ar_buf : I64 }

	ahci_ghc : I64
	ahci_ghc = 4

	ahci_pi : I64
	ahci_pi = 12

	ahci_ghc_ae : I64
	ahci_ghc_ae = 2147483648

	ahci_port_base : I64
	ahci_port_base = 256

	ahci_port_size : I64
	ahci_port_size = 128

	px_clb : I64
	px_clb = 0

	px_clbu : I64
	px_clbu = 4

	px_fb : I64
	px_fb = 8

	px_fbu : I64
	px_fbu = 12

	px_is : I64
	px_is = 16

	px_cmd : I64
	px_cmd = 24

	px_tfd : I64
	px_tfd = 32

	px_sig : I64
	px_sig = 36

	px_ssts : I64
	px_ssts = 40

	px_serr : I64
	px_serr = 48

	px_ci : I64
	px_ci = 56

	px_cmd_st : I64
	px_cmd_st = 1

	px_cmd_fre : I64
	px_cmd_fre = 16

	px_cmd_fr : I64
	px_cmd_fr = 16384

	px_cmd_cr : I64
	px_cmd_cr = 32768

	px_tfd_drq : I64
	px_tfd_drq = 8

	px_tfd_bsy : I64
	px_tfd_bsy = 128

	px_is_tfes : I64
	px_is_tfes = 1073741824

	sata_sig_disk : I64
	sata_sig_disk = 257

	all_ones : I64
	all_ones = 4294967295

	ahci_cmd_read : I64
	ahci_cmd_read = 37

	ahci_cmd_write : I64
	ahci_cmd_write = 53

	ahci_cmd_identify : I64
	ahci_cmd_identify = 236

	ahci_fuel : I64
	ahci_fuel = 1000000

	clear_bit : I64, I64 -> I64
	clear_bit = |v, b| (if (I64.bitwise_and(v, b) != 0) { (v - b) } else { v })

	align_up : I64, I64 -> I64
	align_up = |v, a| ({
		m = (a - 1)
		((v + m) - I64.bitwise_and((v + m), m))
	})

	alloc_zeroed! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	alloc_zeroed! = |mem, size, align| ({
		(mem4, mem__26) = ({
		(mem1, raw) = Mem.mark(mem)
		(mem2, _adv) = Mem.advance(mem1, (size + align))
		base = align_up(raw, align)
		(mem3, _z) = zero_dwords!(mem2, base, 0, I64.div_trunc_by(size, 4))
		(mem3, base)
	})
		(mem4, mem__26)
	})

	zero_dwords! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	zero_dwords! = |mem, addr, i, n| (if (i >= n) { (mem, 0) } else { ({
		(mem1, _p) = Mem.store!(mem, addr, (i * 4), 0, 4)
		zero_dwords!(mem1, addr, (i + 1), n)
	}) })

	ahci_no_hba : GopAhci.AhciHba
	ahci_no_hba = { hba_ok: False, hba_abar: 0, hba_port: 0 }

	ahci_enable! : Mem.Mem, Pci.PciDevice => (Mem.Mem, I64)
	ahci_enable! = |_, _| crash("`ahci-enable` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	ahci_find! : Mem.Mem => (Mem.Mem, GopAhci.AhciHba)
	ahci_find! = |_| crash("`ahci-find` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	ahci_find_nth! : Mem.Mem, I64 => (Mem.Mem, GopAhci.AhciHba)
	ahci_find_nth! = |_, _| crash("`ahci-find-nth` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	ahci_init_device! : Mem.Mem, Pci.PciDevice, I64 => (Mem.Mem, GopAhci.AhciHba)
	ahci_init_device! = |_, _, _| crash("`ahci-init-device` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	port_addr : I64, I64 -> I64
	port_addr = |abar, port| ((abar + ahci_port_base) + (port * ahci_port_size))

	ahci_pick_nth! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	ahci_pick_nth! = |mem, abar, pi, i, n| (if (i >= 32) { (mem, (-1)) } else { (if (I64.bitwise_and(I64.shr_zf_wrap(pi, I64.to_u8_wrap(i)), 1) == 0) { ahci_pick_nth!(mem, abar, pi, (i + 1), n) } else { ({
		p = port_addr(abar, i)
		(mem1, mem__27) = Mem.load!(mem, p, px_ssts, 4)
		det = I64.bitwise_and(mem__27, 15)
		(if (det != 3) { ahci_pick_nth!(mem1, abar, pi, (i + 1), n) } else { ({
			(mem2, mem__28) = Mem.load!(mem1, p, px_sig, 4)
			(if (mem__28 != sata_sig_disk) { ahci_pick_nth!(mem2, abar, pi, (i + 1), n) } else { (if (n > 0) { ahci_pick_nth!(mem2, abar, pi, (i + 1), (n - 1)) } else { (mem2, i) }) })
		}) })
	}) }) })

	ahci_wait_clear! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	ahci_wait_clear! = |mem, p, reg, mask, fuel| ({
		(mem1, mem__29) = Mem.load!(mem, p, reg, 4)
		(if (I64.bitwise_and(mem__29, mask) == 0) { (mem1, 1) } else { (if (fuel <= 0) { (mem1, 0) } else { ahci_wait_clear!(mem1, p, reg, mask, (fuel - 1)) }) })
	})

	ahci_stop_port! : Mem.Mem, I64 => (Mem.Mem, I64)
	ahci_stop_port! = |mem, p| ({
		(mem1, c0) = Mem.load!(mem, p, px_cmd, 4)
		(mem2, _w0) = Mem.store!(mem1, p, px_cmd, clear_bit(c0, px_cmd_st), 4)
		(mem3, _a) = ahci_wait_clear!(mem2, p, px_cmd, px_cmd_cr, ahci_fuel)
		(mem4, c1) = Mem.load!(mem3, p, px_cmd, 4)
		(mem5, _w1) = Mem.store!(mem4, p, px_cmd, clear_bit(c1, px_cmd_fre), 4)
		ahci_wait_clear!(mem5, p, px_cmd, px_cmd_fr, ahci_fuel)
	})

	ahci_start_port! : Mem.Mem, I64 => (Mem.Mem, I64)
	ahci_start_port! = |mem, p| ({
		(mem1, _a) = ahci_wait_clear!(mem, p, px_cmd, px_cmd_cr, ahci_fuel)
		(mem2, c0) = Mem.load!(mem1, p, px_cmd, 4)
		(mem3, _w0) = Mem.store!(mem2, p, px_cmd, I64.bitwise_or(c0, px_cmd_fre), 4)
		(mem4, c1) = Mem.load!(mem3, p, px_cmd, 4)
		Mem.store!(mem4, p, px_cmd, I64.bitwise_or(c1, px_cmd_st), 4)
	})

	ahci_write_header_w! : Mem.Mem, I64, I64, Bool => (Mem.Mem, I64)
	ahci_write_header_w! = |mem, clb, ctba, is_write| ({
		(mem1, _d0) = Mem.store!(mem, clb, 0, ((5 + 65536) + (if is_write { 64 } else { 0 })), 4)
		(mem2, _d1) = Mem.store!(mem1, clb, 4, 0, 4)
		(mem3, _d2) = Mem.store!(mem2, clb, 8, ctba, 4)
		Mem.store!(mem3, clb, 12, 0, 4)
	})

	ahci_write_header! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	ahci_write_header! = |mem, clb, ctba| ahci_write_header_w!(mem, clb, ctba, False)

	ahci_write_fis_cmd! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	ahci_write_fis_cmd! = |mem, ctba, lba, count, cmd| ({
		(mem1, _d0) = Mem.store!(mem, ctba, 0, I64.bitwise_or(32807, I64.shl_wrap(I64.bitwise_and(cmd, 255), I64.to_u8_wrap(16))), 4)
		(mem2, _d1) = Mem.store!(mem1, ctba, 4, I64.bitwise_or(I64.bitwise_and(lba, 255), I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(I64.shr_zf_wrap(lba, I64.to_u8_wrap(8)), 255), I64.to_u8_wrap(8)), I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(I64.shr_zf_wrap(lba, I64.to_u8_wrap(16)), 255), I64.to_u8_wrap(16)), 1073741824))), 4)
		(mem3, _d2) = Mem.store!(mem2, ctba, 8, I64.bitwise_or(I64.bitwise_and(I64.shr_zf_wrap(lba, I64.to_u8_wrap(24)), 255), I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(I64.shr_zf_wrap(lba, I64.to_u8_wrap(32)), 255), I64.to_u8_wrap(8)), I64.shl_wrap(I64.bitwise_and(I64.shr_zf_wrap(lba, I64.to_u8_wrap(40)), 255), I64.to_u8_wrap(16)))), 4)
		(mem4, _d3) = Mem.store!(mem3, ctba, 12, I64.bitwise_and(count, 65535), 4)
		Mem.store!(mem4, ctba, 16, 0, 4)
	})

	ahci_write_fis_n! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	ahci_write_fis_n! = |mem, ctba, lba, count| ahci_write_fis_cmd!(mem, ctba, lba, count, ahci_cmd_read)

	ahci_write_fis! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	ahci_write_fis! = |mem, ctba, lba| ahci_write_fis_n!(mem, ctba, lba, 1)

	ahci_write_prdt_n! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	ahci_write_prdt_n! = |mem, ctba, buf, bytes| ({
		(mem1, _d0) = Mem.store!(mem, ctba, 128, buf, 4)
		(mem2, _d1) = Mem.store!(mem1, ctba, 132, 0, 4)
		(mem3, _d2) = Mem.store!(mem2, ctba, 136, 0, 4)
		Mem.store!(mem3, ctba, 140, ((bytes - 1) + 2147483648), 4)
	})

	ahci_write_prdt! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	ahci_write_prdt! = |mem, ctba, buf| ahci_write_prdt_n!(mem, ctba, buf, 512)

	ahci_wait_ci! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	ahci_wait_ci! = |mem, p, slot_mask, fuel| ({
		(mem1, mem__30) = Mem.load!(mem, p, px_ci, 4)
		(if (I64.bitwise_and(mem__30, slot_mask) == 0) { (mem1, 1) } else { ({
		(mem2, mem__31) = Mem.load!(mem1, p, px_is, 4)
		(if (I64.bitwise_and(mem__31, px_is_tfes) != 0) { (mem2, 0) } else { (if (fuel <= 0) { (mem2, 0) } else { ahci_wait_ci!(mem2, p, slot_mask, (fuel - 1)) }) })
	}) })
	})

	ahci_quiesce! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	ahci_quiesce! = |mem, p, result| ({
		(mem2, mem__32) = ({
		(mem1, _q) = ahci_stop_port!(mem, p)
		(mem1, result)
	})
		(mem2, mem__32)
	})

	ahci_issue_on! : Mem.Mem, GopAhci.AhciHba, I64, I64, I64, I64, Bool => (Mem.Mem, I64)
	ahci_issue_on! = |mem, hba, lba, count, mem_, cmd, is_write| ({
		p = port_addr(hba.hba_abar, hba.hba_port)
		(mem1, stopped) = ahci_stop_port!(mem, p)
		(if (stopped == 0) { (mem1, 0) } else { ({
			(mem2, clb) = alloc_zeroed!(mem1, 1024, 1024)
			(mem3, fb) = alloc_zeroed!(mem2, 256, 256)
			(mem4, ctba) = alloc_zeroed!(mem3, 256, 128)
			(mem5, _s1) = Mem.store!(mem4, p, px_clb, clb, 4)
			(mem6, _s2) = Mem.store!(mem5, p, px_clbu, 0, 4)
			(mem7, _s3) = Mem.store!(mem6, p, px_fb, fb, 4)
			(mem8, _s4) = Mem.store!(mem7, p, px_fbu, 0, 4)
			(mem9, _s5) = Mem.store!(mem8, p, px_serr, all_ones, 4)
			(mem10, _s6) = Mem.store!(mem9, p, px_is, all_ones, 4)
			(mem11, _started) = ahci_start_port!(mem10, p)
			(mem12, _h) = ahci_write_header_w!(mem11, clb, ctba, is_write)
			(mem13, _f) = ahci_write_fis_cmd!(mem12, ctba, lba, count, cmd)
			(mem14, _r) = ahci_write_prdt_n!(mem13, ctba, mem_, (count * 512))
			(mem15, idle) = ahci_wait_clear!(mem14, p, px_tfd, I64.bitwise_or(px_tfd_bsy, px_tfd_drq), ahci_fuel)
			(if (idle == 0) { ahci_quiesce!(mem15, p, 0) } else { ({
				(mem16, _issue) = Mem.store!(mem15, p, px_ci, 1, 4)
				(mem17, done) = ahci_wait_ci!(mem16, p, 1, (ahci_fuel * 16))
				ahci_quiesce!(mem17, p, done)
			}) })
		}) })
	})

	ahci_read_into_on! : Mem.Mem, GopAhci.AhciHba, I64, I64, I64 => (Mem.Mem, I64)
	ahci_read_into_on! = |mem, hba, lba, count, dest| ahci_issue_on!(mem, hba, lba, count, dest, ahci_cmd_read, False)

	ahci_identify_on! : Mem.Mem, GopAhci.AhciHba, I64 => (Mem.Mem, I64)
	ahci_identify_on! = |mem, hba, buf| ahci_issue_on!(mem, hba, 0, 1, buf, ahci_cmd_identify, False)

	ahci_read_into! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	ahci_read_into! = |_, _, _, _| crash("`ahci-read-into` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	ahci_write_into! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	ahci_write_into! = |_, _, _, _| crash("`ahci-write-into` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	ahci_read_sector_on! : Mem.Mem, GopAhci.AhciHba, I64 => (Mem.Mem, GopAhci.AhciRead)
	ahci_read_sector_on! = |mem, hba, lba| ({
		(mem3, mem__33) = ({
		(mem1, buf) = alloc_zeroed!(mem, 512, 512)
		(mem2, ok) = ahci_read_into_on!(mem1, hba, lba, 1, buf)
		(mem2, (if (ok == 0) { { ar_ok: False, ar_buf: 0 } } else { { ar_ok: True, ar_buf: buf } }))
	})
		(mem3, mem__33)
	})

	ahci_read_sector! : Mem.Mem, I64 => (Mem.Mem, GopAhci.AhciRead)
	ahci_read_sector! = |_, _| crash("`ahci-read-sector` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")
}
