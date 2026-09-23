# TeamTests -- partnerships: pagat.com's rules, and the "once home" style.
#
# Partners sit opposite, so red plays with green and blue with purple.
import Assoc
import Game
import LegalMove
import Piece
import Player
import Search
import Strategy
import Type

TeamTests :: [].{
	## A partnership game with only these pieces, red to play these cards.
	game_with : Type.Teams, List((Str, Str, Str)), List(Str) -> Type.Game
	game_with = |teams, pieces, hand| {
		start = Game.begin_game(0, Normal, teams)
		piece_map = List.fold(pieces, [], |pm, (zone, id, color)| Assoc.dict_insert(pm, { zone: NormalColor(zone), id }, color))
		players = Player.update_player(start.players, 0, |p| { ..p, hand, turn: TurnBegin })
		Player.set_turn_to_need_card({ ..start, piece_map, players })
	}

	starts : Type.Game -> List(Str)
	starts = |game| {
		moves = LegalMove.get_moves_for_cards(
			Assoc.set_from_list(Player.get_player(game.players, 0).hand),
			game.piece_map,
			game.zone_colors,
			Player.movers(Player.get_player(game.players, 0), game.piece_map),
		)
		Assoc.set_from_list(List.map(moves, |m| "${Piece.get_the_piece(game.piece_map, m.start)}@${m.start.id}"))
	}

	home : Str -> List((Str, Str, Str))
	home = |color| List.map(["B1", "B2", "B3", "B4"], |id| (color, id, color))
}

# Who red may move.
expect {
	g = TeamTests.game_with(Anytime, [("red", "L0", "red")], ["2"])
	Player.movers(Player.get_player(g.players, 0), g.piece_map) == ["red", "green"]
}
expect {
	g = TeamTests.game_with(OnceHome, [("red", "L0", "red")], ["2"])
	Player.movers(Player.get_player(g.players, 0), g.piece_map) == ["red"]
}
expect {
	g = TeamTests.game_with(OnceHome, TeamTests.home("red"), ["2"])
	Player.movers(Player.get_player(g.players, 0), g.piece_map) == ["red", "green"]
}
expect {
	g = TeamTests.game_with(Solo, [("red", "L0", "red")], ["2"])
	Player.movers(Player.get_player(g.players, 0), g.piece_map) == ["red"]
}

# Red's 2 moves either red's piece or green's.
expect {
	g = TeamTests.game_with(Anytime, [("red", "L0", "red"), ("green", "L0", "green")], ["2"])
	List.len(TeamTests.starts(g)) == 2 and List.contains(TeamTests.starts(g), "green@L0")
}

# Green's piece on the fast track is the team's: red must move it.
expect {
	g = TeamTests.game_with(Anytime, [("red", "L0", "red"), ("blue", "FT", "green")], ["2"])
	TeamTests.starts(g) == ["green@FT"]
}

# A seven splits between red's piece and green's.
expect {
	g = TeamTests.game_with(Anytime, [("red", "L0", "red"), ("green", "L0", "green")], ["7"])
	moves = LegalMove.get_moves_for_cards(["7"], g.piece_map, g.zone_colors, ["red", "green"])
	List.any(moves, |m| m.kind == StartSplit(3))
}

# A team wins only with both partners home.
expect Game.winner(TeamTests.game_with(Anytime, TeamTests.home("red"), ["2"])) == Err(NoWinner)
expect Game.winner(TeamTests.game_with(Anytime, List.concat(TeamTests.home("red"), TeamTests.home("green")), ["2"])) == Ok("red and green")
expect Game.winner(TeamTests.game_with(Solo, TeamTests.home("red"), ["2"])) == Ok("red")

# With a 3 that would land red's piece on green's, the team's computer does
# something else.
expect {
	g = TeamTests.game_with(Anytime, [("red", "L0", "red"), ("red", "L3", "green")], ["3", "2"])
	finished = match Search.best_line(Strategy.champion, g) {
		Ok(best) => best.line.game
		Err(_) => g
	}
	!List.any(finished.piece_map, |e| e.value == "green" and e.key.id == "HP1")
}
