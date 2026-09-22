# SensorData -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

SensorData :: [].{
	SensorKind : [Temperature, Humidity, Barometer, Light, Accelerometer, Gyroscope, Magnetometer, Gps, Battery, Custom(List(U8))]
	SensorValue : [IntValue(I64), FixedValue(I64, I64), BoolValue(Bool), Vec3Value(I64, I64, I64)]
	SensorReading : { kind : SensorData.SensorKind, value : SensorData.SensorValue, timestamp : I64, device_id : List(U8) }
	TimeSeriesEntry : { timestamp : I64, value : I64 }
	AlertCondition : [AboveThreshold(I64), BelowThreshold(I64), OutsideRange(I64, I64), RateOfChange(I64)]

	sensor_kind_name : SensorData.SensorKind -> List(U8)
	sensor_kind_name = |k| (match k {
		Temperature => [14, 13, 26, 31, 13, 21, 15, 14, 25, 21, 13]
		Humidity => [20, 25, 26, 17, 22, 17, 14, 30]
		Barometer => [31, 21, 13, 19, 19, 25, 21, 13]
		Light => [23, 17, 29, 20, 14]
		Accelerometer => [15, 24, 24, 13, 23, 13, 21, 16, 26, 13, 14, 13, 21]
		Gyroscope => [29, 30, 21, 16, 19, 24, 16, 31, 13]
		Magnetometer => [26, 15, 29, 18, 13, 14, 16, 26, 13, 14, 13, 21]
		Gps => [29, 31, 19]
		Battery => [32, 15, 14, 14, 13, 21, 30]
		Custom(name) => name
	})

	sensor_value_to_text : SensorData.SensorValue -> List(U8)
	sensor_value_to_text = |v| (match v {
		IntValue(n) => Text.show_int(n)
		FixedValue(whole, frac) => List.concat(List.concat(Text.show_int(whole), [65]), Text.show_int(frac))
		BoolValue(b) => (if b { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] })
		Vec3Value(x, y, z) => List.concat(List.concat(List.concat(List.concat(Text.show_int(x), [66]), Text.show_int(y)), [66]), Text.show_int(z))
	})

	make_reading : SensorData.SensorKind, SensorData.SensorValue, I64, List(U8) -> SensorData.SensorReading
	make_reading = |kind, value, ts, dev_| { kind: kind, value: value, timestamp: ts, device_id: dev_ }

	format_reading : SensorData.SensorReading -> List(U8)
	format_reading = |r| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(r.device_id, [81]), sensor_kind_name(r.kind)), [77]), sensor_value_to_text(r.value)), [82]), Text.show_int(r.timestamp))

	ts_min : List(SensorData.TimeSeriesEntry) -> I64
	ts_min = |entries| ts_min_loop(entries, 0, U64.to_i64_wrap(List.len(entries)), 2147483647)

	ts_min_loop : List(SensorData.TimeSeriesEntry), I64, I64, I64 -> I64
	ts_min_loop = |entries, i, len, best| (if (i >= len) { best } else { ({
		v = (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).value
		ts_min_loop(entries, (i + 1), len, (if (v < best) { v } else { best }))
	}) })

	ts_max : List(SensorData.TimeSeriesEntry) -> I64
	ts_max = |entries| ts_max_loop(entries, 0, U64.to_i64_wrap(List.len(entries)), (0 - 2147483647))

	ts_max_loop : List(SensorData.TimeSeriesEntry), I64, I64, I64 -> I64
	ts_max_loop = |entries, i, len, best| (if (i >= len) { best } else { ({
		v = (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).value
		ts_max_loop(entries, (i + 1), len, (if (v > best) { v } else { best }))
	}) })

	ts_sum : List(SensorData.TimeSeriesEntry) -> I64
	ts_sum = |entries| ts_sum_loop(entries, 0, U64.to_i64_wrap(List.len(entries)), 0)

	ts_sum_loop : List(SensorData.TimeSeriesEntry), I64, I64, I64 -> I64
	ts_sum_loop = |entries, i, len, acc| (if (i >= len) { acc } else { ts_sum_loop(entries, (i + 1), len, (acc + (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).value)) })

	ts_average : List(SensorData.TimeSeriesEntry) -> I64
	ts_average = |entries| ({
		len = U64.to_i64_wrap(List.len(entries))
		(if (len == 0) { 0 } else { I64.div_trunc_by(ts_sum(entries), len) })
	})

	check_alert : SensorData.AlertCondition, I64 -> Bool
	check_alert = |condition, value| (match condition {
		AboveThreshold(limit) => (value > limit)
		BelowThreshold(limit) => (value < limit)
		OutsideRange(lo, hi) => ((value < lo) or (value > hi))
		RateOfChange(_max_delta) => False
	})

	eq_SensorKind : SensorData.SensorKind, SensorData.SensorKind -> Bool
	eq_SensorKind = |ex, ey| (match ex {
		Temperature => (match ey {
			Temperature => True
			_ => False
		})
		Humidity => (match ey {
			Humidity => True
			_ => False
		})
		Barometer => (match ey {
			Barometer => True
			_ => False
		})
		Light => (match ey {
			Light => True
			_ => False
		})
		Accelerometer => (match ey {
			Accelerometer => True
			_ => False
		})
		Gyroscope => (match ey {
			Gyroscope => True
			_ => False
		})
		Magnetometer => (match ey {
			Magnetometer => True
			_ => False
		})
		Gps => (match ey {
			Gps => True
			_ => False
		})
		Battery => (match ey {
			Battery => True
			_ => False
		})
		Custom(exf0) => (match ey {
			Custom(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})

	eq_SensorValue : SensorData.SensorValue, SensorData.SensorValue -> Bool
	eq_SensorValue = |ex, ey| (match ex {
		IntValue(exf0) => (match ey {
			IntValue(eyf0) => (exf0 == eyf0)
			_ => False
		})
		FixedValue(exf0, exf1) => (match ey {
			FixedValue(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		BoolValue(exf0) => (match ey {
			BoolValue(eyf0) => (exf0 == eyf0)
			_ => False
		})
		Vec3Value(exf0, exf1, exf2) => (match ey {
			Vec3Value(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
			_ => False
		})
	})

	eq_AlertCondition : SensorData.AlertCondition, SensorData.AlertCondition -> Bool
	eq_AlertCondition = |ex, ey| (match ex {
		AboveThreshold(exf0) => (match ey {
			AboveThreshold(eyf0) => (exf0 == eyf0)
			_ => False
		})
		BelowThreshold(exf0) => (match ey {
			BelowThreshold(eyf0) => (exf0 == eyf0)
			_ => False
		})
		OutsideRange(exf0, exf1) => (match ey {
			OutsideRange(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		RateOfChange(exf0) => (match ey {
			RateOfChange(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
