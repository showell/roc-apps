# basic-run with its fast path checked against the full evaluator.
#
#   basic-check ecma  "<listing>" "<replies>"
#   basic-check micro "<listing>" "<replies>"
#
# Wherever the fast path answers a LET, an IF or an array store, the
# statement runs both ways from the same machine: as basic-run runs it, and
# by the full evaluator alone. The two machines are compared on everything
# such a statement can write, and a difference stops the program with
# `fast differs`. basic/check-fast.sh runs the corpus and the controls
# through it.
#
# **THE CHECK HAS A RUN LOOP OF ITS OWN**, so basic-run's is untouched: a
# change of shape in that loop can make every statement copy.
import CommandLine
import Machine
import Parse
import Vec

main! = |args| {
	dialect = List.get(args, 0) ?? ""
	listing = CommandLine.clean(List.get(args, 1) ?? "")
	replies = CommandLine.lines_of(CommandLine.clean(List.get(args, 2) ?? ""))
	l = Machine.loaded(listing, dialect == "ecma")
	r = batch(l.pg, to_effect(l.pg, { m: Machine.started(l, replies, 1), checked: 0 }), 10)
	# **A CHECK THAT NEVER RAN CHECKED NOTHING**: `checked` is how many fast
	# answers were compared.
	dbg { steps: r.m.steps, statements: List.len(l.pg.prog), checked: r.checked }
	echo!(Machine.ended(l.pg, r.m))
	Ok({})
}

# Machine.machine_state_at_next_effect, stepping by `step`.
to_effect : Parse.Program, { m : Machine.M, checked : U64 } -> { m : Machine.M, checked : U64 }
to_effect = |pg, start| {
	var $m = start.m
	var $c = start.checked
	while !($m.done or $m.waiting or $m.pause > 0 or $m.fuel <= 0) {
		s = step(pg, { ..$m, fuel: $m.fuel - 1, steps: $m.steps + 1 })
		$m = s.m
		$c = $c + s.checked
	}
	{ m: $m, checked: $c }
}

# Machine.batch, running by `to_effect`.
batch : Parse.Program, { m : Machine.M, checked : U64 }, I64 -> { m : Machine.M, checked : U64 }
batch = |pg, start, tanks| {
	var $r = start
	var $t = tanks
	while ($r.m.pause > 0 and !$r.m.done) or ($t > 0 and !$r.m.done and !$r.m.waiting and $r.m.fuel <= 0) {
		m = $r.m
		if m.pause > 0 {
			$r = to_effect(pg, { m: { ..m, pause: 0 }, checked: $r.checked })
		} else {
			$r = to_effect(pg, { m: { ..m, fuel: pg.tank }, checked: $r.checked })
			$t = $t - 1
		}
	}
	$r
}

# One statement. `checked` is 1 when the fast path answered and the two ways
# were compared; any other statement runs as basic-run runs it.
# **THE FULL EVALUATOR'S RUN IS THE MACHINE'S LAST USE**, so it writes in
# place, and only the fast path's run copies what it writes.
step : Parse.Program, Machine.M -> { m : Machine.M, checked : U64 }
step = |pg, m| match List.get(pg.prog, m.pc) {
	Ok(SetNum(slot, e)) => match Machine.fast(m, e) {
		Got(_) => agree(pg, m.pc, Machine.do_set_num(pg, m, slot, e), Machine.do_set_num_slow(pg, m, slot, e), Var(slot))
		Slow => { m: Machine.step(pg, m), checked: 0 }
	}
	Ok(IfGo(l, op, r, j, line)) => match Machine.fast_test(m, l, op, r) {
		Unknown => { m: Machine.step(pg, m), checked: 0 }
		_ => agree(pg, m.pc, Machine.do_if_go(pg, m, l, op, r, j, line), Machine.do_if_go_slow(pg, m, l, op, r, j, line), Control)
	}
	Ok(IfThen(l, op, r, line)) => match Machine.fast_test(m, l, op, r) {
		Unknown => { m: Machine.step(pg, m), checked: 0 }
		_ => agree(pg, m.pc, Machine.do_if_then(pg, m, l, op, r, line), Machine.do_if_then_slow(pg, m, l, op, r, line), Control)
	}
	Ok(SetElem(slot, one, two, pair, e)) => match Machine.fast_place(m, slot, one, two, pair, e) {
		Place(i, j, _) => {
			full = Machine.subs(pg, m, [], Machine.fresh(m), one, two, pair)
			agree(pg, m.pc, Machine.do_set_elem(pg, m, slot, one, two, pair, e), Machine.do_set_elem_slow(pg, m, slot, one, two, pair, e), Cells(slot, i, j, full.i, full.j))
		}
		Nothing => { m: Machine.step(pg, m), checked: 0 }
	}
	_ => { m: Machine.step(pg, m), checked: 0 }
}

# The machine the fast path left, when the full evaluator's is the same.
agree : Parse.Program, U64, Machine.M, Machine.M, [Var(U64), Cells(U64, I64, I64, I64, I64), Control] -> { m : Machine.M, checked : U64 }
agree = |pg, pc, by_fast, by_full, look| {
	a = seen(by_fast, look)
	b = seen(by_full, look)
	if a == b {
		{ m: by_fast, checked: 1 }
	} else {
		why = Str.join_with(["fast differs on line ", I64.to_str(Machine.line_of(pg, pc)), ": fast [", shown(a), "] full [", shown(b), "]"], "")
		{ m: { ..by_full, done: True, gap: True, err: why }, checked: 1 }
	}
}

# What a LET, an IF or an array store can write: where the program goes
# next, whether and why it stopped, the random number state, the arrays
# made, the output, the stacks, and the variable or the cells the statement
# names -- an array store's by the fast path's subscripts (`one`) and by the
# full evaluator's (`two`). A number is its bits.
# **NOTHING HERE IS TEXT UNTIL THE MACHINES DIFFER**: building the text for
# every statement was ten times the statement.
Seen : {
	pc : U64,
	done : Bool,
	err : Str,
	gap : Bool,
	waiting : Bool,
	pause : I64,
	seed : U64,
	mtat : U64,
	rlast : U64,
	arrays : U64,
	outs : U64,
	last : Str,
	col : I64,
	rdepth : U64,
	ldepth : U64,
	one : U64,
	two : U64,
}

seen : Machine.M, [Var(U64), Cells(U64, I64, I64, I64, I64), Control] -> Seen
seen = |m, look| {
	d = Machine.devices_of(m)
	named = match look {
		Var(slot) => { one: F64.to_bits(Vec.get(m.nums, slot, 0.0)), two: 0 }
		Cells(slot, i, j, k, n) => { one: cell(m, slot, i, j), two: cell(m, slot, k, n) }
		Control => { one: 0, two: 0 }
	}
	{
		pc: m.pc,
		done: m.done,
		err: m.err,
		gap: m.gap,
		waiting: m.waiting,
		pause: m.pause,
		seed: m.seed,
		mtat: m.mtat,
		rlast: F64.to_bits(m.rlast),
		arrays: m.arr_count,
		outs: List.len(d.out),
		last: if List.is_empty(d.out) { "" } else { List.get(d.out, List.len(d.out) - 1) ?? "" },
		col: d.col,
		rdepth: m.rdepth,
		ldepth: m.ldepth,
		one: named.one,
		two: named.two,
	}
}

# A cell's bits; all ones outside the array.
cell : Machine.M, U64, I64, I64 -> U64
cell = |m, slot, i, j| {
	c = Machine.cell_of(m.arrs, m.base, slot, i, j)
	if c < 0 { 18446744073709551615 } else { F64.to_bits(Vec.at((Vec.at(m.arrs, slot)).cells, I64.to_u64_wrap(c))) }
}

shown : Seen -> Str
shown = |s|
	Str.join_with(
		[
			"pc", U64.to_str(s.pc),
			"done", flag(s.done),
			"err", s.err,
			"gap", flag(s.gap),
			"waiting", flag(s.waiting),
			"pause", I64.to_str(s.pause),
			"seed", U64.to_str(s.seed),
			"mtat", U64.to_str(s.mtat),
			"rlast", F64.to_str(F64.from_bits(s.rlast)),
			"arrays", U64.to_str(s.arrays),
			"out", U64.to_str(s.outs), s.last,
			"col", I64.to_str(s.col),
			"rdepth", U64.to_str(s.rdepth),
			"ldepth", U64.to_str(s.ldepth),
			"named", F64.to_str(F64.from_bits(s.one)), F64.to_str(F64.from_bits(s.two)),
		],
		" ",
	)

flag : Bool -> Str
flag = |b| if b { "yes" } else { "no" }
