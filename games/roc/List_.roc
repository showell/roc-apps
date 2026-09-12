# List_ -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

List_ :: [].{
	ConsList(a) := [Cons(a, List_.ConsList(a)), Nil].{
		is_eq : List_.ConsList(a), List_.ConsList(a) -> Bool where [a.is_eq : a, a -> Bool]
		is_eq = |a, b| eq_ConsList(a, b)
	}

	cl_nil : List_.ConsList(a)
	cl_nil = Nil

	cl_cons : a, List_.ConsList(a) -> List_.ConsList(a)
	cl_cons = |x, xs| Cons(x, xs)

	cl_is_empty : List_.ConsList(a) -> Bool
	cl_is_empty = |xs| (match xs {
		Cons(_h, _t) => False
		Nil => True
	})

	cl_head : List_.ConsList(a) -> a
	cl_head = |xs| (match xs {
		Cons(h, _t) => h
		Nil => cl_head(xs)
	})

	cl_tail : List_.ConsList(a) -> List_.ConsList(a)
	cl_tail = |xs| (match xs {
		Cons(_h, t) => t
		Nil => Nil
	})

	cl_length : List_.ConsList(a) -> I64
	cl_length = |xs| cl_length_acc(xs, 0)

	cl_length_acc : List_.ConsList(a), I64 -> I64
	cl_length_acc = |xs, acc| (match xs {
		Cons(_h, t) => cl_length_acc(t, (acc + 1))
		Nil => acc
	})

	cl_map : (a -> b), List_.ConsList(a) -> List_.ConsList(b)
	cl_map = |f, xs| (match xs {
		Cons(h, t) => Cons(f(h), cl_map(f, t))
		Nil => Nil
	})

	cl_filter : (a -> Bool), List_.ConsList(a) -> List_.ConsList(a)
	cl_filter = |pred, xs| (match xs {
		Cons(h, t) => (if pred(h) { Cons(h, cl_filter(pred, t)) } else { cl_filter(pred, t) })
		Nil => Nil
	})

	cl_foldl : (a, b -> a), a, List_.ConsList(b) -> a
	cl_foldl = |f, acc, xs| (match xs {
		Cons(h, t) => cl_foldl(f, f(acc, h), t)
		Nil => acc
	})

	cl_foldr : (a, b -> b), b, List_.ConsList(a) -> b
	cl_foldr = |f, acc, xs| (match xs {
		Cons(h, t) => f(h, cl_foldr(f, acc, t))
		Nil => acc
	})

	cl_reverse : List_.ConsList(a) -> List_.ConsList(a)
	cl_reverse = |xs| cl_foldl(cl_flip_cons, Nil, xs)

	cl_flip_cons : List_.ConsList(a), a -> List_.ConsList(a)
	cl_flip_cons = |acc, x| Cons(x, acc)

	cl_append : List_.ConsList(a), List_.ConsList(a) -> List_.ConsList(a)
	cl_append = |xs, ys| (match xs {
		Cons(h, t) => Cons(h, cl_append(t, ys))
		Nil => ys
	})

	cl_any : (a -> Bool), List_.ConsList(a) -> Bool
	cl_any = |pred, xs| (match xs {
		Cons(h, t) => (if pred(h) { True } else { cl_any(pred, t) })
		Nil => False
	})

	cl_all : (a -> Bool), List_.ConsList(a) -> Bool
	cl_all = |pred, xs| (match xs {
		Cons(h, t) => (if pred(h) { cl_all(pred, t) } else { False })
		Nil => True
	})

	cl_take : I64, List_.ConsList(a) -> List_.ConsList(a)
	cl_take = |n, xs| (if (n <= 0) { Nil } else { (match xs {
		Cons(h, t) => Cons(h, cl_take((n - 1), t))
		Nil => Nil
	}) })

	cl_drop : I64, List_.ConsList(a) -> List_.ConsList(a)
	cl_drop = |n, xs| (if (n <= 0) { xs } else { (match xs {
		Cons(_h, t) => cl_drop((n - 1), t)
		Nil => Nil
	}) })

	cl_zip_with : (a, b -> c), List_.ConsList(a), List_.ConsList(b) -> List_.ConsList(c)
	cl_zip_with = |f, xs, ys| (match xs {
		Cons(hx, tx) => (match ys {
			Cons(hy, ty) => Cons(f(hx, hy), cl_zip_with(f, tx, ty))
			Nil => Nil
		})
		Nil => Nil
	})

	cl_sum : List_.ConsList(I64) -> I64
	cl_sum = |xs| cl_foldl(cl_add_int, 0, xs)

	cl_add_int : I64, I64 -> I64
	cl_add_int = |a, b| (a + b)

	eq_ConsList : List_.ConsList(a), List_.ConsList(a) -> Bool where [a.is_eq : a, a -> Bool]
	eq_ConsList = |ex, ey| (match ex {
		Cons(exf0, exf1) => (match ey {
			Cons(eyf0, eyf1) => ((exf0 == eyf0) and eq_ConsList(exf1, eyf1))
			_ => False
		})
		Nil => (match ey {
			Nil => True
			_ => False
		})
	})
}
