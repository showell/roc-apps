# Safari on roc-ray: the movie is Safari's, the player is anybody's.
#
# `modules` stages safari/roc (which has this movie's Movie.roc) and ray/player
# (which has MoviePlayer). A second movie is a second directory here.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import MoviePlayer

Model : MoviePlayer.Model

Msg : MoviePlayer.Msg

program = MoviePlayer.program
