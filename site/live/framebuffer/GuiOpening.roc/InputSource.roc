# InputSource -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Event
import Machine

InputSource :: [].{
	RawInput : { ri_mx : I64, ri_my : I64, ri_left : I64, ri_right : I64, ri_middle : I64, ri_key : I64, ri_prev_mx : I64, ri_prev_my : I64, ri_prev_left : I64, ri_prev_right : I64, ri_prev_middle : I64, ri_prev_key : I64, ri_max_x : I64, ri_max_y : I64 }

	is_kb_addr : I64
	is_kb_addr = 28680

	ptr_cells : I64
	ptr_cells = 36736

	ptr_cells_magic : I64
	ptr_cells_magic = 827479120

	raw_input_new : I64, I64 -> InputSource.RawInput
	raw_input_new = |w, h| { ri_mx: I64.div_trunc_by(w, 2), ri_my: I64.div_trunc_by(h, 2), ri_left: 0, ri_right: 0, ri_middle: 0, ri_key: 0, ri_prev_mx: I64.div_trunc_by(w, 2), ri_prev_my: I64.div_trunc_by(h, 2), ri_prev_left: 0, ri_prev_right: 0, ri_prev_middle: 0, ri_prev_key: 0, ri_max_x: (w - 1), ri_max_y: (h - 1) }

	raw_input_poll! : Machine.Machine, InputSource.RawInput => (Machine.Machine, InputSource.RawInput)
	raw_input_poll! = |machine, ri| ({
		(machine1, sc) = ri_take_key!(machine)
		(machine2, mp) = ri_pointer_published!(machine1)
		(machine3, e4) = (if (mp == 1) { (machine2, 255) } else { Machine.port_in_byte!(machine2, 228) })
		(machine4, btn) = (if (mp == 1) { Machine.load!(machine3, ptr_cells, 12, 4) } else { (if (e4 == 255) { (machine3, 0) } else { Machine.port_in_byte!(machine3, 225) }) })
		(machine5, abs_x) = (if (mp == 1) { Machine.load!(machine4, ptr_cells, 4, 4) } else { (if (e4 == 1) { Machine.port_in_16!(machine4, 226) } else { (machine4, ri.ri_mx) }) })
		(machine6, abs_y) = (if (mp == 1) { Machine.load!(machine5, ptr_cells, 8, 4) } else { (if (e4 == 1) { Machine.port_in_16!(machine5, 227) } else { (machine5, ri.ri_my) }) })
		(machine6, ri_build(ri, sc, btn, abs_x, abs_y))
	})

	ri_take_key! : Machine.Machine => (Machine.Machine, I64)
	ri_take_key! = |machine| ({
		(machine1, machine__5) = Machine.exchange!(machine, is_kb_addr, 0)
		(machine1, I64.bitwise_and(machine__5, 255))
	})

	ri_pointer_published! : Machine.Machine => (Machine.Machine, I64)
	ri_pointer_published! = |machine| ({
		(machine1, machine__6) = Machine.load!(machine, ptr_cells, 0, 4)
		(machine1, (if (machine__6 == ptr_cells_magic) { 1 } else { 0 }))
	})

	ri_mouse_flag : I64 -> I64
	ri_mouse_flag = |hm| (if (hm == 0) { 0 } else { (if (hm == 255) { 0 } else { 1 }) })

	ri_build : InputSource.RawInput, I64, I64, I64, I64 -> InputSource.RawInput
	ri_build = |ri, sc, btn, abs_x, abs_y| { ri_mx: ri_clamp(abs_x, 0, ri.ri_max_x), ri_my: ri_clamp(abs_y, 0, ri.ri_max_y), ri_left: (if (I64.bitwise_and(btn, 1) > 0) { 1 } else { 0 }), ri_right: (if (I64.bitwise_and(btn, 2) > 0) { 1 } else { 0 }), ri_middle: (if (I64.bitwise_and(btn, 4) > 0) { 1 } else { 0 }), ri_key: sc, ri_prev_mx: ri.ri_mx, ri_prev_my: ri.ri_my, ri_prev_left: ri.ri_left, ri_prev_right: ri.ri_right, ri_prev_middle: ri.ri_middle, ri_prev_key: ri.ri_key, ri_max_x: ri.ri_max_x, ri_max_y: ri.ri_max_y }

	ri_collect_events : InputSource.RawInput, I64 -> List(Event.Event)
	ri_collect_events = |ri, ts| ({
		acc = ri_mouse_move_events(ri, ts, [])
		acc2 = ri_mouse_btn_events(ri, ts, acc)
		ri_key_events(ri, ts, acc2)
	})

	ri_mouse_move_events : InputSource.RawInput, I64, List(Event.Event) -> List(Event.Event)
	ri_mouse_move_events = |ri, ts, acc| (if (ri.ri_mx == ri.ri_prev_mx) { (if (ri.ri_my == ri.ri_prev_my) { acc } else { List.append(acc, Event.event_mouse_move(ri.ri_mx, ri.ri_my, ts)) }) } else { List.append(acc, Event.event_mouse_move(ri.ri_mx, ri.ri_my, ts)) })

	ri_mouse_btn_events : InputSource.RawInput, I64, List(Event.Event) -> List(Event.Event)
	ri_mouse_btn_events = |ri, ts, acc| ({
		acc2 = ri_btn_edge(acc, ri.ri_left, ri.ri_prev_left, Event.btn_left, ri.ri_mx, ri.ri_my, ts)
		acc3 = ri_btn_edge(acc2, ri.ri_right, ri.ri_prev_right, Event.btn_right, ri.ri_mx, ri.ri_my, ts)
		ri_btn_edge(acc3, ri.ri_middle, ri.ri_prev_middle, Event.btn_middle, ri.ri_mx, ri.ri_my, ts)
	})

	ri_btn_edge : List(Event.Event), I64, I64, I64, I64, I64, I64 -> List(Event.Event)
	ri_btn_edge = |acc, cur, prev, btn, mx, my, ts| (if (cur == 1) { (if (prev == 0) { List.append(acc, Event.event_mouse_down(mx, my, btn, ts)) } else { acc }) } else { (if (prev == 1) { List.append(acc, Event.event_mouse_up(mx, my, btn, ts)) } else { acc }) })

	ri_key_events : InputSource.RawInput, I64, List(Event.Event) -> List(Event.Event)
	ri_key_events = |ri, ts, acc| ({
		sc = ri.ri_key
		(if (sc == 0) { acc } else { (if (sc >= 128) { List.append(acc, Event.event_key_up((sc - 128), Event.mod_none, ts)) } else { (if (ri.ri_prev_key == 0) { List.append(acc, Event.event_key_down(sc, Event.mod_none, ts)) } else { acc }) }) })
	})

	ri_clamp : I64, I64, I64 -> I64
	ri_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	ri_dx : InputSource.RawInput -> I64
	ri_dx = |ri| (ri.ri_mx - ri.ri_prev_mx)

	ri_dy : InputSource.RawInput -> I64
	ri_dy = |ri| (ri.ri_my - ri.ri_prev_my)

	ri_left_down : InputSource.RawInput -> Bool
	ri_left_down = |ri| (if (ri.ri_left == 1) { (if (ri.ri_prev_left == 0) { True } else { False }) } else { False })

	ri_left_up : InputSource.RawInput -> Bool
	ri_left_up = |ri| (if (ri.ri_left == 0) { (if (ri.ri_prev_left == 1) { True } else { False }) } else { False })

	ri_right_down : InputSource.RawInput -> Bool
	ri_right_down = |ri| (if (ri.ri_right == 1) { (if (ri.ri_prev_right == 0) { True } else { False }) } else { False })

	ri_middle_held : InputSource.RawInput -> Bool
	ri_middle_held = |ri| (if (ri.ri_middle == 1) { True } else { False })

	ri_key_pressed : InputSource.RawInput -> I64
	ri_key_pressed = |ri| ({
		sc = ri.ri_key
		(if (sc > 0) { (if (sc < 128) { (if (ri.ri_prev_key == 0) { sc } else { 0 }) } else { 0 }) } else { 0 })
	})
}
