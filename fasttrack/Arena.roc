# Arena -- games four champions play, for the positions SearchTests freezes
# the champion's choice in. A seat that finds no play passes its turn.
import Game
import History
import Player
import Search
import Strategy
import Type

Arena :: [].{

	## The next player's turn.
	rotate : Type.Game -> Type.Game
	rotate = |game| Game.update_game(RotateBoard, History.init({}), game).1

	## The mover's whole turn as the champion plays it, or a finished turn
	## passed on.
	step : Type.Game -> Type.Game
	step = |g|
		if Player.get_active_player(g).turn == TurnDone {
			rotate(g)
		} else {
			match Search.best_line(Strategy.champion, g) {
				Ok(best) => best.line.game
				Err(_) => rotate(g)
			}
		}

	## The start of red's turn `turn` of a seed, four champions playing.
	position : U64, U64 -> Type.Game
	position = |seed, turn| {
		var $g = Game.begin_game(seed, Normal, Solo)
		var $turn = 1
		var $steps = 0
		while $turn < turn and $steps < 100000 {
			next = step($g)
			if next.active_player_idx == 0 and $g.active_player_idx != 0 {
				$turn = $turn + 1
			}
			$g = next
			$steps = $steps + 1
		}
		$g
	}
}
