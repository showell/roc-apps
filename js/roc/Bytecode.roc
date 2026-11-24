## This module holds the shape of a compiled JavaScript program, the bytecode
## VM's input: each function as a flat list of instructions (`Op`) for a
## stack machine, and what a call does before the first of them runs
## (`Entry`). `Compile` makes it from a resolved `Ast` and nothing writes it
## after; `Vm` runs it.
##
## **A FRAME IS A RUN OF SLOTS ON THE OPERAND STACK.** A call's slots start
## at its base: its parameters, then every variable its blocks and loops
## declare, then the hidden slots its `for ... of` loops keep their place
## in, then the boxes of the variables it captures. An instruction names a
## slot by its place from the base. Values the function is working on sit
## above its slots.
##
## **A VARIABLE A CLOSURE MAY CAPTURE LIVES IN A BOX.** Its slot holds a
## reference to a heap cell (`Heap.Cell`'s `Variable`) that the closures
## made over it share, and the `*Boxed` instructions read and write through
## it. Whether a scope's variables are boxed is the parser's `Ast.Capture`:
## a scope with no function literal inside keeps its variables in plain
## slots.
##
## Every jump is relative to the instruction after it: `Jump(n)` and the
## other forward jumps skip `n` instructions, and `Loop(n)` goes back `n`,
## so a compiled piece of code means the same wherever it is placed.
import Ast
import ValueRules

Bytecode :: [].{
	Op := [
		PushNumber(F64),
		PushText(Str),
		PushBoolean(Bool),
		PushNull,
		PushUndefined,
		Pop,
		# a -> a a
		Duplicate,
		# a b -> a b a b
		DuplicatePair,
		# a b -> b
		Nip,
		# a b -> b a
		Swap,
		# a b c -> b c a
		Rotate,
		LoadLocal(U64),
		# A store keeps its value on the stack, an assignment's value; a set
		# takes it, a declaration's.
		StoreLocal(U64),
		SetLocal(U64),
		LoadBoxed(Bytecode.Named),
		# A box's value, or undefined while it is unready, as a compound
		# assignment reads its old value before it checks the variable.
		PeekBoxed(U64),
		StoreBoxed(Bytecode.Assigned),
		# A declaration's value set in its box, which is ready after.
		SetBoxed(U64),
		# A fresh unready box in the slot: a block's or a pass's own variable.
		NewBox(U64),
		# A fresh box holding what the slot's box holds: a C-form `for`'s next
		# pass, whose closures see a variable of their own.
		CopyBox(U64),
		LoadBuiltin(U64),
		# A name declared nowhere, read: refused, or a ReferenceError.
		MissingName({ name : Str, at : Ast.Where }),
		# A variable read or written before its declaration has run.
		ThrowUnready({ name : Str, at : Ast.Where }),
		# A `const` or a builtin assigned.
		ThrowConstant(Ast.Where),
		Refuse(Str),
		# `s += e`, `e` pure: its text appended where the slot holds the string.
		AppendLocal({ slot : U64, at : Ast.Where }),
		UpdateLocal({ slot : U64, step : Bytecode.Update }),
		UpdateBoxed({ slot : U64, name : Str, kind : Bytecode.Kind, step : Bytecode.Update }),
		# `++` or `--` on a `const` or a builtin, its value on the stack.
		UpdateFixed(Ast.Where),
		UpdateProperty({ key : Str, step : Bytecode.Update }),
		UpdateIndex(Bytecode.Update),
		Unary(Ast.UnaryOperator, Ast.Where),
		Binary(Ast.BinaryOperator, Ast.Where),
		# A template's substitution, on the stack above the text so far, made
		# text and joined to it and to the template's next piece.
		TemplatePart(Str),
		Jump(U64),
		Loop(U64),
		JumpIfFalse(U64),
		# The logical operators' jumps: when the value on the stack settles
		# the operator it is kept and the jump taken; otherwise it is dropped.
		SkipIfFalsy(U64),
		SkipIfTruthy(U64),
		SkipIfDefined(U64),
		# A default's jump: a value that isn't `undefined` is kept and the jump
		# taken; `undefined` stays for the default's code to drop.
		SkipIfNotUndefined(U64),
		# A `switch`'s case: the two values on top compared by `===`, both
		# dropped, and the jump taken when they are the same.
		JumpIfSame(U64),
		# An optional link: `null` or `undefined` on top ends its chain, which
		# answers `undefined`, by a jump to the chain's end.
		ShortIfNullish(U64),
		MakeArray(U64),
		# An array literal with a spread in it, built an element at a time.
		NewArray,
		AppendItem,
		AppendSpread({ source : Ast.Expression, at : Ast.Where }),
		NewObject,
		SetField(Str),
		SpreadFields(Ast.Where),
		GetProperty(Str, Ast.Where),
		GetIndex(Ast.Where),
		SetProperty(Str, Ast.Where),
		SetIndex(Ast.Where),
		MakeClosure(
			{
				code : U64,
				# The slots, in the frame making the closure, of the boxes it
				# captures, in the order its code reads them.
				captures : List(U64),
				definition : Box(Ast.FunctionDefinition),
			},
		),
		# A call: the function, then its arguments, on the stack.
		Call(Bytecode.CallSite),
		# A call whose arguments are one array, built with their spreads.
		CallSpread({ written : Str, at : Ast.Where }),
		# What a method call calls, read before its arguments are made: the
		# function a property holds, or, for an array, a string, a Map or a
		# Set, whose methods are called by name, the receiver itself again.
		MethodLookup(Str, Ast.Where),
		# A method call: the receiver, what `MethodLookup` found, then the
		# arguments, on the stack.
		CallMethod({ name : Str, site : Bytecode.CallSite }),
		CallMethodSpread({ name : Str, written : Str, at : Ast.Where }),
		Construct({ count : U64, callee : Ast.Expression, at : Ast.Where }),
		# A `for ... of`'s iterable made the array it walks: an array as it is,
		# a string as its characters.
		IterStart({ source : Ast.Expression, at : Ast.Where }),
		# The next item of the array in `slot`, its place in the slot after;
		# past the end, a jump of `exit` instructions.
		IterNext({ slot : U64, exit : U64 }),
		# An array pattern's value made an array to read its items from: an
		# array as it is, anything else iterable as its values.
		DestructureItems({ origin : ValueRules.Origin, at : Ast.Where }),
		# The item at a place of the array on top, in its place; `undefined`
		# past the end.
		ItemOf(U64),
		# The items of the array on top from a place on, a new array in its place.
		ItemsFrom(U64),
		# An object pattern's value checked: `null` and `undefined` throw.
		CheckDestructurable({ properties : List(Ast.PropertyPattern), origin : ValueRules.Origin, at : Ast.Where }),
		# The own properties of the value on top but `keys`, a new object in
		# its place: an object pattern's rest.
		PropertiesLeft({ keys : List(Str), at : Ast.Where }),
		# A `try`'s handler pushed: a throw before its `LeaveTry` lands `handler`
		# instructions on, the stack as it was here, with the value thrown on
		# top, and for a `finally`'s handler the throw's line and column under it.
		EnterTry({ handler : U64, kind : Bytecode.Handling }),
		LeaveTry,
		# A throw a `finally` held, thrown again: its line, its column and the
		# value, on the stack.
		Rethrow,
		Return,
		Throw(Ast.Where),
		Finish,
	]

	## A box's slot, and its variable's name and the read's place, for the
	## error a read before the declaration throws.
	Named : { slot : U64, name : Str, at : Ast.Where }

	Assigned : { slot : U64, name : Str, kind : Bytecode.Kind, at : Ast.Where }

	## Whether a variable may be assigned: a `const`'s may not.
	Kind : [Mutable, Fixed]

	## How `++` or `--` steps a variable or a property, and which value it answers.
	Update : { delta : F64, fixity : Ast.Fixity, at : Ast.Where }

	## How many arguments a call has, the callee as the program wrote it (for
	## node's `o.f is not a function`), and where.
	CallSite : { count : U64, written : Str, at : Ast.Where }

	## What a call does to a slot before the code runs: a fresh unready box
	## for a boxed variable, a box holding the argument for a boxed
	## parameter, and the box of a captured variable from the closure's
	## environment, by its place there.
	Entry : [FreshBox(U64), FilledBox(U64), CapturedBox({ slot : U64, capture : U64 })]

	## What a `try`'s handler is for: a `catch`, given the value thrown, or a
	## `finally`, given the throw to finish once it has run.
	Handling : [Catching, Finishing]

	## How a call's arguments reach its frame: each to its parameter's slot,
	## as many as the code has parameters, or all of them in an array in one
	## slot, which a function with patterned, defaulted or rest parameters
	## takes apart in its own code.
	Arguments : [Each(U64), Packed(U64)]

	Code : {
		ops : List(Bytecode.Op),
		frame_size : U64,
		arguments : Bytecode.Arguments,
		entry : List(Bytecode.Entry),
	}

	## Every function's code, which of them is the program's own, and where
	## the program's own frame keeps a variable named `frame`, if it declares
	## one: on the canvas library, the function the page calls each frame,
	## read once the program has run.
	Program : { codes : List(Bytecode.Code), main : U64, frame : [Declared([Slot(U64), Boxed(U64)]), Undeclared] }
}
