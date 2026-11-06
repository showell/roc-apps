## A conifer's kind, which sets its height. Its colour is the drawing's, and
## where it stands beside a road is planting's.
import Distance

Conifer := [BigGreen, SmallGreen, Red, Gold].{

	## A small green tree's height.
	small_height : Distance
	small_height = Distance.metres(4.5)

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

expect Conifer.small_height == Distance.metres(4.5)
expect Conifer.big_height == Distance.metres(5.8500000000000005)

expect Conifer.BigGreen.height().to_metres() == 5.8500000000000005
expect Conifer.SmallGreen.height().to_metres() == 4.5
expect Conifer.Red.height().to_metres() == 9.0
expect Conifer.Gold.height().to_metres() == 13.5
