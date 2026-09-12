app [main!] {}

TttBoard : { squares : List(I64), current_player : I64, game_over : Bool, winner : I64 }
TttResult : { winner : I64, moves : I64 }
VerifyStats : { paths : I64, wins : I64, draws : I64, losses : I64 }

ttt_new : TttBoard
ttt_new = { squares: [0, 0, 0, 0, 0, 0, 0, 0, 0], current_player: 1, game_over: False, winner: 0 }

ttt_move : TttBoard, I64 -> TttBoard
ttt_move = |b, i| { ..b, game_over: i > 7 }

ttt_perfect_ai : TttBoard -> I64
ttt_perfect_ai = |b| b.current_player

vf_walk : TttBoard, I64, VerifyStats -> VerifyStats
vf_walk = |b, ai, st| (if b.game_over { st } else { vf_walk(ttt_move(b, ttt_perfect_ai(b)), ai, st) })

vf_new : VerifyStats
vf_new = { paths: 0, wins: 0, draws: 0, losses: 0 }

main! = |_args| {
	as_x = vf_walk(ttt_new, 1, vf_new)
	line!(I64.to_str(as_x.paths))
	Ok({})
}

line! = |s| echo!(Str.concat(s, "\n"))

