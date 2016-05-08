/************************************************
 * *TimedOutput* class
 * Output that stays on for certain amount of time
 *
 * Usage:
 *   TimedOutput(<pin>)
 *     pin - hardware.pin OR null
 *   agentOn(agent_on)
 *     Bind an agent listener to set minutes, call from Agent:
 *     device.send(agent_on, min)
 *   onTest(f(min))
 *     Callback to modify the minutes before set (i.e. set min=0)
 *   onSet(f(min))
 *     Call with the final min value, typically after the pin is set 
 *     Alternatively used to perform a set function iso setting a pin
 *   read()
 *   minutes(min) - switch on for min minutes, 0 will switch off
 *   off() - alias for minutes(0)
 *
 * Author: Johann Kellerman
 * License: CC BY-SA
 ************************************************/
class TimedOutput {
  static version = [1 0 0]
  _pin = null;
  _timer = null; // timer to count down and switch off
  _timer_time = 0;
  _callback = null;
  _testcallback = null;
  _value = 0;

  constructor(pin=null) {
    _pin = pin; //Unconfigured IO pin, eg hardware.pin2
    if (_pin != null) _pin.configure(DIGITAL_OUT);
    minutes(0);
  }
  function onTest(testCB) {_testcallback = testCB;return this;}
  function onSet(callback)   {_callback = callback;return this;}
  function onWrite(callback) {_callback = callback;return this;}
  function agentOn(listener) {
    agent.on(listener, minutes.bindenv(this));
    return this;
  }
  function read() {return _value;}
  function off() {minutes(0);}
  function minutes(min) {
    if (_testcallback != null) min = _testcallback(min);
    if (_timer != null) {
      if ((min>0) && ((time()+min*60)<_timer_time)) {
        // the new timer is less than the previous one
        return;// leave it on for longer!
      }
      // cancel the previous timer
      imp.cancelwakeup(_timer);
      _timer = null;
    }
    _value = min>0?1:0;
    if (min>0) {
      // start a new timer to switch off
      _timer = imp.wakeup(min*60, off.bindenv(this));
      _timer_time = time()+min*60;
    }
    if (_pin!=null) _pin.write(_value);
    if (_callback!=null) _callback(min);
  }
}