# DateTime -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text
import Tuple

DateTime :: [].{
	Timestamp : I64
	Elapsed : I64
	DateTime : { year : I64, month : I64, day : I64, hour : I64, minute : I64, second : I64 }

	seconds_per_minute : I64
	seconds_per_minute = 60

	seconds_per_hour : I64
	seconds_per_hour = 3600

	seconds_per_day : I64
	seconds_per_day = 86400

	unix_to_datetime : DateTime.Timestamp -> DateTime.DateTime
	unix_to_datetime = |ts| ({
		days = I64.div_trunc_by(ts, seconds_per_day)
		time_of_day = (ts - (days * seconds_per_day))
		hour = I64.div_trunc_by(time_of_day, seconds_per_hour)
		minute = I64.div_trunc_by((time_of_day - (hour * seconds_per_hour)), seconds_per_minute)
		second = ((time_of_day - (hour * seconds_per_hour)) - (minute * seconds_per_minute))
		(match days_to_ymd(days) {
			MkTup3(y, m, d) => { year: y, month: m, day: d, hour: hour, minute: minute, second: second }
		})
	})

	days_to_ymd : I64 -> Tuple.Tup3(I64, I64, I64)
	days_to_ymd = |days| days_to_year(days, 1970)

	days_to_year : I64, I64 -> Tuple.Tup3(I64, I64, I64)
	days_to_year = |remaining, year| ({
		days_in_y = (if is_leap_year(year) { 366 } else { 365 })
		(if (remaining < days_in_y) { days_to_month(remaining, year, 1) } else { days_to_year((remaining - days_in_y), (year + 1)) })
	})

	days_to_month : I64, I64, I64 -> Tuple.Tup3(I64, I64, I64)
	days_to_month = |remaining, year, month| (if (month > 12) { MkTup3((year + 1), 1, (remaining + 1)) } else { ({
		dim = days_in_month(year, month)
		(if (remaining < dim) { MkTup3(year, month, (remaining + 1)) } else { days_to_month((remaining - dim), year, (month + 1)) })
	}) })

	is_leap_year : I64 -> Bool
	is_leap_year = |y| (if ((I64.div_trunc_by(y, 400) * 400) == y) { True } else { (if ((I64.div_trunc_by(y, 100) * 100) == y) { False } else { ((I64.div_trunc_by(y, 4) * 4) == y) }) })

	days_in_month : I64, I64 -> I64
	days_in_month = |year, m| (if (m == 1) { 31 } else { (if (m == 2) { (if is_leap_year(year) { 29 } else { 28 }) } else { (if (m == 3) { 31 } else { (if (m == 4) { 30 } else { (if (m == 5) { 31 } else { (if (m == 6) { 30 } else { (if (m == 7) { 31 } else { (if (m == 8) { 31 } else { (if (m == 9) { 30 } else { (if (m == 10) { 31 } else { (if (m == 11) { 30 } else { 31 }) }) }) }) }) }) }) }) }) }) })

	datetime_to_unix : DateTime.DateTime -> I64
	datetime_to_unix = |dt| ({
		days = ymd_to_days(dt.year, dt.month, dt.day)
		((((days * seconds_per_day) + (dt.hour * seconds_per_hour)) + (dt.minute * seconds_per_minute)) + dt.second)
	})

	ymd_to_days : I64, I64, I64 -> I64
	ymd_to_days = |year, month, day| ({
		year_days = count_year_days(1970, year, 0)
		month_days = count_month_days(year, 1, month, 0)
		(((year_days + month_days) + day) - 1)
	})

	count_year_days : I64, I64, I64 -> I64
	count_year_days = |from, to, acc| (if (from >= to) { acc } else { count_year_days((from + 1), to, (acc + (if is_leap_year(from) { 366 } else { 365 }))) })

	count_month_days : I64, I64, I64, I64 -> I64
	count_month_days = |year, from, to, acc| (if (from >= to) { acc } else { count_month_days(year, (from + 1), to, (acc + days_in_month(year, from))) })

	day_of_week : I64 -> I64
	day_of_week = |unix_ts| ({
		days = I64.div_trunc_by(unix_ts, seconds_per_day)
		((((I64.div_trunc_by((days + 4), 7) * 7) - days) - 4) + (days + 4))
	})

	day_of_week_name : I64 -> List(U8)
	day_of_week_name = |dow| (if (dow == 0) { [40, 20, 25] } else { (if (dow == 1) { [54, 21, 17] } else { (if (dow == 2) { [45, 15, 14] } else { (if (dow == 3) { [45, 25, 18] } else { (if (dow == 4) { [52, 16, 18] } else { (if (dow == 5) { [40, 25, 13] } else { (if (dow == 6) { [53, 13, 22] } else { [68] }) }) }) }) }) }) })

	format_datetime : DateTime.DateTime -> List(U8)
	format_datetime = |dt| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(pad4(dt.year), [73]), pad2(dt.month)), [73]), pad2(dt.day)), [40]), pad2(dt.hour)), [69]), pad2(dt.minute)), [69]), pad2(dt.second)), [64])

	format_date : DateTime.DateTime -> List(U8)
	format_date = |dt| List.concat(List.concat(List.concat(List.concat(pad4(dt.year), [73]), pad2(dt.month)), [73]), pad2(dt.day))

	format_time : DateTime.DateTime -> List(U8)
	format_time = |dt| List.concat(List.concat(List.concat(List.concat(pad2(dt.hour), [69]), pad2(dt.minute)), [69]), pad2(dt.second))

	pad2 : I64 -> List(U8)
	pad2 = |n| (if (n < 10) { List.concat([3], Text.show_int(n)) } else { Text.show_int(n) })

	pad4 : I64 -> List(U8)
	pad4 = |n| (if (n < 10) { List.concat([3, 3, 3], Text.show_int(n)) } else { (if (n < 100) { List.concat([3, 3], Text.show_int(n)) } else { (if (n < 1000) { List.concat([3], Text.show_int(n)) } else { Text.show_int(n) }) }) })

	datetime_add_seconds : DateTime.Timestamp, DateTime.Elapsed -> DateTime.Timestamp
	datetime_add_seconds = |ts, secs| (ts + secs)

	datetime_add_hours : DateTime.Timestamp, I64 -> DateTime.Timestamp
	datetime_add_hours = |ts, hours| (ts + (hours * seconds_per_hour))

	datetime_add_days : DateTime.Timestamp, I64 -> DateTime.Timestamp
	datetime_add_days = |ts, days| (ts + (days * seconds_per_day))

	datetime_diff : DateTime.Timestamp, DateTime.Timestamp -> DateTime.Elapsed
	datetime_diff = |a, b| (a - b)

	month_name : I64 -> List(U8)
	month_name = |m| (if (m == 1) { [61, 15, 18] } else { (if (m == 2) { [54, 13, 32] } else { (if (m == 3) { [52, 15, 21] } else { (if (m == 4) { [41, 31, 21] } else { (if (m == 5) { [52, 15, 30] } else { (if (m == 6) { [61, 25, 18] } else { (if (m == 7) { [61, 25, 23] } else { (if (m == 8) { [41, 25, 29] } else { (if (m == 9) { [45, 13, 31] } else { (if (m == 10) { [42, 24, 14] } else { (if (m == 11) { [44, 16, 33] } else { (if (m == 12) { [48, 13, 24] } else { [68] }) }) }) }) }) }) }) }) }) }) }) })
}
