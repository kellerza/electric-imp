/************************************************
 * *Mcp23018* class
 * Microchip Mcp23018 i2c controller
 *
 * Usage:
 *   Mcp23018(<imp i2c>, <address=0>)
 *
 * Note: The Mcp23018 pull-ups could not source 
 *       enough current to drive a ULN2803
 *
 * Author: Johann Kellerman
 * License: CC BY-SA
 ************************************************/
//MCP23018
class Mcp23018 {
  _i2c  = null;
  _addr = null; // write addr, +1=read addr
  _buf = {};
  _activeport=0;

  //MCP23018 registers according to datasheet
  //http://www.microchip.com/TechDoc.aspx?type=datasheet&product=mcp23018
  static IODIR1 =   "\x00\x01";
  static IPOL1 =    "\x02\x03";
  static GPINTEN1 = "\x04\x05";
  static DEFVAL1 =  "\x06\x07";
  static INTCON1 =  "\x08\x09";
  static IOCON1 =   "\x0A";
  static GPPU1 =    "\x0C\x0D";
  static GPIO1 =    "\x12\x13";
  static OLAT =    "\x14\x15";

  static PORTA = 0;
  static PORTB = 1;
  
  constructor(i2c=hardware.i2c12, address=0) {
    _i2c = i2c;
    // Mcp spports: 100kHz, 400kHz, 3.4MHz
    _i2c.configure(CLOCK_SPEED_400_KHZ);
    // Prepare MCP address (as set by voltage divider)
    _addr = 0x40+((address&0x7)<<1);
    server.log("Mcp23018 started on _addr = "+hex(_addr));
    // Set IOCON: bank=1, mirror=0, seqop=1, n/u, n/u, odr=0, intpol=1, intcc=0
    //_i2c.write(_addr, "\x0A\xA0"); // au=sume we are in bank.0
    //_i2c.write(_addr, "\x0A\x04"); // au=sume we are in bank.0
  }
  
  i2cwrite = @(val) _i2c.write(_addr, val);
  i2cread = @(count) _i2c.read(_addr+1, "", count);
  
  setmask = function (port, mask, onoff) {
    _activeport = port;
    //read in buffer...
    if (!(GPIO1[_activeport] in _buf))
      _register(GPIO1);
    if (!(IODIR1[_activeport] in _buf))
      _register(IODIR1);
    local gpio = _buf[GPIO1[_activeport]]; // expect a string in buf
    //local iodir = _buf[IODIR1[_activeport]];
    if (typeof mask == "string") mask = mask[0];
    if (typeof gpio == "string") gpio = gpio[0]
    local newgpio = onoff?(gpio|mask):(gpio&(~mask));
    //server.log("Garage MASK: "+hex(gpio)+(onoff?" + ":" - ")+hex(mask)+" = "+hex(newgpio))
    io(newgpio);
  }
  
  set = function(pin, value=-1) {
    if (pin>7)
      pin = pin%8;
    local bv = 1<<pin;
    local prev = _buf[GPIO1[_activeport]];
    local mask = ~_buf[IODIR1[_activeport]];
    if (!(bv&mask)) {
      server.log("Cannot set readonly bit "+pin+" ["+ab+"]");
      return;
    }
    if (value.tointeger()<0)
      return prev & bv;
    if (value.tointeger()==0)
      prev = prev & (~bv);// clear
    else
      prev = prev | bv;// set
    io(prev); 
  }
  
  A=function() {_activeport=0;return this;}
  B=function() {_activeport=1;return this;}

  _register = function(register_addr, pins=-1) {
    local c=register_addr[_activeport].tochar();
    //server.log("..register_addr = "+hex(register_addr[ab]))
    if (typeof pins == "string")
      pins = pins[0]
    if (pins<0) {
      _i2c.write(_addr, c);
      _buf[register_addr[_activeport]] <- _i2c.read(_addr+1, "",1)
      return _buf[register_addr[_activeport]];
    }
    _buf[register_addr[_activeport]] <- pins; // save for a rainy day
    _i2c.write(_addr, c+pins.tochar())
    return this;
  }
  
  // IO Direction
  //  1=input(default), 0=output
  direction = @(v=-1) _register(IODIR1,v);
  
  // Port state
  //  1 / 0(default)
  io = @(v=-1) _register(GPIO1,v);

  // Pullup resistors 
  //  1=enabled, 0=disabled(default)
  pullup = @(v=-1) _register(GPPU1,v);

  // Polarity
  //  1=inverted, 0=(default)
  polarity = @(v=-1) _register(IPOL1,v);
  
  // Polarity
  //  1=inverted, 0=(default)
  out = @(v=-1) _register(OLAT,v);
}
