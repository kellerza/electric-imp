/************************************************
 * *Message* class
 * Delays log messages to the server
 * Will only send a log every <delay> seconds,
 * Log message starts with <prepend>
 ************************************************/ 
 class Message{
  _tmr = null;
  _delay = 10;
  _msg = "";
  _prepend ="";
  function constructor(prepend="",delay=10) {
    _delay = delay;
    _prepend = prepend;
  }
  function log(m) {
    _msg=(_msg=="")?m:_msg+", "+m;
    if (_tmr== null) {
      _tmr = imp.wakeup(_delay, _log.bindenv(this))
    }
  }
  function _log(){
    server.log(_prepend + _msg);
    _msg="";
    if (_tmr!=null) {
      imp.cancelwakeup(_tmr)
      _tmr=null;
    }
  }
}