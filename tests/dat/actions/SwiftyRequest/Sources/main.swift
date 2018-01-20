import SwiftyRequest
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["error":"Action failed"]
    let echoURL = "http://httpbin.org/post"
    
    // setting body data to {"Data":"string"}
    let origJson: [String: Any] = args
    guard let data = try? JSONSerialization.data(withJSONObject: origJson, options: []) else {
        return ["error": "Could not encode json"]
    }
    let request = RestRequest(method: .post, url: echoURL)
    request.messageBody = data
    let semaphore = DispatchSemaphore(value: 0)
    //sending with query ?hour=9
    request.responseData(queryItems: [URLQueryItem(name: "hour", value: "9")]) { response in
        switch response.result {
        case .success(let retval):
            guard let decoded = try? JSONSerialization.jsonObject(with: retval, options: []),
                let json = decoded as? [String: Any] else {
                    resp = ["error":"Response from server is not a dictionary"]
                    semaphore.signal()
                    return
            }
            resp = json
        case .failure(let error):
            resp = ["error":"Failed to get data response: \(error)"]
            print("Failed to get data response: \(error)")
        }
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .distantFuture)
    return resp
}
let r = main(args:["message":"serveless"])
print(r)

