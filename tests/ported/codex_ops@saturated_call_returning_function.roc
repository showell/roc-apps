# ops@saturated-call-returning-function
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@saturated-call-returning-function.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     one-at-a-time: 47
#     rest-at-once: 47
#     flat: 47
#     other-branch: 48
#     arity-two: 45
#     arity-two-b: 51
#     still-partial: 47
#     self-recursive: 47
#     mutual: 47
#     closure-over-one: 48
#     closure-over-two: 48
#     closure-arity-one-over-two: 45
#     bare-name-over-one: 48

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# SaturatedCallReturningFunction -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

add3 : I64, I64, I64 -> I64
add3 = |a, b, c| ((a + b) + c)

mk : I64 -> (I64, I64 -> I64)
mk = |n| (if (n == 0) { ({
	dev__1 = 6
	|dev__2, dev__3| add3(dev__1, dev__2, dev__3)
}) } else { ({
	dev__4 = 5
	|dev__5, dev__6| add3(dev__4, dev__5, dev__6)
}) })

mk2 : I64, I64 -> (I64, I64 -> I64)
mk2 = |x, y| (if (x == 0) { ({
	dev__1 = ((x + y) + 1)
	|dev__2, dev__3| add3(dev__1, dev__2, dev__3)
}) } else { ({
	dev__4 = (x + y)
	|dev__5, dev__6| add3(dev__4, dev__5, dev__6)
}) })

mk3 : I64, I64, I64 -> (I64, I64 -> I64)
mk3 = |x, y, z| ({
	dev__1 = ((x + y) + z)
	|dev__2, dev__3| add3(dev__1, dev__2, dev__3)
})

rec_fn : I64 -> (I64, I64 -> I64)
rec_fn = |n| (if (n == 0) { ({
	dev__1 = 5
	|dev__2, dev__3| add3(dev__1, dev__2, dev__3)
}) } else { rec_fn((n - 1)) })

odd_fn : I64 -> (I64, I64 -> I64)
odd_fn = |n| even_fn(n)

even_fn : I64 -> (I64, I64 -> I64)
even_fn = |n| (if (n == 0) { ({
	dev__1 = 5
	|dev__2, dev__3| add3(dev__1, dev__2, dev__3)
}) } else { odd_fn((n - 1)) })

# --- Entry ---

main! = |_args| {
	({
		a = mk(4)
		a2 = ({
			dev__1 = 20
			|dev__2| a(dev__1, dev__2)
		})
		({
			line!(CceText.printed(CceText.concat("one-at-a-time: ", CceText.show_int(a2(22)))))
			({
				e = mk(4)
				({
					line!(CceText.printed(CceText.concat("rest-at-once: ", CceText.show_int(e(20, 22)))))
					line!(CceText.printed(CceText.concat("flat: ", CceText.show_int(mk(4)(20, 22)))))
					({
						z = mk(0)
						z2 = ({
							dev__3 = 20
							|dev__4| z(dev__3, dev__4)
						})
						({
							line!(CceText.printed(CceText.concat("other-branch: ", CceText.show_int(z2(22)))))
							({
								m = mk2(1, 2)
								m2 = ({
									dev__5 = 20
									|dev__6| m(dev__5, dev__6)
								})
								({
									line!(CceText.printed(CceText.concat("arity-two: ", CceText.show_int(m2(22)))))
									({
										q = mk2(4, 5)
										q2 = ({
											dev__7 = 20
											|dev__8| q(dev__7, dev__8)
										})
										({
											line!(CceText.printed(CceText.concat("arity-two-b: ", CceText.show_int(q2(22)))))
											({
												j = ({
													dev__9 = 5
													|dev__10, dev__11| add3(dev__9, dev__10, dev__11)
												})
												g = ({
													dev__12 = 20
													|dev__13| j(dev__12, dev__13)
												})
												({
													line!(CceText.printed(CceText.concat("still-partial: ", CceText.show_int(g(22)))))
													({
														c = rec_fn(4)
														c2 = ({
															dev__14 = 20
															|dev__15| c(dev__14, dev__15)
														})
														({
															line!(CceText.printed(CceText.concat("self-recursive: ", CceText.show_int(c2(22)))))
															({
																d = even_fn(4)
																d2 = ({
																	dev__16 = 20
																	|dev__17| d(dev__16, dev__17)
																})
																({
																	line!(CceText.printed(CceText.concat("mutual: ", CceText.show_int(d2(22)))))
																	({
																		k = ({
																			dev__18 = 1
																			|dev__19, dev__20, dev__21, dev__22| mk3(dev__18, dev__19, dev__20)(dev__21, dev__22)
																		})
																		k3 = ({
																			dev__23 = 2
																			dev__24 = 3
																			dev__25 = 20
																			|dev__26| k(dev__23, dev__24, dev__25, dev__26)
																		})
																		({
																			line!(CceText.printed(CceText.concat("closure-over-one: ", CceText.show_int(k3(22)))))
																			({
																				kk = ({
																					dev__27 = 1
																					|dev__28, dev__29, dev__30, dev__31| mk3(dev__27, dev__28, dev__29)(dev__30, dev__31)
																				})
																				k4 = kk(2, 3, 20, 22)
																				({
																					line!(CceText.printed(CceText.concat("closure-over-two: ", CceText.show_int(k4))))
																					({
																						h = ({
																							dev__32 = 1
																							|dev__33, dev__34, dev__35| mk2(dev__32, dev__33)(dev__34, dev__35)
																						})
																						h3 = h(2, 20, 22)
																						({
																							line!(CceText.printed(CceText.concat("closure-arity-one-over-two: ", CceText.show_int(h3))))
																							({
																								f = ({
	|dev__36, dev__37, dev__38, dev__39, dev__40| mk3(dev__36, dev__37, dev__38)(dev__39, dev__40)
})
																								f4 = ({
																									dev__41 = 1
																									dev__42 = 2
																									dev__43 = 3
																									dev__44 = 20
																									|dev__45| f(dev__41, dev__42, dev__43, dev__44, dev__45)
																								})
																								line!(CceText.printed(CceText.concat("bare-name-over-one: ", CceText.show_int(f4(22)))))
																							})
																						})
																					})
																				})
																			})
																		})
																	})
																})
															})
														})
													})
												})
											})
										})
									})
								})
							})
						})
					})
				})
			})
		})
	})
	Ok({})
}
