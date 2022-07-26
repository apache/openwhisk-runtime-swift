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
  if let baseUrl = newArgs["baseUrl"] as? String {
    //Overriding WHISK API HOST using baseUrl, only applicable in testing with self sign ssl certs"
    Whisk.baseUrl = baseUrl
  }
  guard let triggerName = newArgs["triggerName"] as? String else {
      return ["error": "You must specify a triggerName parameter!"]
  }
  guard let actionName = newArgs["actionName"] as? String else {
      return ["error": "You must specify a actionName parameter!"]
  }
  guard let ruleName = newArgs["ruleName"] as? String else {
      return ["error": "You must specify a ruleName parameter!"]
  }
  print("Rule Name: \(ruleName), Trigger Name: \(triggerName), actionName: \(actionName)")
  return Whisk.createRule(ruleNamed: ruleName, withTrigger: triggerName, andAction: actionName)
}
