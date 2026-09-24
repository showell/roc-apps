# DtlsHandshake -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Hkdf
import Hmac

DtlsHandshake :: [].{
	DtlsHsPhase : [PhStart, PhWaitServerHello, PhWaitAck, PhConnected, PhFailed]
	DtlsAction : [ActSendFlight(I64), ActSetTimer(I64), ActDeliverKeys, ActAck, ActAbort(I64)]
	DtlsEvent : [EvStart(I64), EvHelloRetry(List(I64), I64), EvServerFlight(I64), EvAck(I64), EvTimeout(I64)]
	DtlsHsState := { hs_phase : DtlsHandshake.DtlsHsPhase, hs_flight : I64, hs_timer : I64, hs_retries : I64, hs_cookie : List(I64) }.{
		is_eq : DtlsHandshake.DtlsHsState, DtlsHandshake.DtlsHsState -> Bool
		is_eq = |a, b| a.hs_phase == b.hs_phase and a.hs_flight == b.hs_flight and a.hs_timer == b.hs_timer and a.hs_retries == b.hs_retries and a.hs_cookie == b.hs_cookie
	}
	DtlsHsStep := { step_state : DtlsHandshake.DtlsHsState, step_actions : List(DtlsHandshake.DtlsAction) }.{
		is_eq : DtlsHandshake.DtlsHsStep, DtlsHandshake.DtlsHsStep -> Bool
		is_eq = |a, b| a.step_state == b.step_state and a.step_actions == b.step_actions
	}

	dtls_hs_initial_timer : I64
	dtls_hs_initial_timer = 1000

	dtls_hs_max_timer : I64
	dtls_hs_max_timer = 60000

	dtls_hs_max_retries : I64
	dtls_hs_max_retries = 10

	dtls_alert_illegal_parameter : I64
	dtls_alert_illegal_parameter = 47

	dtls_alert_timeout : I64
	dtls_alert_timeout = 80

	dtls_flight_ch1 : I64
	dtls_flight_ch1 = 1

	dtls_flight_hrr : I64
	dtls_flight_hrr = 2

	dtls_flight_ch2 : I64
	dtls_flight_ch2 = 3

	dtls_flight_fin : I64
	dtls_flight_fin = 5

	dtls_hs_new : DtlsHandshake.DtlsHsState
	dtls_hs_new = DtlsHandshake.DtlsHsState.{ hs_phase: PhStart, hs_flight: 0, hs_timer: dtls_hs_initial_timer, hs_retries: 0, hs_cookie: [] }

	dtls_hs_step : DtlsHandshake.DtlsHsState, DtlsHandshake.DtlsEvent -> DtlsHandshake.DtlsHsStep
	dtls_hs_step = |st, ev| (match ev {
		EvStart(now) => dtls_hs_on_start(st, now)
		EvHelloRetry(cookie, now) => dtls_hs_on_hrr(st, cookie, now)
		EvServerFlight(now) => dtls_hs_on_server_flight(st, now)
		EvAck(now) => dtls_hs_on_ack(st, now)
		EvTimeout(now) => dtls_hs_on_timeout(st, now)
	})

	dtls_hs_on_start : DtlsHandshake.DtlsHsState, I64 -> DtlsHandshake.DtlsHsStep
	dtls_hs_on_start = |st, now| (match st.hs_phase {
		PhStart => dtls_hs_send(st, dtls_flight_ch1, PhWaitServerHello, now, [])
		_ => dtls_hs_idle(st)
	})

	dtls_hs_on_hrr : DtlsHandshake.DtlsHsState, List(I64), I64 -> DtlsHandshake.DtlsHsStep
	dtls_hs_on_hrr = |st, cookie, now| (match st.hs_phase {
		PhWaitServerHello => dtls_hs_send(st, dtls_flight_ch2, PhWaitServerHello, now, cookie)
		_ => dtls_hs_idle(st)
	})

	dtls_hs_on_server_flight : DtlsHandshake.DtlsHsState, I64 -> DtlsHandshake.DtlsHsStep
	dtls_hs_on_server_flight = |st, now| (match st.hs_phase {
		PhWaitServerHello => dtls_hs_finish_flight(st, now)
		_ => dtls_hs_idle(st)
	})

	dtls_hs_finish_flight : DtlsHandshake.DtlsHsState, I64 -> DtlsHandshake.DtlsHsStep
	dtls_hs_finish_flight = |st, now| ({
		next = DtlsHandshake.DtlsHsState.{ hs_phase: PhWaitAck, hs_flight: dtls_flight_fin, hs_timer: dtls_hs_initial_timer, hs_retries: 0, hs_cookie: st.hs_cookie }
		DtlsHandshake.DtlsHsStep.{ step_state: next, step_actions: [ActDeliverKeys, ActSendFlight(dtls_flight_fin), ActSetTimer((now + dtls_hs_initial_timer))] }
	})

	dtls_hs_on_ack : DtlsHandshake.DtlsHsState, I64 -> DtlsHandshake.DtlsHsStep
	dtls_hs_on_ack = |st, _now| (match st.hs_phase {
		PhWaitAck => DtlsHandshake.DtlsHsStep.{ step_state: { ..st, hs_phase: PhConnected }, step_actions: [] }
		_ => dtls_hs_idle(st)
	})

	dtls_hs_on_timeout : DtlsHandshake.DtlsHsState, I64 -> DtlsHandshake.DtlsHsStep
	dtls_hs_on_timeout = |st, now| (match st.hs_phase {
		PhWaitServerHello => dtls_hs_retry(st, now)
		PhWaitAck => dtls_hs_retry(st, now)
		_ => dtls_hs_idle(st)
	})

	dtls_hs_retry : DtlsHandshake.DtlsHsState, I64 -> DtlsHandshake.DtlsHsStep
	dtls_hs_retry = |st, now| (if ((st.hs_retries + 1) > dtls_hs_max_retries) { dtls_hs_give_up(st) } else { dtls_hs_retry_now(st, now) })

	dtls_hs_give_up : DtlsHandshake.DtlsHsState -> DtlsHandshake.DtlsHsStep
	dtls_hs_give_up = |st| DtlsHandshake.DtlsHsStep.{ step_state: { ..st, hs_phase: PhFailed }, step_actions: [ActAbort(dtls_alert_timeout)] }

	dtls_hs_retry_now : DtlsHandshake.DtlsHsState, I64 -> DtlsHandshake.DtlsHsStep
	dtls_hs_retry_now = |st, now| ({
		t = dtls_hs_backoff(st.hs_timer)
		next = DtlsHandshake.DtlsHsState.{ hs_phase: st.hs_phase, hs_flight: st.hs_flight, hs_timer: t, hs_retries: (st.hs_retries + 1), hs_cookie: st.hs_cookie }
		DtlsHandshake.DtlsHsStep.{ step_state: next, step_actions: [ActSendFlight(st.hs_flight), ActSetTimer((now + t))] }
	})

	dtls_hs_backoff : I64 -> I64
	dtls_hs_backoff = |t| ({
		doubled = (t * 2)
		(if (doubled > dtls_hs_max_timer) { dtls_hs_max_timer } else { doubled })
	})

	dtls_hs_send : DtlsHandshake.DtlsHsState, I64, DtlsHandshake.DtlsHsPhase, I64, List(I64) -> DtlsHandshake.DtlsHsStep
	dtls_hs_send = |_st, flight, phase, now, cookie| ({
		next = DtlsHandshake.DtlsHsState.{ hs_phase: phase, hs_flight: flight, hs_timer: dtls_hs_initial_timer, hs_retries: 0, hs_cookie: cookie }
		DtlsHandshake.DtlsHsStep.{ step_state: next, step_actions: [ActSendFlight(flight), ActSetTimer((now + dtls_hs_initial_timer))] }
	})

	dtls_hs_idle : DtlsHandshake.DtlsHsState -> DtlsHandshake.DtlsHsStep
	dtls_hs_idle = |st| DtlsHandshake.DtlsHsStep.{ step_state: st, step_actions: [] }

	dtls_cookie : List(I64), List(I64) -> List(I64)
	dtls_cookie = |secret, client_addr| Hkdf.hkdf_words_to_bytes(Hmac.hmac_sha256(secret, client_addr))

	dtls_cookie_valid : List(I64), List(I64), List(I64) -> Bool
	dtls_cookie_valid = |secret, client_addr, offered| dtls_bytes_equal(dtls_cookie(secret, client_addr), offered)

	dtls_bytes_equal : List(I64), List(I64) -> Bool
	dtls_bytes_equal = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { dtls_bytes_equal_loop(a, b, 0, U64.to_i64_wrap(List.len(a)), 0) })

	dtls_bytes_equal_loop : List(I64), List(I64), I64, I64, I64 -> Bool
	dtls_bytes_equal_loop = |a, b, i, n, diff| (if (i >= n) { (diff == 0) } else { dtls_bytes_equal_loop(a, b, (i + 1), n, I64.bitwise_or(diff, I64.bitwise_xor((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	dtls_server_verdict : List(I64), List(I64), List(I64) -> DtlsHandshake.DtlsAction
	dtls_server_verdict = |secret, client_addr, offered| (if (U64.to_i64_wrap(List.len(offered)) == 0) { ActSendFlight(dtls_flight_hrr) } else { (if dtls_cookie_valid(secret, client_addr, offered) { ActDeliverKeys } else { ActAbort(dtls_alert_illegal_parameter) }) })

	dtls_amplification_ok : I64, I64, I64 -> Bool
	dtls_amplification_ok = |received, already_sent, want| ((already_sent + want) <= (received * 3))

	dtls_amplification_budget : I64, I64 -> I64
	dtls_amplification_budget = |received, already_sent| ({
		left = ((received * 3) - already_sent)
		(if (left < 0) { 0 } else { left })
	})

	eq_DtlsHsPhase : DtlsHandshake.DtlsHsPhase, DtlsHandshake.DtlsHsPhase -> Bool
	eq_DtlsHsPhase = |ex, ey| (match ex {
		PhStart => (match ey {
			PhStart => True
			_ => False
		})
		PhWaitServerHello => (match ey {
			PhWaitServerHello => True
			_ => False
		})
		PhWaitAck => (match ey {
			PhWaitAck => True
			_ => False
		})
		PhConnected => (match ey {
			PhConnected => True
			_ => False
		})
		PhFailed => (match ey {
			PhFailed => True
			_ => False
		})
	})

	eq_DtlsAction : DtlsHandshake.DtlsAction, DtlsHandshake.DtlsAction -> Bool
	eq_DtlsAction = |ex, ey| (match ex {
		ActSendFlight(exf0) => (match ey {
			ActSendFlight(eyf0) => (exf0 == eyf0)
			_ => False
		})
		ActSetTimer(exf0) => (match ey {
			ActSetTimer(eyf0) => (exf0 == eyf0)
			_ => False
		})
		ActDeliverKeys => (match ey {
			ActDeliverKeys => True
			_ => False
		})
		ActAck => (match ey {
			ActAck => True
			_ => False
		})
		ActAbort(exf0) => (match ey {
			ActAbort(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})

	eq_DtlsEvent : DtlsHandshake.DtlsEvent, DtlsHandshake.DtlsEvent -> Bool
	eq_DtlsEvent = |ex, ey| (match ex {
		EvStart(exf0) => (match ey {
			EvStart(eyf0) => (exf0 == eyf0)
			_ => False
		})
		EvHelloRetry(exf0, exf1) => (match ey {
			EvHelloRetry(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		EvServerFlight(exf0) => (match ey {
			EvServerFlight(eyf0) => (exf0 == eyf0)
			_ => False
		})
		EvAck(exf0) => (match ey {
			EvAck(eyf0) => (exf0 == eyf0)
			_ => False
		})
		EvTimeout(exf0) => (match ey {
			EvTimeout(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
