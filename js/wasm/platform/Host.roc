## This module is the page's effects, as the platform hands them to Roc. The
## page's host (../host.zig) answers each by calling into the page's
## JavaScript, js_runner.js, while the Roc call that asked is still running.
##
## A list handed to the host is the host's: it gives the list back to the
## Roc to drop (`drop_bytes`) once the page has read it. The tags cross as
## one byte, numbered alphabetically: `X` 0 and `Y` 1, `Down` 0 and `Up` 1.
Host := [].{

	## One line for the page: an effect's written form (Canvas.line_of), or
	## the line `end ...` that says how a call ended (JsApp.roc).
	emit! : List(U8) => {}

	## Where the pointer is on the canvas, along one axis.
	pointer! : [X, Y] => F64

	## Whether the key of this name (a KeyboardEvent's `key`) is held down.
	key! : List(U8) => [Down, Up]
}
