// Imports
import Foundation

let env = ProcessInfo.processInfo.environment
let inputStr: String = env["WHISK_INPUT"] ?? "{}"
let json = inputStr.data(using: .utf8, allowLossyConversion: true)!


// snippet of code "injected" (wrapper code for invoking traditional main)
func _run_main(mainFunction: ([String: Any]) -> [String: Any]) -> Void {
    let parsed = try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
    let result = mainFunction(parsed)
    if JSONSerialization.isValidJSONObject(result) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
            if let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8) {
                print("\(jsonStr)")
            } else {
                print("Error serializing data to JSON, data conversion returns nil string")
            }
        } catch {
            print(("\(error)"))
        }
    } else {
        print("Error serializing JSON, data does not appear to be valid JSON")
    }
}

