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

import cdx.SensorData
import cdx.Text

# SensorDataTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		r = SensorData.make_reading(Temperature, FixedValue(23, 5), 1000, [22, 13, 33, 3, 4])
		({
			line!(Text.printed(SensorData.format_reading(r)))
			line!(Text.printed(SensorData.sensor_kind_name(Humidity)))
			line!(Text.printed(SensorData.sensor_value_to_text(IntValue(42))))
			line!(Text.printed(SensorData.sensor_value_to_text(BoolValue(True))))
			({
				over = SensorData.check_alert(AboveThreshold(30), 35)
				under = SensorData.check_alert(BelowThreshold(10), 5)
				({
					line!(Text.printed((if over { [41, 49, 39, 47, 40] } else { [16, 34] })))
					line!(Text.printed((if under { [41, 49, 39, 47, 40] } else { [16, 34] })))
				})
			})
		})
	})
	Ok({})
}
