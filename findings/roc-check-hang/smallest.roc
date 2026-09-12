ttt_new = { current_player: 1, game_over: False }
ttt_move = |b, i| { ..b, game_over: i > 7 }
ttt_perfect_ai = |b| b.current_player
vf_walk = |b, ai, st| (if b.game_over { st } else { vf_walk(b, ai, st) })
vf_new = { paths: 0 }
main! = |_args| {
	as_x = vf_walk(ttt_new, 1, vf_new)
	line!(I64.to_str(as_x.paths))
	Ok({})
}
line! = |s| echo!(Str.concat(s, "\n"))