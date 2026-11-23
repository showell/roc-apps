## This module holds the shape of a parsed JavaScript program: its
## expressions, its statements and its functions. The parser builds it once
## and nothing writes it after, so the interpreter's heap may hold a function's
## body without copying it.
##
## Each block and function says whether a function literal is written
## anywhere inside it (`Capture`). Where none is, nothing made while it runs
## can hold on to its scope, so the interpreter drops the scope when the block
## ends. Each block also says whether it declares anything (`Scoping`), and
## runs in the enclosing scope when it doesn't.
##
## **EVERY SCOPE IS LAID OUT BEFORE THE PROGRAM RUNS.** A block that declares
## (`Scoped`), a function, and a C-form `for` each carry the names their
## scope holds, in order, and every name read, written or declared carries
## its `Slot`, where its variable sits. The parser lays the scopes out and
## leaves each slot `Unresolved`; `Parser.program_of` answers the tree only
## after `Resolve.program` has placed them all.
Ast :: [].{
	# Where a piece of the program starts, for the messages that point at it.
	Where : { line : U64, column : U64 }

	Expression := [
		Number(F64),
		Text(Str),
		# A template's text pieces, one more than its substitutions.
		Template(List(Str), List(Ast.Expression)),
		Boolean(Bool),
		Null,
		Undefined,
		Name(Str, Ast.Slot, Ast.Where),
		ArrayLit(List(Ast.Element)),
		ObjectLit(List(Ast.Property)),
		Unary(Ast.UnaryOperator, Ast.Expression, Ast.Where),
		Binary(Ast.BinaryOperator, Ast.Expression, Ast.Expression, Ast.Where),
		Logical(Ast.LogicalOperator, Ast.Expression, Ast.Expression),
		Conditional(Ast.Expression, Ast.Expression, Ast.Expression),
		Assign(Ast.Target, Ast.AssignmentOperator, Ast.Expression, Ast.Where),
		Update(Ast.Target, Ast.Step, Ast.Fixity, Ast.Where),
		Member(Ast.Expression, Str, Ast.Where),
		Index(Ast.Expression, Ast.Expression, Ast.Where),
		Call(Ast.Expression, List(Ast.Element), Ast.Where),
		# Boxed, so a heap cell holding a closure is no bigger than one holding
		# an object.
		Function(Box(Ast.FunctionDefinition)),
	]

	## An array literal's element or a call's: one value, or each item of an
	## iterable spread in its place (`...items`).
	Element : [Single(Ast.Expression), Spread(Ast.Expression, Ast.Where)]

	# What an assignment or an update writes.
	Target := [
		ToName(Str, Ast.Slot, Ast.Where),
		ToMember(Ast.Expression, Str),
		ToIndex(Ast.Expression, Ast.Expression),
	]

	## An object literal's property: the property's key, and the expression of
	## the property's value.
	Property : { key : Str, value : Ast.Expression }

	UnaryOperator : [Not, Negate, Plus, TypeOf]

	BinaryOperator : [
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

	LogicalOperator : [And, Or, Nullish]

	# `=` writes the value; the others combine it with what is there first.
	AssignmentOperator : [Set, Combine(Ast.BinaryOperator)]

	Step : [Increment, Decrement]

	# A prefix update answers the new value, a postfix one the old.
	Fixity : [Prefix, Postfix]

	Capture : [Captures, CapturesNothing]

	# A scope's names, in the order its variables sit.
	Scoping : [Scoped(List(Str)), Unscoped]

	# Where a name's variable sits.
	Slot : [
		# Not yet placed: the parser's, which `Resolve` replaces before a run.
		Unresolved,
		# In the scope `hops` scopes out from the one the name is written in.
		Local({ hops : U64, index : U64 }),
		# A builtin, at its place in `global_names`.
		Global(U64),
		# Declared nowhere: a ReferenceError if the program reaches it.
		Undeclared,
	]

	# The builtins the outermost scope holds, in their order.
	global_names : List(Str)
	global_names = ["console", "Math", "Object", "String", "Array", "Number", "NaN", "Infinity"]

	FunctionDefinition : {
		name : Str,
		parameters : List(Str),
		# The call's scope: the parameters, then what the body declares.
		names : List(Str),
		statements : List(Ast.Statement),
		capture : Ast.Capture,
		at : Ast.Where,
	}

	Binding : [Let, Const]

	Declarator : {
		name : Str,
		slot : Ast.Slot,
		init : Ast.Init,
		at : Ast.Where,
	}

	Init : [Initialized(Ast.Expression), Uninitialized]

	Block : {
		statements : List(Ast.Statement),
		scoping : Ast.Scoping,
		capture : Ast.Capture,
	}

	# A C-form `for`. Its `init` is a declaration, an expression or empty,
	# and its own scope holds what the declaration declares.
	ForLoop : {
		# What `init` declares, the loop's scope.
		names : List(Str),
		init : Ast.Statement,
		test : Ast.Test,
		update : Ast.Updater,
		body : Ast.Statement,
		capture : Ast.Capture,
	}

	Test : [Tested(Ast.Expression), Always]

	Updater : [Updated(Ast.Expression), NoUpdate]

	ForOfLoop : {
		binding : Ast.Binding,
		name : Str,
		iterable : Ast.Expression,
		body : Ast.Statement,
		capture : Ast.Capture,
		at : Ast.Where,
	}

	Statement := [
		Expression(Ast.Expression),
		Declare(Ast.Binding, List(Ast.Declarator)),
		FunctionDeclaration(Box(Ast.FunctionDefinition), Ast.Slot),
		If(Ast.Expression, Ast.Statement, Ast.Statement),
		While(Ast.Expression, Ast.Statement),
		For(Ast.ForLoop),
		ForOf(Ast.ForOfLoop),
		BlockStatement(Ast.Block),
		Return(Ast.Expression),
		Break,
		Continue,
		Empty,
	]

	Program : Ast.Block
}
