## A span is a run of a text's bytes, from `start` up to `end`, and the class
## it is colored as. A language's lexer answers a list of them that covers
## every byte of its text once, in order, and SyntaxColor turns that list into
## HTML.
Span := {
	class : Span.Class,
	start : U64,
	end : U64,
}.{

	## What a run of bytes is, as far as its color goes.
	Class : [Plain, Comment, String, Number, Keyword, Name, Type]

	is_eq : _

	## The CSS class a span of `class` is wrapped in, or nothing for plain text.
	## The names are the Safari book's book.css's.
	css_class : Span.Class -> Try(Str, [Plain])
	css_class = |class| match class {
		Plain => Err(Plain)
		Comment => Ok("syn-comment")
		String => Ok("syn-string")
		Number => Ok("syn-number")
		Keyword => Ok("syn-keyword")
		Name => Ok("syn-name")
		Type => Ok("syn-type")
	}

	## The spans with one more run after them. A run that touches the last span
	## and has its class extends it, and an empty run adds nothing.
	push_run : List(Span), Span -> List(Span)
	push_run = |spans, run|
		if run.end <= run.start {
			spans
		} else {
			match spans.last() {
				Ok(last) if last.end == run.start and last.class == run.class => {
					spans.drop_last(1).append({ ..last, end: run.end })
				}
				_ => spans.append(run)
			}
		}

	## The spans with one more token after them, for a language whose tokens
	## stay apart: a token touching the last span is kept apart from it even when
	## the two have one class, though plain text still extends plain text.
	push_token : List(Span), Span -> List(Span)
	push_token = |spans, run|
		if run.class == Plain {
			Span.push_run(spans, run)
		} else if run.end <= run.start {
			spans
		} else {
			spans.append(run)
		}

	## Whether the spans cover `0` up to `length` exactly once, in order, with no
	## empty span: what every lexer promises.
	is_cover : List(Span), U64 -> Bool
	is_cover = |spans, length| {
		reached = spans.fold_until(
			Ok(0),
			|at, span|
				match at {
					Ok(start) if span.start == start and span.end > start => Continue(Ok(span.end))
					_ => Break(Err(Gap))
				},
		)
		reached == Ok(length)
	}
}

expect Span.css_class(Plain) == Err(Plain)
expect
	[
		(Comment, "syn-comment"),
		(String, "syn-string"),
		(Number, "syn-number"),
		(Keyword, "syn-keyword"),
		(Name, "syn-name"),
		(Type, "syn-type"),
	].all(|(class, css)| Span.css_class(class) == Ok(css))

expect Span.push_run(
	[],
	{
		class: Plain,
		start: 0,
		end: 0,
	},
) == []
expect Span.push_run(
	[
		{
			class: Plain,
			start: 0,
			end: 2,
		},
	],
	{
		class: Plain,
		start: 2,
		end: 5,
	},
) == [
	{
		class: Plain,
		start: 0,
		end: 5,
	},
]
expect Span.push_run(
	[
		{
			class: Plain,
			start: 0,
			end: 2,
		},
	],
	{
		class: String,
		start: 2,
		end: 5,
	},
) == [
	{
		class: Plain,
		start: 0,
		end: 2,
	},
	{
		class: String,
		start: 2,
		end: 5,
	},
]
expect Span.push_token(
	[
		{
			class: String,
			start: 0,
			end: 2,
		},
	],
	{
		class: String,
		start: 2,
		end: 5,
	},
) == [
	{
		class: String,
		start: 0,
		end: 2,
	},
	{
		class: String,
		start: 2,
		end: 5,
	},
]
expect Span.push_token(
	[],
	{
		class: String,
		start: 3,
		end: 3,
	},
) == []
expect Span.push_token(
	[
		{
			class: Plain,
			start: 0,
			end: 2,
		},
	],
	{
		class: Plain,
		start: 2,
		end: 3,
	},
) == [
	{
		class: Plain,
		start: 0,
		end: 3,
	},
]

expect Span.is_cover([], 0)
expect !Span.is_cover([], 1)
expect Span.is_cover(
	[
		{
			class: Plain,
			start: 0,
			end: 2,
		},
		{
			class: Comment,
			start: 2,
			end: 3,
		},
	],
	3,
)
expect !Span.is_cover(
	[
		{
			class: Plain,
			start: 0,
			end: 2,
		},
		{
			class: Comment,
			start: 3,
			end: 4,
		},
	],
	4,
)
expect !Span.is_cover(
	[
		{
			class: Plain,
			start: 0,
			end: 2,
		},
		{
			class: Comment,
			start: 1,
			end: 3,
		},
	],
	3,
)
expect !Span.is_cover(
	[
		{
			class: Plain,
			start: 0,
			end: 2,
		},
	],
	3,
)
expect !Span.is_cover(
	[
		{
			class: Plain,
			start: 0,
			end: 0,
		},
		{
			class: Plain,
			start: 0,
			end: 1,
		},
	],
	1,
)
