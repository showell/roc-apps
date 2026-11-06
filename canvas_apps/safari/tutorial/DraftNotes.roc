## A draft keeps its open questions in plain sight. This module wraps them in a
## class so the stylesheet can mark them, and a reader can't take one for the
## book's own voice. It works on rendered HTML because the renderer escapes raw
## markup, and these notes sit in the middle of a paragraph, so no fence can
## reach them.
DraftNotes := [].{

	## Marks each `[check: ...]` note, and each paragraph that is one
	## `*[...]*` placeholder.
	highlight : Str -> Str
	highlight = |html| {
		pieces = html.replace_each("<p><em>[", "<p class=\"draft-note\"><em>[").split_on(check_open)
		match pieces {
			[before_any, .. as notes] => Str.join_with([before_any].concat(notes.map(check_note_html)), "")
			[] => html
		}
	}
}

check_open : Str
check_open = "[check: "

## One piece after a `[check: `: the note up to its `]`, then the prose after it.
check_note_html : Str -> Str
check_note_html = |piece| match piece.split_first("]") {
	Ok({ before, after }) if !before.contains("[") => "<span class=\"draft-note\">${check_open}${before}]</span>${after}"
	_ => crash "book: a [check: note needs one closing bracket and no bracket inside it: ${piece}"
}

expect DraftNotes.highlight("<p>plain [text] here</p>") == "<p>plain [text] here</p>"
expect DraftNotes.highlight("<p>a [check: b] c</p>") == "<p>a <span class=\"draft-note\">[check: b]</span> c</p>"
expect DraftNotes.highlight("<p>[check: a] b [check: c]</p>") == "<p><span class=\"draft-note\">[check: a]</span> b <span class=\"draft-note\">[check: c]</span></p>"
expect DraftNotes.highlight("<p><em>[A widget goes here.]</em></p>") == "<p class=\"draft-note\"><em>[A widget goes here.]</em></p>"
expect DraftNotes.highlight("<p><em>not a note</em></p>") == "<p><em>not a note</em></p>"
