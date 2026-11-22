## EightQueensApp is Eight Queens as a canvas app: the Queens machine on the
## chess kit's page, with the puzzle's words. Click a square to pin the first
## queen there; the search fills in the rest.
import chess.ChessApp
import lib.CanvasApp
import Queens

EightQueensApp :: [].{

	Model : ChessApp.Model(Queens)

	canvas_app : CanvasApp.CanvasApp(EightQueensApp.Model)
	canvas_app = ChessApp.canvas_app({
		target_count: 8,
		next_move: Queens.next_move,
		start: Queens.start,
		impossible_squares: Queens.impossible_squares,
		moves_from: Queens.moves_from,
		words: {
			title: "Eight Queens",
			piece: "♛",
			noun: "queens",
			one_noun: "queen",
			hover_hint: "queen attacks",
			click_hint: "pin the first queen there",
			start_hint: "click a square to pin the first queen",
			indigo_hint: "attacked — no queen can live there",
			solved_message: "solution found!",
			exhausted_message: "no solution with that pin",
		},
	})
}
