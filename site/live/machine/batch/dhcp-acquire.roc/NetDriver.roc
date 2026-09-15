# NetDriver -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import E1000e
import Hpet
import Machine
import Ne2k
import Pci

NetDriver :: [].{

	net_driver_cb : I64
	net_driver_cb = 36264

	net_driver_off_card : I64
	net_driver_off_card = 0

	net_driver_off_mmio : I64
	net_driver_off_mmio = 8

	net_driver_off_rx_ring : I64
	net_driver_off_rx_ring = 16

	net_driver_off_rx_bufs : I64
	net_driver_off_rx_bufs = 24

	net_driver_off_ctrl_blk : I64
	net_driver_off_ctrl_blk = 32

	net_driver_off_tx_ring : I64
	net_driver_off_tx_ring = 40

	net_driver_off_tx_bufs : I64
	net_driver_off_tx_bufs = 48

	net_card_ne2k : I64
	net_card_ne2k = 0

	net_card_e1000 : I64
	net_card_e1000 = 1

	net_driver_cell! : Machine.Machine, I64 => (Machine.Machine, I64)
	net_driver_cell! = |machine, off| ({
		(machine1, machine__79) = Machine.load!(machine, (net_driver_cb + off), 0, 4)
		(machine1, I64.bitwise_and(machine__79, 4294967295))
	})

	net_driver_active! : Machine.Machine => (Machine.Machine, I64)
	net_driver_active! = |machine| net_driver_cell!(machine, net_driver_off_card)

	net_driver_bind_e1000! : Machine.Machine, E1000e.E1000Device => (Machine.Machine, I64)
	net_driver_bind_e1000! = |machine, d| ({
		(machine10, machine__82) = (if (d.e_present == False) { (machine, net_card_ne2k) } else { ({
		(machine9, machine__81) = (if (d.e_mac_valid == False) { (machine, net_card_ne2k) } else { ({
		(machine8, machine__80) = ({
		(machine1, _w1) = Machine.store!(machine, (net_driver_cb + net_driver_off_mmio), 0, d.e_mmio, 4)
		(machine2, _w2) = Machine.store!(machine1, (net_driver_cb + net_driver_off_rx_ring), 0, d.e_rx_ring, 4)
		(machine3, _w3) = Machine.store!(machine2, (net_driver_cb + net_driver_off_rx_bufs), 0, d.e_rx_bufs, 4)
		(machine4, _w4) = Machine.store!(machine3, (net_driver_cb + net_driver_off_ctrl_blk), 0, d.e_ctrl_blk, 4)
		(machine5, _w5) = Machine.store!(machine4, (net_driver_cb + net_driver_off_tx_ring), 0, d.e_tx_ring, 4)
		(machine6, _w6) = Machine.store!(machine5, (net_driver_cb + net_driver_off_tx_bufs), 0, d.e_tx_bufs, 4)
		(machine7, _sel) = Machine.store!(machine6, (net_driver_cb + net_driver_off_card), 0, net_card_e1000, 4)
		(machine7, net_card_e1000)
	})
		(machine8, machine__80)
	}) })
		(machine9, machine__81)
	}) })
		(machine10, machine__82)
	})

	net_driver_bring_up! : Machine.Machine => (Machine.Machine, I64)
	net_driver_bring_up! = |machine| ({
		(machine3, card) = ({
			(machine1, machine__83) = Pci.pci_scan_all!(machine)
			(match E1000e.e1000_find(machine__83) {
			Just(d) => ({
				(machine2, machine__84) = E1000e.e1000_init!(machine1, d)
				net_driver_bind_e1000!(machine2, machine__84)
			})
			None => (machine1, net_card_ne2k)
		})
		})
		({
			(machine4, p) = net_driver_calibrate!(machine3)
			({
				(machine6, machine__85) = ({
				(machine5, _w) = Machine.store!(machine4, net_driver_poll_cell, 0, p, 4)
				(machine5, card)
			})
				(machine6, machine__85)
			})
		})
	})

	net_driver_poll_cell : I64
	net_driver_poll_cell = 36328

	net_driver_tick_ms : I64
	net_driver_tick_ms = 100

	net_driver_poll_fallback : I64
	net_driver_poll_fallback = 100000

	net_driver_poll_floor : I64
	net_driver_poll_floor = 1000

	net_driver_cal_batch : I64
	net_driver_cal_batch = 1000

	net_driver_cal_fuel : I64
	net_driver_cal_fuel = 200000

	net_driver_poll_batch! : Machine.Machine, I64 => (Machine.Machine, I64)
	net_driver_poll_batch! = |machine, n| (if (n <= 0) { (machine, 0) } else { ({
		(machine1, hp) = Machine.mark(machine)
		({
			(machine2, _f) = net_driver_recv_frame!(machine1)
			({
				(machine3, _r) = Machine.release(machine2, hp)
				net_driver_poll_batch!(machine3, (n - 1))
			})
		})
	}) })

	net_driver_cal_loop! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	net_driver_cal_loop! = |machine, deadline, n, fuel| (if (fuel <= 0) { (machine, n) } else { ({
		(machine1, machine__86) = Hpet.hpet_ticks!(machine)
		(if (machine__86 >= deadline) { (machine1, n) } else { ({
		(machine2, _z) = net_driver_poll_batch!(machine1, net_driver_cal_batch)
		net_driver_cal_loop!(machine2, deadline, (n + net_driver_cal_batch), (fuel - 1))
	}) })
	}) })

	net_driver_calibrate! : Machine.Machine => (Machine.Machine, I64)
	net_driver_calibrate! = |machine| ({
		(machine1, _started) = Hpet.hpet_start!(machine)
		(machine2, rate) = Hpet.hpet_ticks_per_second!(machine1)
		(if (rate <= 0) { (machine2, net_driver_poll_fallback) } else { ({
			(machine3, machine__87) = Hpet.hpet_ticks!(machine2)
			deadline = (machine__87 + I64.div_trunc_by((rate * net_driver_tick_ms), 1000))
			({
				(machine4, n) = net_driver_cal_loop!(machine3, deadline, 0, net_driver_cal_fuel)
				(machine4, (if (n < net_driver_poll_floor) { net_driver_poll_floor } else { n }))
			})
		}) })
	})

	net_driver_cal_max : I64
	net_driver_cal_max = (net_driver_cal_fuel * net_driver_cal_batch)

	net_driver_poll_interval! : Machine.Machine => (Machine.Machine, I64)
	net_driver_poll_interval! = |machine| ({
		(machine2, machine__89) = ({
		(machine1, machine__88) = Machine.load!(machine, net_driver_poll_cell, 0, 4)
		v = I64.bitwise_and(machine__88, 4294967295)
		(machine1, (if (v < net_driver_poll_floor) { net_driver_poll_fallback } else { (if (v > net_driver_cal_max) { net_driver_poll_fallback } else { v }) }))
	})
		(machine2, machine__89)
	})

	net_driver_card_name : I64 -> Str
	net_driver_card_name = |c| (if (c == net_card_e1000) { "e1000" } else { "ne2000" })

	net_driver_ne2k_mac : List(I64)
	net_driver_ne2k_mac = [82, 84, 0, 18, 52, 86]

	net_driver_mac! : Machine.Machine => (Machine.Machine, List(I64))
	net_driver_mac! = |machine| ({
		(machine1, machine__90) = net_driver_active!(machine)
		(if (machine__90 == net_card_e1000) { ({
		(machine2, machine__91) = net_driver_cell!(machine1, net_driver_off_mmio)
		E1000e.e1000_read_mac!(machine2, machine__91)
	}) } else { (machine1, net_driver_ne2k_mac) })
	})

	net_driver_e1000_device! : Machine.Machine => (Machine.Machine, E1000e.E1000Device)
	net_driver_e1000_device! = |machine| ({
		(machine1, machine__92) = net_driver_cell!(machine, net_driver_off_mmio)
		(machine2, machine__93) = net_driver_cell!(machine1, net_driver_off_rx_ring)
		(machine3, machine__94) = net_driver_cell!(machine2, net_driver_off_tx_ring)
		(machine4, machine__95) = net_driver_cell!(machine3, net_driver_off_rx_bufs)
		(machine5, machine__96) = net_driver_cell!(machine4, net_driver_off_tx_bufs)
		(machine6, machine__97) = net_driver_cell!(machine5, net_driver_off_ctrl_blk)
		(machine6, { e_mmio: machine__92, e_rx_ring: machine__93, e_tx_ring: machine__94, e_rx_bufs: machine__95, e_tx_bufs: machine__96, e_ctrl_blk: machine__97, e_present: True, e_mac: [], e_mac_valid: False, e_pch: 0, e_ulp: 0 })
	})

	net_driver_send_frame! : Machine.Machine, List(I64) => (Machine.Machine, I64)
	net_driver_send_frame! = |machine, frame| ({
		(machine1, machine__98) = net_driver_active!(machine)
		(if (machine__98 == net_card_e1000) { ({
		(machine2, machine__99) = net_driver_e1000_device!(machine1)
		E1000e.e1000_send_frame!(machine2, machine__99, frame)
	}) } else { Ne2k.ne2k_send_frame!(machine1, frame) })
	})

	net_driver_recv_frame! : Machine.Machine => (Machine.Machine, List(I64))
	net_driver_recv_frame! = |machine| ({
		(machine1, machine__100) = net_driver_active!(machine)
		(if (machine__100 == net_card_e1000) { ({
		(machine2, machine__101) = net_driver_cell!(machine1, net_driver_off_mmio)
		(machine3, machine__102) = net_driver_cell!(machine2, net_driver_off_rx_ring)
		(machine4, machine__103) = net_driver_cell!(machine3, net_driver_off_rx_bufs)
		(machine5, machine__104) = net_driver_cell!(machine4, net_driver_off_ctrl_blk)
		(machine6, machine__105) = E1000e.e1000_poll_raw!(machine5, machine__101, machine__102, machine__103, machine__104)
		(machine6, machine__105.r_frame)
	}) } else { Ne2k.ne2k_recv_frame!(machine1) })
	})
}
