## This lint finds the negative sentences in a book's prose. A book whose rule
## is "say what happens, not what something isn't" rewrites each negative, or
## keeps it and lists it in a table with its kind. It reads the manuscript as
## written, before its includes are expanded, so a quoted file never counts.
##
## The prose is every line outside a fence, except a line that starts `{{`.
## Code spans, between backticks, are taken out before the words are read, and
## so is a chapter reference, `{{chapter Title}}`. A table row's cells are read
## one by one. A sentence ends at `.`, `!` or `?` followed by a space or the
## line's end, so `4.5` and `Distance.metres` stay in one. A curly apostrophe
## reads as a straight one. A negative is a sentence holding one of the words
## file's words, matched as a whole word in any case, and it counts once
## however many it holds.
##
## The words file holds a word or a phrase a line; a blank line or one that
## starts `#` is skipped. The table opens with its kinds, each a line
## `# keep name: what it is` or `# fix name: what it is`. Every other line that
## isn't blank or a `#` comment is `kind: the sentence`, the sentence exactly as
## a finding prints it, and its kind must be a `keep` kind.
import BookText
import Manuscript

Negatives := [].{

	## The findings, one line each, and a summary of the counts. The words
	## file and the table each come with the name the messages give it. A
	## table or a words file that can't be read as the header says is an
	## error.
	judged :
		{
			manuscript : Str,
			lines : List(Manuscript.Line),
			words : { name : Str, text : Str },
			table : { name : Str, text : Str },
		} -> Try({ findings : List(Str), summary : Str }, Str)
	judged = |{ manuscript, lines, words, table }| {
		word_list = words_of(words)?
		exceptions = exception_table(table)?
		prose = prose_hits(lines, word_list)
		if prose.read_count == 0 {
			Err("negatives: no prose in ${manuscript}")
		} else {
			unlisted = prose.found.drop_if(|hit| exceptions.sentences.contains(hit.sentence))
			unused = exceptions.rows.drop_if(|row| prose.found.any(|hit| hit.sentence == row.sentence))
			findings =
				unlisted
					.map(|hit| "${manuscript}:${hit.line.to_str()}: negative [${hit.chapter}] ${hit.words}: ${hit.sentence}")
					.concat(unused.map(|row| "${table.name}:${row.line.to_str()}: unused_exception: no negative sentence of the prose is `${row.sentence}`"))
			counts = [
				"negative ${unlisted.len().to_str()}",
				"unused_exception ${unused.len().to_str()}",
				"${prose.found.len().to_str()} negative sentences of ${prose.read_count.to_str()} read",
				"${exceptions.rows.len().to_str()} kept in the table",
			]
			Ok({ findings, summary: "negatives: ${Str.join_with(counts, ", ")}" })
		}
	}

	## The sentences of a text, as the lint reads them.
	sentences : Str -> List(Str)
	sentences = |text| {
		bytes = text.to_utf8()
		len = bytes.len()
		var $found = []
		var $at = 0
		while $at < len {
			run_end = sentence_run_end(bytes, $at)
			if run_end == $at {
				$at = $at + 1
			} else {
				var $end = run_end
				while $end < len and is_stop(byte_at(bytes, $end)) {
					$end = $end + 1
				}
				sentence = BookText.text_from_bytes(bytes.sublist({ start: $at, len: $end - $at })).trim()
				if !sentence.is_empty() {
					$found = $found.append(sentence)
				}
				$at = $end
			}
		}
		$found
	}

	## The words of `word_list` in a sentence, its code and chapter references
	## taken out, each once, in the order they come.
	words_in : Str, List(Str) -> List(Str)
	words_in = |sentence, word_list| {
		plain = BookText.without_code_spans(sentence.replace_each("’", "'"))
			|> without_chapter_references
			|> Str.with_ascii_lowercased
		bytes = plain.to_utf8()
		len = bytes.len()
		var $found = []
		var $at = 0
		while $at < len {
			match word_list.find_first(|word| is_word_at(bytes, { word: word.to_utf8(), at: $at })) {
				Ok(word) => {
					if !$found.contains(word) {
						$found = $found.append(word)
					}
					$at = $at + Str.count_utf8_bytes(word)
				}
				Err(NotFound) => {
					$at = $at + 1
				}
			}
		}
		$found
	}
}

## A negative sentence: its line, its chapter, its words and the sentence.
Hit : {
	line : U64,
	chapter : Str,
	words : Str,
	sentence : Str,
}

## Every sentence of the prose that holds a word of `word_list`, and how many
## sentences were read.
prose_hits : List(Manuscript.Line), List(Str) -> { found : List(Hit), read_count : U64 }
prose_hits = |lines, word_list| {
	var $found = []
	var $read_count = 0
	var $chapter = "(before the first chapter)"
	for line in lines {
		if line.place == Prose and !line.text.starts_with("{{") {
			match Manuscript.chapter_title(line) {
				Ok(title) => {
					$chapter = title.trim()
				}
				Err(NotAChapter) => {}
			}
			for text in line_texts(line.text) {
				for sentence in Negatives.sentences(text) {
					$read_count = $read_count + 1
					words = Negatives.words_in(sentence, word_list)
					if !words.is_empty() {
						$found = $found.append({ line: line.number, chapter: $chapter, words: Str.join_with(words, ","), sentence })
					}
				}
			}
		}
	}
	{ found: $found, read_count: $read_count }
}

## The texts of one line of prose: a table row's cells, or the line itself.
line_texts : Str -> List(Str)
line_texts = |text|
	if text.trim().starts_with("|") {
		text.split_on("|").drop_if(|cell| cell.trim().is_empty() or is_cell_rule(cell))
	} else {
		[text]
	}

## A cell of a table's rule: spaces, an optional colon, hyphens, an optional
## colon, spaces.
is_cell_rule : Str -> Bool
is_cell_rule = |cell| {
	inner = cell.trim().drop_prefix(":").drop_suffix(":").to_utf8()
	!inner.is_empty() and inner.all(|byte| byte == '-') and !cell.contains("\t")
}

## The text with each `{{chapter ...}}` as one space.
without_chapter_references : Str -> Str
without_chapter_references = |text| match text.split_on("{{chapter ") {
	[before_any, .. as pieces] => {
		kept = pieces.map(
			|piece| match piece.split_first("}") {
				Ok({ after, .. }) if after.starts_with("}") => " ${after.drop_prefix("}")}"
				_ => "{{chapter ${piece}"
			},
		)
		Str.join_with([before_any].concat(kept), "")
	}
	[] => crash "book: Str.split_on answered no pieces"
}

byte_at : List(U8), U64 -> U8
byte_at = |bytes, at| bytes.get(at) ?? crash "Negatives.byte_at: ${at.to_str()} is past the end"

is_stop : U8 -> Bool
is_stop = |byte| byte == '.' or byte == '!' or byte == '?'

## Where a run of sentence pieces starting at `start` ends: a code span whole,
## a byte that ends no sentence, or a stop that a byte other than a space, a
## stop or a backtick follows. `start` itself when none starts there.
sentence_run_end : List(U8), U64 -> U64
sentence_run_end = |bytes, start| {
	len = bytes.len()
	var $at = start
	var $going = Bool.True
	while $going and $at < len {
		byte = byte_at(bytes, $at)
		if byte == '`' {
			match bytes.drop_first($at + 1).find_first_index(|b| b == '`') {
				Ok(n) => {
					$at = $at + n + 2
				}
				Err(NotFound) => {
					$going = Bool.False
				}
			}
		} else if is_stop(byte) {
			match bytes.get($at + 1) {
				Ok(next) if next != ' ' and !is_stop(next) and next != '`' => {
					$at = $at + 2
				}
				_ => {
					$going = Bool.False
				}
			}
		} else {
			$at = $at + 1
		}
	}
	$at
}

## A regular expression's word byte: a letter, a digit or `_`.
is_word_byte : U8 -> Bool
is_word_byte = |byte| BookText.is_letter_or_digit(byte) or byte == '_'

## Whether a word starts or ends at `at`: a word byte on one side only.
is_boundary : List(U8), U64 -> Bool
is_boundary = |bytes, at| {
	before =
		if at == 0 {
			Bool.False
		} else {
			bytes.get(at - 1).map_ok(is_word_byte) == Ok(Bool.True)
		}
	after = bytes.get(at).map_ok(is_word_byte) == Ok(Bool.True)
	before != after
}

## Whether `word` is in `bytes` at `at` as a whole word.
is_word_at : List(U8), { word : List(U8), at : U64 } -> Bool
is_word_at = |bytes, { word, at }|
	is_boundary(bytes, at)
		and bytes.drop_first(at).starts_with(word)
		and is_boundary(bytes, at + word.len())

## The words file's words, in lower case.
words_of : { name : Str, text : Str } -> Try(List(Str), Str)
words_of = |{ name, text }| {
	word_list = BookText.text_lines(text)
		.map(Str.trim)
		.drop_if(|line| line.is_empty() or line.starts_with("#"))
		.map(Str.with_ascii_lowercased)
	if word_list.is_empty() {
		Err("negatives: ${name} names no words")
	} else {
		Ok(word_list)
	}
}

## One sentence the table keeps, and its line in the table.
KeptRow : { kind : Str, sentence : Str, line : U64 }

## The table's rows, and their sentences for looking up.
exception_table : { name : Str, text : Str } -> Try({ rows : List(KeptRow), sentences : List(Str) }, Str)
exception_table = |{ name, text }| {
	var $kinds = []
	var $rows = []
	var $number = 0
	for raw in BookText.text_lines(text) {
		$number = $number + 1
		at = "negatives: ${name}:${$number.to_str()}: "
		line = raw.trim()
		match kind_line(line) {
			Ok(kind) => {
				if $kinds.any(|known| known.name == kind.name) {
					return Err("${at}the kind `${kind.name}` is defined twice")
				}
				$kinds = $kinds.append(kind)
			}
			Err(NotAKind) =>
				if !line.is_empty() and !line.starts_with("#") {
					row = kept_row(line) ? |_| "${at}expected `kind: the sentence`"
					match $kinds.find_first(|known| known.name == row.kind) {
						Err(NotFound) => return Err("${at}`${row.kind}` is no kind the table defines")
						Ok({ action: Fix, .. }) => return Err("${at}`${row.kind}` is a kind to fix, not to keep")
						Ok({ action: Keep, .. }) => {}
					}
					if $rows.any(|kept| kept.sentence == row.sentence) {
						return Err("${at}the sentence is listed twice")
					}
					$rows = $rows.append({ kind: row.kind, sentence: row.sentence, line: $number })
				}
		}
	}
	if $kinds.is_empty() {
		Err("negatives: ${name} defines no kinds")
	} else {
		Ok({ rows: $rows, sentences: $rows.map(|row| row.sentence) })
	}
}

## A kind's line, `# keep name: what it is` or `# fix name: what it is`.
kind_line : Str -> Try({ name : Str, action : [Keep, Fix] }, [NotAKind])
kind_line = |line| {
	{ action, rest } =
		if line.starts_with("# keep ") {
			{ action: Keep, rest: line.drop_prefix("# keep ") }
		} else if line.starts_with("# fix ") {
			{ action: Fix, rest: line.drop_prefix("# fix ") }
		} else {
			return Err(NotAKind)
		}
	{ before: kind_name, after: description } = rest.split_first(":") ? |_| NotAKind
	if is_kind_name(kind_name) and description.starts_with(" ") and !description.trim().is_empty() {
		Ok({ name: kind_name, action })
	} else {
		Err(NotAKind)
	}
}

## A row, `kind: the sentence`.
kept_row : Str -> Try({ kind : Str, sentence : Str }, [NotARow])
kept_row = |line| {
	{ before: kind_name, after } = line.split_first(":") ? |_| NotARow
	sentence = after.trim()
	if is_kind_name(kind_name) and after.starts_with(" ") and !sentence.is_empty() {
		Ok({ kind: kind_name, sentence })
	} else {
		Err(NotARow)
	}
}

## A kind's name: lowercase letters and hyphens.
is_kind_name : Str -> Bool
is_kind_name = |text| {
	bytes = text.to_utf8()
	!bytes.is_empty() and bytes.all(|byte| (byte >= 'a' and byte <= 'z') or byte == '-')
}

negative_words : { name : Str, text : Str }
negative_words = { name: "words.txt", text: "# The words.\nnot\nno\nnone\nnever\nisn't\ndoesn't\nnothing\nrather than\n\n" }

kinds_only : { name : Str, text : Str }
kinds_only = { name: "negatives.txt", text: "# keep guarantee: the no is the point.\n# fix hedge: softens a claim.\n" }

judge_sample : Str, { name : Str, text : Str } -> Try({ findings : List(Str), summary : Str }, Str)
judge_sample = |text, table| match Manuscript.lines(text) {
	Ok(lines) => Negatives.judged({ manuscript: "book.md", lines, words: negative_words, table })
	Err(_) => crash "the test text's fences close"
}

expect Negatives.sentences("One. Two! Three? Four") == ["One.", "Two!", "Three?", "Four"]
expect Negatives.sentences("The value 4.5 and `a. b` stay. Next.") == ["The value 4.5 and `a. b` stay.", "Next."]
expect Negatives.sentences("Wait... what?! Done.") == ["Wait...", "what?!", "Done."]
expect Negatives.sentences("an `open span. Then more.") == ["an", "open span.", "Then more."]
expect Negatives.sentences("x.`y`") == ["x.", "`y`"]
expect Negatives.sentences(". .") == ["."]
expect Negatives.sentences("...") == []
expect Negatives.sentences("") == []
expect Negatives.words_in("It isn’t `not` here, and {{chapter Not none}} is NOT none.", ["not", "isn't", "none"]) == ["isn't", "not", "none"]
expect Negatives.words_in("Notable nothing knot no_one nob", ["not", "no", "nothing"]) == ["nothing"]
expect Negatives.words_in("Rather than this, no.", ["no", "rather than"]) == ["rather than", "no"]
expect Negatives.words_in("Plain words.", ["no"]) == []
expect line_texts("| Not a | b |") == [" Not a ", " b "]
expect line_texts("| a | :---: | -- |") == [" a "]
expect line_texts("plain | text") == ["plain | text"]
expect
	judge_sample("# Book\n\nIt is not here.\n\n## One\n\nA fine line. Nothing is wrong.\n```\nnot code\n```\n{{file x not}}\n| Term | Not this |\n", kinds_only)
		== Ok({
			findings: [
				"book.md:3: negative [(before the first chapter)] not: It is not here.",
				"book.md:7: negative [One] nothing: Nothing is wrong.",
				"book.md:12: negative [One] not: Not this",
			],
			summary: "negatives: negative 3, unused_exception 0, 3 negative sentences of 7 read, 0 kept in the table",
		})
expect
	judge_sample(
		"## One\n\nIt is not here. It never was.\n",
		{ name: "negatives.txt", text: "${kinds_only.text}\nguarantee: It never was.\nguarantee: Gone from the prose.\n" },
	)
		== Ok({
			findings: [
				"book.md:3: negative [One] not: It is not here.",
				"negatives.txt:5: unused_exception: no negative sentence of the prose is `Gone from the prose.`",
			],
			summary: "negatives: negative 1, unused_exception 1, 2 negative sentences of 3 read, 2 kept in the table",
		})
expect
	judge_sample("## One\n\nIt never was.\n", { name: "negatives.txt", text: "${kinds_only.text}guarantee: It never was.\n" })
		== Ok({ findings: [], summary: "negatives: negative 0, unused_exception 0, 1 negative sentences of 2 read, 1 kept in the table" })
expect judge_sample("```\nonly code\n```\n", kinds_only) == Err("negatives: no prose in book.md")
expect judge_sample("A.\n", { name: "t.txt", text: "# keep a: x\n# keep a: y\n" }) == Err("negatives: t.txt:2: the kind `a` is defined twice")
expect judge_sample("A.\n", { name: "t.txt", text: "# keep a: x\nb: A sentence.\n" }) == Err("negatives: t.txt:2: `b` is no kind the table defines")
expect judge_sample("A.\n", { name: "t.txt", text: "# fix a: x\na: A sentence.\n" }) == Err("negatives: t.txt:2: `a` is a kind to fix, not to keep")
expect judge_sample("A.\n", { name: "t.txt", text: "# keep a: x\na: One.\na: One.\n" }) == Err("negatives: t.txt:3: the sentence is listed twice")
expect judge_sample("A.\n", { name: "t.txt", text: "# keep a: x\nnot a row\n" }) == Err("negatives: t.txt:2: expected `kind: the sentence`")
expect judge_sample("A.\n", { name: "t.txt", text: "# Only comments.\n" }) == Err("negatives: t.txt defines no kinds")
expect
	match Manuscript.lines("A.\n") {
		Ok(lines) => Negatives.judged({ manuscript: "book.md", lines, words: { name: "w.txt", text: "# none\n" }, table: kinds_only }) == Err("negatives: w.txt names no words")
		Err(_) => Bool.False
	}
expect kind_line("# keep guarantee: the point") == Ok({ name: "guarantee", action: Keep })
expect kind_line("# fix hedge: softens") == Ok({ name: "hedge", action: Fix })
expect ["# keep Bad: x", "# keep a:x", "# keep a:   ", "# drop a: x", "keep a: x"].all(|line| kind_line(line) == Err(NotAKind))
