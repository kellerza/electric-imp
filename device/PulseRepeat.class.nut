/************************************************
 * *Pulse* class
 * Repeats a certain function forever...
 *
 * while keeping track of one variable, input/output of the function
 * Usage:
 *   Pulse(<delay>, <start_value>, function(current_value) {
 *     return new_value;   
 *   })
 *
 * Author: Johann Kellerman
 * License: CC BY-SA
 ************************************************/
class Pulse {
  _delay=1000;
  _func=null;
  _value=0;
  constructor(delay, start_value, func) {
    _delay = delay;
    _func = func;
    _value = start_value;
    imp.wakeup(_delay+1, _pulse.bindenv(this));
  }
  function _pulse() {
    _value = _func(_value);
    imp.wakeup(_delay, _pulse.bindenv(this));
  }
}


class Repeat {
  _total = 0;
  _i=0;
  _func = null;
  _tmr = null;
  _sleeps = [];
  static _sleepmulti = 60;
  constructor(func, sleeps=[15,30,30,60]) {
    _func = func;
    _sleeps = sleeps;
  }
  function _pulse() {
    if (_i>0) _func(_total);
    _total = _total+_sleeps[_i];
    _tmr=imp.wakeup(_sleeps[_i]*_sleepmulti, _pulse.bindenv(this));
    if (_i<_sleeps.len()-1) _i=_i+1;
  }
  function toggle(v) {
    // always stop...
    if (_tmr!=null) imp.cancelwakeup(_tmr);
    _i=0;
    _total=0;
    _tmr = null;
    if (v) _pulse();
  }
  start = @() toggle(true);
  stop = @() toggle(false);
}
