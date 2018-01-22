struct Result: Decodable {
    let date: String
}
struct Response: Decodable {
    let result:Result
}
struct Activation: Decodable {
    let response: Response
}

func main(args: [String:Any]) -> [String:Any] {
  Whisk.baseUrl = "http://172.17.0.1:10001"
  let invokeResult = Whisk.invoke(actionNamed: "/whisk.system/utils/date", withParameters: [:])
  let jsonData = try! JSONSerialization.data(withJSONObject: invokeResult)
  let dateActivation = try! JSONDecoder().decode(Activation.self, from: jsonData)
  let dateString = dateActivation.response.result.date
  if dateString.isEmpty{
    print("Could not parse date of of the response.")
  } else {
    print("It is now \(dateString)")
  }
  // return the entire invokeResult
  return invokeResult
}