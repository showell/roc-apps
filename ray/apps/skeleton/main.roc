# The Skeleton Dance, after the 1929 Silly Symphony, as a movie.
#
# The movie is theirs (adapted); the player is the same one Safari uses,
# unchanged. That is the point of it being here.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import MoviePlayer
import Skeleton

Model : MoviePlayer.Model(Skeleton.Model)

Msg : MoviePlayer.Msg

program = MoviePlayer.program(Skeleton.movie)
