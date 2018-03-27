import SwiftyRequest
import Dispatch
import Foundation

enum RequestError: Error {
    case requetError
}
struct AnInput: Codable {
    let url: String?
}
struct AnOutput: Codable {
    let greeting: String?
}
func main(param: AnInput, completion: @escaping (AnOutput?, Error?) -> Void) -> Void {
    let echoURL = param.url ?? "https://httpbin.org/get"
    let request = RestRequest(method: .get, url: echoURL)
    request.responseString(responseToError: nil) { response in
        switch response.result {
        case .success(let result):
            print(result)
            completion(AnOutput(greeting:"success"),nil)
        case .failure(let error):
            print(error)
            completion(nil,RequestError.requetError)
        }
    }
}

