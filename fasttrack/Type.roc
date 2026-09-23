# Type -- the game's vocabulary, from elm-fasttrack's Type.elm.
#
# Colors and cards stay strings, as in Elm; a square is its number
# (Board.roc), and a PieceLocation (zone and id) is only for the page and the
# tests. Elm's tuple `( MoveType, PieceLocation, PieceLocation )` is a
# record here. Elm's Maybe is Roc's Try.
#
# Why PlayType and MoveType both exist: after a J or a 7 is played and a
# starting piece clicked, several moves may be possible, of several KINDS.
# PlayType is what the player chose; MoveType is how a particular move gets
# there.
import Assoc
import ElmRandom

Type :: [].{
	Color : Str

	Card : Str

	Location : { x : F64, y : F64, id : Str }

	Zone : [NormalColor(Str), BullsEyeZone]

	PieceLocation : { zone : Type.Zone, id : Str }

	## Who stands on each of the 89 squares (Board.roc): 0 nobody, else the
	## color's place in the game's color order, plus one.
	Board : List(U8)

	PlayType : [PlayCard(Str), FinishSeven(I64)]

	MoveType : [WithCard(Str), Reverse(Str), StartSplit(I64), FinishSplit(I64, U64), JackTrade]

	MoveFlavor : [RegularMove, TradePieces]

	Move : { kind : Type.MoveType, start : U64, end : U64 }

	Turn : [
		TurnIdle,
		TurnBegin,
		TurnNeedCard({ moves : List(Type.Move) }),
		TurnNeedStartLoc({ play_type : Type.PlayType, moves : List(Type.Move), start_locs : Assoc.AssocSet(U64) }),
		TurnNeedEndLoc({ play_type : Type.PlayType, start_location : U64, moves : List(Type.Move), end_locs : Assoc.AssocSet(U64) }),
		TurnNeedDiscard,
		TurnNeedCover,
		TurnDone,
	]

	## Whose pieces a player may move besides its own (Player.movers):
	## none; a partner's at any time (pagat.com's partnership rules); or a
	## partner's once its own are all home.
	Team : [Solo, Partner(Str), PartnerOnceHome(Str)]

	## How a game seats its players: each for itself, or in partnerships of
	## either style.
	Teams : [Solo, Anytime, OnceHome]

	## A player's deck is shuffled once and drawn from the top; `seed` is its
	## own random stream, for the next shuffle when the deck runs out.
	Player : { deck : List(Str), hand : List(Str), get_out_credits : I64, turn : Type.Turn, color : Str, team : Type.Team, seed : ElmRandom.Seed }

	## Elm's `players` is a `Dict Int Player` keyed 0..n-1; a list says the same.
	Game : {
		zone_colors : List(Str),
		board : Type.Board,
		players : List(Type.Player),
		active_player_idx : U64,
		num_players : U64,
	}

	GameMsg : [
		ActivateCard(U64),
		DiscardCard(U64),
		CoverCard(U64),
		RotateBoard,
		SetEndLocation(U64),
		SetStartLocation(U64),
		UndoAction,
	]
}
