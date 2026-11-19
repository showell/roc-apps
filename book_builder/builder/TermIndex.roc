## This module builds a book's index from its prose: for each term of a terms
## file, the chapter that teaches it and every other chapter that mentions it.
##
## The terms file has a `## Category` line above each group of terms. A term
## is a line `Name`, or `Name | pattern | pattern ...`, each pattern a regular
## expression over a lowercased line of prose (TermPattern says which), and
## `\bname\b` when none is given. A part `main: Chapter title` names the
## chapter that teaches it, in place of the one that mentions it most. A blank
## line, or one that starts `#` but not `## `, is skipped.
##
## A term is found in a chapter when one of its patterns matches a line of
## that chapter's prose, every line outside a fence but its title. The index
## is a table for each category, its found terms in alphabetical order, each
## with its main chapter, `{{chapter Title}}`, and the others by number,
## `{{number N Title}}`, or "throughout" for a term in `spread` chapters or
## more. References makes each a link after the render.
import TermPattern

TermIndex := [].{

	## A chapter as the index reads it: its number, its title as its heading
	## spells it, and its prose, one line each, lowercased.
	Chapter : {
		number : U64,
		title : Str,
		prose_lines : List(Str),
	}

	## A term in this many chapters or more is "throughout".
	spread : U64
	spread = 15

	## The index's tables, as markdown, or what is wrong with the terms.
	tables : {
		terms : { name : Str, text : Str },
		chapters : List(TermIndex.Chapter),
	} -> Try(Str, Str)
	tables = |{ terms, chapters }| {
		parsed = terms_of(terms)?
		entries = parsed.map_try(|term| entry_of(term, chapters))?
		categories = categories_of(entries)
		Ok(Str.join_with(categories.map(|category| category_table(category, entries)), ""))
	}
}

## One term of the terms file.
Term : {
	category : Str,
	name : Str,
	patterns : List(TermPattern),
	main : Str,
}

## The terms in the file's order.
terms_of : { name : Str, text : Str } -> Try(List(Term), Str)
terms_of = |{ name, text }| {
	var $found = []
	var $category = ""
	var $number = 0
	for raw in text.split_on("\n") {
		$number = $number + 1
		at = "index: ${name}:${U64.to_str($number)}: "
		line = raw.trim()
		if line.starts_with("## ") {
			$category = line.drop_prefix("## ").trim()
		} else {
			if !line.is_empty() and !line.starts_with("#") {
				if $category.is_empty() {
					return Err("${at}a term before any `## Category`")
				}
				term = term_of(line, $category) ? |why| "${at}${why}"
				$found = $found.append(term)
			}
		}
	}
	Ok($found)
}

## A term's line, `Name | pattern | main: Title ...`.
term_of : Str, Str -> Try(Term, Str)
term_of = |line, category| match line.split_on(" | ") {
	[first, .. as parts] => {
		term_name = first.trim()
		var $patterns = []
		var $main = ""
		for raw_part in parts {
			part = raw_part.trim()
			if part.starts_with("main: ") {
				$main = part.drop_prefix("main: ").trim()
			} else {
				pattern = TermPattern.from_str(part) ? |why| "the term `${term_name}`'s pattern `${part}`: ${why}"
				$patterns = $patterns.append(pattern)
			}
		}
		patterns =
			if $patterns.is_empty() {
				own = "\\b${term_name.with_ascii_lowercased()}\\b"
				[TermPattern.from_str(own) ? |why| "the term `${term_name}`, as its own pattern: ${why}"]
			} else {
				$patterns
			}
		Ok({
			category,
			name: term_name,
			patterns,
			main: $main,
		})
	}
	[] => crash "book: Str.split_on answered no pieces"
}

## The index's entry for a term: how many lines of each chapter mention it,
## those chapters in order, and its main chapter, unless it is nowhere.
Entry : {
	term : Term,
	mentions : List({ chapter : TermIndex.Chapter, lines : U64 }),
	main : [Main(TermIndex.Chapter), Nowhere],
}

entry_of : Term, List(TermIndex.Chapter) -> Try(Entry, Str)
entry_of = |term, chapters| {
	is_mention = |line| term.patterns.any(|pattern| pattern.is_found_in(line))
	mentions = chapters
		.map(|chapter| { chapter, lines: chapter.prose_lines.count_if(is_mention) })
		.keep_if(|mention| mention.lines > 0)
	busiest = mentions.fold(
		Nowhere,
		|most, mention| match most {
			Nowhere => Busiest(mention)
			Busiest(held) if mention.lines > held.lines => Busiest(mention)
			Busiest(_) => most
		},
	)
	match busiest {
		Nowhere => Ok({ term, mentions, main: Nowhere })
		Busiest(held) if term.main.is_empty() => Ok({ term, mentions, main: Main(held.chapter) })
		Busiest(_) => {
			is_mentioned = |chapter|
				mentions.any(|mention| mention.chapter.number == chapter.number)
			match chapters.find_first(|chapter| chapter.title == term.main) {
				Err(NotFound) => Err("index: ${term.name}'s main chapter, ${term.main}, is no chapter of the book")
				Ok(chapter) if is_mentioned(chapter) => Ok({ term, mentions, main: Main(chapter) })
				Ok(_) => Err("index: ${term.name}'s main chapter, ${term.main}, never mentions it")
			}
		}
	}
}

## The categories, in the terms file's order.
categories_of : List(Entry) -> List(Str)
categories_of = |entries| entries.fold(
	[],
	|found, entry|
		if found.last() == Ok(entry.term.category) {
			found
		} else {
			found.append(entry.term.category)
		},
)

## A term's place in the alphabet: lowercased, with its backticks and other
## marks left out, so `match` sorts under m.
sort_key : Str -> List(U8)
sort_key = |term_name| term_name
	.with_ascii_lowercased()
	.to_utf8()
	.keep_if(|byte| (byte >= 'a' and byte <= 'z') or (byte >= '0' and byte <= '9') or byte == ' ')

## Two byte strings in byte order, a shorter one first when it starts the other.
compare_bytes : List(U8), List(U8) -> [Before, Same, After]
compare_bytes = |left, right| match (left, right) {
	([], []) => Same
	([], _) => Before
	(_, []) => After
	([left_byte, .. as left_rest], [right_byte, .. as right_rest]) =>
		if left_byte < right_byte {
			Before
		} else if left_byte > right_byte {
			After
		} else {
			compare_bytes(left_rest, right_rest)
		}
}

## One category's table: its found terms in alphabetical order, a tie kept in
## the file's order.
category_table : Str, List(Entry) -> Str
category_table = |category, entries| {
	found = entries
		.map_with_index(|entry, i| { entry, i })
		.keep_if(|keyed| keyed.entry.term.category == category and keyed.entry.main != Nowhere)
		.sort_with(
			|left_keyed, right_keyed| match compare_bytes(sort_key(left_keyed.entry.term.name), sort_key(right_keyed.entry.term.name)) {
				Same if left_keyed.i < right_keyed.i => Before
				Same if left_keyed.i > right_keyed.i => After
				order => order
			},
		)
	rows = found.map(|keyed| term_row(keyed.entry))
	head = "### ${category}\n\n| Term | Main chapter | Also in |\n|---|---|---|\n"
	"${head}${Str.join_with(rows, "")}\n"
}

term_row : Entry -> Str
term_row = |entry| match entry.main {
	Main(main) => {
		others =
			if entry.mentions.len() >= TermIndex.spread {
				"throughout"
			} else {
				entry.mentions
					.drop_if(|mention| mention.chapter.number == main.number)
					.map(|mention| "{{number ${mention.chapter.number.to_str()} ${mention.chapter.title}}}")
					|> Str.join_with(", ")
			}
		"| ${entry.term.name} | {{chapter ${main.title}}} | ${others} |\n"
	}
	Nowhere => crash "TermIndex.term_row: a term found nowhere has no row"
}

sample_chapters : List(TermIndex.Chapter)
sample_chapters = [
	{
		number: 1,
		title: "Gates",
		prose_lines: ["a gate is a check.", "the gate runs.", "one budget."],
	},
	{
		number: 2,
		title: "Budgets",
		prose_lines: ["a budget, and a gate.", "budgets bound a run.", "the budget again."],
	},
	{
		number: 3,
		title: "Replies",
		prose_lines: ["her reply came.", "a `gate` in code."],
	},
]

index_of : Str -> Try(Str, Str)
index_of = |text| TermIndex.tables({
	terms: { name: "terms.txt", text },
	chapters: sample_chapters,
})

expect
	index_of("# The terms.\n## Machinery\nGate | \\bgates?\\b\nBudget | \\bbudgets?\\b\n\n## Talk\nreply | \\brepl(y|ies)\\b | main: Replies\nFence\n")
		== Ok(
			"### Machinery\n\n| Term | Main chapter | Also in |\n|---|---|---|\n| Budget | {{chapter Budgets}} | {{number 1 Gates}} |\n| Gate | {{chapter Gates}} | {{number 2 Budgets}}, {{number 3 Replies}} |\n\n### Talk\n\n| Term | Main chapter | Also in |\n|---|---|---|\n| reply | {{chapter Replies}} |  |\n\n",
		)
expect index_of("Gate\n") == Err("index: terms.txt:1: a term before any `## Category`")
expect index_of("## A\nReply | main: Gates\n") == Err("index: Reply's main chapter, Gates, never mentions it")
expect index_of("## A\nGate | main: Gone\n") == Err("index: Gate's main chapter, Gone, is no chapter of the book")
expect index_of("## A\nGate | gate{2}\n") == Err("index: terms.txt:2: the term `Gate`'s pattern `gate{2}`: a count in braces")
expect index_of("## A\n## B\n") == Ok("")
expect
	index_of("## A\nzeta | budget\n`Alpha` | gate\nalpha | reply\n")
		== Ok("### A\n\n| Term | Main chapter | Also in |\n|---|---|---|\n| `Alpha` | {{chapter Gates}} | {{number 2 Budgets}}, {{number 3 Replies}} |\n| alpha | {{chapter Replies}} |  |\n| zeta | {{chapter Budgets}} | {{number 1 Gates}} |\n\n")
expect
	TermIndex.tables({
		terms: { name: "t", text: "## A\nword\n" },
		chapters: List.repeat(
			{
				number: 1,
				title: "C",
				prose_lines: ["a word"],
			},
			15,
		).map_with_index(|chapter, i| { ..chapter, number: i + 1 }),
	})
		== Ok("### A\n\n| Term | Main chapter | Also in |\n|---|---|---|\n| word | {{chapter C}} | throughout |\n\n")
expect
	TermIndex.tables({
		terms: { name: "t", text: "## A\nword\n" },
		chapters: List.repeat(
			{
				number: 1,
				title: "C",
				prose_lines: ["a word"],
			},
			14,
		).map_with_index(|chapter, i| { ..chapter, number: i + 1 }),
	})
		.map_ok(|table| table.contains("throughout") or !table.contains("{{number 14 C}}"))
		== Ok(Bool.False)
expect
	compare_bytes([], []) == Same
		and compare_bytes([1], [1, 2]) == Before
		and compare_bytes([2], [1, 2]) == After
