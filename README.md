# Electric Imp Libraries

A collection of [Electric IMP](https://electricimp.com) libraries, this repo contain device libraries and hardware drivers I've used in my projects.

# Device libraries

### Average
```
*Average* class
Running average of a circular bufferss
With this function you add values at a constant
rate, reading will return the average over the
last <size> samples

Usage:
  Average(<size>) - Initialize
    size: Amount of samples
  read() - get average value
  push(<value>) - add a value
```
### Debounce
```
*Debounce* class
Class to debounce a pin
```

### Message
```
*Message* class
Delays log messages to the server
Will only send a log every <delay> seconds,
Log message starts with <prepend>
```
### PulseRepeat
```
*Pulse* class
Repeats a certain function forever...

while keeping track of one variable, input/output of the function
Usage:
  Pulse(<delay>, <start_value>, function(current_value) {
    return new_value;   
  })
```

### TimedOutput
```
*TimedOutput* class
Output that stays on for certain amount of time

Usage:
  TimedOutput(<pin>)
    pin - hardware.pin OR null
  agentOn(agent_on)
    Bind an agent listener to set minutes, call from Agent:
    device.send(agent_on, min)
  onTest(f(min))
    Callback to modify the minutes before set (i.e. set min=0)
  onSet(f(min))
    Call with the final min value, typically after the pin is set 
    Alternatively used to perform a set function iso setting a pin
  read()
  minutes(min) - switch on for min minutes, 0 will switch off
  off() - alias for minutes(0)
```

### Timer

```
*Timer* class
crontab like Timer, without the support for *'s[server]
[device]device\
Usage:
  Timer(<gmt offset>)
  date() - get GMT corrected time
  add(<time table>, <function>, <label, optional>) 
    Add a timer, include a label if you would
    like to change the time later
  replace(<label>, <time table>) - replace time on a timer

<time table> = {hour=, min=<optional>, 
    dur=<minutes,optional>, wday=<wday / array, optional>}

use: timer.add  *
```


# Hardware libraries

### HC595
```
*74HC595* class
Class to control a shift register

Usage:
  Hc595(<cntOut>, <pin table>)

cntOut: Amount of output pins: default 8,16,24.. 
pins: hardware pins {OE=, SER=, SRCLK=, RCLK=}
```

### MCP23018
```
*Mcp23018* class
Microchip Mcp23018 i2c controller

Usage:
  Mcp23018(<imp i2c>, <address=0>)

Note: The Mcp23018 pull-ups could not source
      enough current to drive a ULN2803
```