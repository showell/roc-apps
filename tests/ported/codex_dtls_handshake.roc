# dtls-handshake
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/dtls-handshake.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     hs happy: send1,timer1000 | keys,send5,timer1050 |  | connected
#     hs cookie: send1,timer3000 | send3,timer2200 | timer=1000 retries=0
#     hs backoff: 2000,4000,8000,16000,32000,60000,60000,60000,60000,60000,60000
#     hs giveup: retries=10 phase=wait-sh then=abort80/failed after=/failed
#     hs stale: /connected
#     hs verdict none=send2
#     hs verdict good=keys
#     hs verdict bad=abort47
#     hs verdict wrong-addr=abort47
#     hs amp: at=True over=False partial=True budget=50

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.DtlsHandshake

# DtlsHandshakeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fmt_act : DtlsHandshake.DtlsAction -> CceText
fmt_act = |a| (match a {
	ActSendFlight(f) => CceText.concat("send", CceText.show_int(f))
	ActSetTimer(d) => CceText.concat("timer", CceText.show_int(d))
	ActDeliverKeys => "keys"
	ActAck => "ack"
	ActAbort(x) => CceText.concat("abort", CceText.show_int(x))
})

fmt_acts : List(DtlsHandshake.DtlsAction) -> CceText
fmt_acts = |as_| fmt_acts_loop(as_, 0, U64.to_i64_wrap(List.len(as_)), "")

fmt_acts_loop : List(DtlsHandshake.DtlsAction), I64, I64, CceText -> CceText
fmt_acts_loop = |as_, i, n, acc| (if (i >= n) { acc } else { (if (i == 0) { fmt_acts_loop(as_, (i + 1), n, fmt_act((List.get(as_, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) } else { fmt_acts_loop(as_, (i + 1), n, CceText.concat(CceText.concat(acc, ","), fmt_act((List.get(as_, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) }) })

fmt_phase : DtlsHandshake.DtlsHsPhase -> CceText
fmt_phase = |p| (match p {
	PhStart => "start"
	PhWaitServerHello => "wait-sh"
	PhWaitAck => "wait-ack"
	PhConnected => "connected"
	PhFailed => "failed"
})

h1 : DtlsHandshake.DtlsHsStep
h1 = DtlsHandshake.dtls_hs_step(DtlsHandshake.dtls_hs_new, EvStart(0))

h2 : DtlsHandshake.DtlsHsStep
h2 = DtlsHandshake.dtls_hs_step(h1.step_state, EvServerFlight(50))

h3 : DtlsHandshake.DtlsHsStep
h3 = DtlsHandshake.dtls_hs_step(h2.step_state, EvAck(90))

test_happy : CceText
test_happy = CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("hs happy: ", fmt_acts(h1.step_actions)), " | "), fmt_acts(h2.step_actions)), " | "), fmt_acts(h3.step_actions)), " | "), fmt_phase(h3.step_state.hs_phase))

c1 : DtlsHandshake.DtlsHsStep
c1 = DtlsHandshake.dtls_hs_step(DtlsHandshake.dtls_hs_new, EvStart(0))

c2 : DtlsHandshake.DtlsHsStep
c2 = DtlsHandshake.dtls_hs_step(c1.step_state, EvTimeout(1000))

c3 : DtlsHandshake.DtlsHsStep
c3 = DtlsHandshake.dtls_hs_step(c2.step_state, EvHelloRetry([9, 9, 9, 9], 1200))

test_cookie_flight : CceText
test_cookie_flight = CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("hs cookie: ", fmt_acts(c2.step_actions)), " | "), fmt_acts(c3.step_actions)), " | timer="), CceText.show_int(c3.step_state.hs_timer)), " retries="), CceText.show_int(c3.step_state.hs_retries))

bo : List(I64)
bo = bo_loop(DtlsHandshake.dtls_hs_new, 0, 12, [])

bo_loop : DtlsHandshake.DtlsHsState, I64, I64, List(I64) -> List(I64)
bo_loop = |st, i, n, acc| (if (i >= n) { acc } else { (if (i == 0) { bo_loop(DtlsHandshake.dtls_hs_step(st, EvStart(0)).step_state, (i + 1), n, acc) } else { bo_step(st, i, n, acc) }) })

bo_step : DtlsHandshake.DtlsHsState, I64, I64, List(I64) -> List(I64)
bo_step = |st, i, n, acc| ({
	r = DtlsHandshake.dtls_hs_step(st, EvTimeout((i * 1000)))
	bo_loop(r.step_state, (i + 1), n, List.append(acc, r.step_state.hs_timer))
})

test_backoff : CceText
test_backoff = CceText.concat("hs backoff: ", fmt_ints(bo))

fmt_ints : List(I64) -> CceText
fmt_ints = |xs| fmt_ints_loop(xs, 0, U64.to_i64_wrap(List.len(xs)), "")

fmt_ints_loop : List(I64), I64, I64, CceText -> CceText
fmt_ints_loop = |xs, i, n, acc| (if (i >= n) { acc } else { (if (i == 0) { fmt_ints_loop(xs, (i + 1), n, CceText.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) } else { fmt_ints_loop(xs, (i + 1), n, CceText.concat(CceText.concat(acc, ","), CceText.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) }) })

g0 : DtlsHandshake.DtlsHsState
g0 = DtlsHandshake.dtls_hs_step(DtlsHandshake.dtls_hs_new, EvStart(0)).step_state

g1 : DtlsHandshake.DtlsHsState
g1 = give_up_loop(g0, 0, 10)

give_up_loop : DtlsHandshake.DtlsHsState, I64, I64 -> DtlsHandshake.DtlsHsState
give_up_loop = |st, i, n| (if (i >= n) { st } else { give_up_loop(DtlsHandshake.dtls_hs_step(st, EvTimeout((i * 1000))).step_state, (i + 1), n) })

gfinal : DtlsHandshake.DtlsHsStep
gfinal = DtlsHandshake.dtls_hs_step(g1, EvTimeout(99999))

gafter : DtlsHandshake.DtlsHsStep
gafter = DtlsHandshake.dtls_hs_step(gfinal.step_state, EvTimeout(111111))

test_giveup : CceText
test_giveup = CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("hs giveup: retries=", CceText.show_int(g1.hs_retries)), " phase="), fmt_phase(g1.hs_phase)), " then="), fmt_acts(gfinal.step_actions)), "/"), fmt_phase(gfinal.step_state.hs_phase)), " after="), fmt_acts(gafter.step_actions)), "/"), fmt_phase(gafter.step_state.hs_phase))

s1 : DtlsHandshake.DtlsHsStep
s1 = DtlsHandshake.dtls_hs_step(h3.step_state, EvTimeout(5000))

test_stale : CceText
test_stale = CceText.concat(CceText.concat(CceText.concat("hs stale: ", fmt_acts(s1.step_actions)), "/"), fmt_phase(s1.step_state.hs_phase))

sec : List(I64)
sec = [1, 2, 3, 4]

addr : List(I64)
addr = [10, 0, 0, 7]

good : List(I64)
good = DtlsHandshake.dtls_cookie(sec, addr)

bad : List(I64)
bad = (List.set(DtlsHandshake.dtls_cookie(sec, addr), I64.to_u64_wrap(0), I64.bitwise_xor((List.get(DtlsHandshake.dtls_cookie(sec, addr), I64.to_u64_wrap(0)) ?? crash("list-at out of range")), 1)) ?? crash("list-set-at past the end"))

test_verdict_none : CceText
test_verdict_none = CceText.concat("hs verdict none=", fmt_act(DtlsHandshake.dtls_server_verdict(sec, addr, [])))

test_verdict_good : CceText
test_verdict_good = CceText.concat("hs verdict good=", fmt_act(DtlsHandshake.dtls_server_verdict(sec, addr, good)))

test_verdict_bad : CceText
test_verdict_bad = CceText.concat("hs verdict bad=", fmt_act(DtlsHandshake.dtls_server_verdict(sec, addr, bad)))

test_verdict_other_addr : CceText
test_verdict_other_addr = CceText.concat("hs verdict wrong-addr=", fmt_act(DtlsHandshake.dtls_server_verdict(sec, [10, 0, 0, 8], good)))

test_amp : CceText
test_amp = CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("hs amp: at=", (if DtlsHandshake.dtls_amplification_ok(100, 0, 300) { "True" } else { "False" })), " over="), (if DtlsHandshake.dtls_amplification_ok(100, 0, 301) { "True" } else { "False" })), " partial="), (if DtlsHandshake.dtls_amplification_ok(100, 250, 50) { "True" } else { "False" })), " budget="), CceText.show_int(DtlsHandshake.dtls_amplification_budget(100, 250)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_happy))
	line!(CceText.printed(test_cookie_flight))
	line!(CceText.printed(test_backoff))
	line!(CceText.printed(test_giveup))
	line!(CceText.printed(test_stale))
	line!(CceText.printed(test_verdict_none))
	line!(CceText.printed(test_verdict_good))
	line!(CceText.printed(test_verdict_bad))
	line!(CceText.printed(test_verdict_other_addr))
	line!(CceText.printed(test_amp))
	Ok({})
}
