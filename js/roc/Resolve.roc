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
	# names it declares in its order. The first is the builtins'.
	Scopes : List(List(Str))

	program : Ast.Program, Ast.Library -> Ast.Program
	program = |tree, library| Resolve.block([Ast.global_names_of(library)], tree)

	slot : Resolve.Scopes, Str -> Ast.Slot
	slot = |scopes, name| {
		var $frame = scopes.len()
		var $hops = 0
		var $found = Undeclared
		while $frame > 1 {
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
			Undeclared => match Resolve.builtin_names(scopes).find_first_index(|number| number == name) {
				Ok(index) => Global(index)
				Err(NotFound) => Undeclared
			}
			placed => placed
		}
	}

	builtin_names : Resolve.Scopes -> List(Str)
	builtin_names = |scopes| scopes.first() ?? crash "Resolve.builtin_names: Resolve.program puts the builtins' names first"

	block : Resolve.Scopes, Ast.Block -> Ast.Block
	block = |scopes, tree_block| {
		inner = match tree_block.scoping {
			Scoped(names) => scopes.append(names)
			Unscoped => scopes
		}
		{
			..tree_block,
			statements: tree_block.statements.map(|source| Resolve.statement(inner, source)),
		}
	}

	fun : Resolve.Scopes, Ast.FunctionDefinition -> Ast.FunctionDefinition
	fun = |scopes, definition| {
		inner = scopes.append(definition.names)
		{
			..definition,
			binding: match definition.binding {
				Plain => Plain
				Patterned({ items, rest }) => Patterned({
					items: items.map(
						|given| {
							pattern: Resolve.pattern(inner, given.pattern),
							default: Resolve.pattern_default(inner, given.default),
						},
					),
					rest: Resolve.pattern_rest(inner, rest),
				})
			},
			statements: definition.statements.map(|source| Resolve.statement(inner, source)),
		}
	}

	pattern : Resolve.Scopes, Ast.Pattern -> Ast.Pattern
	pattern = |scopes, given|
		match given {
			Leaf(assigned) => Leaf(Resolve.target(scopes, assigned))
			ArrayPattern(items, rest) => ArrayPattern(
				items.map(
					|item| match item {
						Hole => Hole
						Item(inner, default) => Item(
							Resolve.pattern(scopes, inner),
							Resolve.pattern_default(scopes, default),
						)
					},
				),
				Resolve.pattern_rest(scopes, rest),
			)
			ObjectPattern(properties, rest) => ObjectPattern(
				properties.map(
					|property| {
						key: property.key,
						pattern: Resolve.pattern(scopes, property.pattern),
						default: Resolve.pattern_default(scopes, property.default),
					},
				),
				Resolve.pattern_rest(scopes, rest),
			)
		}

	pattern_default : Resolve.Scopes, Ast.Default -> Ast.Default
	pattern_default = |scopes, given|
		match given {
			Defaulted(tree) => Defaulted(Resolve.expression(scopes, tree))
			NoDefault => NoDefault
		}

	pattern_rest : Resolve.Scopes, Ast.Rest -> Ast.Rest
	pattern_rest = |scopes, given|
		match given {
			RestOf(inner) => RestOf(Resolve.pattern(scopes, inner))
			NoRest => NoRest
		}

	statement : Resolve.Scopes, Ast.Statement -> Ast.Statement
	statement = |scopes, source|
		match source {
			Expression(tree) => Expression(Resolve.expression(scopes, tree))
			Declare(binding, declarations) => Declare(
				binding,
				declarations.map(|given| Resolve.declarator(scopes, given)),
			)
			FunctionDeclaration(definition, _) => FunctionDeclaration(
				Box.box(Resolve.fun(scopes, definition.unbox())),
				Resolve.slot(scopes, definition.unbox().name),
			)
			If(test, yes, no) => If(
				Resolve.expression(scopes, test),
				Resolve.statement(scopes, yes),
				Resolve.statement(scopes, no),
			)
			While(loop) => While({
				..loop,
				test: Resolve.expression(scopes, loop.test),
				body: Resolve.statement(scopes, loop.body),
			})
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
			ForOf(loop) => {
				inner = scopes.append(loop.names)
				ForOf({
					..loop,
					pattern: Resolve.pattern(inner, loop.pattern),
					iterable: Resolve.expression(scopes, loop.iterable),
					body: Resolve.statement(inner, loop.body),
				})
			}
			BlockStatement(tree_block) => BlockStatement(Resolve.block(scopes, tree_block))
			Return(tree) => Return(Resolve.expression(scopes, tree))
			Throw(tree, site) => Throw(Resolve.expression(scopes, tree), site)
			Switch(switch) => {
				inner = match switch.scoping {
					Scoped(names) => scopes.append(names)
					Unscoped => scopes
				}
				Switch({
					..switch,
					discriminant: Resolve.expression(scopes, switch.discriminant),
					cases: switch.cases.map(
						|each| {
							test: match each.test {
								Matches(tree) => Matches(Resolve.expression(inner, tree))
								Otherwise => Otherwise
							},
							statements: each.statements.map(|listed| Resolve.statement(inner, listed)),
						},
					),
				})
			}
			Try({ block: tried, handler, finalizer }) => Try({
				block: Resolve.block(scopes, tried),
				handler: match handler {
					Caught(clause) => {
						inner = match clause.parameter {
							Bound(_) => scopes.append(clause.names)
							Unbound => scopes
						}
						Caught({
							..clause,
							parameter: match clause.parameter {
								Bound(bound) => Bound(Resolve.pattern(inner, bound))
								Unbound => Unbound
							},
							body: Resolve.block(inner, clause.body),
						})
					}
					Uncaught => Uncaught
				},
				finalizer: match finalizer {
					Finally(final_block) => Finally(Resolve.block(scopes, final_block))
					NoFinally => NoFinally
				},
			})
			Break(label) => Break(label)
			Continue(label) => Continue(label)
			Labelled(label, body) => Labelled(label, Resolve.statement(scopes, body))
			Empty => Empty
		}

	declarator : Resolve.Scopes, Ast.Declarator -> Ast.Declarator
	declarator = |scopes, given| {
		..given,
		init: match given.init {
			Initialized(tree) => Initialized(Resolve.expression(scopes, tree))
			Uninitialized => Uninitialized
		},
		pattern: Resolve.pattern(scopes, given.pattern),
	}

	element : Resolve.Scopes, Ast.Element -> Ast.Element
	element = |scopes, given|
		match given {
			Single(tree) => Single(Resolve.expression(scopes, tree))
			Spread(tree, site) => Spread(Resolve.expression(scopes, tree), site)
		}

	target : Resolve.Scopes, Ast.Target -> Ast.Target
	target = |scopes, assigned|
		match assigned {
			ToName(name, _, site) => ToName(name, Resolve.slot(scopes, name), site)
			ToMember(object, key) => ToMember(Resolve.expression(scopes, object), key)
			ToIndex(object, key) => ToIndex(
				Resolve.expression(scopes, object),
				Resolve.expression(scopes, key),
			)
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
			ArrayLit(items) => ArrayLit(items.map(|item| Resolve.element(scopes, item)))
			ObjectLit(parts) => ObjectLit(
				parts.map(
					|part| match part {
						Field(p) => Field({ ..p, value: Resolve.expression(scopes, p.value) })
						Spread(spread, site) => Spread(Resolve.expression(scopes, spread), site)
					},
				),
			)
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
				arguments.map(|argument| Resolve.element(scopes, argument)),
				site,
			)
			Function(definition) => Function(Box.box(Resolve.fun(scopes, definition.unbox())))
			OptionalMember(object, key, site) => OptionalMember(Resolve.expression(scopes, object), key, site)
			OptionalIndex(object, key, site) => OptionalIndex(
				Resolve.expression(scopes, object),
				Resolve.expression(scopes, key),
				site,
			)
			OptionalCall(callee, arguments, site) => OptionalCall(
				Resolve.expression(scopes, callee),
				arguments.map(|argument| Resolve.element(scopes, argument)),
				site,
			)
			Chain(chain) => Chain(Resolve.expression(scopes, chain))
			New(callee, arguments, site) => New(
				Resolve.expression(scopes, callee),
				arguments.map(|argument| Resolve.element(scopes, argument)),
				site,
			)
			Instance(classes) => Instance(classes)
			InstanceOf(value, class, name, site) => InstanceOf(
				Resolve.expression(scopes, value),
				Resolve.expression(scopes, class),
				name,
				site,
			)
			Destructure(assigned, value, site) => Destructure(
				Resolve.pattern(scopes, assigned),
				Resolve.expression(scopes, value),
				site,
			)
		}
	}
}
