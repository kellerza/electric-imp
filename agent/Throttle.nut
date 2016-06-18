/************************************************
 * Throttle once every x seconds
 * use: if (Throttle('var', 10)) return
 ************************************************/
THROTTLE <- {}
function Throttle(var, seconds) {
  if (var in THROTTLE && time() <= THROTTLE[var])
      return true
  THROTTLE[var] <- time() + seconds
  return false
}