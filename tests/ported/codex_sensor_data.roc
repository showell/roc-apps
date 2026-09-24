# sensor-data
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/sensor-data.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     dev01/temperature=23.5@1000
#     humidity
#     42
#     true
#     ALERT
#     ALERT

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.SensorData

# SensorDataTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		r = SensorData.make_reading(Temperature, FixedValue(23, 5), 1000, "dev01")
		({
			line!(CceText.printed(SensorData.format_reading(r)))
			line!(CceText.printed(SensorData.sensor_kind_name(Humidity)))
			line!(CceText.printed(SensorData.sensor_value_to_text(IntValue(42))))
			line!(CceText.printed(SensorData.sensor_value_to_text(BoolValue(True))))
			({
				over : Bool
				over = SensorData.check_alert(AboveThreshold(30), 35)
				under : Bool
				under = SensorData.check_alert(BelowThreshold(10), 5)
				({
					line!(CceText.printed((if over { "ALERT" } else { "ok" })))
					line!(CceText.printed((if under { "ALERT" } else { "ok" })))
				})
			})
		})
	})
	Ok({})
}
