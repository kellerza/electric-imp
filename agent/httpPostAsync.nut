/************************************************
 * An async wrapper function for http.post
 * that accepts and returns JSON
 ************************************************/
function httpPostAsync(url, data, cb=null) {
  local debug=1
  debug && server.log("httpPostAsync post: "+http.jsonencode(data) + " ["+url+"]")
  http.post(url,{"content-type": "application/json"},
    http.jsonencode(data))
    .sendasync(function (response) {
      if ((response.statuscode != 200) || debug==1)
        server.log("httpPostAsync reply: "+response.statuscode+" -> "+response.body)
      if (cb!=null) {
        local json
        try { json = http.jsondecode(response.body) }
        catch (e) { json=response.body }
        try { cb(response.statuscode, json) }
        catch (e) { server.log("httpPostAsync: " + e + "URL:"+url) }
      }
    })
}