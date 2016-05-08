/************************************************
 * *Average* class
 * Running average of a circular buffer
 * With this function you add values at a constant
 * rate, reading will return the average over the
 * last <size> samples
 *
 * Usage:
 *   Average(<size>) - Initialize
 *     size: Amount of samples
 *   read() - get average value
 *   push(<value>) - add a value
 *
 * Author: Johann Kellerman
 * License: CC BY-SA
 ************************************************/
class Average {
  _data=[];
  _size=0;
  _i = 0;
  _tot = 0;
  function constructor(size=100) {
    _size=size.tointeger();
  }
  function read() {
    return _tot/_size;
  }
  function push(val) {
    if (_data.len()==0) {
      // Initialize the array with val
      while (_data.len()<_size) _data.push(val);
      _tot = val*_size;
    }
    _tot += val-_data[_i];
    _data[_i] = val
    _i += 1;
    if (_i>=_size) _i=0;
  }
}