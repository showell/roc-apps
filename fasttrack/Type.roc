# Type -- the game's vocabulary, from elm-fasttrack's Type.elm.
#
# Colors, cards and location ids stay strings, as in Elm. Elm's tuples
# `( Zone, String )` and `( MoveType, PieceLocation, PieceLocation )` are
# records here. Elm's Maybe is Roc's Try.
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

	PieceMap : Assoc.AssocDict(Type.PieceLocation, Str)

	PlayType : [PlayCard(Str), FinishSeven(I64)]

	MoveType : [WithCard(Str), Reverse(Str), StartSplit(I64), FinishSplit(I64, Type.PieceLocation), JackTrade]

	MoveFlavor : [RegularMove, TradePieces]

	Move : { kind : Type.MoveType, start : Type.PieceLocation, end : Type.PieceLocation }

	Turn : [
		TurnIdle,
		TurnBegin,
		TurnNeedCard({ moves : List(Type.Move) }),
		TurnNeedStartLoc({ play_type : Type.PlayType, moves : List(Type.Move), start_locs : Assoc.AssocSet(Type.PieceLocation) }),
		TurnNeedEndLoc({ play_type : Type.PlayType, start_location : Type.PieceLocation, moves : List(Type.Move), end_locs : Assoc.AssocSet(Type.PieceLocation) }),
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

	Player : { deck : List(Str), hand : List(Str), get_out_credits : I64, turn : Type.Turn, color : Str, team : Type.Team }

	FindLocParams : {
		can_fast_track : Bool,
		can_leave_pen : Bool,
		can_leave_bulls_eye : Bool,
		reverse_mode : Bool,
		piece_color : Str,
		piece_map : Type.PieceMap,
		zone_colors : List(Str),
	}

	## Elm's `players` is a `Dict Int Player` keyed 0..n-1; a list says the same.
	Game : {
		zone_colors : List(Str),
		piece_map : Type.PieceMap,
		players : List(Type.Player),
		seed : ElmRandom.Seed,
		active_player_idx : U64,
		num_players : U64,
	}

	GameMsg : [
		ActivateCard(U64),
		DiscardCard(U64),
		CoverCard(U64),
		RotateBoard,
		SetEndLocation(Type.PieceLocation),
		SetStartLocation(Type.PieceLocation),
		UndoAction,
	]
}
