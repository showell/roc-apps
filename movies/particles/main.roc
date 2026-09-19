# roc-ray's particles example, as a movie.
#
# The movie is theirs (adapted); the player is the same one Safari uses,
# unchanged. That is the point of it being here.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import MoviePlayer
import Particles

Model : MoviePlayer.Model(Particles.Model)

Msg : MoviePlayer.Msg

program = MoviePlayer.program(Particles.movie)
