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
import Ast
import Lexer
import NumberText

Parser :: [].{
	# Where the parser is in the tokens, and how many function literals it has
	# passed, which tells a block whether one was written inside it.
	State : {
		tokens : List(Lexer.Token),
		at : U64,
		functions : U64,
	}

	Parsed(a) : { p : Parser.State, value : a }

	program_of : Str -> Try(Ast.Program, Lexer.Fault)
	program_of = |text| {
		tokens = Lexer.tokens_of(text)?
		var $p = { tokens: tokens, at: 0, functions: 0 }
		var $stmts = []
		while !Parser.is_end($p) {
			r = Parser.statement($p)?
			$p = r.p
			$stmts = $stmts.append(r.value)
		}
		Ok({
			stmts: $stmts,
			scoping: Scoped,
			capture: if $p.functions > 0 {
				Captures
			} else {
				CapturesNothing
			},
		})
	}

	# ---- tokens ----------------------------------------------------------------

	token : Parser.State -> Lexer.Token
	token = |p| p.tokens.get(p.at) ?? crash "Parser.token: the parser never passes the end token"

	token_after : Parser.State -> Lexer.Token
	token_after = |p| p.tokens.get(p.at + 1) ?? Parser.token(p)

	advance : Parser.State -> Parser.State
	advance = |p|
		if Parser.is_end(p) {
			p
		} else {
			{ ..p, at: p.at + 1 }
		}

	is_end : Parser.State -> Bool
	is_end = |p| Parser.token(p).tok == End

	is_punct : Parser.State, Str -> Bool
	is_punct = |p, s| Parser.token(p).tok == Punct(s)

	is_word : Parser.State, Str -> Bool
	is_word = |p, s| Parser.token(p).tok == Name(s)

	where_of : Lexer.Token -> Ast.Where
	where_of = |t| { line: t.line, col: t.col }

	here : Parser.State -> Ast.Where
	here = |p| Parser.where_of(Parser.token(p))

	fault_here : Parser.State, Str -> Lexer.Fault
	fault_here = |p, why| {
		t = Parser.token(p)
		{ why: why, line: t.line, col: t.col }
	}

	fault_at : Ast.Where, Str -> Lexer.Fault
	fault_at = |w, why| { why: why, line: w.line, col: w.col }

	shown : Lexer.Tok -> Str
	shown = |tok| match tok {
		Number(n) => NumberText.of(n)
		Text(_) => "a string"
		Name(s) => "`${s}`"
		Punct(s) => "`${s}`"
		TemplateWhole(_) => "a template literal"
		TemplateHead(_) => "a template literal"
		TemplateMiddle(_) => "the middle of a template literal"
		TemplateTail(_) => "the end of a template literal"
		End => "the end of the program"
	}

	expect_punct : Parser.State, Str -> Try(Parser.State, Lexer.Fault)
	expect_punct = |p, s|
		if Parser.is_punct(p, s) {
			Ok(Parser.advance(p))
		} else {
			Err(Parser.fault_here(p, "expected `${s}`, found ${Parser.shown(Parser.token(p).tok)}"))
		}

	# A statement's end: a `;`, or at JavaScript would insert one.
	end_of_statement : Parser.State -> Try(Parser.State, Lexer.Fault)
	end_of_statement = |p| {
		t = Parser.token(p)
		if Parser.is_punct(p, ";") {
			Ok(Parser.advance(p))
		} else if Parser.is_punct(p, "}") or t.tok == End or t.before == NewLine {
			Ok(p)
		} else {
			Err(Parser.fault_here(p, "expected `;` or a line break, found ${Parser.shown(t.tok)}"))
		}
	}

	name_here : Parser.State, Str -> Try(Parser.Parsed(Str), Lexer.Fault)
	name_here = |p, what|
		match Parser.token(p).tok {
			Name(s) => {
				if Parser.is_reserved(s) {
					Err(Parser.fault_here(p, "`${s}` is a reserved word, not ${what}"))
				} else {
					Ok({ p: Parser.advance(p), value: s })
				}
			}
			other => Err(Parser.fault_here(p, "expected ${what}, found ${Parser.shown(other)}"))
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
	is_reserved = |s| Parser.reserved_words.contains(s)

	# The words that begin a form the subset leaves out, and what to say.
	unsupported_word : Str -> Try(Str, [Supported])
	unsupported_word = |s| match s {
		"this" => Ok("unsupported: `this`")
		"new" => Ok("unsupported: `new` (constructors and prototypes)")
		"class" => Ok("unsupported: classes")
		"var" => Ok("unsupported: `var` (use `let` or `const`)")
		"switch" => Ok("unsupported: `switch`")
		"do" => Ok("unsupported: `do ... while`")
		"try" => Ok("unsupported: exceptions (`try`)")
		"throw" => Ok("unsupported: exceptions (`throw`)")
		"catch" => Ok("unsupported: exceptions (`catch`)")
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
	refuse_unsupported_word = |p|
		match Parser.token(p).tok {
			Name(s) => match Parser.unsupported_word(s) {
				Ok(why) => Err(Parser.fault_here(p, why))
				Err(Supported) => Ok({})
			}
			_ => Ok({})
		}

	capture_since : Parser.State, U64 -> Ast.Capture
	capture_since = |p, before|
		if p.functions > before {
			Captures
		} else {
			CapturesNothing
		}

	# ---- statements ------------------------------------------------------------

	statement : Parser.State -> Try(Parser.Parsed(Ast.Stmt), Lexer.Fault)
	statement = |p| {
		Parser.refuse_unsupported_word(p)?
		t = Parser.token(p)
		match t.tok {
			Punct("{") => {
				r = Parser.block(p)?
				Ok({ p: r.p, value: BlockStmt(r.value) })
			}
			Punct(";") => Ok({ p: Parser.advance(p), value: Empty })
			Name("let") => Parser.declaration(p, Let)
			Name("const") => Parser.declaration(p, Const)
			Name("function") => {
				r = Parser.function_rest(Parser.advance(p), Parser.where_of(t), Declared)?
				Ok({ p: r.p, value: FunctionDecl(r.value) })
			}
			Name("if") => Parser.if_statement(p)
			Name("while") => {
				q = Parser.expect_punct(Parser.advance(p), "(")?
				test = Parser.expression(q)?
				q2 = Parser.expect_punct(test.p, ")")?
				body = Parser.statement(q2)?
				Ok({ p: body.p, value: While(test.value, body.value) })
			}
			Name("for") => Parser.for_statement(p)
			Name("return") => {
				q = Parser.advance(p)
				n = Parser.token(q)
				if Parser.is_punct(
					q,
					";",
				) or Parser.is_punct(q, "}") or n.tok == End or n.before == NewLine {
					q2 = Parser.end_of_statement(q)?
					Ok({ p: q2, value: Return(Undefined) })
				} else {
					e = Parser.expression(q)?
					q2 = Parser.end_of_statement(e.p)?
					Ok({ p: q2, value: Return(e.value) })
				}
			}
			Name("break") => Parser.jump(p, Break)
			Name("continue") => Parser.jump(p, Continue)
			_ => {
				e = Parser.expression(p)?
				q = Parser.end_of_statement(e.p)?
				Ok({ p: q, value: Expression(e.value) })
			}
		}
	}

	jump : Parser.State, Ast.Stmt -> Try(Parser.Parsed(Ast.Stmt), Lexer.Fault)
	jump = |p, stmt| {
		q = Parser.advance(p)
		n = Parser.token(q)
		match n.tok {
			Name(_) if n.before == SameLine => Err(Parser.fault_here(q, "unsupported: labels"))
			_ => {
				q2 = Parser.end_of_statement(q)?
				Ok({ p: q2, value: stmt })
			}
		}
	}

	block : Parser.State -> Try(Parser.Parsed(Ast.Block), Lexer.Fault)
	block = |p| {
		before = p.functions
		var $q = Parser.expect_punct(p, "{")?
		var $stmts = []
		while !Parser.is_punct($q, "}") {
			if Parser.is_end($q) {
				return Err(Parser.fault_here($q, "a block that never ends (expected `}`)"))
			}
			r = Parser.statement($q)?
			$q = r.p
			$stmts = $stmts.append(r.value)
		}
		Ok({
			p: Parser.advance($q),
			value: {
				stmts: $stmts,
				scoping: Parser.scoping_of($stmts),
				capture: Parser.capture_since($q, before),
			},
		})
	}

	scoping_of : List(Ast.Stmt) -> Ast.Scoping
	scoping_of = |stmts| {
		declares = stmts.any(
			|s| match s {
				Declare(_, _) => True
				FunctionDecl(_) => True
				_ => False
			},
		)
		if declares {
			Scoped
		} else {
			Unscoped
		}
	}

	declaration : Parser.State, Ast.Binding -> Try(Parser.Parsed(Ast.Stmt), Lexer.Fault)
	declaration = |p, binding| {
		r = Parser.declarators(Parser.advance(p), binding)?
		q = Parser.end_of_statement(r.p)?
		Ok({ p: q, value: Declare(binding, r.value) })
	}

	declarators : Parser.State, Ast.Binding -> Try(Parser.Parsed(List(Ast.Declarator)), Lexer.Fault)
	declarators = |p, binding| {
		var $q = p
		var $out = []
		var $more = True
		while $more {
			if Parser.is_punct($q, "[") or Parser.is_punct($q, "{") {
				return Err(Parser.fault_here($q, "unsupported: destructuring"))
			}
			w = Parser.here($q)
			n = Parser.name_here($q, "a name to declare")?
			if Parser.is_punct(n.p, "=") {
				e = Parser.assignment(Parser.advance(n.p))?
				$out = $out.append({
					name: n.value,
					init: Initialized(Parser.named(e.value, n.value)),
					at: w,
				})
				$q = e.p
			} else if binding == Const {
				return Err(Parser.fault_here(n.p, "a `const` without a value"))
			} else {
				$out = $out.append({ name: n.value, init: Uninitialized, at: w })
				$q = n.p
			}
			if Parser.is_punct($q, ",") {
				$q = Parser.advance($q)
			} else {
				$more = False
			}
		}
		Ok({ p: $q, value: $out })
	}

	# A function literal written with no name of its own takes the name it is
	# bound to, as JavaScript names `const f = () => 1` "f".
	named : Ast.Expr, Str -> Ast.Expr
	named = |e, name| match e {
		Function(def) if def.name == "" => Function({ ..def, name: name })
		_ => e
	}

	if_statement : Parser.State -> Try(Parser.Parsed(Ast.Stmt), Lexer.Fault)
	if_statement = |p| {
		q = Parser.expect_punct(Parser.advance(p), "(")?
		test = Parser.expression(q)?
		q2 = Parser.expect_punct(test.p, ")")?
		yes = Parser.statement(q2)?
		if Parser.is_word(yes.p, "else") {
			no = Parser.statement(Parser.advance(yes.p))?
			Ok({ p: no.p, value: If(test.value, yes.value, no.value) })
		} else {
			Ok({ p: yes.p, value: If(test.value, yes.value, Empty) })
		}
	}

	for_statement : Parser.State -> Try(Parser.Parsed(Ast.Stmt), Lexer.Fault)
	for_statement = |p| {
		before = p.functions
		q = Parser.expect_punct(Parser.advance(p), "(")?
		binding_word = if Parser.is_word(q, "let") {
			Bound(Let)
		} else if Parser.is_word(q, "const") {
			Bound(Const)
		} else {
			Unbound
		}
		match binding_word {
			Bound(binding) if Parser.is_word(Parser.advance(Parser.advance(q)), "of") => {
				Parser.for_of_rest(Parser.advance(q), binding)
			}
			Bound(_) if Parser.is_word(Parser.advance(Parser.advance(q)), "in") => {
				Err(
					Parser.fault_here(
						q,
						"unsupported: `for ... in` (use `for ... of` over Object.keys)",
					),
				)
			}
			_ => {
				init = match binding_word {
					Bound(binding) => {
						r = Parser.declarators(Parser.advance(q), binding)?
						Ok({ p: r.p, value: Declare(binding, r.value) })
					}
					Unbound => if Parser.is_punct(q, ";") {
						Ok({ p: q, value: Empty })
					} else {
						e = Parser.expression(q)?
						Ok({ p: e.p, value: Expression(e.value) })
					}
				}?
				q2 = Parser.expect_punct(init.p, ";")?
				test = if Parser.is_punct(q2, ";") {
					{ p: q2, value: Always }
				} else {
					e = Parser.expression(q2)?
					{ p: e.p, value: Tested(e.value) }
				}
				q3 = Parser.expect_punct(test.p, ";")?
				update = if Parser.is_punct(q3, ")") {
					{ p: q3, value: NoUpdate }
				} else {
					e = Parser.expression(q3)?
					{ p: e.p, value: Updated(e.value) }
				}
				q4 = Parser.expect_punct(update.p, ")")?
				body = Parser.statement(q4)?
				loop = {
					init: init.value,
					test: test.value,
					update: update.value,
					body: body.value,
					capture: Parser.capture_since(body.p, before),
				}
				Ok({ p: body.p, value: For(loop) })
			}
		}
	}

	for_of_rest : Parser.State, Ast.Binding -> Try(Parser.Parsed(Ast.Stmt), Lexer.Fault)
	for_of_rest = |p, binding| {
		w = Parser.here(p)
		n = Parser.name_here(p, "a name to declare")?
		e = Parser.assignment(Parser.advance(n.p))?
		q = Parser.expect_punct(e.p, ")")?
		before = q.functions
		body = Parser.statement(q)?
		loop = {
			binding: binding,
			name: n.value,
			iterable: e.value,
			body: body.value,
			capture: Parser.capture_since(body.p, before),
			at: w,
		}
		Ok({ p: body.p, value: ForOf(loop) })
	}

	# ---- functions -------------------------------------------------------------

	# How a function's name is written: a declaration must have one.
	Naming : [Declared, Expressed]

	# A function after its `function` keyword: an optional name, the
	# parameters and the body.
	function_rest : Parser.State,
	Ast.Where,
	Parser.Naming -> Try(
		Parser.Parsed(Ast.FunDef),
		Lexer.Fault,
	)
	function_rest = |p, w, naming| {
		if Parser.is_punct(p, "*") {
			return Err(Parser.fault_here(p, "unsupported: generators"))
		}
		named_p = match Parser.token(p).tok {
			Name(_) => {
				n = Parser.name_here(p, "a function's name")?
				Ok(n)
			}
			_ => match naming {
				Declared => Err(Parser.fault_here(p, "a function declaration without a name"))
				Expressed => Ok({ p: p, value: "" })
			}
		}?
		params = Parser.parameters(named_p.p)?
		Parser.function_body(params.p, named_p.value, params.value, w)
	}

	parameters : Parser.State -> Try(Parser.Parsed(List(Str)), Lexer.Fault)
	parameters = |p| {
		var $q = Parser.expect_punct(p, "(")?
		var $names = []
		while !Parser.is_punct($q, ")") {
			if Parser.is_punct($q, "...") {
				return Err(Parser.fault_here($q, "unsupported: rest parameters"))
			}
			if Parser.is_punct($q, "[") or Parser.is_punct($q, "{") {
				return Err(Parser.fault_here($q, "unsupported: destructuring"))
			}
			n = Parser.name_here($q, "a parameter's name")?
			if Parser.is_punct(n.p, "=") {
				return Err(Parser.fault_here(n.p, "unsupported: default parameters"))
			}
			$names = $names.append(n.value)
			$q = if Parser.is_punct(n.p, ",") {
				Parser.advance(n.p)
			} else {
				n.p
			}
			if !Parser.is_punct($q, ")") and !Parser.is_punct(n.p, ",") {
				return Err(Parser.fault_here($q, "expected `,` or `)` in the parameters"))
			}
		}
		Ok({ p: Parser.advance($q), value: $names })
	}

	function_body : Parser.State,
	Str,
	List(Str),
	Ast.Where -> Try(
		Parser.Parsed(Ast.FunDef),
		Lexer.Fault,
	)
	function_body = |p, name, params, w| {
		before = p.functions
		b = Parser.block(p)?
		def = {
			name: name,
			params: params,
			body: b.value.stmts,
			capture: Parser.capture_since(b.p, before),
			at: w,
		}
		Ok({ p: { ..b.p, functions: b.p.functions + 1 }, value: def })
	}

	# Whether an arrow function starts here: a name and `=>`, or a
	# parenthesized list whose `)` is followed by `=>`.
	is_arrow_start : Parser.State -> Bool
	is_arrow_start = |p|
		match Parser.token(p).tok {
			Name(_) => Parser.token_after(p).tok == Punct("=>")
			Punct("(") => {
				close = Parser.matching_close(p)
				match p.tokens.get(close + 1) {
					Ok(t) => t.tok == Punct("=>")
					Err(OutOfBounds) => False
				}
			}
			_ => False
		}

	# The index of the `)` that closes the `(` at the parser's place.
	matching_close : Parser.State -> U64
	matching_close = |p| {
		var $i = p.at
		var $depth = 0
		var $found = False
		while !$found and $i < p.tokens.len() {
			t = p.tokens.get($i) ?? crash "Parser.matching_close: inside the tokens"
			if t.tok == Punct("(") or t.tok == Punct("[") or t.tok == Punct("{") {
				$depth = $depth + 1
				$i = $i + 1
			} else if t.tok == Punct(")") or t.tok == Punct("]") or t.tok == Punct("}") {
				$depth = $depth - 1
				if $depth == 0 {
					$found = True
				} else {
					$i = $i + 1
				}
			} else if t.tok == End {
				$found = True
			} else {
				$i = $i + 1
			}
		}
		$i
	}

	arrow : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	arrow = |p| {
		w = Parser.here(p)
		params = match Parser.token(p).tok {
			Name(_) => {
				n = Parser.name_here(p, "a parameter's name")?
				Ok({ p: n.p, value: [n.value] })
			}
			_ => Parser.parameters(p)
		}?
		q = Parser.expect_punct(params.p, "=>")?
		if Parser.is_punct(q, "{") {
			def = Parser.function_body(q, "", params.value, w)?
			Ok({ p: def.p, value: Function(def.value) })
		} else {
			before = q.functions
			e = Parser.assignment(q)?
			def = {
				name: "",
				params: params.value,
				body: [Return(e.value)],
				capture: Parser.capture_since(e.p, before),
				at: w,
			}
			Ok({ p: { ..e.p, functions: e.p.functions + 1 }, value: Function(def) })
		}
	}

	# ---- expressions -----------------------------------------------------------

	expression : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	expression = |p| {
		e = Parser.assignment(p)?
		if Parser.is_punct(e.p, ",") {
			Err(Parser.fault_here(e.p, "unsupported: the comma operator"))
		} else {
			Ok(e)
		}
	}

	assign_op : Lexer.Tok -> Try(Ast.AssignOp, [NotAssignment, Unsupported(Str)])
	assign_op = |tok| match tok {
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
		Punct("&&=") => Err(Unsupported("unsupported: logical assignment (`&&=`)"))
		Punct("||=") => Err(Unsupported("unsupported: logical assignment (`||=`)"))
		Punct("??=") => Err(Unsupported("unsupported: logical assignment (`??=`)"))
		_ => Err(NotAssignment)
	}

	target_of : Ast.Expr, Ast.Where -> Try(Ast.Target, Lexer.Fault)
	target_of = |e, w| match e {
		Name(s, at) => Ok(ToName(s, at))
		Member(obj, key, _) => Ok(ToMember(obj, key))
		Index(obj, key, _) => Ok(ToIndex(obj, key))
		ArrayLit(_) => Err(Parser.fault_at(w, "unsupported: destructuring"))
		ObjectLit(_) => Err(Parser.fault_at(w, "unsupported: destructuring"))
		_ => Err(Parser.fault_at(w, "this can't be assigned to"))
	}

	assignment : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	assignment = |p|
		if Parser.is_arrow_start(p) {
			Parser.arrow(p)
		} else {
			w = Parser.here(p)
			left = Parser.conditional(p)?
			match Parser.assign_op(Parser.token(left.p).tok) {
				Ok(op) => {
					target = Parser.target_of(left.value, w)?
					right = Parser.assignment(Parser.advance(left.p))?
					value = match target {
						ToName(s, _) => Parser.named(right.value, s)
						_ => right.value
					}
					Ok({ p: right.p, value: Assign(target, op, value, w) })
				}
				Err(Unsupported(why)) => Err(Parser.fault_here(left.p, why))
				Err(NotAssignment) => Ok(left)
			}
		}

	conditional : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	conditional = |p| {
		test = Parser.logical_or(p)?
		if Parser.is_punct(test.p, "?") {
			yes = Parser.assignment(Parser.advance(test.p))?
			q = Parser.expect_punct(yes.p, ":")?
			no = Parser.assignment(q)?
			Ok({ p: no.p, value: Conditional(test.value, yes.value, no.value) })
		} else {
			Ok(test)
		}
	}

	logical_or : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	logical_or = |p| {
		first = Parser.logical_and(p)?
		var $q = first.p
		var $e = first.value
		while Parser.is_punct($q, "||") or Parser.is_punct($q, "??") {
			op = if Parser.is_punct($q, "||") {
				Or
			} else {
				Nullish
			}
			r = Parser.logical_and(Parser.advance($q))?
			$e = Logical(op, $e, r.value)
			$q = r.p
		}
		Ok({ p: $q, value: $e })
	}

	logical_and : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	logical_and = |p| {
		first = Parser.equality(p)?
		var $q = first.p
		var $e = first.value
		while Parser.is_punct($q, "&&") {
			r = Parser.equality(Parser.advance($q))?
			$e = Logical(And, $e, r.value)
			$q = r.p
		}
		Ok({ p: $q, value: $e })
	}

	# The binary operators of one level of precedence, by their tokens.
	Level : List({ punct : Str, op : Ast.BinaryOp })

	# One left-associative level: operands from `next`, joined by the level's
	# operators.
	binary_level : Parser.State,
	Parser.Level,
	(
		Parser.State -> Try(
			Parser.Parsed(Ast.Expr),
			Lexer.Fault,
		)) -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	binary_level = |p, level, next| {
		first = next(p)?
		var $q = first.p
		var $e = first.value
		var $more = True
		while $more {
			t = Parser.token($q)
			match level.find_first(|l| t.tok == Punct(l.punct)) {
				Ok(l) => {
					r = next(Parser.advance($q))?
					$e = Binary(l.op, $e, r.value, Parser.where_of(t))
					$q = r.p
				}
				Err(NotFound) => {
					$more = False
				}
			}
		}
		Ok({ p: $q, value: $e })
	}

	refuse_operator : Parser.State, List(Str), Str -> Try({}, Lexer.Fault)
	refuse_operator = |p, puncts, why|
		match Parser.token(p).tok {
			Punct(s) if puncts.contains(s) => Err(Parser.fault_here(p, "${why} (`${s}`)"))
			_ => Ok({})
		}

	equality : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	equality = |p| {
		r = Parser.binary_level(
			p,
			[{ punct: "===", op: StrictEqual }, { punct: "!==", op: StrictNotEqual }],
			Parser.relational,
		)?
		Parser.refuse_operator(
			r.p,
			["==", "!="],
			"unsupported: loose equality, use `===` or `!==`",
		)?
		Parser.refuse_operator(r.p, ["&", "|", "^"], "unsupported: bitwise operators")?
		Ok(r)
	}

	relational : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	relational = |p| {
		r = Parser.binary_level(
			p,
			[
				{ punct: "<", op: Less },
				{ punct: "<=", op: LessOrEqual },
				{ punct: ">", op: Greater },
				{ punct: ">=", op: GreaterOrEqual },
			],
			Parser.additive,
		)?
		if Parser.is_word(r.p, "in") or Parser.is_word(r.p, "instanceof") {
			Err(Parser.fault_here(r.p, "unsupported: `in` and `instanceof`"))
		} else {
			Parser.refuse_operator(r.p, ["<<", ">>", ">>>"], "unsupported: bitwise operators")?
			Ok(r)
		}
	}

	additive : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	additive = |p|
		Parser.binary_level(
			p,
			[{ punct: "+", op: Add }, { punct: "-", op: Subtract }],
			Parser.multiplicative,
		)

	multiplicative : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	multiplicative = |p|
		Parser.binary_level(
			p,
			[
				{ punct: "*", op: Multiply },
				{ punct: "/", op: Divide },
				{ punct: "%", op: Remainder },
			],
			Parser.exponent,
		)

	# `**` binds to the right: `2 ** 3 ** 2` is `2 ** 9`.
	exponent : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	exponent = |p| {
		base = Parser.unary(p)?
		if Parser.is_punct(base.p, "**") {
			w = Parser.here(base.p)
			power = Parser.exponent(Parser.advance(base.p))?
			Ok({ p: power.p, value: Binary(Power, base.value, power.value, w) })
		} else {
			Ok(base)
		}
	}

	unary : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	unary = |p| {
		w = Parser.here(p)
		op = match Parser.token(p).tok {
			Punct("!") => Ok(Op(Not))
			Punct("-") => Ok(Op(Negate))
			Punct("+") => Ok(Op(Plus))
			Name("typeof") => Ok(Op(TypeOf))
			Punct("++") => Ok(Prefixed(Increment))
			Punct("--") => Ok(Prefixed(Decrement))
			Punct("~") => Err(Parser.fault_here(p, "unsupported: bitwise operators (`~`)"))
			_ => Ok(NoOp)
		}?
		match op {
			Op(o) => {
				r = Parser.unary(Parser.advance(p))?
				Ok({ p: r.p, value: Unary(o, r.value, w) })
			}
			Prefixed(step) => {
				r = Parser.unary(Parser.advance(p))?
				target = Parser.target_of(r.value, w)?
				Ok({ p: r.p, value: Update(target, step, Prefix, w) })
			}
			NoOp => Parser.postfix(p)
		}
	}

	postfix : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	postfix = |p| {
		w = Parser.here(p)
		r = Parser.call_or_member(p)?
		t = Parser.token(r.p)
		step = if t.before == NewLine {
			NoStep
		} else if t.tok == Punct("++") {
			Stepped(Increment)
		} else if t.tok == Punct("--") {
			Stepped(Decrement)
		} else {
			NoStep
		}
		match step {
			Stepped(s) => {
				target = Parser.target_of(r.value, w)?
				Ok({ p: Parser.advance(r.p), value: Update(target, s, Postfix, w) })
			}
			NoStep => Ok(r)
		}
	}

	call_or_member : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	call_or_member = |p| {
		first = Parser.primary(p)?
		var $q = first.p
		var $e = first.value
		var $more = True
		while $more {
			t = Parser.token($q)
			w = Parser.where_of(t)
			match t.tok {
				Punct(".") => {
					q = Parser.advance($q)
					match Parser.token(q).tok {
						Name(s) => {
							$e = Member($e, s, w)
							$q = Parser.advance(q)
						}
						Punct("#") => return Err(Parser.fault_here(q, "unsupported: private names"))
						other => return Err(
							Parser.fault_here(
								q,
								"expected a property's name after `.`, found ${Parser.shown(other)}",
							),
						)
					}
				}
				Punct("[") => {
					k = Parser.expression(Parser.advance($q))?
					q = Parser.expect_punct(k.p, "]")?
					$e = Index($e, k.value, w)
					$q = q
				}
				Punct("(") => {
					args = Parser.arguments($q)?
					$e = Call($e, args.value, w)
					$q = args.p
				}
				Punct("?.") => return Err(
					Parser.fault_here(
						$q,
						"unsupported: optional chaining (`?.`)",
					),
				)
				TemplateWhole(_) => return Err(
					Parser.fault_here(
						$q,
						"unsupported: tagged templates",
					),
				)
				TemplateHead(_) => return Err(
					Parser.fault_here(
						$q,
						"unsupported: tagged templates",
					),
				)
				_ => {
					$more = False
				}
			}
		}
		Ok({ p: $q, value: $e })
	}

	arguments : Parser.State -> Try(Parser.Parsed(List(Ast.Expr)), Lexer.Fault)
	arguments = |p| Parser.expression_list(Parser.advance(p), ")", "an argument")

	# Expressions separated by commas up to `close`, a trailing comma allowed.
	expression_list : Parser.State, Str, Str -> Try(Parser.Parsed(List(Ast.Expr)), Lexer.Fault)
	expression_list = |p, close, what| {
		var $q = p
		var $items = []
		while !Parser.is_punct($q, close) {
			if Parser.is_punct($q, "...") {
				return Err(Parser.fault_here($q, "unsupported: spread (`...`)"))
			}
			if Parser.is_punct($q, ",") {
				return Err(
					Parser.fault_here(
						$q,
						"unsupported: holes in an array (`,,`), or a missing ${what}",
					),
				)
			}
			e = Parser.assignment($q)?
			$items = $items.append(e.value)
			if Parser.is_punct(e.p, ",") {
				$q = Parser.advance(e.p)
			} else if Parser.is_punct(e.p, close) {
				$q = e.p
			} else {
				return Err(
					Parser.fault_here(
						e.p,
						"expected `,` or `${close}`, found ${Parser.shown(Parser.token(e.p).tok)}",
					),
				)
			}
		}
		Ok({ p: Parser.advance($q), value: $items })
	}

	primary : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	primary = |p| {
		Parser.refuse_unsupported_word(p)?
		t = Parser.token(p)
		w = Parser.where_of(t)
		after = Parser.advance(p)
		match t.tok {
			Number(n) => Ok({ p: after, value: Number(n) })
			Text(s) => Ok({ p: after, value: Text(s) })
			TemplateWhole(s) => Ok({ p: after, value: Template([s], []) })
			TemplateHead(s) => Parser.template_rest(after, s)
			Name("true") => Ok({ p: after, value: Boolean(True) })
			Name("false") => Ok({ p: after, value: Boolean(False) })
			Name("null") => Ok({ p: after, value: Null })
			Name("undefined") => Ok({ p: after, value: Undefined })
			Name("function") => {
				def = Parser.function_rest(after, w, Expressed)?
				Ok({ p: def.p, value: Function(def.value) })
			}
			Name(s) => {
				if Parser.is_reserved(s) {
					Err(Parser.fault_here(p, "`${s}` can't start an expression"))
				} else {
					Ok({ p: after, value: Name(s, w) })
				}
			}
			Punct("(") => {
				e = Parser.expression(after)?
				q = Parser.expect_punct(e.p, ")")?
				Ok({ p: q, value: e.value })
			}
			Punct("[") => {
				items = Parser.expression_list(after, "]", "item")?
				Ok({ p: items.p, value: ArrayLit(items.value) })
			}
			Punct("{") => Parser.object_rest(after)
			Punct("/") => Err(Parser.fault_here(p, "unsupported: regular expressions"))
			Punct("#") => Err(Parser.fault_here(p, "unsupported: private names"))
			Punct("@") => Err(Parser.fault_here(p, "unsupported: decorators"))
			other => Err(
				Parser.fault_here(
					p,
					"expected an expression, found ${Parser.shown(other)}",
				),
			)
		}
	}

	template_rest : Parser.State, Str -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	template_rest = |p, head| {
		var $q = p
		var $texts = [head]
		var $parts = []
		var $open = True
		while $open {
			e = Parser.expression($q)?
			$parts = $parts.append(e.value)
			match Parser.token(e.p).tok {
				TemplateMiddle(s) => {
					$texts = $texts.append(s)
					$q = Parser.advance(e.p)
				}
				TemplateTail(s) => {
					$texts = $texts.append(s)
					$q = Parser.advance(e.p)
					$open = False
				}
				other => return Err(
					Parser.fault_here(
						e.p,
						"expected `}` to close a template's `\${`, found ${Parser.shown(other)}",
					),
				)
			}
		}
		Ok({ p: $q, value: Template($texts, $parts) })
	}

	# An object literal after its `{`.
	object_rest : Parser.State -> Try(Parser.Parsed(Ast.Expr), Lexer.Fault)
	object_rest = |p| {
		var $q = p
		var $props = []
		while !Parser.is_punct($q, "}") {
			r = Parser.property($q)?
			$props = $props.append(r.value)
			if Parser.is_punct(r.p, ",") {
				$q = Parser.advance(r.p)
			} else if Parser.is_punct(r.p, "}") {
				$q = r.p
			} else {
				return Err(
					Parser.fault_here(
						r.p,
						"expected `,` or `}` in an object, found ${Parser.shown(Parser.token(r.p).tok)}",
					),
				)
			}
		}
		Ok({ p: Parser.advance($q), value: ObjectLit($props) })
	}

	property : Parser.State -> Try(Parser.Parsed(Ast.Prop), Lexer.Fault)
	property = |p| {
		t = Parser.token(p)
		w = Parser.where_of(t)
		key = match t.tok {
			Name(s) => {
				next = Parser.token_after(p).tok
				if (s == "get" or s == "set" or s == "async") and next != Punct(":") and next != Punct("(") and next != Punct(",") and next != Punct("}") {
					Err(Parser.fault_here(p, "unsupported: getters, setters and async methods"))
				} else {
					Ok(s)
				}
			}
			Text(s) => Ok(s)
			Number(n) => Ok(NumberText.of(n))
			Punct("[") => Err(Parser.fault_here(p, "unsupported: computed property names"))
			Punct("...") => Err(Parser.fault_here(p, "unsupported: spread (`...`)"))
			Punct("*") => Err(Parser.fault_here(p, "unsupported: generators"))
			other => Err(
				Parser.fault_here(
					p,
					"expected a property's name, found ${Parser.shown(other)}",
				),
			)
		}?
		after = Parser.advance(p)
		if Parser.is_punct(after, ":") {
			v = Parser.assignment(Parser.advance(after))?
			Ok({ p: v.p, value: { key: key, value: Parser.named(v.value, key) } })
		} else if Parser.is_punct(after, "(") {
			params = Parser.parameters(after)?
			def = Parser.function_body(params.p, key, params.value, w)?
			Ok({ p: def.p, value: { key: key, value: Function(def.value) } })
		} else {
			match t.tok {
				Name(s) => {
					if Parser.is_reserved(s) {
						Err(Parser.fault_here(p, "`${s}` is a reserved word, not a name"))
					} else {
						Ok({ p: after, value: { key: s, value: Name(s, w) } })
					}
				}
				_ => Err(Parser.fault_here(after, "expected `:` after a property's name"))
			}
		}
	}
}
