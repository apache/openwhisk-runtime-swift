// Licensed to the Apache Software Foundation (ASF) under one or more contributor
// license agreements; and to You under the Apache License, Version 2.0.

struct Activation: Decodable {
  let activationId: String
}

func main(args: [String:Any]) -> [String:Any] {
  if let baseUrl = args["baseUrl"] as? String {
    //Overriding WHISK API HOST using baseUrl, only applicable in testing with self sign ssl certs"
    Whisk.baseUrl = baseUrl
  }
  let invokeResult = Whisk.invoke(actionNamed: "/whisk.system/utils/date", withParameters: [:], blocking: false)
  let jsonData = try! JSONSerialization.data(withJSONObject: invokeResult)
  let dateActivation = try! JSONDecoder().decode(Activation.self, from: jsonData)
  // the date we are looking for is the result inside the date activation
  let activationId = dateActivation.activationId
  if activationId.isEmpty{
      print("Failed to invoke.")
  } else {
      print("Invoked.")
  }

  // return the entire invokeResult
  return invokeResult
}
