# Wire -- what a view IS, declared by the platform so the type table carries
# it and `roc glue` writes the page's reader.
#
# Structural throughout (`:`, not `:=`), so the app's values unify with these
# by shape. Integers are U32 and reals F64: a U64 would reach JavaScript as a
# BigInt.
#
# A page is a list of `Node`s in document order. `parent` is the index of the
# parent plus one, and 0 for the page itself. A node with tag "" is text; the
# node with tag "board" is where the board goes. `click` is the code a click
# sends back to `update`, 0 for none.
#
# The board is `slots`: one per square, in the same order every time, so a
# page draws them once and afterwards changes only what changed.
Wire :: [].{
	Slot : {
		square : Bool,
		cx : F64,
		cy : F64,
		size : F64,
		fill : Str,
		stroke : Str,
		piece : Str,
		piece_r : F64,
		click : U32,
	}

	Node : { parent : U32, tag : Str, text : Str, style : Str, click : U32, disabled : Bool }

	## `tick` is a code the page sends back by itself after a pause (the
	## computer's next click), 0 for none; `winner` is a color, or "".
	View : { board_size : F64, slots : List(Wire.Slot), nodes : List(Wire.Node), tick : U32, winner : Str }
}
