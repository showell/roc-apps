# DateTime -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Tuple

DateTime :: [].{
	Timestamp : I64
	Elapsed : I64
	DateTime := { year : I64, month : I64, day : I64, hour : I64, minute : I64, second : I64 }.{
		is_eq : DateTime.DateTime, DateTime.DateTime -> Bool
		is_eq = |a, b| a.year == b.year and a.month == b.month and a.day == b.day and a.hour == b.hour and a.minute == b.minute and a.second == b.second
	}

	seconds_per_minute : I64
	seconds_per_minute = 60

	seconds_per_hour : I64
	seconds_per_hour = 3600

	seconds_per_day : I64
	seconds_per_day = 86400

	unix_to_datetime : DateTime.Timestamp -> DateTime.DateTime
	unix_to_datetime = |ts| ({
		days : DateTime.Timestamp
		days = I64.div_trunc_by(ts, seconds_per_day)
		time_of_day : DateTime.Timestamp
		time_of_day = (ts - (days * seconds_per_day))
		hour : DateTime.Timestamp
		hour = I64.div_trunc_by(time_of_day, seconds_per_hour)
		minute : DateTime.Timestamp
		minute = I64.div_trunc_by((time_of_day - (hour * seconds_per_hour)), seconds_per_minute)
		second : DateTime.Timestamp
		second = ((time_of_day - (hour * seconds_per_hour)) - (minute * seconds_per_minute))
		(match days_to_ymd(days) {
			MkTup3(y, m, d) => DateTime.DateTime.{ year: y, month: m, day: d, hour: hour, minute: minute, second: second }
		})
	})

	days_to_ymd : I64 -> Tuple.Tup3(I64, I64, I64)
	days_to_ymd = |days| days_to_year(days, 1970)

	days_to_year : I64, I64 -> Tuple.Tup3(I64, I64, I64)
	days_to_year = |remaining, year| ({
		days_in_y : I64
		days_in_y = (if is_leap_year(year) { 366 } else { 365 })
		(if (remaining < days_in_y) { days_to_month(remaining, year, 1) } else { days_to_year((remaining - days_in_y), (year + 1)) })
	})

	days_to_month : I64, I64, I64 -> Tuple.Tup3(I64, I64, I64)
	days_to_month = |remaining, year, month| (if (month > 12) { MkTup3((year + 1), 1, (remaining + 1)) } else { ({
		dim : I64
		dim = days_in_month(year, month)
		(if (remaining < dim) { MkTup3(year, month, (remaining + 1)) } else { days_to_month((remaining - dim), year, (month + 1)) })
	}) })

	is_leap_year : I64 -> Bool
	is_leap_year = |y| (if ((I64.div_trunc_by(y, 400) * 400) == y) { True } else { (if ((I64.div_trunc_by(y, 100) * 100) == y) { False } else { ((I64.div_trunc_by(y, 4) * 4) == y) }) })

	days_in_month : I64, I64 -> I64
	days_in_month = |year, m| (if (m == 1) { 31 } else { (if (m == 2) { (if is_leap_year(year) { 29 } else { 28 }) } else { (if (m == 3) { 31 } else { (if (m == 4) { 30 } else { (if (m == 5) { 31 } else { (if (m == 6) { 30 } else { (if (m == 7) { 31 } else { (if (m == 8) { 31 } else { (if (m == 9) { 30 } else { (if (m == 10) { 31 } else { (if (m == 11) { 30 } else { 31 }) }) }) }) }) }) }) }) }) }) })

	datetime_to_unix : DateTime.DateTime -> I64
	datetime_to_unix = |dt| ({
		days : I64
		days = ymd_to_days(dt.year, dt.month, dt.day)
		((((days * seconds_per_day) + (dt.hour * seconds_per_hour)) + (dt.minute * seconds_per_minute)) + dt.second)
	})

	ymd_to_days : I64, I64, I64 -> I64
	ymd_to_days = |year, month, day| ({
		year_days : I64
		year_days = count_year_days(1970, year, 0)
		month_days : I64
		month_days = count_month_days(year, 1, month, 0)
		(((year_days + month_days) + day) - 1)
	})

	count_year_days : I64, I64, I64 -> I64
	count_year_days = |from, to, acc| (if (from >= to) { acc } else { count_year_days((from + 1), to, (acc + (if is_leap_year(from) { 366 } else { 365 }))) })

	count_month_days : I64, I64, I64, I64 -> I64
	count_month_days = |year, from, to, acc| (if (from >= to) { acc } else { count_month_days(year, (from + 1), to, (acc + days_in_month(year, from))) })

	day_of_week : I64 -> I64
	day_of_week = |unix_ts| ({
		days : I64
		days = I64.div_trunc_by(unix_ts, seconds_per_day)
		((((I64.div_trunc_by((days + 4), 7) * 7) - days) - 4) + (days + 4))
	})

	day_of_week_name : I64 -> CceText
	day_of_week_name = |dow| (if (dow == 0) { "Thu" } else { (if (dow == 1) { "Fri" } else { (if (dow == 2) { "Sat" } else { (if (dow == 3) { "Sun" } else { (if (dow == 4) { "Mon" } else { (if (dow == 5) { "Tue" } else { (if (dow == 6) { "Wed" } else { "?" }) }) }) }) }) }) })

	format_datetime : DateTime.DateTime -> CceText
	format_datetime = |dt| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(pad4(dt.year), "-"), pad2(dt.month)), "-"), pad2(dt.day)), "T"), pad2(dt.hour)), ":"), pad2(dt.minute)), ":"), pad2(dt.second)), "Z")

	format_date : DateTime.DateTime -> CceText
	format_date = |dt| CceText.concat(CceText.concat(CceText.concat(CceText.concat(pad4(dt.year), "-"), pad2(dt.month)), "-"), pad2(dt.day))

	format_time : DateTime.DateTime -> CceText
	format_time = |dt| CceText.concat(CceText.concat(CceText.concat(CceText.concat(pad2(dt.hour), ":"), pad2(dt.minute)), ":"), pad2(dt.second))

	pad2 : I64 -> CceText
	pad2 = |n| (if (n < 10) { CceText.concat("0", CceText.show_int(n)) } else { CceText.show_int(n) })

	pad4 : I64 -> CceText
	pad4 = |n| (if (n < 10) { CceText.concat("000", CceText.show_int(n)) } else { (if (n < 100) { CceText.concat("00", CceText.show_int(n)) } else { (if (n < 1000) { CceText.concat("0", CceText.show_int(n)) } else { CceText.show_int(n) }) }) })

	datetime_add_seconds : DateTime.Timestamp, DateTime.Elapsed -> DateTime.Timestamp
	datetime_add_seconds = |ts, secs| (ts + secs)

	datetime_add_hours : DateTime.Timestamp, I64 -> DateTime.Timestamp
	datetime_add_hours = |ts, hours| (ts + (hours * seconds_per_hour))

	datetime_add_days : DateTime.Timestamp, I64 -> DateTime.Timestamp
	datetime_add_days = |ts, days| (ts + (days * seconds_per_day))

	datetime_diff : DateTime.Timestamp, DateTime.Timestamp -> DateTime.Elapsed
	datetime_diff = |a, b| (a - b)

	month_name : I64 -> CceText
	month_name = |m| (if (m == 1) { "Jan" } else { (if (m == 2) { "Feb" } else { (if (m == 3) { "Mar" } else { (if (m == 4) { "Apr" } else { (if (m == 5) { "May" } else { (if (m == 6) { "Jun" } else { (if (m == 7) { "Jul" } else { (if (m == 8) { "Aug" } else { (if (m == 9) { "Sep" } else { (if (m == 10) { "Oct" } else { (if (m == 11) { "Nov" } else { (if (m == 12) { "Dec" } else { "?" }) }) }) }) }) }) }) }) }) }) }) })
}
