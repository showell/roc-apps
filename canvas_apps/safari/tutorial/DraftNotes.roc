## A draft keeps its open questions in plain sight. This module wraps them in a
## class so the stylesheet can mark them, and a reader can't take one for the
## book's own voice. It works on rendered HTML because the renderer escapes raw
## markup, and these notes sit in the middle of a paragraph, so no fence can
## reach them.
import BookText

DraftNotes := [].{

	## Marks each `[check: ...]` note, and each paragraph that is one
	## `*[...]*` placeholder.
	highlight : Str -> Str
	highlight = |html| {
		placeholders_marked = html.replace_each("<p><em>[", "<p class=\"draft-note\"><em>[")
		notes_closed = BookText.rewritten_after(placeholders_marked, { opening: check_open, rewrite: check_note_end })
		notes_closed.replace_each(check_open, "<span class=\"draft-note\">${check_open}")
	}
}

check_open : Str
check_open = "[check: "

## One piece after a `[check: `: the note up to its `]`, the end of its span, then
## the prose after it. The span's start goes in front of each `[check: ` after.
check_note_end : Str -> Str
check_note_end = |piece| match piece.split_first("]") {
	Ok({ before, after }) =>
		if before.contains("[") {
			crash "book: a [check: note has a [ inside it: ${piece}"
		} else {
			"${before}]</span>${after}"
		}
	Err(NotFound) => crash "book: a [check: note never closes with a ]: ${piece}"
}

expect DraftNotes.highlight("<p>plain [text] here</p>") == "<p>plain [text] here</p>"
expect DraftNotes.highlight("<p>a [check: b] c</p>") == "<p>a <span class=\"draft-note\">[check: b]</span> c</p>"
expect DraftNotes.highlight("<p>[check: a] b [check: c]</p>") == "<p><span class=\"draft-note\">[check: a]</span> b <span class=\"draft-note\">[check: c]</span></p>"
expect DraftNotes.highlight("<p><em>[A widget goes here.]</em></p>") == "<p class=\"draft-note\"><em>[A widget goes here.]</em></p>"
expect DraftNotes.highlight("<p><em>not a note</em></p>") == "<p><em>not a note</em></p>"
