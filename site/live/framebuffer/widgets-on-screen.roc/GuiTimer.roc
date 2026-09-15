# GuiTimer -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem

GuiTimer :: [].{
	MutWheel : { mw_base : I64, mw_meta : I64, mw_notepad : GuiTimer.NotepadBuf }
	NotepadBuf : { nb_base : I64 }

	mtw_slot_size : I64
	mtw_slot_size = 32

	mtw_fine_count : I64
	mtw_fine_count = 256

	mtw_fine_bytes : I64
	mtw_fine_bytes = 8192

	mtw_max_timers : I64
	mtw_max_timers = 16

	mtw_tag_none : I64
	mtw_tag_none = 0

	mtw_tag_clock : I64
	mtw_tag_clock = 1

	mtw_tag_heartbeat : I64
	mtw_tag_heartbeat = 2

	mw_meta_size : I64
	mw_meta_size = 256

	mw_notepad_size : I64
	mw_notepad_size = 2048

	mw_get_tick! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_tick! = |mem, w| Mem.load!(mem, w.mw_meta, 0, 4)

	mw_set_tick! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_tick! = |mem, w, v| Mem.store!(mem, w.mw_meta, 0, v, 4)

	mw_get_next_id! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_next_id! = |mem, w| Mem.load!(mem, w.mw_meta, 8, 4)

	mw_set_next_id! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_next_id! = |mem, w, v| Mem.store!(mem, w.mw_meta, 8, v, 4)

	mw_get_frame! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_frame! = |mem, w| Mem.load!(mem, w.mw_meta, 16, 4)

	mw_inc_frame! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_inc_frame! = |mem, w| ({
		(mem1, f) = Mem.load!(mem, w.mw_meta, 16, 4)
		Mem.store!(mem1, w.mw_meta, 16, (f + 1), 4)
	})

	mw_get_last_key! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_last_key! = |mem, w| Mem.load!(mem, w.mw_meta, 24, 4)

	mw_set_last_key! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_last_key! = |mem, w, v| Mem.store!(mem, w.mw_meta, 24, v, 4)

	mw_get_last_sc! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_last_sc! = |mem, w| Mem.load!(mem, w.mw_meta, 32, 4)

	mw_set_last_sc! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_last_sc! = |mem, w, v| Mem.store!(mem, w.mw_meta, 32, v, 4)

	mw_get_view! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_view! = |mem, w| Mem.load!(mem, w.mw_meta, 40, 4)

	mw_set_view! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_view! = |mem, w, v| Mem.store!(mem, w.mw_meta, 40, v, 4)

	mw_get_mouse_x! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_mouse_x! = |mem, w| Mem.load!(mem, w.mw_meta, 48, 4)

	mw_set_mouse_x! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_mouse_x! = |mem, w, v| Mem.store!(mem, w.mw_meta, 48, v, 4)

	mw_get_mouse_y! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_mouse_y! = |mem, w| Mem.load!(mem, w.mw_meta, 56, 4)

	mw_set_mouse_y! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_mouse_y! = |mem, w, v| Mem.store!(mem, w.mw_meta, 56, v, 4)

	mw_get_kb_shift! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_kb_shift! = |mem, w| Mem.load!(mem, w.mw_meta, 64, 4)

	mw_set_kb_shift! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_kb_shift! = |mem, w, v| Mem.store!(mem, w.mw_meta, 64, v, 4)

	mw_get_kb_ctrl! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_kb_ctrl! = |mem, w| Mem.load!(mem, w.mw_meta, 72, 4)

	mw_set_kb_ctrl! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_kb_ctrl! = |mem, w, v| Mem.store!(mem, w.mw_meta, 72, v, 4)

	mw_get_kb_caps! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_kb_caps! = |mem, w| Mem.load!(mem, w.mw_meta, 80, 4)

	mw_set_kb_caps! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_kb_caps! = |mem, w, v| Mem.store!(mem, w.mw_meta, 80, v, 4)

	mw_get_kb_num! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_kb_num! = |mem, w| Mem.load!(mem, w.mw_meta, 88, 4)

	mw_set_kb_num! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_kb_num! = |mem, w, v| Mem.store!(mem, w.mw_meta, 88, v, 4)

	mw_get_mouse_btn! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_mouse_btn! = |mem, w| Mem.load!(mem, w.mw_meta, 96, 4)

	mw_set_mouse_btn! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_mouse_btn! = |mem, w, v| Mem.store!(mem, w.mw_meta, 96, v, 4)

	mw_get_app! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_app! = |mem, w| Mem.load!(mem, w.mw_meta, 112, 4)

	mw_set_app! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_app! = |mem, w, v| Mem.store!(mem, w.mw_meta, 112, v, 4)

	mw_get_calc_acc! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_calc_acc! = |mem, w| Mem.load!(mem, w.mw_meta, 120, 4)

	mw_set_calc_acc! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_calc_acc! = |mem, w, v| Mem.store!(mem, w.mw_meta, 120, v, 4)

	mw_get_calc_cur! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_calc_cur! = |mem, w| Mem.load!(mem, w.mw_meta, 128, 4)

	mw_set_calc_cur! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_calc_cur! = |mem, w, v| Mem.store!(mem, w.mw_meta, 128, v, 4)

	mw_get_calc_op! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_calc_op! = |mem, w| Mem.load!(mem, w.mw_meta, 136, 4)

	mw_set_calc_op! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_calc_op! = |mem, w, v| Mem.store!(mem, w.mw_meta, 136, v, 4)

	mw_get_font_scale! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_scale! = |mem, w| ({
		(mem2, mem__449) = ({
		(mem1, v) = Mem.load!(mem, w.mw_meta, 144, 4)
		(mem1, (if (v <= 0) { 1 } else { v }))
	})
		(mem2, mem__449)
	})

	mw_set_font_scale! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_scale! = |mem, w, v| Mem.store!(mem, w.mw_meta, 144, v, 4)

	mw_get_font_role_serif! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_role_serif! = |mem, w| Mem.load!(mem, w.mw_meta, 148, 4)

	mw_set_font_role_serif! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_role_serif! = |mem, w, v| Mem.store!(mem, w.mw_meta, 148, v, 4)

	mw_get_font_role_sans! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_role_sans! = |mem, w| Mem.load!(mem, w.mw_meta, 152, 4)

	mw_set_font_role_sans! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_role_sans! = |mem, w, v| Mem.store!(mem, w.mw_meta, 152, v, 4)

	mw_get_font_role_mono! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_role_mono! = |mem, w| Mem.load!(mem, w.mw_meta, 156, 4)

	mw_set_font_role_mono! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_role_mono! = |mem, w, v| Mem.store!(mem, w.mw_meta, 156, v, 4)

	mw_get_fonts_loaded! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_fonts_loaded! = |mem, w| Mem.load!(mem, w.mw_meta, 160, 4)

	mw_set_fonts_loaded! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_fonts_loaded! = |mem, w, v| Mem.store!(mem, w.mw_meta, 160, v, 4)

	mw_get_font_picker_cursor! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_picker_cursor! = |mem, w| Mem.load!(mem, w.mw_meta, 164, 4)

	mw_set_font_picker_cursor! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_picker_cursor! = |mem, w, v| Mem.store!(mem, w.mw_meta, 164, v, 4)

	mw_get_font_picker_role! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_picker_role! = |mem, w| Mem.load!(mem, w.mw_meta, 168, 4)

	mw_set_font_picker_role! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_picker_role! = |mem, w, v| Mem.store!(mem, w.mw_meta, 168, v, 4)

	mw_get_font_serif_base! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_serif_base! = |mem, w| Mem.load!(mem, w.mw_meta, 172, 4)

	mw_set_font_serif_base! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_serif_base! = |mem, w, v| Mem.store!(mem, w.mw_meta, 172, v, 4)

	mw_get_font_sans_base! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_sans_base! = |mem, w| Mem.load!(mem, w.mw_meta, 176, 4)

	mw_set_font_sans_base! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_sans_base! = |mem, w, v| Mem.store!(mem, w.mw_meta, 176, v, 4)

	mw_get_font_mono_base! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_mono_base! = |mem, w| Mem.load!(mem, w.mw_meta, 180, 4)

	mw_set_font_mono_base! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_mono_base! = |mem, w, v| Mem.store!(mem, w.mw_meta, 180, v, 4)

	mw_get_font_serif_w! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_serif_w! = |mem, w| Mem.load!(mem, w.mw_meta, 184, 4)

	mw_set_font_serif_w! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_serif_w! = |mem, w, v| Mem.store!(mem, w.mw_meta, 184, v, 4)

	mw_get_font_sans_w! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_sans_w! = |mem, w| Mem.load!(mem, w.mw_meta, 188, 4)

	mw_set_font_sans_w! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_sans_w! = |mem, w, v| Mem.store!(mem, w.mw_meta, 188, v, 4)

	mw_get_font_mono_w! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_mono_w! = |mem, w| Mem.load!(mem, w.mw_meta, 192, 4)

	mw_set_font_mono_w! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_mono_w! = |mem, w, v| Mem.store!(mem, w.mw_meta, 192, v, 4)

	mw_get_font_glyph_h! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_glyph_h! = |mem, w| ({
		(mem2, mem__450) = ({
		(mem1, v) = Mem.load!(mem, w.mw_meta, 196, 4)
		(mem1, (if (v <= 0) { 16 } else { v }))
	})
		(mem2, mem__450)
	})

	mw_set_font_glyph_h! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_glyph_h! = |mem, w, v| Mem.store!(mem, w.mw_meta, 196, v, 4)

	mw_get_font_cache_base! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_font_cache_base! = |mem, w| Mem.load!(mem, w.mw_meta, 208, 4)

	mw_set_font_cache_base! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_font_cache_base! = |mem, w, v| Mem.store!(mem, w.mw_meta, 208, v, 4)

	mw_get_tab_cursor! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_tab_cursor! = |mem, w| Mem.load!(mem, w.mw_meta, 216, 4)

	mw_set_tab_cursor! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_tab_cursor! = |mem, w, v| Mem.store!(mem, w.mw_meta, 216, v, 4)

	mw_get_key_repeat_delay! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_key_repeat_delay! = |mem, w| ({
		(mem2, mem__451) = ({
		(mem1, v) = Mem.load!(mem, w.mw_meta, 200, 4)
		(mem1, (if (v <= 0) { 5 } else { v }))
	})
		(mem2, mem__451)
	})

	mw_set_key_repeat_delay! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_key_repeat_delay! = |mem, w, v| Mem.store!(mem, w.mw_meta, 200, v, 4)

	mw_get_last_key_tick! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_last_key_tick! = |mem, w| Mem.load!(mem, w.mw_meta, 204, 4)

	mw_set_last_key_tick! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_last_key_tick! = |mem, w, v| Mem.store!(mem, w.mw_meta, 204, v, 4)

	notepad_new! : Mem.Mem => (Mem.Mem, GuiTimer.NotepadBuf)
	notepad_new! = |mem| ({
		(mem3, mem__452) = ({
		(mem1, base) = Mem.alloc(mem, mw_notepad_size)
		(mem2, _d) = notepad_zero_loop!(mem1, base, 0)
		(mem2, { nb_base: base })
	})
		(mem3, mem__452)
	})

	notepad_zero_loop! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	notepad_zero_loop! = |mem, base, i| (if (i >= mw_notepad_size) { (mem, 0) } else { ({
		(mem1, _d) = Mem.store!(mem, base, i, 0, 1)
		notepad_zero_loop!(mem1, base, (i + 1))
	}) })

	mw_get_note_len! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_note_len! = |mem, w| Mem.load!(mem, w.mw_meta, 104, 4)

	mw_set_note_len! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_note_len! = |mem, w, v| Mem.store!(mem, w.mw_meta, 104, v, 4)

	notepad_append! : Mem.Mem, GuiTimer.NotepadBuf, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	notepad_append! = |mem, nb, w, cce| ({
		(mem1, pos) = mw_get_note_len!(mem, w)
		(if (pos >= (mw_notepad_size - 1)) { (mem1, 0) } else { ({
			(mem2, _d) = Mem.store!(mem1, nb.nb_base, pos, cce, 1)
			mw_set_note_len!(mem2, w, (pos + 1))
		}) })
	})

	notepad_backspace! : Mem.Mem, GuiTimer.NotepadBuf, GuiTimer.MutWheel => (Mem.Mem, I64)
	notepad_backspace! = |mem, nb, w| ({
		(mem1, pos) = mw_get_note_len!(mem, w)
		(if (pos <= 0) { (mem1, 0) } else { ({
			(mem2, _d) = Mem.store!(mem1, nb.nb_base, (pos - 1), 0, 1)
			mw_set_note_len!(mem2, w, (pos - 1))
		}) })
	})

	notepad_get_char! : Mem.Mem, GuiTimer.NotepadBuf, I64 => (Mem.Mem, I64)
	notepad_get_char! = |mem, nb, i| Mem.load!(mem, nb.nb_base, i, 1)

	mw_new! : Mem.Mem => (Mem.Mem, GuiTimer.MutWheel)
	mw_new! = |mem| ({
		(mem9, mem__453) = ({
		(mem1, base) = Mem.alloc(mem, mtw_fine_bytes)
		(mem2, meta) = Mem.alloc(mem1, mw_meta_size)
		(mem3, _dummy) = mw_zero_slots!(mem2, base, 0)
		(mem4, _d2) = Mem.store!(mem3, meta, 0, 0, 4)
		(mem5, _d3) = Mem.store!(mem4, meta, 4, 0, 4)
		(mem6, _d4) = Mem.store!(mem5, meta, 8, 1, 4)
		(mem7, _d5) = Mem.store!(mem6, meta, 12, 0, 4)
		(mem8, np) = notepad_new!(mem7)
		(mem8, { mw_base: base, mw_meta: meta, mw_notepad: np })
	})
		(mem9, mem__453)
	})

	mw_zero_slots! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	mw_zero_slots! = |mem, base, i| (if (i >= mtw_fine_count) { (mem, 0) } else { ({
		off = (i * mtw_slot_size)
		(mem1, _d1) = Mem.store!(mem, base, off, 0, 4)
		(mem2, _d2) = Mem.store!(mem1, base, (off + 4), 0, 4)
		(mem3, _d3) = Mem.store!(mem2, base, (off + 8), 0, 4)
		(mem4, _d4) = Mem.store!(mem3, base, (off + 12), 0, 4)
		(mem5, _d5) = Mem.store!(mem4, base, (off + 16), 0, 4)
		(mem6, _d6) = Mem.store!(mem5, base, (off + 20), 0, 4)
		(mem7, _d7) = Mem.store!(mem6, base, (off + 24), 0, 4)
		(mem8, _d8) = Mem.store!(mem7, base, (off + 28), 0, 4)
		mw_zero_slots!(mem8, base, (i + 1))
	}) })

	mw_schedule! : Mem.Mem, GuiTimer.MutWheel, I64, I64 => (Mem.Mem, GuiTimer.MutWheel)
	mw_schedule! = |mem, w, delay, tag_id| ({
		(mem12, mem__454) = ({
		(mem1, tick) = mw_get_tick!(mem, w)
		(mem2, nid) = mw_get_next_id!(mem1, w)
		deadline = (tick + delay)
		slot_idx = mw_mod(deadline, mtw_fine_count)
		off = (slot_idx * mtw_slot_size)
		(mem3, _d1) = Mem.store!(mem2, w.mw_base, off, nid, 4)
		(mem4, _d2) = Mem.store!(mem3, w.mw_base, (off + 4), 0, 4)
		(mem5, _d3) = Mem.store!(mem4, w.mw_base, (off + 8), deadline, 4)
		(mem6, _d4) = Mem.store!(mem5, w.mw_base, (off + 12), 0, 4)
		(mem7, _d5) = Mem.store!(mem6, w.mw_base, (off + 16), tag_id, 4)
		(mem8, _d6) = Mem.store!(mem7, w.mw_base, (off + 20), 0, 4)
		(mem9, _d7) = Mem.store!(mem8, w.mw_base, (off + 24), 1, 4)
		(mem10, _d8) = Mem.store!(mem9, w.mw_base, (off + 28), 0, 4)
		(mem11, _d9) = mw_set_next_id!(mem10, w, (nid + 1))
		(mem11, w)
	})
		(mem12, mem__454)
	})

	mw_tick! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, GuiTimer.MutWheel)
	mw_tick! = |mem, w| ({
		(mem3, mem__455) = ({
		(mem1, tick) = mw_get_tick!(mem, w)
		(mem2, _d) = mw_set_tick!(mem1, w, (tick + 1))
		(mem2, w)
	})
		(mem3, mem__455)
	})

	mw_check_and_fire! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_check_and_fire! = |mem, w| ({
		(mem11, mem__462) = ({
		(mem1, mem__456) = mw_get_tick!(mem, w)
		slot_idx = mw_mod(mem__456, mtw_fine_count)
		off = (slot_idx * mtw_slot_size)
		(mem2, active) = Mem.load!(mem1, w.mw_base, (off + 24), 4)
		({
			(mem10, mem__461) = (if (active == 0) { (mem2, 0) } else { ({
			(mem9, mem__460) = ({
			(mem3, deadline) = Mem.load!(mem2, w.mw_base, (off + 8), 4)
			({
				(mem4, mem__457) = mw_get_tick!(mem3, w)
				(mem8, mem__459) = (if (deadline > mem__457) { (mem4, 0) } else { ({
				(mem7, mem__458) = ({
				(mem5, tag) = Mem.load!(mem4, w.mw_base, (off + 16), 4)
				(mem6, _d) = Mem.store!(mem5, w.mw_base, (off + 24), 0, 4)
				(mem6, tag)
			})
				(mem7, mem__458)
			}) })
				(mem8, mem__459)
			})
		})
			(mem9, mem__460)
		}) })
			(mem10, mem__461)
		})
	})
		(mem11, mem__462)
	})

	mw_reschedule! : Mem.Mem, GuiTimer.MutWheel, I64, I64 => (Mem.Mem, GuiTimer.MutWheel)
	mw_reschedule! = |mem, w, tag_id, interval| mw_schedule!(mem, w, interval, tag_id)

	mw_compact! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, GuiTimer.MutWheel)
	mw_compact! = |mem, w| ({
		(mem3, mem__464) = ({
		(mem2, _dummy) = ({
			(mem1, mem__463) = mw_get_tick!(mem, w)
			mw_compact_loop!(mem1, w.mw_base, mem__463, 0)
		})
		(mem2, w)
	})
		(mem3, mem__464)
	})

	mw_compact_loop! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	mw_compact_loop! = |mem, base, now, i| (if (i >= mtw_fine_count) { (mem, 0) } else { ({
		off = (i * mtw_slot_size)
		(mem1, active) = Mem.load!(mem, base, (off + 24), 4)
		(if (active == 0) { mw_compact_loop!(mem1, base, now, (i + 1)) } else { ({
			(mem2, deadline) = Mem.load!(mem1, base, (off + 8), 4)
			(if (deadline <= now) { ({
				(mem3, _d1) = Mem.store!(mem2, base, (off + 24), 0, 4)
				mw_compact_loop!(mem3, base, now, (i + 1))
			}) } else { mw_compact_loop!(mem2, base, now, (i + 1)) })
		}) })
	}) })

	mw_active_count! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_active_count! = |mem, w| mw_count_loop!(mem, w.mw_base, 0, 0)

	mw_count_loop! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	mw_count_loop! = |mem, base, i, acc| (if (i >= mtw_fine_count) { (mem, acc) } else { ({
		off = (i * mtw_slot_size)
		(mem1, active) = Mem.load!(mem, base, (off + 24), 4)
		mw_count_loop!(mem1, base, (i + 1), (if (active == 1) { (acc + 1) } else { acc }))
	}) })

	mw_get_app_s0! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_app_s0! = |mem, w| Mem.load!(mem, w.mw_meta, 220, 4)

	mw_set_app_s0! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_app_s0! = |mem, w, v| Mem.store!(mem, w.mw_meta, 220, v, 4)

	mw_get_app_s1! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_app_s1! = |mem, w| Mem.load!(mem, w.mw_meta, 224, 4)

	mw_set_app_s1! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_app_s1! = |mem, w, v| Mem.store!(mem, w.mw_meta, 224, v, 4)

	mw_get_app_s2! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_app_s2! = |mem, w| Mem.load!(mem, w.mw_meta, 228, 4)

	mw_set_app_s2! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_app_s2! = |mem, w, v| Mem.store!(mem, w.mw_meta, 228, v, 4)

	mw_get_app_s3! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_app_s3! = |mem, w| Mem.load!(mem, w.mw_meta, 232, 4)

	mw_set_app_s3! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_app_s3! = |mem, w, v| Mem.store!(mem, w.mw_meta, 232, v, 4)

	mw_get_app_s4! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_app_s4! = |mem, w| Mem.load!(mem, w.mw_meta, 236, 4)

	mw_set_app_s4! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_app_s4! = |mem, w, v| Mem.store!(mem, w.mw_meta, 236, v, 4)

	mw_get_ext_0! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_ext_0! = |mem, w| Mem.load!(mem, w.mw_meta, 240, 4)

	mw_set_ext_0! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_ext_0! = |mem, w, v| Mem.store!(mem, w.mw_meta, 240, v, 4)

	mw_get_ext_1! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_ext_1! = |mem, w| Mem.load!(mem, w.mw_meta, 244, 4)

	mw_set_ext_1! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_ext_1! = |mem, w, v| Mem.store!(mem, w.mw_meta, 244, v, 4)

	mw_get_ext_2! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_ext_2! = |mem, w| Mem.load!(mem, w.mw_meta, 248, 4)

	mw_set_ext_2! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_ext_2! = |mem, w, v| Mem.store!(mem, w.mw_meta, 248, v, 4)

	mw_get_ext_3! : Mem.Mem, GuiTimer.MutWheel => (Mem.Mem, I64)
	mw_get_ext_3! = |mem, w| Mem.load!(mem, w.mw_meta, 252, 4)

	mw_set_ext_3! : Mem.Mem, GuiTimer.MutWheel, I64 => (Mem.Mem, I64)
	mw_set_ext_3! = |mem, w, v| Mem.store!(mem, w.mw_meta, 252, v, 4)

	mw_mod : I64, I64 -> I64
	mw_mod = |a, b| (a - (I64.div_trunc_by(a, b) * b))
}
