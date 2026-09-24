# forewords@encode-midi
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@encode-midi.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Encode/Midi OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.Units

# FwdMidiTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

nanosecond : I64 -> Units.Duration
nanosecond = |fv| fv

duration_to_Nanosecond : Units.Duration -> I64
duration_to_Nanosecond = |fv| fv

microsecond : I64 -> Units.Duration
microsecond = |fv| (fv * 1000)

duration_to_Microsecond : Units.Duration -> I64
duration_to_Microsecond = |fv| I64.div_trunc_by(fv, 1000)

millisecond : I64 -> Units.Duration
millisecond = |fv| (fv * 1000000)

duration_to_Millisecond : Units.Duration -> I64
duration_to_Millisecond = |fv| I64.div_trunc_by(fv, 1000000)

second : I64 -> Units.Duration
second = |fv| (fv * 1000000000)

duration_to_Second : Units.Duration -> I64
duration_to_Second = |fv| I64.div_trunc_by(fv, 1000000000)

minute : I64 -> Units.Duration
minute = |fv| (fv * 60000000000)

duration_to_Minute : Units.Duration -> I64
duration_to_Minute = |fv| I64.div_trunc_by(fv, 60000000000)

hour : I64 -> Units.Duration
hour = |fv| (fv * 3600000000000)

duration_to_Hour : Units.Duration -> I64
duration_to_Hour = |fv| I64.div_trunc_by(fv, 3600000000000)

longSecond : I64 -> Units.LongDuration
longSecond = |fv| fv

longDuration_to_LongSecond : Units.LongDuration -> I64
longDuration_to_LongSecond = |fv| fv

longMinute : I64 -> Units.LongDuration
longMinute = |fv| (fv * 60)

longDuration_to_LongMinute : Units.LongDuration -> I64
longDuration_to_LongMinute = |fv| I64.div_trunc_by(fv, 60)

longHour : I64 -> Units.LongDuration
longHour = |fv| (fv * 3600)

longDuration_to_LongHour : Units.LongDuration -> I64
longDuration_to_LongHour = |fv| I64.div_trunc_by(fv, 3600)

day : I64 -> Units.LongDuration
day = |fv| (fv * 86400)

longDuration_to_Day : Units.LongDuration -> I64
longDuration_to_Day = |fv| I64.div_trunc_by(fv, 86400)

week : I64 -> Units.LongDuration
week = |fv| (fv * 604800)

longDuration_to_Week : Units.LongDuration -> I64
longDuration_to_Week = |fv| I64.div_trunc_by(fv, 604800)

month : I64 -> Units.LongDuration
month = |fv| (fv * 2592000)

longDuration_to_Month : Units.LongDuration -> I64
longDuration_to_Month = |fv| I64.div_trunc_by(fv, 2592000)

year : I64 -> Units.LongDuration
year = |fv| (fv * 31557600)

longDuration_to_Year : Units.LongDuration -> I64
longDuration_to_Year = |fv| I64.div_trunc_by(fv, 31557600)

century : I64 -> Units.LongDuration
century = |fv| (fv * 3155760000)

longDuration_to_Century : Units.LongDuration -> I64
longDuration_to_Century = |fv| I64.div_trunc_by(fv, 3155760000)

millimeter : I64 -> Units.Length
millimeter = |fv| fv

length_to_Millimeter : Units.Length -> I64
length_to_Millimeter = |fv| fv

centimeter : I64 -> Units.Length
centimeter = |fv| (fv * 10)

length_to_Centimeter : Units.Length -> I64
length_to_Centimeter = |fv| I64.div_trunc_by(fv, 10)

meter : I64 -> Units.Length
meter = |fv| (fv * 1000)

length_to_Meter : Units.Length -> I64
length_to_Meter = |fv| I64.div_trunc_by(fv, 1000)

kilometer : I64 -> Units.Length
kilometer = |fv| (fv * 1000000)

length_to_Kilometer : Units.Length -> I64
length_to_Kilometer = |fv| I64.div_trunc_by(fv, 1000000)

inch : I64 -> Units.Length
inch = |fv| (fv * 25)

length_to_Inch : Units.Length -> I64
length_to_Inch = |fv| I64.div_trunc_by(fv, 25)

foot : I64 -> Units.Length
foot = |fv| (fv * 305)

length_to_Foot : Units.Length -> I64
length_to_Foot = |fv| I64.div_trunc_by(fv, 305)

yard : I64 -> Units.Length
yard = |fv| (fv * 914)

length_to_Yard : Units.Length -> I64
length_to_Yard = |fv| I64.div_trunc_by(fv, 914)

mile : I64 -> Units.Length
mile = |fv| (fv * 1609344)

length_to_Mile : Units.Length -> I64
length_to_Mile = |fv| I64.div_trunc_by(fv, 1609344)

nauticalMile : I64 -> Units.Length
nauticalMile = |fv| (fv * 1852000)

length_to_NauticalMile : Units.Length -> I64
length_to_NauticalMile = |fv| I64.div_trunc_by(fv, 1852000)

astroKm : I64 -> Units.AstroDistance
astroKm = |fv| fv

astroDistance_to_AstroKm : Units.AstroDistance -> I64
astroDistance_to_AstroKm = |fv| fv

astroMile : I64 -> Units.AstroDistance
astroMile = |fv| fv

astroDistance_to_AstroMile : Units.AstroDistance -> I64
astroDistance_to_AstroMile = |fv| fv

earthRadius : I64 -> Units.AstroDistance
earthRadius = |fv| (fv * 6371)

astroDistance_to_EarthRadius : Units.AstroDistance -> I64
astroDistance_to_EarthRadius = |fv| I64.div_trunc_by(fv, 6371)

lunarDistance : I64 -> Units.AstroDistance
lunarDistance = |fv| (fv * 384400)

astroDistance_to_LunarDistance : Units.AstroDistance -> I64
astroDistance_to_LunarDistance = |fv| I64.div_trunc_by(fv, 384400)

aU : I64 -> Units.AstroDistance
aU = |fv| (fv * 149597871)

astroDistance_to_AU : Units.AstroDistance -> I64
astroDistance_to_AU = |fv| I64.div_trunc_by(fv, 149597871)

lightMinute : I64 -> Units.AstroDistance
lightMinute = |fv| (fv * 17987547)

astroDistance_to_LightMinute : Units.AstroDistance -> I64
astroDistance_to_LightMinute = |fv| I64.div_trunc_by(fv, 17987547)

lightHour : I64 -> Units.AstroDistance
lightHour = |fv| (fv * 1079252849)

astroDistance_to_LightHour : Units.AstroDistance -> I64
astroDistance_to_LightHour = |fv| I64.div_trunc_by(fv, 1079252849)

lightYear : I64 -> Units.AstroDistance
lightYear = |fv| (fv * 9460730472581)

astroDistance_to_LightYear : Units.AstroDistance -> I64
astroDistance_to_LightYear = |fv| I64.div_trunc_by(fv, 9460730472581)

picometer : I64 -> Units.MicroLength
picometer = |fv| fv

microLength_to_Picometer : Units.MicroLength -> I64
microLength_to_Picometer = |fv| fv

angstrom : I64 -> Units.MicroLength
angstrom = |fv| (fv * 100)

microLength_to_Angstrom : Units.MicroLength -> I64
microLength_to_Angstrom = |fv| I64.div_trunc_by(fv, 100)

nanometer : I64 -> Units.MicroLength
nanometer = |fv| (fv * 1000)

microLength_to_Nanometer : Units.MicroLength -> I64
microLength_to_Nanometer = |fv| I64.div_trunc_by(fv, 1000)

micrometer : I64 -> Units.MicroLength
micrometer = |fv| (fv * 1000000)

microLength_to_Micrometer : Units.MicroLength -> I64
microLength_to_Micrometer = |fv| I64.div_trunc_by(fv, 1000000)

microMm : I64 -> Units.MicroLength
microMm = |fv| (fv * 1000000000)

microLength_to_MicroMm : Units.MicroLength -> I64
microLength_to_MicroMm = |fv| I64.div_trunc_by(fv, 1000000000)

milligram : I64 -> Units.Mass
milligram = |fv| fv

mass_to_Milligram : Units.Mass -> I64
mass_to_Milligram = |fv| fv

gram : I64 -> Units.Mass
gram = |fv| (fv * 1000)

mass_to_Gram : Units.Mass -> I64
mass_to_Gram = |fv| I64.div_trunc_by(fv, 1000)

kilogram : I64 -> Units.Mass
kilogram = |fv| (fv * 1000000)

mass_to_Kilogram : Units.Mass -> I64
mass_to_Kilogram = |fv| I64.div_trunc_by(fv, 1000000)

metricTon : I64 -> Units.Mass
metricTon = |fv| (fv * 1000000000)

mass_to_MetricTon : Units.Mass -> I64
mass_to_MetricTon = |fv| I64.div_trunc_by(fv, 1000000000)

ounce : I64 -> Units.Mass
ounce = |fv| (fv * 28350)

mass_to_Ounce : Units.Mass -> I64
mass_to_Ounce = |fv| I64.div_trunc_by(fv, 28350)

pound : I64 -> Units.Mass
pound = |fv| (fv * 453592)

mass_to_Pound : Units.Mass -> I64
mass_to_Pound = |fv| I64.div_trunc_by(fv, 453592)

stone : I64 -> Units.Mass
stone = |fv| (fv * 6350293)

mass_to_Stone : Units.Mass -> I64
mass_to_Stone = |fv| I64.div_trunc_by(fv, 6350293)

mmPerSec : I64 -> Units.Speed
mmPerSec = |fv| fv

speed_to_MmPerSec : Units.Speed -> I64
speed_to_MmPerSec = |fv| fv

meterPerSec : I64 -> Units.Speed
meterPerSec = |fv| (fv * 1000)

speed_to_MeterPerSec : Units.Speed -> I64
speed_to_MeterPerSec = |fv| I64.div_trunc_by(fv, 1000)

kmPerHour : I64 -> Units.Speed
kmPerHour = |fv| (fv * 278)

speed_to_KmPerHour : Units.Speed -> I64
speed_to_KmPerHour = |fv| I64.div_trunc_by(fv, 278)

milePerHour : I64 -> Units.Speed
milePerHour = |fv| (fv * 447)

speed_to_MilePerHour : Units.Speed -> I64
speed_to_MilePerHour = |fv| I64.div_trunc_by(fv, 447)

knot : I64 -> Units.Speed
knot = |fv| (fv * 514)

speed_to_Knot : Units.Speed -> I64
speed_to_Knot = |fv| I64.div_trunc_by(fv, 514)

speedOfSound : I64 -> Units.Speed
speedOfSound = |fv| (fv * 343000)

speed_to_SpeedOfSound : Units.Speed -> I64
speed_to_SpeedOfSound = |fv| I64.div_trunc_by(fv, 343000)

dataByte : I64 -> Units.DataSize
dataByte = |fv| fv

dataSize_to_DataByte : Units.DataSize -> I64
dataSize_to_DataByte = |fv| fv

kilobyte : I64 -> Units.DataSize
kilobyte = |fv| (fv * 1024)

dataSize_to_Kilobyte : Units.DataSize -> I64
dataSize_to_Kilobyte = |fv| I64.div_trunc_by(fv, 1024)

megabyte : I64 -> Units.DataSize
megabyte = |fv| (fv * 1048576)

dataSize_to_Megabyte : Units.DataSize -> I64
dataSize_to_Megabyte = |fv| I64.div_trunc_by(fv, 1048576)

gigabyte : I64 -> Units.DataSize
gigabyte = |fv| (fv * 1073741824)

dataSize_to_Gigabyte : Units.DataSize -> I64
dataSize_to_Gigabyte = |fv| I64.div_trunc_by(fv, 1073741824)

terabyte : I64 -> Units.DataSize
terabyte = |fv| (fv * 1099511627776)

dataSize_to_Terabyte : Units.DataSize -> I64
dataSize_to_Terabyte = |fv| I64.div_trunc_by(fv, 1099511627776)

bitPerSec : I64 -> Units.DataRate
bitPerSec = |fv| fv

dataRate_to_BitPerSec : Units.DataRate -> I64
dataRate_to_BitPerSec = |fv| fv

kilobitPerSec : I64 -> Units.DataRate
kilobitPerSec = |fv| (fv * 1000)

dataRate_to_KilobitPerSec : Units.DataRate -> I64
dataRate_to_KilobitPerSec = |fv| I64.div_trunc_by(fv, 1000)

megabitPerSec : I64 -> Units.DataRate
megabitPerSec = |fv| (fv * 1000000)

dataRate_to_MegabitPerSec : Units.DataRate -> I64
dataRate_to_MegabitPerSec = |fv| I64.div_trunc_by(fv, 1000000)

gigabitPerSec : I64 -> Units.DataRate
gigabitPerSec = |fv| (fv * 1000000000)

dataRate_to_GigabitPerSec : Units.DataRate -> I64
dataRate_to_GigabitPerSec = |fv| I64.div_trunc_by(fv, 1000000000)

bytePerSec : I64 -> Units.DataRate
bytePerSec = |fv| (fv * 8)

dataRate_to_BytePerSec : Units.DataRate -> I64
dataRate_to_BytePerSec = |fv| I64.div_trunc_by(fv, 8)

megabytePerSec : I64 -> Units.DataRate
megabytePerSec = |fv| (fv * 8388608)

dataRate_to_MegabytePerSec : Units.DataRate -> I64
dataRate_to_MegabytePerSec = |fv| I64.div_trunc_by(fv, 8388608)

hertz : I64 -> Units.Frequency
hertz = |fv| fv

frequency_to_Hertz : Units.Frequency -> I64
frequency_to_Hertz = |fv| fv

kilohertz : I64 -> Units.Frequency
kilohertz = |fv| (fv * 1000)

frequency_to_Kilohertz : Units.Frequency -> I64
frequency_to_Kilohertz = |fv| I64.div_trunc_by(fv, 1000)

megahertz : I64 -> Units.Frequency
megahertz = |fv| (fv * 1000000)

frequency_to_Megahertz : Units.Frequency -> I64
frequency_to_Megahertz = |fv| I64.div_trunc_by(fv, 1000000)

gigahertz : I64 -> Units.Frequency
gigahertz = |fv| (fv * 1000000000)

frequency_to_Gigahertz : Units.Frequency -> I64
frequency_to_Gigahertz = |fv| I64.div_trunc_by(fv, 1000000000)

terahertz : I64 -> Units.Frequency
terahertz = |fv| (fv * 1000000000000)

frequency_to_Terahertz : Units.Frequency -> I64
frequency_to_Terahertz = |fv| I64.div_trunc_by(fv, 1000000000000)

millijoule : I64 -> Units.Energy
millijoule = |fv| fv

energy_to_Millijoule : Units.Energy -> I64
energy_to_Millijoule = |fv| fv

joule : I64 -> Units.Energy
joule = |fv| (fv * 1000)

energy_to_Joule : Units.Energy -> I64
energy_to_Joule = |fv| I64.div_trunc_by(fv, 1000)

kilojoule : I64 -> Units.Energy
kilojoule = |fv| (fv * 1000000)

energy_to_Kilojoule : Units.Energy -> I64
energy_to_Kilojoule = |fv| I64.div_trunc_by(fv, 1000000)

calorie : I64 -> Units.Energy
calorie = |fv| (fv * 4184)

energy_to_Calorie : Units.Energy -> I64
energy_to_Calorie = |fv| I64.div_trunc_by(fv, 4184)

kilocalorie : I64 -> Units.Energy
kilocalorie = |fv| (fv * 4184000)

energy_to_Kilocalorie : Units.Energy -> I64
energy_to_Kilocalorie = |fv| I64.div_trunc_by(fv, 4184000)

bTU : I64 -> Units.Energy
bTU = |fv| (fv * 1055060)

energy_to_BTU : Units.Energy -> I64
energy_to_BTU = |fv| I64.div_trunc_by(fv, 1055060)

kilowattHour : I64 -> Units.Energy
kilowattHour = |fv| (fv * 3600000000)

energy_to_KilowattHour : Units.Energy -> I64
energy_to_KilowattHour = |fv| I64.div_trunc_by(fv, 3600000000)

millinewton : I64 -> Units.Force
millinewton = |fv| fv

force_to_Millinewton : Units.Force -> I64
force_to_Millinewton = |fv| fv

newton : I64 -> Units.Force
newton = |fv| (fv * 1000)

force_to_Newton : Units.Force -> I64
force_to_Newton = |fv| I64.div_trunc_by(fv, 1000)

kilonewton : I64 -> Units.Force
kilonewton = |fv| (fv * 1000000)

force_to_Kilonewton : Units.Force -> I64
force_to_Kilonewton = |fv| I64.div_trunc_by(fv, 1000000)

poundForce : I64 -> Units.Force
poundForce = |fv| (fv * 4448)

force_to_PoundForce : Units.Force -> I64
force_to_PoundForce = |fv| I64.div_trunc_by(fv, 4448)

milliwatt : I64 -> Units.Power
milliwatt = |fv| fv

power_to_Milliwatt : Units.Power -> I64
power_to_Milliwatt = |fv| fv

watt : I64 -> Units.Power
watt = |fv| (fv * 1000)

power_to_Watt : Units.Power -> I64
power_to_Watt = |fv| I64.div_trunc_by(fv, 1000)

kilowatt : I64 -> Units.Power
kilowatt = |fv| (fv * 1000000)

power_to_Kilowatt : Units.Power -> I64
power_to_Kilowatt = |fv| I64.div_trunc_by(fv, 1000000)

megawatt : I64 -> Units.Power
megawatt = |fv| (fv * 1000000000)

power_to_Megawatt : Units.Power -> I64
power_to_Megawatt = |fv| I64.div_trunc_by(fv, 1000000000)

gigawatt : I64 -> Units.Power
gigawatt = |fv| (fv * 1000000000000)

power_to_Gigawatt : Units.Power -> I64
power_to_Gigawatt = |fv| I64.div_trunc_by(fv, 1000000000000)

horsepower : I64 -> Units.Power
horsepower = |fv| (fv * 745700)

power_to_Horsepower : Units.Power -> I64
power_to_Horsepower = |fv| I64.div_trunc_by(fv, 745700)

pascal : I64 -> Units.Pressure
pascal = |fv| fv

pressure_to_Pascal : Units.Pressure -> I64
pressure_to_Pascal = |fv| fv

kilopascal : I64 -> Units.Pressure
kilopascal = |fv| (fv * 1000)

pressure_to_Kilopascal : Units.Pressure -> I64
pressure_to_Kilopascal = |fv| I64.div_trunc_by(fv, 1000)

pSI : I64 -> Units.Pressure
pSI = |fv| (fv * 6895)

pressure_to_PSI : Units.Pressure -> I64
pressure_to_PSI = |fv| I64.div_trunc_by(fv, 6895)

torr : I64 -> Units.Pressure
torr = |fv| (fv * 133)

pressure_to_Torr : Units.Pressure -> I64
pressure_to_Torr = |fv| I64.div_trunc_by(fv, 133)

bar : I64 -> Units.Pressure
bar = |fv| (fv * 100000)

pressure_to_Bar : Units.Pressure -> I64
pressure_to_Bar = |fv| I64.div_trunc_by(fv, 100000)

atmosphere : I64 -> Units.Pressure
atmosphere = |fv| (fv * 101325)

pressure_to_Atmosphere : Units.Pressure -> I64
pressure_to_Atmosphere = |fv| I64.div_trunc_by(fv, 101325)

microvolt : I64 -> Units.Voltage
microvolt = |fv| fv

voltage_to_Microvolt : Units.Voltage -> I64
voltage_to_Microvolt = |fv| fv

millivolt : I64 -> Units.Voltage
millivolt = |fv| (fv * 1000)

voltage_to_Millivolt : Units.Voltage -> I64
voltage_to_Millivolt = |fv| I64.div_trunc_by(fv, 1000)

volt : I64 -> Units.Voltage
volt = |fv| (fv * 1000000)

voltage_to_Volt : Units.Voltage -> I64
voltage_to_Volt = |fv| I64.div_trunc_by(fv, 1000000)

kilovolt : I64 -> Units.Voltage
kilovolt = |fv| (fv * 1000000000)

voltage_to_Kilovolt : Units.Voltage -> I64
voltage_to_Kilovolt = |fv| I64.div_trunc_by(fv, 1000000000)

microamp : I64 -> Units.Current
microamp = |fv| fv

current_to_Microamp : Units.Current -> I64
current_to_Microamp = |fv| fv

milliamp : I64 -> Units.Current
milliamp = |fv| (fv * 1000)

current_to_Milliamp : Units.Current -> I64
current_to_Milliamp = |fv| I64.div_trunc_by(fv, 1000)

amp : I64 -> Units.Current
amp = |fv| (fv * 1000000)

current_to_Amp : Units.Current -> I64
current_to_Amp = |fv| I64.div_trunc_by(fv, 1000000)

milliohm : I64 -> Units.Resistance
milliohm = |fv| fv

resistance_to_Milliohm : Units.Resistance -> I64
resistance_to_Milliohm = |fv| fv

ohm : I64 -> Units.Resistance
ohm = |fv| (fv * 1000)

resistance_to_Ohm : Units.Resistance -> I64
resistance_to_Ohm = |fv| I64.div_trunc_by(fv, 1000)

kilohm : I64 -> Units.Resistance
kilohm = |fv| (fv * 1000000)

resistance_to_Kilohm : Units.Resistance -> I64
resistance_to_Kilohm = |fv| I64.div_trunc_by(fv, 1000000)

megohm : I64 -> Units.Resistance
megohm = |fv| (fv * 1000000000)

resistance_to_Megohm : Units.Resistance -> I64
resistance_to_Megohm = |fv| I64.div_trunc_by(fv, 1000000000)

picofarad : I64 -> Units.Capacitance
picofarad = |fv| fv

capacitance_to_Picofarad : Units.Capacitance -> I64
capacitance_to_Picofarad = |fv| fv

nanofarad : I64 -> Units.Capacitance
nanofarad = |fv| (fv * 1000)

capacitance_to_Nanofarad : Units.Capacitance -> I64
capacitance_to_Nanofarad = |fv| I64.div_trunc_by(fv, 1000)

microfarad : I64 -> Units.Capacitance
microfarad = |fv| (fv * 1000000)

capacitance_to_Microfarad : Units.Capacitance -> I64
capacitance_to_Microfarad = |fv| I64.div_trunc_by(fv, 1000000)

arcsecond : I64 -> Units.Angle
arcsecond = |fv| fv

angle_to_Arcsecond : Units.Angle -> I64
angle_to_Arcsecond = |fv| fv

arcminute : I64 -> Units.Angle
arcminute = |fv| (fv * 60)

angle_to_Arcminute : Units.Angle -> I64
angle_to_Arcminute = |fv| I64.div_trunc_by(fv, 60)

degree : I64 -> Units.Angle
degree = |fv| (fv * 3600)

angle_to_Degree : Units.Angle -> I64
angle_to_Degree = |fv| I64.div_trunc_by(fv, 3600)

rightAngle : I64 -> Units.Angle
rightAngle = |fv| (fv * 324000)

angle_to_RightAngle : Units.Angle -> I64
angle_to_RightAngle = |fv| I64.div_trunc_by(fv, 324000)

fullCircle : I64 -> Units.Angle
fullCircle = |fv| (fv * 1296000)

angle_to_FullCircle : Units.Angle -> I64
angle_to_FullCircle = |fv| I64.div_trunc_by(fv, 1296000)

gradian : I64 -> Units.Angle
gradian = |fv| (fv * 3240)

angle_to_Gradian : Units.Angle -> I64
angle_to_Gradian = |fv| I64.div_trunc_by(fv, 3240)

electronVolt : I64 -> Units.ParticleEnergy
electronVolt = |fv| fv

particleEnergy_to_ElectronVolt : Units.ParticleEnergy -> I64
particleEnergy_to_ElectronVolt = |fv| fv

keV : I64 -> Units.ParticleEnergy
keV = |fv| (fv * 1000)

particleEnergy_to_KeV : Units.ParticleEnergy -> I64
particleEnergy_to_KeV = |fv| I64.div_trunc_by(fv, 1000)

meV : I64 -> Units.ParticleEnergy
meV = |fv| (fv * 1000000)

particleEnergy_to_MeV : Units.ParticleEnergy -> I64
particleEnergy_to_MeV = |fv| I64.div_trunc_by(fv, 1000000)

geV : I64 -> Units.ParticleEnergy
geV = |fv| (fv * 1000000000)

particleEnergy_to_GeV : Units.ParticleEnergy -> I64
particleEnergy_to_GeV = |fv| I64.div_trunc_by(fv, 1000000000)

teV : I64 -> Units.ParticleEnergy
teV = |fv| (fv * 1000000000000)

particleEnergy_to_TeV : Units.ParticleEnergy -> I64
particleEnergy_to_TeV = |fv| I64.div_trunc_by(fv, 1000000000000)

femtobarn : I64 -> Units.CrossSection
femtobarn = |fv| fv

crossSection_to_Femtobarn : Units.CrossSection -> I64
crossSection_to_Femtobarn = |fv| fv

picobarn : I64 -> Units.CrossSection
picobarn = |fv| (fv * 1000)

crossSection_to_Picobarn : Units.CrossSection -> I64
crossSection_to_Picobarn = |fv| I64.div_trunc_by(fv, 1000)

nanobarn : I64 -> Units.CrossSection
nanobarn = |fv| (fv * 1000000)

crossSection_to_Nanobarn : Units.CrossSection -> I64
crossSection_to_Nanobarn = |fv| I64.div_trunc_by(fv, 1000000)

microbarn : I64 -> Units.CrossSection
microbarn = |fv| (fv * 1000000000)

crossSection_to_Microbarn : Units.CrossSection -> I64
crossSection_to_Microbarn = |fv| I64.div_trunc_by(fv, 1000000000)

millibarn : I64 -> Units.CrossSection
millibarn = |fv| (fv * 1000000000000)

crossSection_to_Millibarn : Units.CrossSection -> I64
crossSection_to_Millibarn = |fv| I64.div_trunc_by(fv, 1000000000000)

barn : I64 -> Units.CrossSection
barn = |fv| (fv * 1000000000000000)

crossSection_to_Barn : Units.CrossSection -> I64
crossSection_to_Barn = |fv| I64.div_trunc_by(fv, 1000000000000000)

kilobarn : I64 -> Units.CrossSection
kilobarn = |fv| (fv * 1000000000000000000)

crossSection_to_Kilobarn : Units.CrossSection -> I64
crossSection_to_Kilobarn = |fv| I64.div_trunc_by(fv, 1000000000000000000)

microsievert : I64 -> Units.DoseEquivalent
microsievert = |fv| fv

doseEquivalent_to_Microsievert : Units.DoseEquivalent -> I64
doseEquivalent_to_Microsievert = |fv| fv

millisievert : I64 -> Units.DoseEquivalent
millisievert = |fv| (fv * 1000)

doseEquivalent_to_Millisievert : Units.DoseEquivalent -> I64
doseEquivalent_to_Millisievert = |fv| I64.div_trunc_by(fv, 1000)

sievert : I64 -> Units.DoseEquivalent
sievert = |fv| (fv * 1000000)

doseEquivalent_to_Sievert : Units.DoseEquivalent -> I64
doseEquivalent_to_Sievert = |fv| I64.div_trunc_by(fv, 1000000)

microgray : I64 -> Units.AbsorbedDose
microgray = |fv| fv

absorbedDose_to_Microgray : Units.AbsorbedDose -> I64
absorbedDose_to_Microgray = |fv| fv

milligray : I64 -> Units.AbsorbedDose
milligray = |fv| (fv * 1000)

absorbedDose_to_Milligray : Units.AbsorbedDose -> I64
absorbedDose_to_Milligray = |fv| I64.div_trunc_by(fv, 1000)

gray : I64 -> Units.AbsorbedDose
gray = |fv| (fv * 1000000)

absorbedDose_to_Gray : Units.AbsorbedDose -> I64
absorbedDose_to_Gray = |fv| I64.div_trunc_by(fv, 1000000)

becquerel : I64 -> Units.Radioactivity
becquerel = |fv| fv

radioactivity_to_Becquerel : Units.Radioactivity -> I64
radioactivity_to_Becquerel = |fv| fv

kilobecquerel : I64 -> Units.Radioactivity
kilobecquerel = |fv| (fv * 1000)

radioactivity_to_Kilobecquerel : Units.Radioactivity -> I64
radioactivity_to_Kilobecquerel = |fv| I64.div_trunc_by(fv, 1000)

megabecquerel : I64 -> Units.Radioactivity
megabecquerel = |fv| (fv * 1000000)

radioactivity_to_Megabecquerel : Units.Radioactivity -> I64
radioactivity_to_Megabecquerel = |fv| I64.div_trunc_by(fv, 1000000)

gigabecquerel : I64 -> Units.Radioactivity
gigabecquerel = |fv| (fv * 1000000000)

radioactivity_to_Gigabecquerel : Units.Radioactivity -> I64
radioactivity_to_Gigabecquerel = |fv| I64.div_trunc_by(fv, 1000000000)

curie : I64 -> Units.Radioactivity
curie = |fv| (fv * 37000000000)

radioactivity_to_Curie : Units.Radioactivity -> I64
radioactivity_to_Curie = |fv| I64.div_trunc_by(fv, 37000000000)

microtesla : I64 -> Units.MagneticField
microtesla = |fv| fv

magneticField_to_Microtesla : Units.MagneticField -> I64
magneticField_to_Microtesla = |fv| fv

millitesla : I64 -> Units.MagneticField
millitesla = |fv| (fv * 1000)

magneticField_to_Millitesla : Units.MagneticField -> I64
magneticField_to_Millitesla = |fv| I64.div_trunc_by(fv, 1000)

tesla : I64 -> Units.MagneticField
tesla = |fv| (fv * 1000000)

magneticField_to_Tesla : Units.MagneticField -> I64
magneticField_to_Tesla = |fv| I64.div_trunc_by(fv, 1000000)

gauss : I64 -> Units.MagneticField
gauss = |fv| (fv * 100)

magneticField_to_Gauss : Units.MagneticField -> I64
magneticField_to_Gauss = |fv| I64.div_trunc_by(fv, 100)

lux : I64 -> Units.Illuminance
lux = |fv| fv

illuminance_to_Lux : Units.Illuminance -> I64
illuminance_to_Lux = |fv| fv

kilolux : I64 -> Units.Illuminance
kilolux = |fv| (fv * 1000)

illuminance_to_Kilolux : Units.Illuminance -> I64
illuminance_to_Kilolux = |fv| I64.div_trunc_by(fv, 1000)

footCandle : I64 -> Units.Illuminance
footCandle = |fv| (fv * 10)

illuminance_to_FootCandle : Units.Illuminance -> I64
illuminance_to_FootCandle = |fv| I64.div_trunc_by(fv, 10)

lumen : I64 -> Units.LuminousFlux
lumen = |fv| fv

luminousFlux_to_Lumen : Units.LuminousFlux -> I64
luminousFlux_to_Lumen = |fv| fv

kilolumen : I64 -> Units.LuminousFlux
kilolumen = |fv| (fv * 1000)

luminousFlux_to_Kilolumen : Units.LuminousFlux -> I64
luminousFlux_to_Kilolumen = |fv| I64.div_trunc_by(fv, 1000)

nanogramPerLiter : I64 -> Units.Concentration
nanogramPerLiter = |fv| fv

concentration_to_NanogramPerLiter : Units.Concentration -> I64
concentration_to_NanogramPerLiter = |fv| fv

microgramPerLiter : I64 -> Units.Concentration
microgramPerLiter = |fv| (fv * 1000)

concentration_to_MicrogramPerLiter : Units.Concentration -> I64
concentration_to_MicrogramPerLiter = |fv| I64.div_trunc_by(fv, 1000)

milligramPerLiter : I64 -> Units.Concentration
milligramPerLiter = |fv| (fv * 1000000)

concentration_to_MilligramPerLiter : Units.Concentration -> I64
concentration_to_MilligramPerLiter = |fv| I64.div_trunc_by(fv, 1000000)

gramPerLiter : I64 -> Units.Concentration
gramPerLiter = |fv| (fv * 1000000000)

concentration_to_GramPerLiter : Units.Concentration -> I64
concentration_to_GramPerLiter = |fv| I64.div_trunc_by(fv, 1000000000)

nanogramPerML : I64 -> Units.Concentration
nanogramPerML = |fv| (fv * 1000)

concentration_to_NanogramPerML : Units.Concentration -> I64
concentration_to_NanogramPerML = |fv| I64.div_trunc_by(fv, 1000)

microgramPerDL : I64 -> Units.Concentration
microgramPerDL = |fv| (fv * 10000)

concentration_to_MicrogramPerDL : Units.Concentration -> I64
concentration_to_MicrogramPerDL = |fv| I64.div_trunc_by(fv, 10000)

milligramPerDL : I64 -> Units.Concentration
milligramPerDL = |fv| (fv * 10000000)

concentration_to_MilligramPerDL : Units.Concentration -> I64
concentration_to_MilligramPerDL = |fv| I64.div_trunc_by(fv, 10000000)

microlitPerMin : I64 -> Units.FlowRate
microlitPerMin = |fv| fv

flowRate_to_MicrolitPerMin : Units.FlowRate -> I64
flowRate_to_MicrolitPerMin = |fv| fv

millilitPerMin : I64 -> Units.FlowRate
millilitPerMin = |fv| (fv * 1000)

flowRate_to_MillilitPerMin : Units.FlowRate -> I64
flowRate_to_MillilitPerMin = |fv| I64.div_trunc_by(fv, 1000)

literPerMin : I64 -> Units.FlowRate
literPerMin = |fv| (fv * 1000000)

flowRate_to_LiterPerMin : Units.FlowRate -> I64
flowRate_to_LiterPerMin = |fv| I64.div_trunc_by(fv, 1000000)

millilitPerHour : I64 -> Units.FlowRate
millilitPerHour = |fv| (fv * 16)

flowRate_to_MillilitPerHour : Units.FlowRate -> I64
flowRate_to_MillilitPerHour = |fv| I64.div_trunc_by(fv, 16)

literPerHour : I64 -> Units.FlowRate
literPerHour = |fv| (fv * 16667)

flowRate_to_LiterPerHour : Units.FlowRate -> I64
flowRate_to_LiterPerHour = |fv| I64.div_trunc_by(fv, 16667)

mmHg : I64 -> Units.BloodPressure
mmHg = |fv| fv

bloodPressure_to_MmHg : Units.BloodPressure -> I64
bloodPressure_to_MmHg = |fv| fv

bpKilopascal : I64 -> Units.BloodPressure
bpKilopascal = |fv| (fv * 7)

bloodPressure_to_BpKilopascal : Units.BloodPressure -> I64
bloodPressure_to_BpKilopascal = |fv| I64.div_trunc_by(fv, 7)

doseMicrogram : I64 -> Units.DoseWeight
doseMicrogram = |fv| fv

doseWeight_to_DoseMicrogram : Units.DoseWeight -> I64
doseWeight_to_DoseMicrogram = |fv| fv

doseMilligram : I64 -> Units.DoseWeight
doseMilligram = |fv| (fv * 1000)

doseWeight_to_DoseMilligram : Units.DoseWeight -> I64
doseWeight_to_DoseMilligram = |fv| I64.div_trunc_by(fv, 1000)

doseGram : I64 -> Units.DoseWeight
doseGram = |fv| (fv * 1000000)

doseWeight_to_DoseGram : Units.DoseWeight -> I64
doseWeight_to_DoseGram = |fv| I64.div_trunc_by(fv, 1000000)

internationalUnit : I64 -> Units.DoseWeight
internationalUnit = |fv| fv

doseWeight_to_InternationalUnit : Units.DoseWeight -> I64
doseWeight_to_InternationalUnit = |fv| fv

milliCelsius : I64 -> Units.BodyTemp
milliCelsius = |fv| fv

bodyTemp_to_MilliCelsius : Units.BodyTemp -> I64
bodyTemp_to_MilliCelsius = |fv| fv

deciCelsius : I64 -> Units.BodyTemp
deciCelsius = |fv| (fv * 100)

bodyTemp_to_DeciCelsius : Units.BodyTemp -> I64
bodyTemp_to_DeciCelsius = |fv| I64.div_trunc_by(fv, 100)

celsiusBody : I64 -> Units.BodyTemp
celsiusBody = |fv| (fv * 1000)

bodyTemp_to_CelsiusBody : Units.BodyTemp -> I64
bodyTemp_to_CelsiusBody = |fv| I64.div_trunc_by(fv, 1000)

# --- Entry ---

main! = |_args| {
	line!(Text.printed("Encode/Midi OK"))
	Ok({})
}
