## What one limit on the throttle asks. Throttle holds the acceleration it
## offers to the least of its limits, and EncounterReaction and Gawking each
## give one. The type has a module of its own because Throttle imports both of
## them.
import Acceleration

## Nothing, or to accelerate no harder than this.
ThrottleLimit := [NoLimit, AtMost(Acceleration)].{
	is_eq : _
}
