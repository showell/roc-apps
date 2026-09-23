# Diagnosis: how big a search gets, and how much of it is the same position
# reached twice. Plays one seed with four champions to the first player home,
# finds the search with the most lines, and shows its board and hand. Then,
# level by level (a level is one more card played), how many lines the search
# grew, how many Search.distinct_lines kept (whole game records equal), and
# how many positions they really are: the same board, the mover's hand as a
# multiset, its turn and its discard credits.
#
#   fasttrack/run_exp.sh exp_search_size
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Game
import Board
import Config
import Piece
import Player
import Search
import Strategy
import Type

seed : U64
seed = 74

loc_str : List(Str), U64 -> Str
loc_str = |zone_colors, s|
	if s == Board.bullseye {
		"bullseye"
	} else {
		"${List.get(zone_colors, Board.zone(s)) ?? "?"}.${Board.loc_of(zone_colors, s).id}"
	}

## A number for every piece: its square and its color.
sorted_nums : List(U64) -> List(U64)
sorted_nums = |xs| List.sort_with(xs, |a, b| if a < b { Before } else if a > b { After } else { Same })

Key : { board : List(U64), hand : List(U64), turn : Type.Turn, credits : I64 }

key : Search.Line -> Key
key = |line| {
	g = line.game
	p = Player.get_active_player(g)
	{
		board: List.join(List.map_with_index(g.board, |v, sq| if v == 0 { [] } else { [10 * sq + U8.to_u64(v) - 1] })),
		hand: sorted_nums(List.map(p.hand, |c| I64.to_u64_wrap(Config.card_value(c)))),
		turn: p.turn,
		credits: p.get_out_credits,
	}
}

distinct_keys : List(Search.Line) -> U64
distinct_keys = |lines|
	List.len(
		List.fold(
			lines,
			[],
			|kept, l| {
				k = key(l)
				if List.contains(kept, k) { kept } else { List.append(kept, k) }
			},
		),
	)

## The distinct boards among these lines, each with how many lines reach it
## and one of them.
boards : List(Search.Line) -> List({ board : List(U64), n : U64, example : Search.Line })
boards = |lines|
	List.fold(
		lines,
		[],
		|kept, l| {
			b = key(l).board
			match List.find_first_index(kept, |x| x.board == b) {
				Ok(i) => List.update(kept, i, |x| { ..x, n: x.n + 1 }) ?? kept
				Err(_) => List.append(kept, { board: b, n: 1, example: l })
			}
		},
	)

pieces : Type.Game -> Str
pieces = |g|
	Str.join_with(
		List.map(
			g.zone_colors,
			|c| "${c}: ${Str.join_with(List.map(Piece.my_pieces(g.board, Board.color_index(g.zone_colors, c)), |sq| loc_str(g.zone_colors, sq)), " ")}",
		),
		"\n",
	)

main! = |_args| {
	seats = List.repeat(Plays(Strategy.champion), 4)
	start_game = Game.begin_game(seed, Normal, Solo)
	var $g = start_game
	var $best = { n: 0, game: start_game, turn: 0 }
	var $searches = 0
	var $total = 0
	var $big = 0
	var $turn = 1
	var $over = Bool.False
	var $steps = 0
	while !$over and $steps < 100000 {
		a = $g.active_player_idx
		if Player.get_active_player($g).turn != TurnDone {
			n = List.len(Search.all_lines($g).lines)
			$searches = $searches + 1
			$total = $total + n
			$big = $big + (if n > 100 { 1 } else { 0 })
			if n > $best.n {
				$best = { n, game: $g, turn: $turn }
			}
		}
		s = Arena.step(seats, $g)
		if Arena.home(s.game, a) {
			$over = Bool.True
		}
		if s.game.active_player_idx == 0 and a != 0 {
			$turn = $turn + 1
		}
		$g = s.game
		$steps = $steps + 1
	}
	g = $best.game
	mover = Player.get_active_player(g)
	Echo.line!("## Seed ${U64.to_str(seed)}: the biggest search\n")
	Echo.line!("${U64.to_str($searches)} searches to the first player home, ${U64.to_str($total)} lines in all; ${U64.to_str($big)} searches had more than 100.\n")
	Echo.line!("The biggest: ${U64.to_str($best.n)} lines, ${mover.color} to play in round ${U64.to_str($best.turn)}, hand ${Str.join_with(mover.hand, " ")}, discard credits ${I64.to_str(mover.get_out_credits)}. The board:\n")
	Echo.line!(pieces(g))
	Echo.line!("\nLevel by level (a level is one more card):\n")
	Echo.line!("| level | open lines | grown | kept by distinct_lines | positions | boards |")
	Echo.line!("|---|---|---|---|---|---|")
	first = Search.settle({ game: g, msgs: [], drew: Bool.False })
	var $level = first
	var $done = List.drop_if(first, Search.is_open)
	var $depth = 0
	while List.any($level, Search.is_open) and $depth < 8 {
		open = List.keep_if($level, Search.is_open)
		grown = List.join_map(open, Search.expand)
		merged = Search.distinct_lines(grown)
		Echo.line!("| ${U64.to_str($depth + 1)} | ${U64.to_str(List.len(open))} | ${U64.to_str(List.len(grown))} | ${U64.to_str(List.len(merged))} | ${U64.to_str(distinct_keys(grown))} | ${U64.to_str(List.len(boards(grown)))} |")
		$level = merged
		$done = List.concat($done, List.drop_if(merged, Search.is_open))
		$depth = $depth + 1
	}
	finals = List.keep_if(List.concat($done, List.keep_if($level, Search.is_open)), |l| !List.is_empty(l.msgs))
	final_boards = List.sort_with(boards(finals), |x, y| if x.n > y.n { Before } else if x.n < y.n { After } else { Same })
	Echo.line!("\nThe search's answer: ${U64.to_str(List.len(finals))} lines, ${U64.to_str(distinct_keys(finals))} positions, ${U64.to_str(List.len(final_boards))} boards.\n")
	Echo.line!("The boards reached most often:\n")
	for b in List.take_first(final_boards, 3) {
		Echo.line!("${U64.to_str(b.n)} lines reach:\n${pieces(b.example.game)}\n")
	}
	Ok({})
}
