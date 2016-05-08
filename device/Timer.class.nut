/************************************************
 * *Timer* class
 * crontab like Timer, without the support for *'s
 *
 * Usage:
 *   Timer(<gmt offset>)
 *   date() - get GMT corrected time
 *   add(<time table>, <function>, <label, optional>) 
 *     Add a timer, include a label if you would
 *     like to change the time later
 *   replace(<label>, <time table>) - replace time on a timer
 *
 * <time table> = {hour=, min=<optional>, 
 *     dur=<minutes,optional>, wday=<wday / array, optional>}
 * 
 * use: timer.add  *
 *
 * Author: Johann Kellerman
 * License: CC BY-SA
 ************************************************/

class Timer {
  _t=[]
  _map = {}
  _TZ=0
  
  function constructor(offset=2) {
    _TZ=offset;
    imp.wakeup(5, _chk.bindenv(this));
  }
  /*
   * Update normally on the start of the program to
   * ensure it is in the correct state
   *  Called by "add" and "replace"
   */
  _update = function (t) {
    // switch on for the remainder of an interval...
    if ("dur" in t && t.dur>0) {
      local now = date()
      if (wdayTest(t, now.wday)) {
        now = to_min(now);
        local from = timer.to_min(t);
        local to = from+t.dur;
        if (now<from) now=now+24*60; // add a day
        if (from<=now && now<=to) {
          server.log("timer update ["+(to-now)+"min left] "+_print(t))
          return t.func(to-now);
        }
      }
    }
    server.log("timer update "+_print(t))
  }
  
  _fixtime = function(time, dur=-1) {
    time.hour = time.hour.tointeger();
    time.min <- ("min" in time)? time.min.tointeger():0;
    if (dur>=0 || "dur" in time)
      time.dur <- ("dur" in time)? time.dur.tointeger():dur.tointeger();
    return time;
  }
  
  _print = function(time) {
    local v = _fixtime(time);
    local dur= (("dur" in v) && (v.dur>0))?v.dur+"m ":"";
    return format("(%s@%02d:%02d)", dur, v.hour, v.min)
  }
  
  add = function (time,func,label="") {
    time = _fixtime(time);
    if (label != "") {
      server.log("timer."+label+" registered "+_print(time))
      _map[label] <- _t.len();
      local rr=replace.bindenv(this);
      agent.on("timer."+label, @(value) rr(label, value));
    }
    time.func <- func;
    _t.push(time);
    _update(time);
  }
  
  function replace(label, time) {
    if (label in _map) {
      local idx = _map[label];
      time = _fixtime(time, _t[idx].dur);
      _t[idx].hour = time.hour;
      _t[idx].min = time.min;
      _t[idx].dur = time.dur;
      //server.log("New time for '"+label+"' "+hour+":"+min);
      server.log("timer: new time for '"+label+"' "+_print(_t[idx]));
      _update(_t[idx]);
    } else {
      server.log("timer: replace label not in timer._map: "+label)
    }
  }
  date = function() {
    local now = ::date();
    now.hour += _TZ; // add GMT+-...
    return now;
  }
  wdayTest = function (v, wday) {
    if ("wday" in v) {
      if ((typeof v.wday == "array") && (v.wday.find(wday) == null))
        return false;
      if ((typeof v.wday == "integer") && (v.wday != wday))
        return false;
    }
    return true;
  }
  _chk = function () {
    local now = date();
    imp.wakeup(65-now.sec, _chk.bindenv(this)); // wake 5 seconds past next minute
    //server.log("chk "+now.hour+":"+now.min+":"+now.sec);
    foreach (i, v in timer._t) {
      if (v.min==now.min && v.hour==now.hour) {
        //do some day checking
        if (!wdayTest(v, now.wday)) continue;
        server.log("timer: match "+_print(now)+" "+_print(v));
        if ("dur" in v)
          v.func(v.dur)
        else
          v.func(1)
      }
    }
  }

  function to_min(t="now") {
    if (typeof(t)=="array") {
      //server.log("array: "+t[1]+":"+t[0]);
      return t[0]+(60*t[1]);
    }
    if (t=="now") {
      t=date();
      //t.hour+=_TZ;
    }
    if (typeof(t)=="table") {
      return t.min.tointeger()+((t.hour.tointeger())*60);
    }
    server.log("invalid time: "+typeof(t));
  }

  function isNight() {
    local now=to_min("now");
    //server.log("Time:"+now+" sunset:"+to_min(config.vars.sunset)+
    //   " sunrise:"+to_min(config.vars.sunrise));
    return (((now-30)<to_min(config.vars.sunrise)) ||
      ((now+40)>to_min(config.vars.sunset)));
  }
}