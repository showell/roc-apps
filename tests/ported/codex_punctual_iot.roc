# punctual-iot
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/punctual-iot.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     threat-2500: 3
#     threat-400: 0
#     threat-3800: 4
#     temp-2500: 91
#     temp-400: 14
#     temp-3800: 139
#     byte1: 15
#     byte2: 34
#     byte3: 83
#     checksum: 132

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.IntOps

# PunctualIoT -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
SensorReading : { raw_adc : I64, channel : I64 }
ThreatLevel : [ThreatNone, ThreatLow, ThreatMedium, ThreatHigh, ThreatCritical]

classify_threat : I64 -> ThreatLevel
classify_threat = |raw| (if (raw < 512) { ThreatNone } else { (if (raw < 1024) { ThreatLow } else { (if (raw < 2048) { ThreatMedium } else { (if (raw < 3072) { ThreatHigh } else { ThreatCritical }) }) }) })

threat_to_integer : ThreatLevel -> I64
threat_to_integer = |t| (match t {
	ThreatNone => 0
	ThreatLow => 1
	ThreatMedium => 2
	ThreatHigh => 3
	ThreatCritical => 4
})

scale_adc_to_celsius : I64 -> I64
scale_adc_to_celsius = |raw| ({
	shifted = (raw * 150)
	I64.div_trunc_by(shifted, 4095)
})

encode_telemetry_byte : I64, I64, I64 -> I64
encode_telemetry_byte = |channel, temp, threat| ({
	ch = I64.bitwise_and(channel, 7)
	t = IntOps.int_clamp(0, 255, temp)
	thr = I64.bitwise_and(threat, 7)
	I64.bitwise_or(I64.shl_wrap(ch, I64.to_u8_wrap(5)), I64.bitwise_or(I64.shl_wrap(thr, I64.to_u8_wrap(2)), I64.bitwise_and(t, 3)))
})

checksum_byte : I64, I64 -> I64
checksum_byte = |a, b| I64.bitwise_and((a + b), 255)

eq_ThreatLevel : ThreatLevel, ThreatLevel -> Bool
eq_ThreatLevel = |ex, ey| (match ex {
	ThreatNone => (match ey {
		ThreatNone => True
		_ => False
	})
	ThreatLow => (match ey {
		ThreatLow => True
		_ => False
	})
	ThreatMedium => (match ey {
		ThreatMedium => True
		_ => False
	})
	ThreatHigh => (match ey {
		ThreatHigh => True
		_ => False
	})
	ThreatCritical => (match ey {
		ThreatCritical => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	({
		raw1 = 2500
		raw2 = 400
		raw3 = 3800
		t1 = classify_threat(raw1)
		t2 = classify_threat(raw2)
		t3 = classify_threat(raw3)
		temp1 = scale_adc_to_celsius(raw1)
		temp2 = scale_adc_to_celsius(raw2)
		temp3 = scale_adc_to_celsius(raw3)
		byte1 = encode_telemetry_byte(0, temp1, threat_to_integer(t1))
		byte2 = encode_telemetry_byte(1, temp2, threat_to_integer(t2))
		byte3 = encode_telemetry_byte(2, temp3, threat_to_integer(t3))
		ck = checksum_byte(checksum_byte(byte1, byte2), byte3)
		({
			line!(CceText.printed(CceText.concat("threat-2500: ", CceText.show_int(threat_to_integer(t1)))))
			line!(CceText.printed(CceText.concat("threat-400: ", CceText.show_int(threat_to_integer(t2)))))
			line!(CceText.printed(CceText.concat("threat-3800: ", CceText.show_int(threat_to_integer(t3)))))
			line!(CceText.printed(CceText.concat("temp-2500: ", CceText.show_int(temp1))))
			line!(CceText.printed(CceText.concat("temp-400: ", CceText.show_int(temp2))))
			line!(CceText.printed(CceText.concat("temp-3800: ", CceText.show_int(temp3))))
			line!(CceText.printed(CceText.concat("byte1: ", CceText.show_int(byte1))))
			line!(CceText.printed(CceText.concat("byte2: ", CceText.show_int(byte2))))
			line!(CceText.printed(CceText.concat("byte3: ", CceText.show_int(byte3))))
			line!(CceText.printed(CceText.concat("checksum: ", CceText.show_int(ck))))
		})
	})
	Ok({})
}
