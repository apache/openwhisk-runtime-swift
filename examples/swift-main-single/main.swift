/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

func main(args: Any) -> Any {
    let newArgs = args as! [String:Any]
    if let name = newArgs["name"] as? String {
        return [ "greeting" : "Hello \(name)!" ]
    } else {
        return [ "greeting" : "Hello swif4.2!" ]
    }
}

func mainenv(args: Any) -> Any {
     let env = ProcessInfo.processInfo.environment
     var a = "???"
     var b = "???"
     var c = "???"
     var d = "???"
     var e = "???"
     var f = "???"
     if let v : String = env["__OW_API_HOST"] {
         a = "\(v)"
     }
     if let v : String = env["__OW_API_KEY"] {
         b = "\(v)"
     }
     if let v : String = env["__OW_NAMESPACE"] {
         c = "\(v)"
     }
     if let v : String = env["__OW_ACTION_NAME"] {
         d = "\(v)"
     }
     if let v : String = env["__OW_ACTIVATION_ID"] {
         e = "\(v)"
     }
     if let v : String = env["__OW_DEADLINE"] {
         f = "\(v)"
     }
     return ["api_host": a, "api_key": b, "namespace": c, "action_name": d, "activation_id": e, "deadline": f]
}
