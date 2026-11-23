## This module places every name of a parsed program before it runs: each
## read, write and declaration learns which scope its variable lives in,
## counted outward from the scope it is written in, and where in that
## scope's variables it sits (`Ast.Slot`). The interpreter then reads a
## variable by its place, never by comparing names.
##
## The scopes it counts are the ones the interpreter makes, one for one:
## the program's, a `Scoped` block's, a C-form `for`'s, a `for ... of`
## pass's and a call's, each laid out by the names the parser gave it. A
## name declared in none of them is a builtin (`Global`) or `Undeclared`,
## which is a ReferenceError only if the program reaches it.
import Ast

Resolve :: [].{
	# The scopes around the code being placed, the innermost last, each the
	# names it declares in its order.
	Scopes : List(List(Str))

	program : Ast.Program -> Ast.Program
	program = |tree| Resolve.block([], tree)

	slot : Resolve.Scopes, Str -> Ast.Slot
	slot = |scopes, name| {
		var $frame = scopes.len()
		var $hops = 0
		var $found = Undeclared
		while $frame > 0 {
			names = scopes.get($frame - 1) ?? crash "Resolve.slot: inside the scopes"
			match names.find_first_index(|n| n == name) {
				Ok(index) => {
					$found = Local({ hops: $hops, index: index })
					$frame = 0
				}
				Err(NotFound) => {
					$frame = $frame - 1
					$hops = $hops + 1
				}
			}
		}
		match $found {
			Undeclared => match Ast.global_names.find_first_index(|n| n == name) {
				Ok(index) => Global(index)
				Err(NotFound) => Undeclared
			}
			placed => placed
		}
	}

	block : Resolve.Scopes, Ast.Block -> Ast.Block
	block = |scopes, b| {
		inner = match b.scoping {
			Scoped(names) => scopes.append(names)
			Unscoped => scopes
		}
		{ ..b, statements: b.statements.map(|s| Resolve.statement(inner, s)) }
	}

	fun : Resolve.Scopes, Ast.FunctionDefinition -> Ast.FunctionDefinition
	fun = |scopes, definition| {
		inner = scopes.append(definition.names)
		{ ..definition, body: definition.body.map(|s| Resolve.statement(inner, s)) }
	}

	statement : Resolve.Scopes, Ast.Statement -> Ast.Statement
	statement = |scopes, s|
		match s {
			Expression(e) => Expression(Resolve.expression(scopes, e))
			Declare(binding, declarations) => Declare(binding, declarations.map(|d| Resolve.declarator(scopes, d)))
			FunctionDeclaration(definition, _) => FunctionDeclaration(
				Box.box(Resolve.fun(scopes, definition.unbox())),
				Resolve.slot(scopes, definition.unbox().name),
			)
			If(test, yes, no) => If(
				Resolve.expression(scopes, test),
				Resolve.statement(scopes, yes),
				Resolve.statement(scopes, no),
			)
			While(test, body) => While(Resolve.expression(scopes, test), Resolve.statement(scopes, body))
			For(loop) => {
				inner = scopes.append(loop.names)
				For({
					..loop,
					init: Resolve.statement(inner, loop.init),
					test: match loop.test {
						Tested(e) => Tested(Resolve.expression(inner, e))
						Always => Always
					},
					update: match loop.update {
						Updated(e) => Updated(Resolve.expression(inner, e))
						NoUpdate => NoUpdate
					},
					body: Resolve.statement(inner, loop.body),
				})
			}
			ForOf(loop) => ForOf({
				..loop,
				iterable: Resolve.expression(scopes, loop.iterable),
				body: Resolve.statement(scopes.append([loop.name]), loop.body),
			})
			BlockStatement(b) => BlockStatement(Resolve.block(scopes, b))
			Return(e) => Return(Resolve.expression(scopes, e))
			Break => Break
			Continue => Continue
			Empty => Empty
		}

	declarator : Resolve.Scopes, Ast.Declarator -> Ast.Declarator
	declarator = |scopes, d| {
		..d,
		init: match d.init {
			Initialized(e) => Initialized(Resolve.expression(scopes, e))
			Uninitialized => Uninitialized
		},
		slot: Resolve.slot(scopes, d.name),
	}

	target : Resolve.Scopes, Ast.Target -> Ast.Target
	target = |scopes, t|
		match t {
			ToName(name, _, w) => ToName(name, Resolve.slot(scopes, name), w)
			ToMember(object, key) => ToMember(Resolve.expression(scopes, object), key)
			ToIndex(object, key) => ToIndex(Resolve.expression(scopes, object), Resolve.expression(scopes, key))
		}

	expression : Resolve.Scopes, Ast.Expression -> Ast.Expression
	expression = |scopes, e| {
		each = |expressions| expressions.map(|x| Resolve.expression(scopes, x))
		match e {
			Number(n) => Number(n)
			Text(s) => Text(s)
			Template(texts, parts) => Template(texts, each(parts))
			Boolean(b) => Boolean(b)
			Null => Null
			Undefined => Undefined
			Name(name, _, w) => Name(name, Resolve.slot(scopes, name), w)
			ArrayLit(items) => ArrayLit(each(items))
			ObjectLit(properties) => ObjectLit(properties.map(|p| { ..p, value: Resolve.expression(scopes, p.value) }))
			Unary(operator, a, w) => Unary(operator, Resolve.expression(scopes, a), w)
			Binary(operator, a, b, w) => Binary(
				operator,
				Resolve.expression(scopes, a),
				Resolve.expression(scopes, b),
				w,
			)
			Logical(operator, a, b) => Logical(
				operator,
				Resolve.expression(scopes, a),
				Resolve.expression(scopes, b),
			)
			Conditional(a, b, c) => Conditional(
				Resolve.expression(scopes, a),
				Resolve.expression(scopes, b),
				Resolve.expression(scopes, c),
			)
			Assign(t, operator, value, w) => Assign(
				Resolve.target(scopes, t),
				operator,
				Resolve.expression(scopes, value),
				w,
			)
			Update(t, step, fixity, w) => Update(
				Resolve.target(scopes, t),
				step,
				fixity,
				w,
			)
			Member(object, key, w) => Member(Resolve.expression(scopes, object), key, w)
			Index(object, key, w) => Index(
				Resolve.expression(scopes, object),
				Resolve.expression(scopes, key),
				w,
			)
			Call(callee, arguments, w) => Call(
				Resolve.expression(scopes, callee),
				each(arguments),
				w,
			)
			Function(definition) => Function(Box.box(Resolve.fun(scopes, definition.unbox())))
		}
	}
}
