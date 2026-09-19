# Trick or treat: walking up to a house, past six skeletons.
#
# The skeletons are the same figure the skeleton movie dances, drawn at
# whatever size the distance makes them. The player is Safari's, unchanged.
app [Model, program] { rr: platform "roc-ray/platform/main.roc" }

import MoviePlayer
import Halloween

Model : MoviePlayer.Model(Halloween.Model)

Msg : MoviePlayer.Msg

program = MoviePlayer.program(Halloween.movie)
