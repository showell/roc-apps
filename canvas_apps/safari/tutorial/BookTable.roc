## A table's code can be wide, and a phone has little room. This module marks the
## places where a name may break, after a `.` or a `_`, so a narrow table wraps a
## long name there and never mid-word. It works on rendered HTML because the
## renderer writes no markup a chapter can reach.
import BookText

BookTable := [].{

	## Each table's code with its break points marked.
	with_break_points : Str -> Str
	with_break_points = |html| BookText.rewritten_after(html, { opening: table_open, rewrite: marked_table })
}

table_open : Str
table_open = "<table>"

code_open : Str
code_open = "<code>"

## One piece after a `<table>`: the table up to its end, then the page after it.
marked_table : Str -> Str
marked_table = |piece| match piece.split_first("</table>") {
	Ok({ before: cells, after }) => {
		marked = BookText.rewritten_after(cells, { opening: code_open, rewrite: marked_code })
		"${marked}</table>${after}"
	}
	Err(NotFound) => crash "book: a table with no end: ${piece}"
}

## One piece after a `<code>`: the code up to its end, then the cell after it.
marked_code : Str -> Str
marked_code = |piece| match piece.split_first("</code>") {
	Ok({ before: code, after }) => {
		marked = code.replace_each("_", "_<wbr>").replace_each(".", ".<wbr>")
		"${marked}</code>${after}"
	}
	Err(NotFound) => crash "book: code with no end in a table: ${piece}"
}

expect BookTable.with_break_points("<p><code>a_b.c</code></p>") == "<p><code>a_b.c</code></p>"
expect BookTable.with_break_points("<table><tr><td>a_b.c</td></tr></table>") == "<table><tr><td>a_b.c</td></tr></table>"
expect
	BookTable.with_break_points("<table><td><code>a_b.c</code> d_e</td></table><code>f_g</code>")
		== "<table><td><code>a_<wbr>b.<wbr>c</code> d_e</td></table><code>f_g</code>"
expect
	BookTable.with_break_points("<table><code>a_b</code></table>x<table><code>c.d</code></table>")
		== "<table><code>a_<wbr>b</code></table>x<table><code>c.<wbr>d</code></table>"
