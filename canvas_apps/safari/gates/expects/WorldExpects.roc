## WorldExpects holds the rules the real route keeps that World can't check
## beside its data, because the rule's home is a module World doesn't import.

import game.Speed
import game.VehicleLimits
import game.World

WorldExpects :: [].{}

# Every bend's turn rounds to a whole degree in VehicleLimits' turn_speeds. Throttle and
# TruckJourney ask turn_speed for each bend, and it crashes on a turn that isn't there.
expect World.bending_plans.all(|{ turn, .. }| VehicleLimits.turn_speed(turn) > Speed.at_rest)
