/************************************************
 * *Debounce* class
 * Class to debounce a pin
 *
 * Author: Johann Kellerman
 * License: CC BY-SA
 ************************************************/
class Debounce {
  _pin      = null
  _callback = null
  _value    = 0.5
  _repeats  = 0
  _r_count  = 0
  _swap     = false
  _timer    = 0
  _all_value= null
  _agent_link_name = null

  constructor(pin, pull, callback, swap=false, ms=10, all_value=null){
    _pin = pin //Unconfigured IO pin, eg hardware.pin2
    //pull     //DIGITAL_IN_PULLDOWN, DIGITAL_IN or DIGITAL_IN_PULLUP
    _callback = callback //Function to call on a button press (may be null)
    _swap = swap
    _repeats = (ms/1000 / 0.01).tointeger()
    if (_repeats<1) _repeats = 1
    _pin.configure(pull, pinchange.bindenv(this))
    _value = _pin.read()
    linkAgent(all_value)
    //pinchange();
  }
  function read() {return _swap?(1-_value):_value}
  function pinchange() {
    if (_timer == 0)
      _timer = imp.wakeup(0.01, debounce.bindenv(this))
    _r_count = _repeats
  }
  function debounce(){
    _timer = 0
    if (_pin.read() == _value) {
      if (_r_count == _repeats) {
        _r_count = 0
        return // stop this timer...
      }
      _r_count = _repeats
    } else {
      _r_count -= 1
      if (_r_count == 0) {
        _value = _pin.read()
        linkAgent()
        if (_callback != null) _callback(read())
      }
    }
    _timer = imp.wakeup(0.01, debounce.bindenv(this))
  }
  function linkAgent(bind_name=null) {
    if (bind_name != null) {
      _agent_link_name = bind_name}
    if (_agent_link_name != null) {
      all_values[_agent_link_name] <- read()
      agent.send("all_values", all_values)}
    return this
  }
}