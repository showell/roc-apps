# Units -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Units :: [].{
	Duration : I64
	LongDuration : I64
	Length : I64
	AstroDistance : I64
	MicroLength : I64
	Mass : I64
	Kelvin : I64
	Celsius : I64
	Fahrenheit : I64
	Speed : I64
	DataSize : I64
	DataRate : I64
	Frequency : I64
	Energy : I64
	Force : I64
	Power : I64
	Pressure : I64
	Voltage : I64
	Current : I64
	Resistance : I64
	Capacitance : I64
	Angle : I64
	ParticleEnergy : I64
	CrossSection : I64
	NeutronFlux : I64
	Fluence : I64
	DoseEquivalent : I64
	AbsorbedDose : I64
	Radioactivity : I64
	MagneticField : I64
	Illuminance : I64
	LuminousFlux : I64
	Concentration : I64
	FlowRate : I64
	BloodPressure : I64
	DoseWeight : I64
	HeartRate : I64
	SpO2 : I64
	BodyTemp : I64

	celsius_to_Kelvin : Units.Celsius -> Units.Kelvin
	celsius_to_Kelvin = |c| (c + 273)

	kelvin_to_Celsius : Units.Kelvin -> Units.Celsius
	kelvin_to_Celsius = |k| (k - 273)

	celsius_to_Fahrenheit : Units.Celsius -> Units.Fahrenheit
	celsius_to_Fahrenheit = |c| (I64.div_trunc_by((c * 9), 5) + 32)

	fahrenheit_to_Celsius : Units.Fahrenheit -> Units.Celsius
	fahrenheit_to_Celsius = |f| I64.div_trunc_by(((f - 32) * 5), 9)

	milliCelsius_to_MilliFahrenheit : Units.BodyTemp -> I64
	milliCelsius_to_MilliFahrenheit = |mc| (I64.div_trunc_by((mc * 9), 5) + 32000)
}
