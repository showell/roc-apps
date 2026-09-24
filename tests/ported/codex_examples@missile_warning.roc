# examples@missile-warning
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/examples@missile-warning.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     THREAT: CRITICAL
#     ACTION: FLARE
#     IMMINENT: YES
#     THREAT: NONE
#     ACTION: HOLD
#     IMMINENT: NO

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# MissileWarning -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
ThreatLevel : [None, Low, Medium, High, Critical]
SensorReading : { bearing : I64, range_m : I64, velocity : I64, ir_signal : I64 }
Countermeasure : [NoAction, Chaff, Flare, Jam, Evade]

classify_threat : SensorReading -> ThreatLevel
classify_threat = |s| ({
	range_score = (if (s.range_m < 1000) { 40 } else { (if (s.range_m < 5000) { 25 } else { (if (s.range_m < 20000) { 10 } else { 0 }) }) })
	vel_score = (if (s.velocity > 3000) { 30 } else { (if (s.velocity > 1500) { 20 } else { (if (s.velocity > 500) { 10 } else { 0 }) }) })
	ir_score = (if (s.ir_signal > 800) { 30 } else { (if (s.ir_signal > 400) { 15 } else { 0 }) })
	total = ((range_score + vel_score) + ir_score)
	(if (total >= 80) { Critical } else { (if (total >= 60) { High } else { (if (total >= 35) { Medium } else { (if (total >= 15) { Low } else { None }) }) }) })
})

select_response : ThreatLevel, SensorReading -> Countermeasure
select_response = |threat, s| (match threat {
	Critical => (if (s.ir_signal > 600) { Flare } else { Evade })
	High => Jam
	Medium => Chaff
	Low => NoAction
	None => NoAction
})

is_imminent : SensorReading -> Bool
is_imminent = |s| ((s.range_m < 1000) and (s.velocity > 2000))

threat_name : ThreatLevel -> Text
threat_name = |t| (match t {
	None => "NONE"
	Low => "LOW"
	Medium => "MEDIUM"
	High => "HIGH"
	Critical => "CRITICAL"
})

response_name : Countermeasure -> Text
response_name = |c| (match c {
	NoAction => "HOLD"
	Chaff => "CHAFF"
	Flare => "FLARE"
	Jam => "JAM"
	Evade => "EVADE"
})

eq_ThreatLevel : ThreatLevel, ThreatLevel -> Bool
eq_ThreatLevel = |ex, ey| (match ex {
	None => (match ey {
		None => True
		_ => False
	})
	Low => (match ey {
		Low => True
		_ => False
	})
	Medium => (match ey {
		Medium => True
		_ => False
	})
	High => (match ey {
		High => True
		_ => False
	})
	Critical => (match ey {
		Critical => True
		_ => False
	})
})

eq_Countermeasure : Countermeasure, Countermeasure -> Bool
eq_Countermeasure = |ex, ey| (match ex {
	NoAction => (match ey {
		NoAction => True
		_ => False
	})
	Chaff => (match ey {
		Chaff => True
		_ => False
	})
	Flare => (match ey {
		Flare => True
		_ => False
	})
	Jam => (match ey {
		Jam => True
		_ => False
	})
	Evade => (match ey {
		Evade => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	({
		inbound = { bearing: 45, range_m: 800, velocity: 2800, ir_signal: 900 }
		threat = classify_threat(inbound)
		response = select_response(threat, inbound)
		({
			({
				line!(Text.printed(Text.concat("THREAT: ", threat_name(threat))))
				line!(Text.printed(Text.concat("ACTION: ", response_name(response))))
				line!(Text.printed(Text.concat("IMMINENT: ", (if is_imminent(inbound) { "YES" } else { "NO" }))))
			})
			({
				far_contact = { bearing: 270, range_m: 45000, velocity: 300, ir_signal: 50 }
				threat2 = classify_threat(far_contact)
				response2 = select_response(threat2, far_contact)
				({
					line!(Text.printed(Text.concat("THREAT: ", threat_name(threat2))))
					line!(Text.printed(Text.concat("ACTION: ", response_name(response2))))
					line!(Text.printed(Text.concat("IMMINENT: ", (if is_imminent(far_contact) { "YES" } else { "NO" }))))
				})
			})
		})
	})
	Ok({})
}
