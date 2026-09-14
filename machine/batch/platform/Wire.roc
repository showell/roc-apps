# Wire -- the frames that cross the network card, kept for the page in order:
# direction 0 is a frame the program sent, 1 a frame the network answered.
Wire := [].{
	frame! : U64, List(U8) => {}
}
