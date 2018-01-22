func main(args: [String:Any]) -> [String:Any] {
  guard let baseUrl = args["baseUrl"] as? String else {
    return [ "error" : "baseUrl argument missing" ]
  }
  //Overriding WHISK API HOST using baseUrl, only applicable in testing with self sign ssl certs"
  Whisk.baseUrl = baseUrl
  if let triggerName = args["triggerName"] as? String {
    print("Trigger Name: \(triggerName)")
    return Whisk.trigger(eventNamed: triggerName, withParameters: [:])
  } else {
    return ["error": "You must specify a triggerName parameter!"]
  }
}