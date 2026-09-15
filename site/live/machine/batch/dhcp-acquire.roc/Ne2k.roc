# Ne2k -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Machine
import Prelude

Ne2k :: [].{

	ne2k_max_frame : I64
	ne2k_max_frame = 1536

	ne2k_cr_port : I64
	ne2k_cr_port = 768

	ne2k_tpsr_port : I64
	ne2k_tpsr_port = 772

	ne2k_tbcr0_port : I64
	ne2k_tbcr0_port = 773

	ne2k_tbcr1_port : I64
	ne2k_tbcr1_port = 774

	ne2k_isr_port : I64
	ne2k_isr_port = 775

	ne2k_rsar0_port : I64
	ne2k_rsar0_port = 776

	ne2k_rsar1_port : I64
	ne2k_rsar1_port = 777

	ne2k_rbcr0_port : I64
	ne2k_rbcr0_port = 778

	ne2k_rbcr1_port : I64
	ne2k_rbcr1_port = 779

	ne2k_data_port : I64
	ne2k_data_port = 784

	ne2k_tx_page : I64
	ne2k_tx_page = 64

	ne2k_tx_buf : I64
	ne2k_tx_buf = 34592

	ne2k_stage_frame! : Machine.Machine, List(I64), I64, I64 => (Machine.Machine, I64)
	ne2k_stage_frame! = |machine, bs, i, len| (if (i >= len) { (machine, i) } else { ({
		(machine1, _w) = Machine.store!(machine, ne2k_tx_buf, i, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1)
		ne2k_stage_frame!(machine1, bs, (i + 1), len)
	}) })

	ne2k_send_frame! : Machine.Machine, List(I64) => (Machine.Machine, I64)
	ne2k_send_frame! = |machine, frame| ({
		len = U64.to_i64_wrap(List.len(frame))
		(if (len > ne2k_max_frame) { (machine, 0) } else { ({
			(machine1, _staged) = ne2k_stage_frame!(machine, frame, 0, len)
			(machine2, _pad) = (if (Prelude.int_mod(len, 2) == 1) { Machine.store!(machine1, ne2k_tx_buf, len, 0, 1) } else { (machine1, 0) })
			Machine.net_send_raw!(machine2, ne2k_tx_buf, (len + Prelude.int_mod(len, 2)))
		}) })
	})

	ne2k_recv_frame! : Machine.Machine => (Machine.Machine, List(I64))
	ne2k_recv_frame! = |machine| ({
		(machine1, len) = Machine.net_recv_raw!(machine, 33056)
		(if (len <= 0) { (machine1, []) } else { ne2k_read_from_buf!(machine1, 33056, 0, len, []) })
	})

	ne2k_read_from_buf! : Machine.Machine, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	ne2k_read_from_buf! = |machine, base, i, len, acc| (if (i >= len) { (machine, acc) } else { ({
		(machine1, machine__1) = Machine.load!(machine, base, i, 1)
		ne2k_read_from_buf!(machine1, base, (i + 1), len, List.append(acc, machine__1))
	}) })

	ne2k_available! : Machine.Machine => (Machine.Machine, Bool)
	ne2k_available! = |machine| ({
		(machine1, machine__2) = Machine.net_status(machine)
		(machine1, (machine__2 > 0))
	})
}
