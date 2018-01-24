func main(args: [String:Any]) -> [String:Any] {
  if let baseUrl = args["baseUrl"] as? String {
    //Overriding WHISK API HOST using baseUrl, only applicable in testing with self sign ssl certs"
    Whisk.baseUrl = baseUrl
  }
  guard let triggerName = args["triggerName"] as? String else {
    return ["error": "You must specify a triggerName parameter!"]
  }
  print("Trigger Name: \(triggerName)")
  return Whisk.createTrigger(triggerNamed: triggerName, withParameters: [:])
}