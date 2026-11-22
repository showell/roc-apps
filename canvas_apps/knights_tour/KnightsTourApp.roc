## KnightsTourApp is the Knight's Tour as a canvas app: the Knight machine on
## the chess kit's page, with the tour's words. Click a square and a tour
## starts there; knights pile on, dead-end, and are pulled back off.
import chess.ChessApp
import lib.CanvasApp
import Knight

KnightsTourApp :: [].{

	Model : ChessApp.Model(Knight)

	canvas_app : CanvasApp.CanvasApp(KnightsTourApp.Model)
	canvas_app = ChessApp.canvas_app({
		target_count: 64,
		next_move: Knight.next_move,
		start: Knight.start,
		impossible_squares: Knight.impossible_squares,
		moves_from: Knight.moves_from,
		words: {
			title: "Knight's Tour",
			piece: "♞",
			noun: "knights",
			one_noun: "knight",
			hover_hint: "knight moves",
			click_hint: "start a tour there",
			start_hint: "click a square to place the first knight",
			indigo_hint: "cut off from the tour",
			solved_message: "tour complete!",
			exhausted_message: "no tour from here (search exhausted)",
		},
	})
}
