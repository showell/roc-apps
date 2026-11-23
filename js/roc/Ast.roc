# This module holds the shape of a parsed JavaScript program: its
# expressions, its statements and its functions. The parser builds it once
# and nothing writes it after, so the interpreter's heap may hold a function's
# body without copying it.
#
# Each block and function says whether a function literal is written
# anywhere inside it (`Capture`). Where none is, nothing made while it runs
# can hold on to its scope, so the interpreter drops the scope when the block
# ends. Each block also says whether it declares anything (`Scoping`), and
# runs in the enclosing scope when it doesn't.
Ast :: [].{
	# Where a piece of the program starts, for the messages that point at it.
	Where : { line : U64, col : U64 }

	Expr := [
		Number(F64),
		Text(Str),
		# A template's text pieces, one more than its substitutions.
		Template(List(Str), List(Ast.Expr)),
		Boolean(Bool),
		Null,
		Undefined,
		Name(Str, Ast.Where),
		ArrayLit(List(Ast.Expr)),
		ObjectLit(List(Ast.Prop)),
		Unary(Ast.UnaryOp, Ast.Expr, Ast.Where),
		Binary(Ast.BinaryOp, Ast.Expr, Ast.Expr, Ast.Where),
		Logical(Ast.LogicalOp, Ast.Expr, Ast.Expr),
		Conditional(Ast.Expr, Ast.Expr, Ast.Expr),
		Assign(Ast.Target, Ast.AssignOp, Ast.Expr, Ast.Where),
		Update(Ast.Target, Ast.Step, Ast.Fixity, Ast.Where),
		Member(Ast.Expr, Str, Ast.Where),
		Index(Ast.Expr, Ast.Expr, Ast.Where),
		Call(Ast.Expr, List(Ast.Expr), Ast.Where),
		Function(Ast.FunDef),
	]

	# What an assignment or an update writes.
	Target := [
		ToName(Str, Ast.Where),
		ToMember(Ast.Expr, Str),
		ToIndex(Ast.Expr, Ast.Expr),
	]

	Prop : { key : Str, value : Ast.Expr }

	UnaryOp : [Not, Negate, Plus, TypeOf]

	BinaryOp : [
		Add,
		Subtract,
		Multiply,
		Divide,
		Remainder,
		Power,
		StrictEqual,
		StrictNotEqual,
		Less,
		LessOrEqual,
		Greater,
		GreaterOrEqual,
	]

	LogicalOp : [And, Or, Nullish]

	# `=` writes the value; the others combine it with what is there first.
	AssignOp : [Set, Combine(Ast.BinaryOp)]

	Step : [Increment, Decrement]

	# A prefix update answers the new value, a postfix one the old.
	Fixity : [Prefix, Postfix]

	Capture : [Captures, CapturesNothing]

	Scoping : [Scoped, Unscoped]

	FunDef : {
		name : Str,
		params : List(Str),
		body : List(Ast.Stmt),
		capture : Ast.Capture,
		at : Ast.Where,
	}

	Binding : [Let, Const]

	Declarator : { name : Str, init : Ast.Init, at : Ast.Where }

	Init : [Initialized(Ast.Expr), Uninitialized]

	Block : {
		stmts : List(Ast.Stmt),
		scoping : Ast.Scoping,
		capture : Ast.Capture,
	}

	# A C-form `for`. Its `init` is a declaration, an expression or empty,
	# and its own scope holds what the declaration declares.
	ForLoop : {
		init : Ast.Stmt,
		test : Ast.Test,
		update : Ast.Updater,
		body : Ast.Stmt,
		capture : Ast.Capture,
	}

	Test : [Tested(Ast.Expr), Always]

	Updater : [Updated(Ast.Expr), NoUpdate]

	ForOfLoop : {
		binding : Ast.Binding,
		name : Str,
		iterable : Ast.Expr,
		body : Ast.Stmt,
		capture : Ast.Capture,
		at : Ast.Where,
	}

	Stmt := [
		Expression(Ast.Expr),
		Declare(Ast.Binding, List(Ast.Declarator)),
		FunctionDecl(Ast.FunDef),
		If(Ast.Expr, Ast.Stmt, Ast.Stmt),
		While(Ast.Expr, Ast.Stmt),
		For(Ast.ForLoop),
		ForOf(Ast.ForOfLoop),
		BlockStmt(Ast.Block),
		Return(Ast.Expr),
		Break,
		Continue,
		Empty,
	]

	Program : Ast.Block
}
