# Safari on roc-ray.
#
# The movie is Safari's; the player is anybody's. This file is the glue, and
# says so out loud: it names the movie it is playing and hands it over.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import MoviePlayer
import SafariMovie

Model : MoviePlayer.Model(SafariMovie.Model)

Msg : MoviePlayer.Msg

program = MoviePlayer.program(SafariMovie.movie)
