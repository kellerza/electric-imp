/************************************************
 * *74HC595* class
 * Class to control a shift register
 *
 * Usage:
 *   Hc595(<cntOut>, <pin table>)
 *
 * cntOut: Amount of output pins: default 8,16,24.. 
 * pins: hardware pins {OE=, SER=, SRCLK=, RCLK=}
 *
 * Author: Johann Kellerman
 * License: CC BY-SA
 ************************************************/
class Hc595 {
  _value = 0;
  _cntOut = 8;
  _wakeuphandle = null;
  pinOE = hardware.pinC; // low (enable)
  pinSER = hardware.pinD;
  pinSRCLK = hardware.pinA;
  pinRCLK = hardware.pinB;

  constructor(cntOut=8, pins={}) {
    if ("OE" in pins) pinOE=pins.OE;
    if ("SER" in pins) pinSER=pins.SER;
    if ("SRCLK" in pins) pinSRCLK=pins.SRCLK;
    if ("RCLK" in pins) pinRCLK=pins.RCLK;
    _cntOut=cntOut;
    enable(0);
    _value=0;
    pinSER.configure(DIGITAL_OUT);
    pinSRCLK.configure(DIGITAL_OUT);
    pinRCLK.configure(DIGITAL_OUT);
    io(0);
  }
  
  enable = function (en) {
    pinOE.configure(en?DIGITAL_OUT:DIGITAL_IN);
    pinOE.write(0);//en?0:1); // enable outputs
  }
  
  set = function(pin, value=-1) {
    if (pin<1 || pin>_cntOut) {
      return server.log("Invalid pin "+pin);
      return 0;
    }
    local bv=1<<(pin-1);
    if (value.tointeger()<0) 
      return (_value & bv)>0; // return value
    if (value.tointeger()==0)
      io(_value & (~bv));// clear
    else
      io(_value | bv);// set
  }
  
  io = function(value=-1) {
    if (value.tointeger()<0) 
      return _value;
    if (value!=_value) {
      _value = value;
      if (_wakeuphandle) imp.cancelwakeup(_wakeuphandle);
      _wakeuphandle = imp.wakeup(0.5, _io.bindenv(this));
    }
  }
  
  get = function (pin=-1) {
    if (pin=="hex") return "0x"+format("%x", _value);
    if (pin<0) return _value;
  }
  
  _io = function() {
    //pinRCLK.write(0);
    local a = 1;
//D    local debug="out "+_value+": ";
    while (a< (1<<_cntOut)) {
      pinSER.write(_value&a); // write data
      // clock in
      imp.sleep(0.000001);pinSRCLK.write(1);
      imp.sleep(0.000001);pinSRCLK.write(0);
//D      debug = debug+ a + (_value&a?"^ ":"_ ");
      a=a<<1;
    }
//D    server.log(debug);
    //latch
    imp.sleep(0.000001);pinRCLK.write(1);
    imp.sleep(0.000001);pinRCLK.write(0);
    pinSER.write(0);
    enable(_value>0);// enable/disable
  }
}