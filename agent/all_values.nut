/************************************************
 * *all_values* hook for *TimedOutput*
 *
 * - Receive all_values from the device
 * - Using Rocky, you can then retrieve & update
 *   any value though the /all_values HTTP API
 *
 * Written to get the state of all TimedOutputs on
 * an Imp with a single HTTP call, ensuring less
 * calls for a Home Automation controller like
 * Home-Assistant
 ************************************************/
device_values <- {}
agent_values <- {"timestamp_updated": 0} // Value originating from agent, not device
device.on("all_values", function (_new_all_values) {
  device_values = _new_all_values
  agent_values["timestamp_updated"] <- time()
})
app.get("/all_values", function (context) {
  local av = clone device_values
  local now = time()
  foreach (idx,val in av) {
    if (typeof val != "integer") continue
    if (val > agent_values["timestamp_updated"]) {av[idx] = val - now}
  }
  foreach (idx,val in agent_values)
    av[idx] <- val
  av["timestamp_updated"] <- now - av["timestamp_updated"]
  av["binarysensor_Connected_"+db.read("name")] <- device.isconnected()
  context.send(200, av)
})
app.post("/all_values", function (context) {
  local res = {}
  foreach (key, value in context.req.body)
    if (key in device_values) {
      device.send(key, value.tointeger())
      res[key] <- value
    } else {
      server.log("Key not in all_values:"+key)
      server.log(http.jsonencode(device_values))
    }
  context.send(res.len() > 0 ? 200 : 400, res)
}).use([ logMiddleware ])