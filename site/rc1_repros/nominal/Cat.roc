Cat := { pose : [Sit, Run] }.{
	pose_of : Cat -> [Sit, Run]
	pose_of = |c| c.pose
}
