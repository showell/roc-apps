# What the chess toys share, as a package: the event tape every search
# writes and the board replays, and the page every toy is drawn on. A toy
# reaches this as `chess: "../chess_kit/main.roc"` and says
# `import chess.Tape` and `import chess.ChessApp`.
package
	[
		ChessApp,
		ChessBoard,
		ChessControls,
		Tape,
	]
	{ lib: "../lib/main.roc" }
