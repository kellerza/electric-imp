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
all_values <- {}
device.on("all_values", function (_new_all_values) {
  all_values = _new_all_values;
  all_values["timestamp_updated"] <- time();
})
app.get("/all_values", function (context) {
  local av = clone all_values;
  local now = time();
  foreach (idx,val in av)
    if (val != 0) {av[idx] = val-now;}
  av["timestamp_diff"] <- av["timestamp_updated"]
  av["timestamp_updated"] = all_values["timestamp_updated"]
  context.send(200, av);
});
app.post("/all_values", function (context) {
  #local min = context.req.body.minutes.tointeger();
  #local name = context.req.body.name;
  local res = {}
  foreach (key, value in context.req.body) {
    if (key in all_values) {
      device.send(key, value.tointeger())
      res[key] <- value
    }
    if (res.len()>0) {
      context.send(200, res);
    } else {
      context.send(400, "");
    }
  }
}).use([ logMiddleware ]);

