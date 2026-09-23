# Analysis: where playing against the leader chooses differently. Every seat
# plays Strategy.champion; at each of red's searches the leader-chasing
# strategy (`opponents: Leader`) is asked too, and where the two lines part,
# the log says what the chaser gave up of red's own position and what it took
# off the leader, and whether either line captured.
#
#   fasttrack/run_exp.sh exp_leader_shadow
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Game
import Player
import Search
import Strategy
import Type

loc_str : Type.PieceLocation -> Str
loc_str = |loc|
	match loc.zone {
		BullsEyeZone => "bullseye"
		NormalColor(zone) => "${zone}.${loc.id}"
	}

## The pieces a line moved: where they left and where they went.
moved : Type.Game, Type.Game -> Str
moved = |before, after| {
	left = List.keep_if(before.piece_map, |e| !List.contains(after.piece_map, e))
	went = List.keep_if(after.piece_map, |e| !List.contains(before.piece_map, e))
	show = |es| Str.join_with(List.map(es, |e| "${e.value}@${loc_str(e.key)}"), " ")
	"from ${show(left)} to ${show(went)}"
}

## The opponent whose pieces are worth most, as the champion values them.
leading : Type.Game -> Str
leading = |game|
	List.fold(
		["blue", "green", "purple"],
		{ color: "", v: I64.lowest },
		|best, c| {
			v = Strategy.board(Strategy.champion, game, [c])
			if v > best.v { { color: c, v } } else { best }
		},
	).color

main! = |_args| {
	champion = Strategy.champion
	chaser = { ..champion, opponents: Leader }
	seats = List.repeat(Plays(champion), 4)
	games = 20
	var $decisions = 0
	var $differ = 0
	var $given = 0
	var $gained = 0
	var $cap_champion = 0
	var $cap_chaser = 0
	var $cap_chaser_leader = 0
	var $shown = 0
	var $behind = 0
	var $behind_differ = 0
	for seed in List.map_with_index(List.repeat(0, games), |_, i| i + 1) {
		var $g = Game.begin_game(seed, Normal, Solo)
		var $turn = 1
		var $steps = 0
		while !Arena.home($g, 0) and $steps < 100000 {
			red_to_search = $g.active_player_idx == 0 and Player.get_active_player($g).turn != TurnDone
			a = if red_to_search { Search.best_line(champion, $g) } else { Err(NoPlay) }
			b = if red_to_search { Search.best_line(chaser, $g) } else { Err(NoPlay) }
			next = match a {
				Ok(best) => best.line.game
				Err(_) => Arena.step(seats, $g).game
			}
			if Try.is_ok(a) and Try.is_ok(b) {
				la = (a ?? crash("no line")).line
				lb = (b ?? crash("no line")).line
				$decisions = $decisions + 1
				red_colors = Strategy.team(Player.get_active_player($g))
				behind = Strategy.leader(champion, $g, red_colors) > Strategy.board(champion, $g, red_colors)
				$behind = $behind + (if behind { 1 } else { 0 })
				$behind_differ = $behind_differ + (if behind and la.game != lb.game { 1 } else { 0 })
				if la.game != lb.game {
					mover = Player.get_active_player($g)
					colors = Strategy.team(mover)
					worths = Strategy.hoard_worths(champion, $g, mover.color)
					own = |l| Strategy.board(champion, l.game, colors) + (if l.drew { 0 } else { Strategy.hand(worths, Player.get_active_player(l.game).hand) })
					lead = |l| Strategy.leader(champion, l.game, colors)
					took = |l| U64.to_i64_wrap(Arena.others_in_pen(l.game)) - U64.to_i64_wrap(Arena.others_in_pen($g))
					who = leading($g)
					took_leader = Arena.in_pen(lb.game, who) > Arena.in_pen($g, who)
					$differ = $differ + 1
					$given = $given + own(la) - own(lb)
					$gained = $gained + lead(la) - lead(lb)
					$cap_champion = $cap_champion + (if took(la) > 0 { 1 } else { 0 })
					$cap_chaser = $cap_chaser + (if took(lb) > 0 { 1 } else { 0 })
					$cap_chaser_leader = $cap_chaser_leader + (if took_leader { 1 } else { 0 })
					if $shown < 15 {
						$shown = $shown + 1
						Echo.line!(
							"\nseed ${U64.to_str(seed)}, red's turn ${U64.to_str($turn)}, hand ${Str.join_with(mover.hand, " ")}, leader ${who}\n  champion: ${moved($g, la.game)} (own ${I64.to_str(own(la))}, leader ${I64.to_str(lead(la))})\n  chaser:   ${moved($g, lb.game)} (own ${I64.to_str(own(lb))}, leader ${I64.to_str(lead(lb))})",
						)
					}
				}
			}
			if next.active_player_idx == 0 and $g.active_player_idx != 0 {
				$turn = $turn + 1
			}
			$g = next
			$steps = $steps + 1
		}
		Echo.line!("seed ${U64.to_str(seed)}: ${U64.to_str($differ)} of ${U64.to_str($decisions)} searches so far chose differently")
	}
	d = I64.max(1, U64.to_i64_wrap($differ))
	Echo.line!(
		"\n${U64.to_str(games)} games of four champions; at each of red's searches the chaser is asked too.\n${U64.to_str($differ)} of ${U64.to_str($decisions)} searches chose differently. Where they did, the chaser on average gave up ${I64.to_str($given // d)} of red's own value and took ${I64.to_str($gained // d)} off the leader.\nLines that captured: champion ${U64.to_str($cap_champion)}, chaser ${U64.to_str($cap_chaser)} (the leader's piece ${U64.to_str($cap_chaser_leader)}).\nRed was behind the leader as ${U64.to_str($behind)} of its ${U64.to_str($decisions)} searches began, and at ${U64.to_str($behind_differ)} of the ${U64.to_str($differ)} where the chaser chose differently.",
	)
	Ok({})
}
