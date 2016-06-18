app <- Rocky()
app.on("OPTIONS", ".*", @(context) context.send("OK"))
function connectedMiddleware(context, next) {
  server.log("http://"+context.req.path.tolower()
    + (device.isconnected()?" ":" Not connected")
    + context.req.rawbody)
  if (!device.isconnected()) context.send(500, "Imp not connected")
  next()
}
function logMiddleware(context, next) {
  server.log("http://"+context.req.path.tolower()
    + (device.isconnected()?" ":" Not connected")
    + context.req.rawbody)
  next()
}