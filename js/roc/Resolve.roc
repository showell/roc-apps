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
			match names.find_first_index(|number| number == name) {
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
			Undeclared => match Ast.global_names.find_first_index(|number| number == name) {
				Ok(index) => Global(index)
				Err(NotFound) => Undeclared
			}
			placed => placed
		}
	}

	block : Resolve.Scopes, Ast.Block -> Ast.Block
	block = |scopes, tree_block| {
		inner = match tree_block.scoping {
			Scoped(names) => scopes.append(names)
			Unscoped => scopes
		}
		{ ..tree_block, statements: tree_block.statements.map(|source| Resolve.statement(inner, source)) }
	}

	fun : Resolve.Scopes, Ast.FunctionDefinition -> Ast.FunctionDefinition
	fun = |scopes, definition| {
		inner = scopes.append(definition.names)
		{ ..definition, body: definition.body.map(|source| Resolve.statement(inner, source)) }
	}

	statement : Resolve.Scopes, Ast.Statement -> Ast.Statement
	statement = |scopes, source|
		match source {
			Expression(tree) => Expression(Resolve.expression(scopes, tree))
			Declare(binding, declarations) => Declare(binding, declarations.map(|given| Resolve.declarator(scopes, given)))
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
						Tested(tree) => Tested(Resolve.expression(inner, tree))
						Always => Always
					},
					update: match loop.update {
						Updated(tree) => Updated(Resolve.expression(inner, tree))
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
			BlockStatement(tree_block) => BlockStatement(Resolve.block(scopes, tree_block))
			Return(tree) => Return(Resolve.expression(scopes, tree))
			Break => Break
			Continue => Continue
			Empty => Empty
		}

	declarator : Resolve.Scopes, Ast.Declarator -> Ast.Declarator
	declarator = |scopes, given| {
		..given,
		init: match given.init {
			Initialized(tree) => Initialized(Resolve.expression(scopes, tree))
			Uninitialized => Uninitialized
		},
		slot: Resolve.slot(scopes, given.name),
	}

	target : Resolve.Scopes, Ast.Target -> Ast.Target
	target = |scopes, assigned|
		match assigned {
			ToName(name, _, site) => ToName(name, Resolve.slot(scopes, name), site)
			ToMember(object, key) => ToMember(Resolve.expression(scopes, object), key)
			ToIndex(object, key) => ToIndex(Resolve.expression(scopes, object), Resolve.expression(scopes, key))
		}

	expression : Resolve.Scopes, Ast.Expression -> Ast.Expression
	expression = |scopes, tree| {
		each = |expressions| expressions.map(|x| Resolve.expression(scopes, x))
		match tree {
			Number(number) => Number(number)
			Text(text) => Text(text)
			Template(texts, parts) => Template(texts, each(parts))
			Boolean(truth) => Boolean(truth)
			Null => Null
			Undefined => Undefined
			Name(name, _, site) => Name(name, Resolve.slot(scopes, name), site)
			ArrayLit(items) => ArrayLit(each(items))
			ObjectLit(properties) => ObjectLit(properties.map(|p| { ..p, value: Resolve.expression(scopes, p.value) }))
			Unary(operator, left, site) => Unary(operator, Resolve.expression(scopes, left), site)
			Binary(operator, left, right, site) => Binary(
				operator,
				Resolve.expression(scopes, left),
				Resolve.expression(scopes, right),
				site,
			)
			Logical(operator, left, right) => Logical(
				operator,
				Resolve.expression(scopes, left),
				Resolve.expression(scopes, right),
			)
			Conditional(test, yes, no) => Conditional(
				Resolve.expression(scopes, test),
				Resolve.expression(scopes, yes),
				Resolve.expression(scopes, no),
			)
			Assign(assigned, operator, value, site) => Assign(
				Resolve.target(scopes, assigned),
				operator,
				Resolve.expression(scopes, value),
				site,
			)
			Update(assigned, step, fixity, site) => Update(
				Resolve.target(scopes, assigned),
				step,
				fixity,
				site,
			)
			Member(object, key, site) => Member(Resolve.expression(scopes, object), key, site)
			Index(object, key, site) => Index(
				Resolve.expression(scopes, object),
				Resolve.expression(scopes, key),
				site,
			)
			Call(callee, arguments, site) => Call(
				Resolve.expression(scopes, callee),
				each(arguments),
				site,
			)
			Function(definition) => Function(Box.box(Resolve.fun(scopes, definition.unbox())))
		}
	}
}
