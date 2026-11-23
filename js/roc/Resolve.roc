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
	Env : List(List(Str))

	program : Ast.Program -> Ast.Program
	program = |tree| Resolve.block([], tree)

	slot : Resolve.Env, Str -> Ast.Slot
	slot = |env, name| {
		var $frame = env.len()
		var $hops = 0
		var $found = Undeclared
		while $frame > 0 {
			names = env.get($frame - 1) ?? crash "Resolve.slot: inside the scopes"
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

	block : Resolve.Env, Ast.Block -> Ast.Block
	block = |env, b| {
		inner = match b.scoping {
			Scoped(names) => env.append(names)
			Unscoped => env
		}
		{ ..b, stmts: b.stmts.map(|s| Resolve.stmt(inner, s)) }
	}

	fun : Resolve.Env, Ast.FunDef -> Ast.FunDef
	fun = |env, def| {
		inner = env.append(def.names)
		{ ..def, body: def.body.map(|s| Resolve.stmt(inner, s)) }
	}

	stmt : Resolve.Env, Ast.Stmt -> Ast.Stmt
	stmt = |env, s|
		match s {
			Expression(e) => Expression(Resolve.expr(env, e))
			Declare(binding, decls) => Declare(binding, decls.map(|d| Resolve.declarator(env, d)))
			FunctionDecl(def, _) => FunctionDecl(
				Box.box(Resolve.fun(env, def.unbox())),
				Resolve.slot(env, def.unbox().name),
			)
			If(test, yes, no) => If(
				Resolve.expr(env, test),
				Resolve.stmt(env, yes),
				Resolve.stmt(env, no),
			)
			While(test, body) => While(Resolve.expr(env, test), Resolve.stmt(env, body))
			For(loop) => {
				inner = env.append(loop.names)
				For({
					..loop,
					init: Resolve.stmt(inner, loop.init),
					test: match loop.test {
						Tested(e) => Tested(Resolve.expr(inner, e))
						Always => Always
					},
					update: match loop.update {
						Updated(e) => Updated(Resolve.expr(inner, e))
						NoUpdate => NoUpdate
					},
					body: Resolve.stmt(inner, loop.body),
				})
			}
			ForOf(loop) => ForOf({
				..loop,
				iterable: Resolve.expr(env, loop.iterable),
				body: Resolve.stmt(env.append([loop.name]), loop.body),
			})
			BlockStmt(b) => BlockStmt(Resolve.block(env, b))
			Return(e) => Return(Resolve.expr(env, e))
			Break => Break
			Continue => Continue
			Empty => Empty
		}

	declarator : Resolve.Env, Ast.Declarator -> Ast.Declarator
	declarator = |env, d| {
		..d,
		init: match d.init {
			Initialized(e) => Initialized(Resolve.expr(env, e))
			Uninitialized => Uninitialized
		},
		slot: Resolve.slot(env, d.name),
	}

	target : Resolve.Env, Ast.Target -> Ast.Target
	target = |env, t|
		match t {
			ToName(name, _, w) => ToName(name, Resolve.slot(env, name), w)
			ToMember(obj, key) => ToMember(Resolve.expr(env, obj), key)
			ToIndex(obj, key) => ToIndex(Resolve.expr(env, obj), Resolve.expr(env, key))
		}

	expr : Resolve.Env, Ast.Expr -> Ast.Expr
	expr = |env, e| {
		each = |es| es.map(|x| Resolve.expr(env, x))
		match e {
			Number(n) => Number(n)
			Text(s) => Text(s)
			Template(texts, parts) => Template(texts, each(parts))
			Boolean(b) => Boolean(b)
			Null => Null
			Undefined => Undefined
			Name(name, _, w) => Name(name, Resolve.slot(env, name), w)
			ArrayLit(items) => ArrayLit(each(items))
			ObjectLit(props) => ObjectLit(props.map(|p| { ..p, value: Resolve.expr(env, p.value) }))
			Unary(op, a, w) => Unary(op, Resolve.expr(env, a), w)
			Binary(op, a, b, w) => Binary(
				op,
				Resolve.expr(env, a),
				Resolve.expr(env, b),
				w,
			)
			Logical(op, a, b) => Logical(
				op,
				Resolve.expr(env, a),
				Resolve.expr(env, b),
			)
			Conditional(a, b, c) => Conditional(
				Resolve.expr(env, a),
				Resolve.expr(env, b),
				Resolve.expr(env, c),
			)
			Assign(t, op, value, w) => Assign(
				Resolve.target(env, t),
				op,
				Resolve.expr(env, value),
				w,
			)
			Update(t, step, fixity, w) => Update(
				Resolve.target(env, t),
				step,
				fixity,
				w,
			)
			Member(obj, key, w) => Member(Resolve.expr(env, obj), key, w)
			Index(obj, key, w) => Index(
				Resolve.expr(env, obj),
				Resolve.expr(env, key),
				w,
			)
			Call(callee, args, w) => Call(
				Resolve.expr(env, callee),
				each(args),
				w,
			)
			Function(def) => Function(Box.box(Resolve.fun(env, def.unbox())))
		}
	}
}
