# The machine's devices: the terminal, the screen, the address space and the
# framebuffer. A statement changes them only when it uses one, so the machine
# keeps them behind one reference (`devices` in Machine.M).
import Vec

Devices :: [].{
	D : {
		# INPUT's reply split into its items, and the lines typed with the next
		# to read.
		reply : List(Str),
		inp : List(Str),
		ip : U64,
		# **INPUT'S PROMPT GOES OUT ONCE**, though the statement runs again when
		# its line arrives.
		asked : Bool,
		# The transcript, and the column the next character prints in.
		out : List(Str),
		col : I64,
		# **THE ADDRESS SPACE**, 16 MB, which costs nothing until written.
		mem : Vec.V(U8),
		# **THE SCREEN IS A FLAT THOUSAND BYTES, AND STILL MEMORY**: 40x25 at
		# 1024, colour at 55296. Its rows are a ring: `top` is the row shown
		# first, so a scroll moves `top` and blanks one row.
		scr : List(U8),
		col_ram : List(U8),
		top : I64,
		crow : I64,
		ccol : I64,
		# **A LINEAR FRAMEBUFFER**, 320x200 from 131072, made when first drawn.
		pix : List(U8),
		drew : Bool,
	}

	# The devices of a machine given these lines to read.
	fresh : List(Str) -> D
	fresh = |inp| {
		reply: [],
		inp: inp,
		ip: 0,
		asked: False,
		out: [],
		col: 0,
		mem: Vec.repeat(16777216, 0),
		scr: List.repeat(32, 1000),
		col_ram: List.repeat(14, 1000),
		top: 0,
		crow: 0,
		ccol: 0,
		pix: [],
		drew: False,
	}

	# What the machine holds while its devices are out being written.
	none : D
	none = { reply: [], inp: [], ip: 0, asked: False, out: [], col: 0, mem: Vec.repeat(0, 0), scr: [], col_ram: [], top: 0, crow: 0, ccol: 0, pix: [], drew: False }

	# ---- the machine's list of one --------------------------------------------------

	# **A WRITE TAKES THE DEVICES OUT OF THE MACHINE'S LIST AND PUTS THEM BACK**,
	# so they are written while nothing else refers to them. The machine calls
	# these inside its own record update: `{ ..m, devices: Devices.poke_into(m.devices, a, v) }`.
	write_text : List(D), Str -> List(D)
	write_text = |ds, t| {
		r = List.replace(ds, 0, Devices.none) ?? crash("the machine has no devices")
		List.set(r.list, 0, Devices.written(r.prev, t)) ?? crash("the machine has no devices")
	}

	poke_into : List(D), U64, U8 -> List(D)
	poke_into = |ds, a, v| {
		r = List.replace(ds, 0, Devices.none) ?? crash("the machine has no devices")
		List.set(r.list, 0, Devices.poked(r.prev, a, v)) ?? crash("the machine has no devices")
	}

	# INPUT's prompt has gone out.
	prompt_out : List(D) -> List(D)
	prompt_out = |ds| {
		r = List.replace(ds, 0, Devices.none) ?? crash("the machine has no devices")
		List.set(r.list, 0, Devices.prompted(r.prev)) ?? crash("the machine has no devices")
	}

	# A line read: its items kept, and the line after it next.
	reply_in : List(D), List(Str) -> List(D)
	reply_in = |ds, vals| {
		r = List.replace(ds, 0, Devices.none) ?? crash("the machine has no devices")
		List.set(r.list, 0, Devices.replied(r.prev, vals)) ?? crash("the machine has no devices")
	}

	# A line typed, kept for INPUT to read.
	line_in : List(D), Str -> List(D)
	line_in = |ds, line| {
		r = List.replace(ds, 0, Devices.none) ?? crash("the machine has no devices")
		List.set(r.list, 0, Devices.typed_in(r.prev, line)) ?? crash("the machine has no devices")
	}

	prompted : D -> D
	prompted = |d| { ..d, asked: True }

	replied : D, List(Str) -> D
	replied = |d, vals| { ..d, ip: d.ip + 1, asked: False, reply: vals }

	typed_in : D, Str -> D
	typed_in = |d, line| { ..d, inp: List.append(d.inp, line) }

	# ---- the display ----------------------------------------------------------------

	# **PRINT AND POKE SHARE ONE DISPLAY.** Text goes into the transcript and
	# onto the screen at the cursor; the twenty-sixth line scrolls.
	written : D, Str -> D
	written = |d, t| {
		b = Str.to_utf8(t)
		s = Devices.draw(d.scr, d.col_ram, d.top, d.crow, d.ccol, b)
		{ ..d, scr: s.scr, col_ram: s.col_ram, top: s.top, crow: s.crow, ccol: s.ccol, out: Devices.append_out(d.out, t), col: Devices.col_after(b, d.col) }
	}

	Drawn : { scr : List(U8), col_ram : List(U8), top : I64, crow : I64, ccol : I64 }

	draw : List(U8), List(U8), I64, I64, I64, List(U8) -> Drawn
	draw = |scr, col_ram, top, crow, ccol, b| {
		var $scr = scr
		var $col_ram = col_ram
		var $top = top
		var $row = crow
		var $col = ccol
		for c in b {
			if c != 10 {
				$scr = List.set($scr, Devices.cell(Devices.row_at($top, $row), $col), Devices.screen_code(c)) ?? crash("draw: outside the screen")
			} else {
				{}
			}
			if c == 10 or $col + 1 >= Devices.screen_w {
				$col = 0
				if $row + 1 >= Devices.screen_h {
					# The row at the top becomes the blank row at the foot.
					bottom = Devices.row_at($top, 0)
					$scr = Devices.fill_row($scr, bottom, 32)
					$col_ram = Devices.fill_row($col_ram, bottom, 14)
					$top = I64.rem_by($top + 1, Devices.screen_h)
				} else {
					$row = $row + 1
				}
			} else {
				$col = $col + 1
			}
		}
		{ scr: $scr, col_ram: $col_ram, top: $top, crow: $row, ccol: $col }
	}

	screen_w : I64
	screen_w = 40

	screen_h : I64
	screen_h = 25

	# Where a screen row is kept, given the row shown first.
	row_at : I64, I64 -> I64
	row_at = |top, row| I64.rem_by(top + row, Devices.screen_h)

	cell : I64, I64 -> U64
	cell = |kept_row, col| I64.to_u64_wrap(kept_row * Devices.screen_w + col)

	fill_row : List(U8), I64, U8 -> List(U8)
	fill_row = |bytes, kept_row, v| {
		var $b = bytes
		var $c = 0
		while $c < Devices.screen_w {
			$b = List.set($b, Devices.cell(kept_row, $c), v) ?? crash("fill_row: outside the screen")
			$c = $c + 1
		}
		$b
	}

	# A Commodore screen code: letters from 64, lower case as upper, 32..63
	# themselves, graphics from 128.
	screen_code : U8 -> U8
	screen_code = |c|
		if c >= 64 and c <= 95 { c - 64 }
		else if c >= 97 and c <= 122 { c - 96 }
		else if c >= 32 and c <= 63 { c }
		else if c >= 128 { c - 128 }
		else { 32 }

	col_after : List(U8), I64 -> I64
	col_after = |b, col| {
		var $c = col
		for x in b {
			$c = if x == 10 { 0 } else { $c + 1 }
		}
		$c
	}

	# The column after text, without making its bytes when it has no newline.
	col_after_text : Str, I64 -> I64
	col_after_text = |t, col| if Str.contains(t, "\n") { Devices.col_after(Str.to_utf8(t), col) } else { col + U64.to_i64_wrap(Str.count_utf8_bytes(t)) }

	# **A PROGRAM THAT PRINTS FOREVER MUST NOT GROW FOREVER**: the transcript
	# is trimmed to its last 8,000 pieces once it has twice that.
	scrollback : U64
	scrollback = 8000

	append_out : List(Str), Str -> List(Str)
	append_out = |out, t|
		if List.len(out) < Devices.scrollback * 2 {
			List.append(out, t)
		} else {
			List.append(List.sublist(out, { start: Devices.scrollback, len: List.len(out) - Devices.scrollback }), t)
		}

	# The screen codes and colours in the order shown, then the framebuffer.
	view : D -> List(U8)
	view = |d| {
		var $codes = List.with_capacity(2000)
		var $colours = List.with_capacity(1000)
		var $row = 0
		while $row < Devices.screen_h {
			start_at = Devices.cell(Devices.row_at(d.top, $row), 0)
			$codes = List.concat($codes, List.sublist(d.scr, { start: start_at, len: 40 }))
			$colours = List.concat($colours, List.sublist(d.col_ram, { start: start_at, len: 40 }))
			$row = $row + 1
		}
		List.concat(List.concat($codes, $colours), d.pix)
	}

	# ---- memory -----------------------------------------------------------------------

	# **THE SMALL WINDOWS ARE MATCHED FIRST**, the framebuffer last.
	hires_base : U64
	hires_base = 131072

	hires_w : U64
	hires_w = 320

	hires_h : U64
	hires_h = 200

	hires_cells : U64
	hires_cells = 64000

	screen_base : U64
	screen_base = 1024

	colour_base : U64
	colour_base = 55296

	screen_cells : U64
	screen_cells = 1000

	# A screen address as the cell it is kept in.
	kept : D, U64 -> U64
	kept = |d, i| Devices.cell(Devices.row_at(d.top, U64.to_i64_wrap(U64.div_trunc_by(i, 40))), U64.to_i64_wrap(U64.rem_by(i, 40)))

	peek : D, U64 -> U8
	peek = |d, a|
		if a >= Devices.screen_base and a < Devices.screen_base + Devices.screen_cells {
			List.get(d.scr, Devices.kept(d, a - Devices.screen_base)) ?? 0
		} else if a >= Devices.colour_base and a < Devices.colour_base + Devices.screen_cells {
			List.get(d.col_ram, Devices.kept(d, a - Devices.colour_base)) ?? 0
		} else if a >= Devices.hires_base and a < Devices.hires_base + Devices.hires_cells {
			List.get(d.pix, a - Devices.hires_base) ?? 0
		} else {
			Vec.get(d.mem, a, 0)
		}

	poked : D, U64, U8 -> D
	poked = |d, a, v|
		if a >= Devices.screen_base and a < Devices.screen_base + Devices.screen_cells {
			{ ..d, scr: List.set(d.scr, Devices.kept(d, a - Devices.screen_base), v) ?? crash("poke: screen") }
		} else if a >= Devices.colour_base and a < Devices.colour_base + Devices.screen_cells {
			{ ..d, col_ram: List.set(d.col_ram, Devices.kept(d, a - Devices.colour_base), v) ?? crash("poke: colour") }
		} else if a >= Devices.hires_base and a < Devices.hires_base + Devices.hires_cells {
			lit = if d.drew { d.pix } else { List.repeat(0, Devices.hires_cells) }
			{ ..d, pix: List.set(lit, a - Devices.hires_base, v) ?? crash("poke: hires"), drew: True }
		} else {
			{ ..d, mem: Vec.set(d.mem, a, v) }
		}
}
