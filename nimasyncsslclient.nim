import asyncnet, asyncdispatch, net, os, openssl

var client: AsyncSocket
let port = 9090
let host = "127.0.0.1"
let serverPublicKey = "publicKey.pem"

proc handle(client: AsyncSocket) {.async.} = 
  ## We speek to the ssl server.
  var cnt = 0
  while true:
    await client.send("TEST " & $cnt & "\n")
    echo await client.recvLine()
    cnt.inc
    await sleepAsync(1000)

proc main() {.async.} = 
  if not fileExists(serverPublicKey): 
    echo "[-] could not find server's public key at: ", serverPublicKey
    quit()
  client = newAsyncSocket()  
  var ctx = newContext()
  discard SSL_CTX_load_verify_locations(ctx.context, "publicKey.pem", "") # we gonna trust our self signed certificat
  wrapSocket(ctx, client) # enables SSL for this socket.
  try:
    await client.connect(host, Port port)
  except:
    echo "[-] could not connect to server: ", host, port
  await client.handle()


waitFor main()