// Licensed to the Apache Software Foundation (ASF) under one or more contributor
// license agreements; and to You under the Apache License, Version 2.0.

func main(args: [String:Any]) -> [String:Any] {
  if let baseUrl = args["baseUrl"] as? String {
    //Overriding WHISK API HOST using baseUrl, only applicable in testing with self sign ssl certs"
    Whisk.baseUrl = baseUrl
  }
  guard let triggerName = args["triggerName"] as? String else {
      return ["error": "You must specify a triggerName parameter!"]
  }
  guard let actionName = args["actionName"] as? String else {
      return ["error": "You must specify a actionName parameter!"]
  }
  guard let ruleName = args["ruleName"] as? String else {
      return ["error": "You must specify a ruleName parameter!"]
  }
  print("Rule Name: \(ruleName), Trigger Name: \(triggerName), actionName: \(actionName)")
  return Whisk.createRule(ruleNamed: ruleName, withTrigger: triggerName, andAction: actionName)
}
