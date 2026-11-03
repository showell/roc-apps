## Safari's angles, in radians, as two types. A bearing is a direction in
## the world: 0 is north, and a bearing grows to the rider's right. A turn is
## the angle between two directions, such as how far a range reaches either
## side of its middle. A turn added to a bearing gives a bearing, and two
## bearings give the turn between them, but two bearings can't be added. Each
## operation does the plain float arithmetic its name says, so code moved onto
## these types computes exactly what it did before.
import lib.Trig

Angle :: [].{

	Bearing := F64.{

		radians : F64 -> Angle.Bearing
		radians = |r| Angle.Bearing.(r)

		to_radians : Angle.Bearing -> F64
		to_radians = |Angle.Bearing.(r)| r

		## The bearing `turn` to the right of this one.
		plus : Angle.Bearing, Angle.Turn -> Angle.Bearing
		plus = |Angle.Bearing.(b), Angle.Turn.(t)| Angle.Bearing.(b + t)

		## The shortest turn from `from` round to this bearing, between minus
		## and plus a half turn.
		turn_from : Angle.Bearing, Angle.Bearing -> Angle.Turn
		turn_from = |Angle.Bearing.(b), Angle.Bearing.(from)| Angle.Turn.(Trig.wrap(b - from, 64))

		## The shortest turn from north round to this bearing.
		turn_from_north : Angle.Bearing -> Angle.Turn
		turn_from_north = |Angle.Bearing.(b)| Angle.Turn.(Trig.wrap(b, 64))

		## Whether this bearing is further right than `other`, read without
		## going round: for a sweep across a stretch of bearings.
		is_gt : Angle.Bearing, Angle.Bearing -> Bool
		is_gt = |Angle.Bearing.(b), Angle.Bearing.(other)| b > other

		is_eq : _
	}

	Turn := F64.{

		radians : F64 -> Angle.Turn
		radians = |r| Angle.Turn.(r)

		to_radians : Angle.Turn -> F64
		to_radians = |Angle.Turn.(r)| r

		## How many of `whole` this turn is: negative for a turn to the left.
		fraction_of : Angle.Turn, Angle.Turn -> F64
		fraction_of = |Angle.Turn.(t), Angle.Turn.(whole)| t / whole

		is_eq : _
	}

	north : Angle.Bearing
	north = Angle.Bearing.(0.0)
}
