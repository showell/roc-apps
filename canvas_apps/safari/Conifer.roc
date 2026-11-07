## A conifer's kind, which sets its height: from the ground to the tip of its
## crown, where a bird perches. Its color comes from `TreeShapes`, and where it
## stands beside a road comes from `Trees`.
import Distance

Conifer := [BigGreen, SmallGreen, Red, Gold].{

	## A small green tree's height.
	small_height : Distance
	small_height = Distance.metres(4.896)

	## A big green tree's height.
	big_height : Distance
	big_height = small_height.times(1.3)

	height : Conifer -> Distance
	height = |conifer|
		match conifer {
			BigGreen => big_height
			SmallGreen => small_height
			Red => small_height.times(2.0)
			Gold => small_height.times(3.0)
		}

	is_eq : _
}

expect
	[
		(Conifer.BigGreen, 6.3648),
		(Conifer.SmallGreen, 4.896),
		(Conifer.Red, 9.792),
		(Conifer.Gold, 14.688),
	].all(|(conifer, want)| (conifer.height().to_metres() - want).abs() <= 0.000000001)
