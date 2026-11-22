Distance :: F64.{
	metres : F64 -> Distance
	metres = |metres| Distance.(metres)

	to_metres : Distance -> F64
	to_metres = |Distance.(amount)| amount
}
