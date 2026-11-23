## This module reads the JavaScript subset's tokens into a program (Ast), by
## recursive descent, one function a level of precedence.
##
## Every form outside the subset that the parser can recognize is refused
## with a message that names it ("unsupported: `this`"), at the line and
## column at it starts. A program that parses runs only constructs whose
## meaning the interpreter has.
##
## Semicolons may be left out at JavaScript inserts them: before a `}`, at
## the end, and at a line break the next token can't continue.
##
## The parser lays out each scope (`Ast.Scoping`, a function's and a `for`'s
## `names`) and refuses what would make a layout ambiguous: a name declared
## twice where JavaScript refuses it, two parameters of one name, and a
## declaration as the lone body of an `if`, a `while` or a `for`. Then
## `Resolve` places every name in those layouts.
import Ast
import Lexer
import NumberText
import Resolve

Parser :: [].{
	# Where the parser is in the tokens, and how many function literals it has
	# passed, which tells a block whether one was written inside it.
	State : {
		tokens : List(Lexer.Token),
		at : U64,
		functions : U64,
		# The statements around the parser's place, innermost last, up to the
		# function it is in, which a `break` or a `continue` may leave.
		enclosing : List(Parser.Enclosure),
	}

	Enclosure : [Looping, Switching, LoopLabel(Str), BlockLabel(Str)]

	# The parser inside one more statement a `break` or a `continue` may
	# leave, and back out of it after, to where it was before.
	inside : Parser.State, Parser.Enclosure -> Parser.State
	inside = |parser, enclosure| { ..parser, enclosing: parser.enclosing.append(enclosure) }

	outside : Parser.State, Parser.State -> Parser.State
	outside = |after, before| { ..after, enclosing: before.enclosing }

	## A parse's value, and the parser after it.
	Parsed(a) : { parser : Parser.State, value : a }

	program_of : Str, Ast.Library -> Try(Ast.Program, Lexer.Fault)
	program_of = |text, library| {
		tokens = Lexer.tokens_of(text)?
		var $parser = {
			tokens: tokens,
			at: 0,
			functions: 0,
			enclosing: [],
		}
		var $statements = []
		while !Parser.is_end($parser) {
			parsed = Parser.statement($parser)?
			$parser = parsed.parser
			$statements = $statements.append(parsed.value)
		}
		Ok(
			Resolve.program(
				{
					statements: $statements,
					scoping: Scoped(Parser.scope_names([], $statements)?),
					capture: if $parser.functions > 0 {
						Captures
					} else {
						CapturesNothing
					},
				},
				library,
			),
		)
	}

	# The names a scope holds, in order: `first` (a call's parameters), then
	# each function and each `let` and `const` that `statements` declare. A
	# function may share its name with a parameter or another function, the
	# later made winning; a `let` or a `const` shares its name with nothing,
	# as JavaScript refuses.
	scope_names : List(Str), List(Ast.Statement) -> Try(List(Str), Lexer.Fault)
	scope_names = |leading_names, statements| {
		var $names = leading_names
		var $lexical = []
		for listed in statements {
			match listed {
				FunctionDeclaration(boxed, _) => {
					definition = boxed.unbox()
					if $lexical.contains(definition.name) {
						return Err(
							Parser.fault_at(
								definition.at,
								Parser.redeclared_message(definition.name),
							),
						)
					}
					if !$names.contains(definition.name) {
						$names = $names.append(definition.name)
					}
				}
				Declare(_, declarations) => {
					for d in declarations {
						for name in Ast.pattern_names(d.pattern) {
							if $names.contains(name) {
								return Err(Parser.fault_at(d.at, Parser.redeclared_message(name)))
							}
							$names = $names.append(name)
							$lexical = $lexical.append(name)
						}
					}
				}
				_ => {}
			}
		}
		Ok($names)
	}

	redeclared_message : Str -> Str
	redeclared_message = |name| "SyntaxError: Identifier '${name}' has already been declared"

	# The first name `names` holds twice, if one is.
	repeated_name : List(Str) -> Try(Str, [NoneRepeated])
	repeated_name = |names| {
		var $seen = []
		for name in names {
			if $seen.contains(name) {
				return Ok(name)
			}
			$seen = $seen.append(name)
		}
		Err(NoneRepeated)
	}

	# ---- tokens ----------------------------------------------------------------

	token : Parser.State -> Lexer.Token
	token = |parser| parser.tokens.get(parser.at) ?? crash "Parser.token: the parser never passes the end token"

	token_after : Parser.State -> Lexer.Token
	token_after = |parser| parser.tokens.get(parser.at + 1) ?? Parser.token(parser)

	advance : Parser.State -> Parser.State
	advance = |parser|
		if Parser.is_end(parser) {
			parser
		} else {
			{ ..parser, at: parser.at + 1 }
		}

	is_end : Parser.State -> Bool
	is_end = |parser| Parser.token(parser).kind == End

	is_punct : Parser.State, Str -> Bool
	is_punct = |parser, text| Parser.token(parser).kind == Punct(text)

	is_word : Parser.State, Str -> Bool
	is_word = |parser, text| Parser.token(parser).kind == Name(text)

	where_of : Lexer.Token -> Ast.Where
	where_of = |current| { line: current.line, column: current.column }

	here : Parser.State -> Ast.Where
	here = |parser| Parser.where_of(Parser.token(parser))

	fault_here : Parser.State, Str -> Lexer.Fault
	fault_here = |parser, why| {
		current = Parser.token(parser)
		{
			why: why,
			line: current.line,
			column: current.column,
		}
	}

	fault_at : Ast.Where, Str -> Lexer.Fault
	fault_at = |site, why| {
		why: why,
		line: site.line,
		column: site.column,
	}

	token_text : Lexer.TokenKind -> Str
	token_text = |kind| match kind {
		Number(number) => NumberText.text_for(number)
		Text(_) => "a string"
		Name(text) => "`${text}`"
		Punct(text) => "`${text}`"
		TemplateWhole(_) => "a template literal"
		TemplateHead(_) => "a template literal"
		TemplateMiddle(_) => "the middle of a template literal"
		TemplateTail(_) => "the end of a template literal"
		End => "the end of the program"
	}

	expect_punct : Parser.State, Str -> Try(Parser.State, Lexer.Fault)
	expect_punct = |parser, text|
		if Parser.is_punct(parser, text) {
			Ok(Parser.advance(parser))
		} else {
			Err(
				Parser.fault_here(
					parser,
					"expected `${text}`, found ${Parser.token_text(Parser.token(parser).kind)}",
				),
			)
		}

	# A statement's end: a `;`, or at JavaScript would insert one.
	end_of_statement : Parser.State -> Try(Parser.State, Lexer.Fault)
	end_of_statement = |parser| {
		current = Parser.token(parser)
		if Parser.is_punct(parser, ";") {
			Ok(Parser.advance(parser))
		} else if Parser.is_punct(parser, "}") or current.kind == End or current.before == NewLine {
			Ok(parser)
		} else {
			Err(
				Parser.fault_here(
					parser,
					"expected `;` or a line break, found ${Parser.token_text(current.kind)}",
				),
			)
		}
	}

	name_here : Parser.State, Str -> Try(Parser.Parsed(Str), Lexer.Fault)
	name_here = |parser, what|
		match Parser.token(parser).kind {
			Name(text) => {
				if Parser.is_reserved(text) {
					Err(Parser.fault_here(parser, "`${text}` is a reserved word, not ${what}"))
				} else {
					Ok({ parser: Parser.advance(parser), value: text })
				}
			}
			other => Err(
				Parser.fault_here(parser, "expected ${what}, found ${Parser.token_text(other)}"),
			)
		}

	reserved_words : List(Str)
	reserved_words = [
		"break",
		"case",
		"catch",
		"class",
		"const",
		"continue",
		"debugger",
		"default",
		"delete",
		"do",
		"else",
		"export",
		"extends",
		"false",
		"finally",
		"for",
		"function",
		"if",
		"import",
		"in",
		"instanceof",
		"let",
		"new",
		"null",
		"return",
		"super",
		"switch",
		"this",
		"throw",
		"true",
		"try",
		"typeof",
		"var",
		"void",
		"while",
		"with",
		"yield",
		"undefined",
	]

	is_reserved : Str -> Bool
	is_reserved = |text| Parser.reserved_words.contains(text)

	# The words that begin a form the subset leaves out, and what to say.
	unsupported_word : Str -> Try(Str, [Supported])
	unsupported_word = |text| match text {
		"this" => Ok("unsupported: `this`")
		"class" => Ok("unsupported: classes")
		"var" => Ok("unsupported: `var` (use `let` or `const`)")
		"delete" => Ok("unsupported: `delete`")
		"void" => Ok("unsupported: `void`")
		"import" => Ok("unsupported: modules (`import`)")
		"export" => Ok("unsupported: modules (`export`)")
		"async" => Ok("unsupported: async functions")
		"await" => Ok("unsupported: `await`")
		"yield" => Ok("unsupported: generators (`yield`)")
		"with" => Ok("unsupported: `with`")
		"super" => Ok("unsupported: `super`")
		"eval" => Ok("unsupported: `eval`")
		"arguments" => Ok("unsupported: `arguments`")
		"debugger" => Ok("unsupported: `debugger`")
		_ => Err(Supported)
	}

	refuse_unsupported_word : Parser.State -> Try({}, Lexer.Fault)
	refuse_unsupported_word = |parser|
		match Parser.token(parser).kind {
			Name(text) => match Parser.unsupported_word(text) {
				Ok(why) => Err(Parser.fault_here(parser, why))
				Err(Supported) => Ok({})
			}
			_ => Ok({})
		}

	capture_since : Parser.State, U64 -> Ast.Capture
	capture_since = |parser, before|
		if parser.functions > before {
			Captures
		} else {
			CapturesNothing
		}

	# ---- statements ------------------------------------------------------------

	statement : Parser.State -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	statement = |parser| {
		Parser.refuse_unsupported_word(parser)?
		current = Parser.token(parser)
		match current.kind {
			Punct("{") => {
				parsed = Parser.block(parser)?
				Ok({ parser: parsed.parser, value: BlockStatement(parsed.value) })
			}
			Punct(";") => Ok({ parser: Parser.advance(parser), value: Empty })
			Name("let") => Parser.declaration(parser, Let)
			Name("const") => Parser.declaration(parser, Const)
			Name("function") => {
				parsed = Parser.function_rest(
					Parser.advance(parser),
					Parser.where_of(current),
					Declared,
				)?
				Ok({
					parser: parsed.parser,
					value: FunctionDeclaration(Box.box(parsed.value), Unresolved),
				})
			}
			Name("if") => Parser.if_statement(parser)
			Name("while") => {
				onward = Parser.expect_punct(Parser.advance(parser), "(")?
				test = Parser.expression(onward)?
				q2 = Parser.expect_punct(test.parser, ")")?
				body = Parser.body_statement(Parser.inside(q2, Looping))?
				Ok({
					parser: Parser.outside(body.parser, parser),
					value: While({
						test: test.value,
						body: body.value,
						order: TestFirst,
						labels: [],
					}),
				})
			}
			Name("do") => {
				body = Parser.body_statement(Parser.inside(Parser.advance(parser), Looping))?
				if !Parser.is_word(body.parser, "while") {
					return Err(Parser.fault_here(body.parser, "expected `while` after a `do` loop's body"))
				}
				onward = Parser.expect_punct(Parser.advance(Parser.outside(body.parser, parser)), "(")?
				test = Parser.expression(onward)?
				closed = Parser.expect_punct(test.parser, ")")?
				# JavaScript ends a `do ... while` at its `)`, with or without a `;`.
				ended = if Parser.is_punct(closed, ";") {
					Parser.advance(closed)
				} else {
					closed
				}
				Ok({
					parser: ended,
					value: While({
						test: test.value,
						body: body.value,
						order: TestAfter,
						labels: [],
					}),
				})
			}
			Name(text) if Parser.token_after(parser).kind == Punct(":") and !Parser.is_reserved(text) => {
				Parser.labelled_statement(parser, text)
			}
			Name("for") => Parser.for_statement(parser)
			Name("return") => {
				onward = Parser.advance(parser)
				next_token = Parser.token(onward)
				if Parser.is_punct(onward, ";") or Parser.is_punct(
					onward,
					"}",
				) or next_token.kind == End or next_token.before == NewLine {
					q2 = Parser.end_of_statement(onward)?
					Ok({ parser: q2, value: Return(Undefined) })
				} else {
					parsed_expression = Parser.expression(onward)?
					q2 = Parser.end_of_statement(parsed_expression.parser)?
					Ok({ parser: q2, value: Return(parsed_expression.value) })
				}
			}
			Name("try") => Parser.try_statement(parser)
			Name("switch") => Parser.switch_statement(parser)
			Name("throw") => {
				onward = Parser.advance(parser)
				if Parser.token(onward).before == NewLine {
					Err(Parser.fault_here(onward, "SyntaxError: Illegal newline after throw"))
				} else {
					parsed_expression = Parser.expression(onward)?
					q2 = Parser.end_of_statement(parsed_expression.parser)?
					Ok({ parser: q2, value: Throw(parsed_expression.value, Parser.where_of(current)) })
				}
			}
			Name("break") => Parser.jump(parser, Breaking)
			Name("continue") => Parser.jump(parser, Continuing)
			_ => {
				parsed_expression = Parser.expression(parser)?
				onward = Parser.end_of_statement(parsed_expression.parser)?
				Ok({ parser: onward, value: Expression(parsed_expression.value) })
			}
		}
	}

	# The lone statement an `if`, a `while` or a `for` runs, which may not be a
	# declaration: its scope would be the statement alone.
	body_statement : Parser.State -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	body_statement = |parser|
		if Parser.is_word(parser, "let") or Parser.is_word(parser, "const") {
			Err(
				Parser.fault_here(
					parser,
					"SyntaxError: Lexical declaration cannot appear in a single-statement context",
				),
			)
		} else if Parser.is_word(parser, "function") {
			Err(
				Parser.fault_here(
					parser,
					"unsupported: a function declared as the lone body of `if`, `while` or `for` (put it in a block)",
				),
			)
		} else {
			Parser.statement(parser)
		}

	switch_statement : Parser.State -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	switch_statement = |parser| {
		before = parser.functions
		onward = Parser.expect_punct(Parser.advance(parser), "(")?
		discriminant = Parser.expression(onward)?
		closed = Parser.expect_punct(discriminant.parser, ")")?
		var $at = Parser.inside(Parser.expect_punct(closed, "{")?, Switching)
		var $cases = []
		var $statements = []
		var $defaults = 0
		while !Parser.is_punct($at, "}") {
			test = if Parser.is_word($at, "case") {
				parsed = Parser.expression(Parser.advance($at))?
				{ parser: Parser.expect_punct(parsed.parser, ":")?, value: Matches(parsed.value) }
			} else if Parser.is_word($at, "default") {
				if $defaults > 0 {
					return Err(
						Parser.fault_here($at, "SyntaxError: More than one default clause in switch statement"),
					)
				}
				$defaults = $defaults + 1
				{ parser: Parser.expect_punct(Parser.advance($at), ":")?, value: Otherwise }
			} else {
				return Err(
					Parser.fault_here(
						$at,
						"expected `case`, `default` or `}` in a `switch`, found ${Parser.token_text(Parser.token($at).kind)}",
					),
				)
			}
			var $body = []
			var $p = test.parser
			while !Parser.is_punct($p, "}") and !Parser.is_word($p, "case") and !Parser.is_word($p, "default") {
				if Parser.is_end($p) {
					return Err(Parser.fault_here($p, "a `switch` that never ends (expected `}`)"))
				}
				parsed = Parser.statement($p)?
				$body = $body.append(parsed.value)
				$p = parsed.parser
			}
			$cases = $cases.append({ test: test.value, statements: $body })
			$statements = List.concat($statements, $body)
			$at = $p
		}
		Ok({
			parser: Parser.outside(Parser.advance($at), parser),
			value: Switch({
				discriminant: discriminant.value,
				cases: $cases,
				scoping: Parser.scoping_of($statements)?,
				capture: Parser.capture_since($at, before),
			}),
		})
	}

	try_statement : Parser.State -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	try_statement = |parser| {
		tried = Parser.block(Parser.advance(parser))?
		handler = if Parser.is_word(tried.parser, "catch") {
			Parser.catch_clause(tried.parser)?
		} else {
			{ parser: tried.parser, value: Uncaught }
		}
		finalizer = if Parser.is_word(handler.parser, "finally") {
			final_block = Parser.block(Parser.advance(handler.parser))?
			{ parser: final_block.parser, value: Finally(final_block.value) }
		} else {
			{ parser: handler.parser, value: NoFinally }
		}
		match (handler.value, finalizer.value) {
			(Uncaught, NoFinally) => Err(
				Parser.fault_here(finalizer.parser, "SyntaxError: Missing catch or finally after try"),
			)
			_ => Ok({
				parser: finalizer.parser,
				value: Try({
					block: tried.value,
					handler: handler.value,
					finalizer: finalizer.value,
				}),
			})
		}
	}

	# A `catch` and its block, the name or pattern it binds in parentheses, or
	# none.
	catch_clause : Parser.State -> Try(Parser.Parsed([Caught(Ast.CatchClause), Uncaught]), Lexer.Fault)
	catch_clause = |parser| {
		site = Parser.here(parser)
		before = parser.functions
		onward = Parser.advance(parser)
		if Parser.is_punct(onward, "(") {
			bound = Parser.pattern(Parser.advance(onward), Declaring)?
			closed = Parser.expect_punct(bound.parser, ")")?
			names = Ast.pattern_names(bound.value)
			match Parser.repeated_name(names) {
				Ok(name) => return Err(Parser.fault_at(site, Parser.redeclared_message(name)))
				Err(NoneRepeated) => {}
			}
			body = Parser.block(closed)?
			match body.value.scoping {
				Scoped(declared) => {
					for name in names {
						if declared.contains(name) {
							return Err(Parser.fault_at(site, Parser.redeclared_message(name)))
						}
					}
				}
				Unscoped => {}
			}
			Ok({
				parser: body.parser,
				value: Caught({
					parameter: Bound(bound.value),
					names: names,
					body: body.value,
					capture: Parser.capture_since(body.parser, before),
					at: site,
				}),
			})
		} else {
			body = Parser.block(onward)?
			Ok({
				parser: body.parser,
				value: Caught({
					parameter: Unbound,
					names: [],
					body: body.value,
					capture: body.value.capture,
					at: site,
				}),
			})
		}
	}

	# A statement with a label: a loop holds the label itself, and any other
	# statement is `Labelled`.
	labelled_statement : Parser.State, Str -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	labelled_statement = |parser, name| {
		if parser.enclosing.contains(LoopLabel(name)) or parser.enclosing.contains(BlockLabel(name)) {
			return Err(Parser.fault_here(parser, "SyntaxError: Label '${name}' has already been declared"))
		}
		after_colon = Parser.advance(Parser.advance(parser))
		enclosure = if Parser.is_loop_start(after_colon) {
			LoopLabel(name)
		} else {
			BlockLabel(name)
		}
		body = Parser.body_statement(Parser.inside(after_colon, enclosure))?
		labelled = match body.value {
			While(loop) => While({ ..loop, labels: loop.labels.append(name) })
			For(loop) => For({ ..loop, labels: loop.labels.append(name) })
			ForOf(loop) => ForOf({ ..loop, labels: loop.labels.append(name) })
			other => Labelled(name, other)
		}
		Ok({ parser: Parser.outside(body.parser, parser), value: labelled })
	}

	# Whether a loop starts here, after any labels of its own.
	is_loop_start : Parser.State -> Bool
	is_loop_start = |parser|
		match Parser.token(parser).kind {
			Name("for") | Name("while") | Name("do") => True
			Name(text) if Parser.token_after(parser).kind == Punct(":") and !Parser.is_reserved(text) => {
				Parser.is_loop_start(Parser.advance(Parser.advance(parser)))
			}
			_ => False
		}

	Jump : [Breaking, Continuing]

	# A `break` or a `continue`, and the label it names, held to what
	# encloses it as JavaScript holds it.
	jump : Parser.State, Parser.Jump -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	jump = |parser, jumping| {
		onward = Parser.advance(parser)
		name_found = Parser.token(onward)
		{ label, after } = match name_found.kind {
			Name(text) if name_found.before == SameLine and !Parser.is_reserved(text) => {
				label: Named(text),
				after: Parser.advance(onward),
			}
			_ => { label: Unlabelled, after: onward }
		}
		enclosing = parser.enclosing
		refusal = match (jumping, label) {
			(Breaking, Unlabelled) if !enclosing.contains(Looping) and !enclosing.contains(Switching) => Refused("SyntaxError: Illegal break statement")
			(Continuing, Unlabelled) if !enclosing.contains(Looping) => Refused("SyntaxError: Illegal continue statement: no surrounding iteration statement")
			(Continuing, Named(name)) if enclosing.contains(BlockLabel(name)) => Refused("SyntaxError: Illegal continue statement: '${name}' does not denote an iteration statement")
			(_, Named(name)) if !enclosing.contains(LoopLabel(name)) and !enclosing.contains(BlockLabel(name)) => Refused("SyntaxError: Undefined label '${name}'")
			_ => Allowed
		}
		match refusal {
			Refused(why) => Err(Parser.fault_here(parser, why))
			Allowed => {
				q2 = Parser.end_of_statement(after)?
				jumped = match jumping {
					Breaking => Break(label)
					Continuing => Continue(label)
				}
				Ok({ parser: q2, value: jumped })
			}
		}
	}

	block : Parser.State -> Try(Parser.Parsed(Ast.Block), Lexer.Fault)
	block = |parser| {
		before = parser.functions
		var $onward = Parser.expect_punct(parser, "{")?
		var $statements = []
		while !Parser.is_punct($onward, "}") {
			if Parser.is_end($onward) {
				return Err(Parser.fault_here($onward, "a block that never ends (expected `}`)"))
			}
			parsed = Parser.statement($onward)?
			$onward = parsed.parser
			$statements = $statements.append(parsed.value)
		}
		Ok({
			parser: Parser.advance($onward),
			value: {
				statements: $statements,
				scoping: Parser.scoping_of($statements)?,
				capture: Parser.capture_since($onward, before),
			},
		})
	}

	scoping_of : List(Ast.Statement) -> Try(Ast.Scoping, Lexer.Fault)
	scoping_of = |statements| {
		declares = statements.any(
			|listed| match listed {
				Declare(_, _) => True
				FunctionDeclaration(_, _) => True
				_ => False
			},
		)
		if declares {
			Ok(Scoped(Parser.scope_names([], statements)?))
		} else {
			Ok(Unscoped)
		}
	}

	declaration : Parser.State, Ast.Binding -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	declaration = |parser, binding| {
		parsed = Parser.declarators(Parser.advance(parser), binding)?
		onward = Parser.end_of_statement(parsed.parser)?
		Ok({ parser: onward, value: Declare(binding, parsed.value) })
	}

	declarators : Parser.State, Ast.Binding -> Try(Parser.Parsed(List(Ast.Declarator)), Lexer.Fault)
	declarators = |parser, binding| {
		var $onward = parser
		var $out = []
		var $more = True
		while $more {
			site = Parser.here($onward)
			bound = Parser.pattern($onward, Declaring)?
			if Parser.is_punct(bound.parser, "=") {
				parsed_expression = Parser.assignment(Parser.advance(bound.parser))?
				$out = $out.append({
					pattern: bound.value,
					init: Initialized(Parser.named_for(parsed_expression.value, bound.value)),
					at: site,
				})
				$onward = parsed_expression.parser
			} else if !Parser.is_leaf(bound.value) {
				return Err(
					Parser.fault_here(
						bound.parser,
						"SyntaxError: Missing initializer in destructuring declaration",
					),
				)
			} else if binding == Const {
				return Err(Parser.fault_here(bound.parser, "a `const` without a value"))
			} else {
				$out = $out.append({
					pattern: bound.value,
					init: Uninitialized,
					at: site,
				})
				$onward = bound.parser
			}
			if Parser.is_punct($onward, ",") {
				$onward = Parser.advance($onward)
			} else {
				$more = False
			}
		}
		Ok({ parser: $onward, value: $out })
	}

	# A function literal written with no name of its own takes the name it is
	# bound to, as JavaScript names `const f = () => 1` "f".
	with_name_given : Ast.Expression, Str -> Ast.Expression
	with_name_given = |tree, name| match tree {
		Function(boxed) => {
			definition = boxed.unbox()
			if definition.name == "" {
				Function(Box.box({ ..definition, name: name }))
			} else {
				tree
			}
		}
		_ => tree
	}

	# A function literal bound by a pattern that is a plain name takes the
	# name, as `with_name_given` gives it.
	named_for : Ast.Expression, Ast.Pattern -> Ast.Expression
	named_for = |tree, bound| match bound {
		Leaf(ToName(name, _, _)) => Parser.with_name_given(tree, name)
		_ => tree
	}

	is_leaf : Ast.Pattern -> Bool
	is_leaf = |bound| match bound {
		Leaf(_) => True
		_ => False
	}

	# ---- patterns --------------------------------------------------------------

	# How a pattern's leaves are written: a declaration's and a parameter's
	# are names; an assignment's may be any target.
	PatternMode : [Declaring, Assigning]

	pattern : Parser.State, Parser.PatternMode -> Try(Parser.Parsed(Ast.Pattern), Lexer.Fault)
	pattern = |parser, mode|
		if Parser.is_punct(parser, "[") {
			Parser.array_pattern(Parser.advance(parser), mode)
		} else if Parser.is_punct(parser, "{") {
			Parser.object_pattern(Parser.advance(parser), mode)
		} else {
			site = Parser.here(parser)
			match mode {
				Declaring => {
					name_found = Parser.name_here(parser, "a name to declare")?
					Ok({
						parser: name_found.parser,
						value: Leaf(ToName(name_found.value, Unresolved, site)),
					})
				}
				Assigning => {
					parsed = Parser.call_or_member(parser)?
					target = Parser.target_of(parsed.value, site)?
					Ok({ parser: parsed.parser, value: Leaf(target) })
				}
			}
		}

	# An array pattern after its `[`.
	array_pattern : Parser.State, Parser.PatternMode -> Try(Parser.Parsed(Ast.Pattern), Lexer.Fault)
	array_pattern = |parser, mode| {
		var $onward = parser
		var $items = []
		var $rest = NoRest
		while !Parser.is_punct($onward, "]") {
			if Parser.is_punct($onward, ",") {
				$items = $items.append(Hole)
				$onward = Parser.advance($onward)
			} else if Parser.is_punct($onward, "...") {
				parsed = Parser.pattern(Parser.advance($onward), mode)?
				if !Parser.is_punct(parsed.parser, "]") {
					return Err(Parser.fault_here(parsed.parser, "SyntaxError: Rest element must be last element"))
				}
				$rest = RestOf(parsed.value)
				$onward = parsed.parser
			} else {
				parsed = Parser.pattern($onward, mode)?
				defaulted = Parser.default_after(parsed.parser, parsed.value)?
				$items = $items.append(Item(parsed.value, defaulted.value))
				$onward = Parser.after_part(defaulted.parser, "]", "an array pattern")?
			}
		}
		Ok({ parser: Parser.advance($onward), value: ArrayPattern($items, $rest) })
	}

	# An object pattern after its `{`.
	object_pattern : Parser.State, Parser.PatternMode -> Try(Parser.Parsed(Ast.Pattern), Lexer.Fault)
	object_pattern = |parser, mode| {
		var $onward = parser
		var $properties = []
		var $rest = NoRest
		while !Parser.is_punct($onward, "}") {
			if Parser.is_punct($onward, "...") {
				parsed = Parser.pattern(Parser.advance($onward), mode)?
				if !Parser.is_leaf(parsed.value) {
					return Err(
						Parser.fault_here(
							Parser.advance($onward),
							"SyntaxError: `...` must be followed by an assignable reference in assignment contexts",
						),
					)
				}
				if !Parser.is_punct(parsed.parser, "}") {
					return Err(Parser.fault_here(parsed.parser, "SyntaxError: Rest element must be last element"))
				}
				$rest = RestOf(parsed.value)
				$onward = parsed.parser
			} else {
				current = Parser.token($onward)
				site = Parser.where_of(current)
				key = match current.kind {
					Name(text) => Ok(text)
					Text(text) => Ok(text)
					Number(number) => Ok(NumberText.text_for(number))
					Punct("[") => Err(Parser.fault_here($onward, "unsupported: computed property names"))
					other => Err(
						Parser.fault_here(
							$onward,
							"expected a property's name, found ${Parser.token_text(other)}",
						),
					)
				}?
				after = Parser.advance($onward)
				bound = if Parser.is_punct(after, ":") {
					Parser.pattern(Parser.advance(after), mode)?
				} else {
					match current.kind {
						Name(text) if !Parser.is_reserved(text) => {
							parser: after,
							value: Leaf(ToName(text, Unresolved, site)),
						}
						_ => return Err(Parser.fault_here(after, "expected `:` after a property's name"))
					}
				}
				defaulted = Parser.default_after(bound.parser, bound.value)?
				$properties = $properties.append({
					key: key,
					pattern: bound.value,
					default: defaulted.value,
				})
				$onward = Parser.after_part(defaulted.parser, "}", "an object pattern")?
			}
		}
		Ok({ parser: Parser.advance($onward), value: ObjectPattern($properties, $rest) })
	}

	# Past the `,` after a part of a list, or at its `close`.
	after_part : Parser.State, Str, Str -> Try(Parser.State, Lexer.Fault)
	after_part = |parser, close, what|
		if Parser.is_punct(parser, ",") {
			Ok(Parser.advance(parser))
		} else if Parser.is_punct(parser, close) {
			Ok(parser)
		} else {
			Err(
				Parser.fault_here(
					parser,
					"expected `,` or `${close}` in ${what}, found ${Parser.token_text(Parser.token(parser).kind)}",
				),
			)
		}

	# A pattern's default, `= value`, if one follows it.
	default_after : Parser.State, Ast.Pattern -> Try(Parser.Parsed(Ast.Default), Lexer.Fault)
	default_after = |parser, bound|
		if Parser.is_punct(parser, "=") {
			parsed = Parser.assignment(Parser.advance(parser))?
			Ok({ parser: parsed.parser, value: Defaulted(Parser.named_for(parsed.value, bound)) })
		} else {
			Ok({ parser: parser, value: NoDefault })
		}

	# Whether an assignment to a pattern starts here: a `[` or a `{` whose
	# closing bracket is followed by `=`.
	is_pattern_assignment : Parser.State -> Bool
	is_pattern_assignment = |parser|
		if Parser.is_punct(parser, "[") or Parser.is_punct(parser, "{") {
			match parser.tokens.get(Parser.matching_close(parser) + 1) {
				Ok(current) => current.kind == Punct("=")
				Err(OutOfBounds) => False
			}
		} else {
			False
		}

	# The parser past the binding at its place: a name, or a pattern to its
	# closing bracket.
	after_binding : Parser.State -> Parser.State
	after_binding = |parser|
		if Parser.is_punct(parser, "[") or Parser.is_punct(parser, "{") {
			{ ..parser, at: U64.min(Parser.matching_close(parser) + 1, parser.tokens.len() - 1) }
		} else {
			Parser.advance(parser)
		}

	if_statement : Parser.State -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	if_statement = |parser| {
		onward = Parser.expect_punct(Parser.advance(parser), "(")?
		test = Parser.expression(onward)?
		q2 = Parser.expect_punct(test.parser, ")")?
		yes = Parser.body_statement(q2)?
		if Parser.is_word(yes.parser, "else") {
			no = Parser.body_statement(Parser.advance(yes.parser))?
			Ok({ parser: no.parser, value: If(test.value, yes.value, no.value) })
		} else {
			Ok({ parser: yes.parser, value: If(test.value, yes.value, Empty) })
		}
	}

	for_statement : Parser.State -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	for_statement = |parser| {
		before = parser.functions
		onward = Parser.expect_punct(Parser.advance(parser), "(")?
		binding_word = if Parser.is_word(onward, "let") {
			Bound(Let)
		} else if Parser.is_word(onward, "const") {
			Bound(Const)
		} else {
			Unbound
		}
		past_binding = Parser.after_binding(Parser.advance(onward))
		match binding_word {
			Bound(binding) if Parser.is_word(past_binding, "of") => {
				Parser.for_of_rest(Parser.advance(onward), binding)
			}
			Bound(_) if Parser.is_word(past_binding, "in") => {
				Err(
					Parser.fault_here(
						onward,
						"unsupported: `for ... in` (use `for ... of` over Object.keys)",
					),
				)
			}
			_ => {
				init = match binding_word {
					Bound(binding) => {
						parsed = Parser.declarators(Parser.advance(onward), binding)?
						Ok({ parser: parsed.parser, value: Declare(binding, parsed.value) })
					}
					Unbound => if Parser.is_punct(onward, ";") {
						Ok({ parser: onward, value: Empty })
					} else {
						parsed_expression = Parser.expression(onward)?
						Ok({
							parser: parsed_expression.parser,
							value: Expression(parsed_expression.value),
						})
					}
				}?
				q2 = Parser.expect_punct(init.parser, ";")?
				test = if Parser.is_punct(q2, ";") {
					{ parser: q2, value: Always }
				} else {
					parsed_expression = Parser.expression(q2)?
					{ parser: parsed_expression.parser, value: Tested(parsed_expression.value) }
				}
				q3 = Parser.expect_punct(test.parser, ";")?
				update = if Parser.is_punct(q3, ")") {
					{ parser: q3, value: NoUpdate }
				} else {
					parsed_expression = Parser.expression(q3)?
					{ parser: parsed_expression.parser, value: Updated(parsed_expression.value) }
				}
				q4 = Parser.expect_punct(update.parser, ")")?
				looped = Parser.body_statement(Parser.inside(q4, Looping))?
				body = { ..looped, parser: Parser.outside(looped.parser, q4) }
				loop = {
					labels: [],
					names: Parser.scope_names([], [init.value])?,
					init: init.value,
					test: test.value,
					update: update.value,
					body: body.value,
					capture: Parser.capture_since(body.parser, before),
				}
				Ok({ parser: body.parser, value: For(loop) })
			}
		}
	}

	for_of_rest : Parser.State, Ast.Binding -> Try(Parser.Parsed(Ast.Statement), Lexer.Fault)
	for_of_rest = |parser, binding| {
		site = Parser.here(parser)
		bound = Parser.pattern(parser, Declaring)?
		names = Ast.pattern_names(bound.value)
		match Parser.repeated_name(names) {
			Ok(name) => return Err(Parser.fault_at(site, Parser.redeclared_message(name)))
			Err(NoneRepeated) => {}
		}
		parsed_expression = Parser.assignment(Parser.advance(bound.parser))?
		onward = Parser.expect_punct(parsed_expression.parser, ")")?
		before = onward.functions
		looped = Parser.body_statement(Parser.inside(onward, Looping))?
		body = { ..looped, parser: Parser.outside(looped.parser, onward) }
		loop = {
			labels: [],
			binding: binding,
			pattern: bound.value,
			names: names,
			iterable: parsed_expression.value,
			body: body.value,
			# A closure in the pattern's defaults can capture the pass's scope
			# too; one in the iterable can't.
			capture: if bound.parser.functions > parser.functions {
				Captures
			} else {
				Parser.capture_since(body.parser, before)
			},
			at: site,
		}
		Ok({ parser: body.parser, value: ForOf(loop) })
	}

	# ---- functions -------------------------------------------------------------

	# How a function's name is written: a declaration must have one.
	Naming : [Declared, Expressed]

	# A function after its `function` keyword: an optional name, the
	# parameters and the body.
	ParsedFunction : Try(Parser.Parsed(Ast.FunctionDefinition), Lexer.Fault)

	ParsedExpression : Try(Parser.Parsed(Ast.Expression), Lexer.Fault)

	# What a function's body is parsed with: the function's name, its
	# parameters, where it starts, and how many function literals the parser
	# had passed before its parameters, since a closure in a parameter's
	# default captures the call's scope as one in the body does.
	Signature : {
		name : Str,
		parameters : Parser.Parameters,
		at : Ast.Where,
		before : U64,
	}

	## A function's parameters: the names they bind, in order, and how the
	## arguments reach them.
	Parameters : { names : List(Str), binding : Ast.ParameterBinding }

	function_rest : Parser.State, Ast.Where, Parser.Naming -> Parser.ParsedFunction
	function_rest = |parser, site, naming| {
		if Parser.is_punct(parser, "*") {
			return Err(Parser.fault_here(parser, "unsupported: generators"))
		}
		named_p = match Parser.token(parser).kind {
			Name(_) => {
				name_found = Parser.name_here(parser, "a function's name")?
				Ok(name_found)
			}
			_ => match naming {
				Declared => Err(Parser.fault_here(parser, "a function declaration without a name"))
				Expressed => Ok({ parser: parser, value: "" })
			}
		}?
		parameters = Parser.parameter_list(named_p.parser)?
		Parser.function_body(
			parameters.parser,
			{
				name: named_p.value,
				parameters: parameters.value,
				at: site,
				before: named_p.parser.functions,
			},
		)
	}

	# The parameters in their parentheses: each a name or a pattern, with a
	# default or none, and a rest parameter last.
	parameter_list : Parser.State -> Try(Parser.Parsed(Parser.Parameters), Lexer.Fault)
	parameter_list = |parser| {
		var $onward = Parser.expect_punct(parser, "(")?
		var $items = []
		var $names = []
		var $rest = NoRest
		var $plain = True
		while !Parser.is_punct($onward, ")") {
			start = $onward
			rests = Parser.is_punct($onward, "...")
			bound = if rests {
				Parser.pattern(Parser.advance($onward), Declaring)?
			} else {
				Parser.pattern($onward, Declaring)?
			}
			for name in Ast.pattern_names(bound.value) {
				if $names.contains(name) {
					return Err(Parser.fault_here(start, "unsupported: two parameters named `${name}`"))
				}
				$names = $names.append(name)
			}
			if rests {
				if !Parser.is_punct(bound.parser, ")") {
					return Err(
						Parser.fault_here(
							bound.parser,
							"SyntaxError: Rest parameter must be last formal parameter",
						),
					)
				}
				$rest = RestOf(bound.value)
				$plain = False
				$onward = bound.parser
			} else {
				defaulted = Parser.default_after(bound.parser, bound.value)?
				match (bound.value, defaulted.value) {
					(Leaf(_), NoDefault) => {}
					_ => {
						$plain = False
					}
				}
				$items = $items.append({ pattern: bound.value, default: defaulted.value })
				$onward = Parser.after_part(defaulted.parser, ")", "the parameters")?
			}
		}
		binding = if $plain {
			Plain
		} else {
			Patterned({ items: $items, rest: $rest })
		}
		Ok({ parser: Parser.advance($onward), value: { names: $names, binding: binding } })
	}

	function_body : Parser.State, Parser.Signature -> Parser.ParsedFunction
	function_body = |parser, signature| {
		{ name, parameters, at: site, before } = signature
		# A `break` or a `continue` never leaves a function.
		parsed_block = Parser.block({ ..parser, enclosing: [] })?
		definition = {
			name: name,
			parameters: parameters.names,
			binding: parameters.binding,
			names: Parser.scope_names(parameters.names, parsed_block.value.statements)?,
			statements: parsed_block.value.statements,
			capture: Parser.capture_since(parsed_block.parser, before),
			at: site,
		}
		Ok({
			parser: {
				..parsed_block.parser,
				functions: parsed_block.parser.functions + 1,
				enclosing: parser.enclosing,
			},
			value: definition,
		})
	}

	# Whether an arrow function starts here: a name and `=>`, or a
	# parenthesized list whose `)` is followed by `=>`.
	is_arrow_start : Parser.State -> Bool
	is_arrow_start = |parser|
		match Parser.token(parser).kind {
			Name(_) => Parser.token_after(parser).kind == Punct("=>")
			Punct("(") => {
				close = Parser.matching_close(parser)
				match parser.tokens.get(close + 1) {
					Ok(current) => current.kind == Punct("=>")
					Err(OutOfBounds) => False
				}
			}
			_ => False
		}

	# The index of the `)` that closes the `(` at the parser's place.
	matching_close : Parser.State -> U64
	matching_close = |parser| {
		var $i = parser.at
		var $depth = 0
		var $found = False
		while !$found and $i < parser.tokens.len() {
			current = parser.tokens.get($i) ?? crash "Parser.matching_close: inside the tokens"
			if current.kind == Punct("(") or current.kind == Punct("[") or current.kind == Punct("{") {
				$depth = $depth + 1
				$i = $i + 1
			} else if current.kind == Punct(")") or current.kind == Punct("]") or current.kind == Punct("}") {
				$depth = $depth - 1
				if $depth == 0 {
					$found = True
				} else {
					$i = $i + 1
				}
			} else if current.kind == End {
				$found = True
			} else {
				$i = $i + 1
			}
		}
		$i
	}

	arrow : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	arrow = |parser| {
		site = Parser.here(parser)
		before = parser.functions
		parameters = match Parser.token(parser).kind {
			Name(_) => {
				name_found = Parser.name_here(parser, "a parameter's name")?
				Ok({
					parser: name_found.parser,
					value: { names: [name_found.value], binding: Plain },
				})
			}
			_ => Parser.parameter_list(parser)
		}?
		onward = Parser.expect_punct(parameters.parser, "=>")?
		if Parser.is_punct(onward, "{") {
			definition = Parser.function_body(
				onward,
				{
					name: "",
					parameters: parameters.value,
					at: site,
					before: before,
				},
			)?
			Ok({ parser: definition.parser, value: Function(Box.box(definition.value)) })
		} else {
			parsed_expression = Parser.assignment(onward)?
			definition = {
				name: "",
				parameters: parameters.value.names,
				binding: parameters.value.binding,
				names: parameters.value.names,
				statements: [Return(parsed_expression.value)],
				capture: Parser.capture_since(parsed_expression.parser, before),
				at: site,
			}
			Ok({
				parser: {
					..parsed_expression.parser,
					functions: parsed_expression.parser.functions + 1,
				},
				value: Function(Box.box(definition)),
			})
		}
	}

	# ---- expressions -----------------------------------------------------------

	expression : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	expression = |parser| {
		parsed_expression = Parser.assignment(parser)?
		if Parser.is_punct(parsed_expression.parser, ",") {
			Err(Parser.fault_here(parsed_expression.parser, "unsupported: the comma operator"))
		} else {
			Ok(parsed_expression)
		}
	}

	Assigning : Try(Ast.AssignmentOperator, [NotAssignment, Unsupported(Str)])

	assignment_operator : Lexer.TokenKind -> Parser.Assigning
	assignment_operator = |kind| match kind {
		Punct("=") => Ok(Set)
		Punct("+=") => Ok(Combine(Add))
		Punct("-=") => Ok(Combine(Subtract))
		Punct("*=") => Ok(Combine(Multiply))
		Punct("/=") => Ok(Combine(Divide))
		Punct("%=") => Ok(Combine(Remainder))
		Punct("**=") => Ok(Combine(Power))
		Punct("<<=") => Err(Unsupported("unsupported: bitwise operators (`<<=`)"))
		Punct(">>=") => Err(Unsupported("unsupported: bitwise operators (`>>=`)"))
		Punct("&=") => Err(Unsupported("unsupported: bitwise operators (`&=`)"))
		Punct("|=") => Err(Unsupported("unsupported: bitwise operators (`|=`)"))
		Punct("^=") => Err(Unsupported("unsupported: bitwise operators (`^=`)"))
		Punct("&&=") => Ok(Logically(And))
		Punct("||=") => Ok(Logically(Or))
		Punct("??=") => Ok(Logically(Nullish))
		_ => Err(NotAssignment)
	}

	target_of : Ast.Expression, Ast.Where -> Try(Ast.Target, Lexer.Fault)
	target_of = |tree, site| match tree {
		Name(text, slot, at) => Ok(ToName(text, slot, at))
		Member(object, key, _) => Ok(ToMember(object, key))
		Index(object, key, _) => Ok(ToIndex(object, key))
		ArrayLit(_) => Err(Parser.fault_at(site, "unsupported: destructuring"))
		ObjectLit(_) => Err(Parser.fault_at(site, "unsupported: destructuring"))
		Chain(_) => Err(Parser.fault_at(site, "SyntaxError: Invalid left-hand side in assignment"))
		_ => Err(Parser.fault_at(site, "this can't be assigned to"))
	}

	assignment : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	assignment = |parser|
		if Parser.is_arrow_start(parser) {
			Parser.arrow(parser)
		} else if Parser.is_pattern_assignment(parser) {
			site = Parser.here(parser)
			bound = Parser.pattern(parser, Assigning)?
			onward = Parser.expect_punct(bound.parser, "=")?
			right = Parser.assignment(onward)?
			Ok({ parser: right.parser, value: Destructure(bound.value, right.value, site) })
		} else {
			site = Parser.here(parser)
			left = Parser.conditional(parser)?
			match Parser.assignment_operator(Parser.token(left.parser).kind) {
				Ok(operator) => {
					target = Parser.target_of(left.value, site)?
					right = Parser.assignment(Parser.advance(left.parser))?
					value = match target {
						ToName(text, _, _) => Parser.with_name_given(right.value, text)
						_ => right.value
					}
					Ok({ parser: right.parser, value: Assign(target, operator, value, site) })
				}
				Err(Unsupported(why)) => Err(Parser.fault_here(left.parser, why))
				Err(NotAssignment) => Ok(left)
			}
		}

	conditional : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	conditional = |parser| {
		test = Parser.logical_or(parser)?
		if Parser.is_punct(test.parser, "?") {
			yes = Parser.assignment(Parser.advance(test.parser))?
			onward = Parser.expect_punct(yes.parser, ":")?
			no = Parser.assignment(onward)?
			Ok({ parser: no.parser, value: Conditional(test.value, yes.value, no.value) })
		} else {
			Ok(test)
		}
	}

	logical_or : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	logical_or = |parser| {
		first = Parser.logical_and(parser)?
		var $onward = first.parser
		var $built = first.value
		while Parser.is_punct($onward, "||") or Parser.is_punct($onward, "??") {
			operator = if Parser.is_punct($onward, "||") {
				Or
			} else {
				Nullish
			}
			parsed = Parser.logical_and(Parser.advance($onward))?
			$built = Logical(operator, $built, parsed.value)
			$onward = parsed.parser
		}
		Ok({ parser: $onward, value: $built })
	}

	logical_and : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	logical_and = |parser| {
		first = Parser.equality(parser)?
		var $onward = first.parser
		var $built = first.value
		while Parser.is_punct($onward, "&&") {
			parsed = Parser.equality(Parser.advance($onward))?
			$built = Logical(And, $built, parsed.value)
			$onward = parsed.parser
		}
		Ok({ parser: $onward, value: $built })
	}

	# The binary operators of one level of precedence, by their tokens.
	Level : List({ punct : Str, operator : Ast.BinaryOperator })

	# One left-associative level: operands from `next`, joined by the level's
	# operators.
	# A level's parser, which reads its operands.
	Operand : Parser.State -> Parser.ParsedExpression

	binary_level : Parser.State, Parser.Level, Parser.Operand -> Parser.ParsedExpression
	binary_level = |parser, level, next| {
		first = next(parser)?
		var $onward = first.parser
		var $built = first.value
		var $more = True
		while $more {
			current = Parser.token($onward)
			match level.find_first(|matched| current.kind == Punct(matched.punct)) {
				Ok(matched) => {
					parsed = next(Parser.advance($onward))?
					$built = Binary(
						matched.operator,
						$built,
						parsed.value,
						Parser.where_of(current),
					)
					$onward = parsed.parser
				}
				Err(NotFound) => {
					$more = False
				}
			}
		}
		Ok({ parser: $onward, value: $built })
	}

	refuse_operator : Parser.State, List(Str), Str -> Try({}, Lexer.Fault)
	refuse_operator = |parser, puncts, why|
		match Parser.token(parser).kind {
			Punct(text) if puncts.contains(text) => Err(
				Parser.fault_here(parser, "${why} (`${text}`)"),
			)
			_ => Ok({})
		}

	equality : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	equality = |parser| {
		parsed = Parser.binary_level(
			parser,
			[{ punct: "===", operator: StrictEqual }, { punct: "!==", operator: StrictNotEqual }],
			Parser.relational,
		)?
		Parser.refuse_operator(
			parsed.parser,
			["==", "!="],
			"unsupported: loose equality, use `===` or `!==`",
		)?
		Parser.refuse_operator(parsed.parser, ["&", "|", "^"], "unsupported: bitwise operators")?
		Ok(parsed)
	}

	relational : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	relational = |parser| {
		parsed = Parser.binary_level(
			parser,
			[
				{ punct: "<", operator: Less },
				{ punct: "<=", operator: LessOrEqual },
				{ punct: ">", operator: Greater },
				{ punct: ">=", operator: GreaterOrEqual },
			],
			Parser.additive,
		)?
		if Parser.is_word(parsed.parser, "in") or Parser.is_word(parsed.parser, "instanceof") {
			Err(Parser.fault_here(parsed.parser, "unsupported: `in` and `instanceof`"))
		} else {
			Parser.refuse_operator(
				parsed.parser,
				["<<", ">>", ">>>"],
				"unsupported: bitwise operators",
			)?
			Ok(parsed)
		}
	}

	additive : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	additive = |parser|
		Parser.binary_level(
			parser,
			[{ punct: "+", operator: Add }, { punct: "-", operator: Subtract }],
			Parser.multiplicative,
		)

	multiplicative : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	multiplicative = |parser|
		Parser.binary_level(
			parser,
			[
				{ punct: "*", operator: Multiply },
				{ punct: "/", operator: Divide },
				{ punct: "%", operator: Remainder },
			],
			Parser.exponent,
		)

	# `**` binds to the right: `2 ** 3 ** 2` is `2 ** 9`.
	exponent : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	exponent = |parser| {
		base = Parser.unary(parser)?
		if Parser.is_punct(base.parser, "**") {
			site = Parser.here(base.parser)
			power = Parser.exponent(Parser.advance(base.parser))?
			Ok({ parser: power.parser, value: Binary(Power, base.value, power.value, site) })
		} else {
			Ok(base)
		}
	}

	unary : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	unary = |parser| {
		site = Parser.here(parser)
		operator = match Parser.token(parser).kind {
			Punct("!") => Ok(Operator(Not))
			Punct("-") => Ok(Operator(Negate))
			Punct("+") => Ok(Operator(Plus))
			Name("typeof") => Ok(Operator(TypeOf))
			Punct("++") => Ok(Prefixed(Increment))
			Punct("--") => Ok(Prefixed(Decrement))
			Punct("~") => Err(Parser.fault_here(parser, "unsupported: bitwise operators (`~`)"))
			_ => Ok(NoOperator)
		}?
		match operator {
			Operator(unary_operator) => {
				parsed = Parser.unary(Parser.advance(parser))?
				Ok({ parser: parsed.parser, value: Unary(unary_operator, parsed.value, site) })
			}
			Prefixed(step) => {
				parsed = Parser.unary(Parser.advance(parser))?
				target = Parser.target_of(parsed.value, site)?
				Ok({ parser: parsed.parser, value: Update(target, step, Prefix, site) })
			}
			NoOperator => Parser.postfix(parser)
		}
	}

	postfix : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	postfix = |parser| {
		site = Parser.here(parser)
		parsed = Parser.call_or_member(parser)?
		current = Parser.token(parsed.parser)
		step = if current.before == NewLine {
			NoStep
		} else if current.kind == Punct("++") {
			Stepped(Increment)
		} else if current.kind == Punct("--") {
			Stepped(Decrement)
		} else {
			NoStep
		}
		match step {
			Stepped(direction) => {
				target = Parser.target_of(parsed.value, site)?
				Ok({
					parser: Parser.advance(parsed.parser),
					value: Update(target, direction, Postfix, site),
				})
			}
			NoStep => Ok(parsed)
		}
	}

	call_or_member : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	call_or_member = |parser| {
		first = Parser.primary(parser)?
		var $onward = first.parser
		var $built = first.value
		var $optional = False
		var $more = True
		while $more {
			current = Parser.token($onward)
			site = Parser.where_of(current)
			match current.kind {
				Punct(".") => {
					name_found = Parser.name_after_dot(Parser.advance($onward))?
					$built = Member($built, name_found.value, site)
					$onward = name_found.parser
				}
				Punct("?.") => {
					onward = Parser.advance($onward)
					$optional = True
					match Parser.token(onward).kind {
						Name(text) => {
							$built = OptionalMember($built, text, site)
							$onward = Parser.advance(onward)
						}
						Punct("[") => {
							index_key = Parser.expression(Parser.advance(onward))?
							closed = Parser.expect_punct(index_key.parser, "]")?
							$built = OptionalIndex($built, index_key.value, site)
							$onward = closed
						}
						Punct("(") => {
							call_arguments = Parser.arguments(onward)?
							$built = OptionalCall($built, call_arguments.value, site)
							$onward = call_arguments.parser
						}
						other => return Err(
							Parser.fault_here(
								onward,
								"expected a property's name, `[` or `(` after `?.`, found ${Parser.token_text(other)}",
							),
						)
					}
				}
				Punct("[") => {
					index_key = Parser.expression(Parser.advance($onward))?
					onward = Parser.expect_punct(index_key.parser, "]")?
					$built = Index($built, index_key.value, site)
					$onward = onward
				}
				Punct("(") => {
					call_arguments = Parser.arguments($onward)?
					$built = Call($built, call_arguments.value, site)
					$onward = call_arguments.parser
				}
				TemplateWhole(_) => return Err(
					Parser.fault_here($onward, "unsupported: tagged templates"),
				)
				TemplateHead(_) => return Err(
					Parser.fault_here($onward, "unsupported: tagged templates"),
				)
				_ => {
					$more = False
				}
			}
		}
		chained = if $optional {
			Chain($built)
		} else {
			$built
		}
		Ok({ parser: $onward, value: chained })
	}

	arguments : Parser.State -> Try(Parser.Parsed(List(Ast.Element)), Lexer.Fault)
	arguments = |parser| Parser.expression_list(
		Parser.advance(parser),
		{ close: ")", what: "an argument" },
	)

	# Where a list of expressions ends, and what one of them is called in a
	# message.
	Closing : { close : Str, what : Str }

	# Elements separated by commas up to `close`, a trailing comma allowed:
	# each an expression, or `...` and the expression it spreads.
	expression_list : Parser.State,
	Parser.Closing -> Try(
		Parser.Parsed(List(Ast.Element)),
		Lexer.Fault,
	)
	expression_list = |parser, closing| {
		{ close, what } = closing
		var $onward = parser
		var $items = []
		while !Parser.is_punct($onward, close) {
			if Parser.is_punct($onward, ",") {
				return Err(
					Parser.fault_here(
						$onward,
						"unsupported: holes in an array (`,,`), or a missing ${what}",
					),
				)
			}
			spreads = Parser.is_punct($onward, "...")
			start = if spreads {
				Parser.advance($onward)
			} else {
				$onward
			}
			parsed_expression = Parser.assignment(start)?
			element = if spreads {
				Spread(parsed_expression.value, Parser.here($onward))
			} else {
				Single(parsed_expression.value)
			}
			$items = $items.append(element)
			if Parser.is_punct(parsed_expression.parser, ",") {
				$onward = Parser.advance(parsed_expression.parser)
			} else if Parser.is_punct(parsed_expression.parser, close) {
				$onward = parsed_expression.parser
			} else {
				return Err(
					Parser.fault_here(
						parsed_expression.parser,
						"expected `,` or `${close}`, found ${Parser.token_text(Parser.token(parsed_expression.parser).kind)}",
					),
				)
			}
		}
		Ok({ parser: Parser.advance($onward), value: $items })
	}

	primary : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	primary = |parser| {
		Parser.refuse_unsupported_word(parser)?
		current = Parser.token(parser)
		site = Parser.where_of(current)
		after = Parser.advance(parser)
		match current.kind {
			Number(number) => Ok({ parser: after, value: Number(number) })
			Text(text) => Ok({ parser: after, value: Text(text) })
			TemplateWhole(text) => Ok({ parser: after, value: Template([text], []) })
			TemplateHead(text) => Parser.template_rest(after, text)
			Name("true") => Ok({ parser: after, value: Boolean(True) })
			Name("false") => Ok({ parser: after, value: Boolean(False) })
			Name("null") => Ok({ parser: after, value: Null })
			Name("undefined") => Ok({ parser: after, value: Undefined })
			Name("new") => {
				if Parser.is_punct(after, ".") {
					Err(Parser.fault_here(after, "unsupported: `new.target`"))
				} else {
					callee = Parser.new_callee(after)?
					if Parser.is_punct(callee.parser, "(") {
						call_arguments = Parser.arguments(callee.parser)?
						Ok({
							parser: call_arguments.parser,
							value: New(callee.value, call_arguments.value, site),
						})
					} else {
						Ok({ parser: callee.parser, value: New(callee.value, [], site) })
					}
				}
			}
			Name("function") => {
				definition = Parser.function_rest(after, site, Expressed)?
				Ok({ parser: definition.parser, value: Function(Box.box(definition.value)) })
			}
			Name(text) => {
				if Parser.is_reserved(text) {
					Err(Parser.fault_here(parser, "`${text}` can't start an expression"))
				} else {
					Ok({ parser: after, value: Name(text, Unresolved, site) })
				}
			}
			Punct("(") => {
				parsed_expression = Parser.expression(after)?
				onward = Parser.expect_punct(parsed_expression.parser, ")")?
				Ok({ parser: onward, value: parsed_expression.value })
			}
			Punct("[") => {
				items = Parser.expression_list(after, { close: "]", what: "item" })?
				Ok({ parser: items.parser, value: ArrayLit(items.value) })
			}
			Punct("{") => Parser.object_rest(after)
			Punct("/") => Err(Parser.fault_here(parser, "unsupported: regular expressions"))
			Punct("#") => Err(Parser.fault_here(parser, "unsupported: private names"))
			Punct("@") => Err(Parser.fault_here(parser, "unsupported: decorators"))
			other => Err(
				Parser.fault_here(
					parser,
					"expected an expression, found ${Parser.token_text(other)}",
				),
			)
		}
	}

	# What `new` calls: a name and the properties after it, up to the
	# arguments.
	new_callee : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	new_callee = |parser| {
		first = Parser.primary(parser)?
		var $onward = first.parser
		var $built = first.value
		var $more = True
		while $more {
			current = Parser.token($onward)
			site = Parser.where_of(current)
			match current.kind {
				Punct(".") => {
					name_found = Parser.name_after_dot(Parser.advance($onward))?
					$built = Member($built, name_found.value, site)
					$onward = name_found.parser
				}
				Punct("[") => {
					index_key = Parser.expression(Parser.advance($onward))?
					onward = Parser.expect_punct(index_key.parser, "]")?
					$built = Index($built, index_key.value, site)
					$onward = onward
				}
				_ => {
					$more = False
				}
			}
		}
		Ok({ parser: $onward, value: $built })
	}

	# A property's name after a `.`.
	name_after_dot : Parser.State -> Try(Parser.Parsed(Str), Lexer.Fault)
	name_after_dot = |parser|
		match Parser.token(parser).kind {
			Name(text) => Ok({ parser: Parser.advance(parser), value: text })
			Punct("#") => Err(Parser.fault_here(parser, "unsupported: private names"))
			other => Err(
				Parser.fault_here(
					parser,
					"expected a property's name after `.`, found ${Parser.token_text(other)}",
				),
			)
		}

	template_rest : Parser.State, Str -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	template_rest = |parser, head| {
		var $onward = parser
		var $texts = [head]
		var $parts = []
		var $open = True
		while $open {
			parsed_expression = Parser.expression($onward)?
			$parts = $parts.append(parsed_expression.value)
			match Parser.token(parsed_expression.parser).kind {
				TemplateMiddle(text) => {
					$texts = $texts.append(text)
					$onward = Parser.advance(parsed_expression.parser)
				}
				TemplateTail(text) => {
					$texts = $texts.append(text)
					$onward = Parser.advance(parsed_expression.parser)
					$open = False
				}
				other => return Err(
					Parser.fault_here(
						parsed_expression.parser,
						"expected `}` to close a template's `\${`, found ${Parser.token_text(other)}",
					),
				)
			}
		}
		Ok({ parser: $onward, value: Template($texts, $parts) })
	}

	# An object literal after its `{`.
	object_rest : Parser.State -> Try(Parser.Parsed(Ast.Expression), Lexer.Fault)
	object_rest = |parser| {
		var $onward = parser
		var $parts = []
		while !Parser.is_punct($onward, "}") {
			parsed = if Parser.is_punct($onward, "...") {
				spread = Parser.assignment(Parser.advance($onward))?
				{ parser: spread.parser, value: Spread(spread.value, Parser.here($onward)) }
			} else {
				field = Parser.property($onward)?
				{ parser: field.parser, value: Field(field.value) }
			}
			$parts = $parts.append(parsed.value)
			if Parser.is_punct(parsed.parser, ",") {
				$onward = Parser.advance(parsed.parser)
			} else if Parser.is_punct(parsed.parser, "}") {
				$onward = parsed.parser
			} else {
				return Err(
					Parser.fault_here(
						parsed.parser,
						"expected `,` or `}` in an object, found ${Parser.token_text(Parser.token(parsed.parser).kind)}",
					),
				)
			}
		}
		Ok({ parser: Parser.advance($onward), value: ObjectLit($parts) })
	}

	property : Parser.State -> Try(Parser.Parsed(Ast.Property), Lexer.Fault)
	property = |parser| {
		current = Parser.token(parser)
		site = Parser.where_of(current)
		key = match current.kind {
			Name(text) => {
				next = Parser.token_after(parser).kind
				if (text == "get" or text == "set" or text == "async") and next != Punct(":") and next != Punct("(") and next != Punct(",") and next != Punct("}") {
					Err(
						Parser.fault_here(
							parser,
							"unsupported: getters, setters and async methods",
						),
					)
				} else {
					Ok(text)
				}
			}
			Text(text) => Ok(text)
			Number(number) => Ok(NumberText.text_for(number))
			Punct("[") => Err(Parser.fault_here(parser, "unsupported: computed property names"))
			Punct("*") => Err(Parser.fault_here(parser, "unsupported: generators"))
			other => Err(
				Parser.fault_here(
					parser,
					"expected a property's name, found ${Parser.token_text(other)}",
				),
			)
		}?
		after = Parser.advance(parser)
		if Parser.is_punct(after, ":") {
			parsed_value = Parser.assignment(Parser.advance(after))?
			Ok({
				parser: parsed_value.parser,
				value: { key: key, value: Parser.with_name_given(parsed_value.value, key) },
			})
		} else if Parser.is_punct(after, "(") {
			parameters = Parser.parameter_list(after)?
			definition = Parser.function_body(
				parameters.parser,
				{
					name: key,
					parameters: parameters.value,
					at: site,
					before: after.functions,
				},
			)?
			Ok({
				parser: definition.parser,
				value: { key: key, value: Function(Box.box(definition.value)) },
			})
		} else {
			match current.kind {
				Name(text) => {
					if Parser.is_reserved(text) {
						Err(Parser.fault_here(parser, "`${text}` is a reserved word, not a name"))
					} else {
						Ok({
							parser: after,
							value: { key: text, value: Name(text, Unresolved, site) },
						})
					}
				}
				_ => Err(Parser.fault_here(after, "expected `:` after a property's name"))
			}
		}
	}
}
