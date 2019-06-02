import asyncnet, asyncdispatch, net, osproc, os

var server: AsyncSocket
let port = 9090
let publicKey = "publicKey.pem"
let secretKey = "secretKey.pem"

proc handle(client: AsyncSocket) {.async.} =
  while true:
    var line: string = ""    
    try:
      line = await client.recvLine()
    except:
      echo "socket breaks in read:", getCurrentExceptionMsg()
      break
    if line == "": 
      echo "client disconnected"
      if not client.isClosed:
        client.close()
      break
    try:
      await client.send("GOT: " & line & "\n")
    except:
      echo "socket breaks in send:", getCurrentExceptionMsg()
      break
    
proc createKeyFiles() = 
  ## creates neccessary certificates for ssl socket.
  echo "[+] going to create ssl certificates"
  let res = execCmd "openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout " & secretKey & " -out " & publicKey
  if res != 0: 
    echo "[-] could not create keyfiles"
    quit()
  echo "[+] keys created"

proc main() {.async.} = 
  if not (fileExists(publicKey) or fileExists(secretKey)): createKeyFiles()
  server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.setSockOpt(OptReusePort, true)
  server.bindAddr(Port port)
  server.listen()
  var ctx = newContext(certFile = publicKey, keyFile = secretKey)
  wrapSocket(ctx, server)
  echo "listening on port ", port
  while true:
    var (address, client) = await server.acceptAddr()
    echo "connection from: ", address
    wrapConnectedSocket(ctx, client, handshakeAsServer)
    asyncCheck client.handle

waitFor main()