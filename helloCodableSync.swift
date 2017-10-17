// Domain model/entity
struct Employee: Codable {
  let id: Int
  let name: String
}
// codable main function (sync)
func main(input: Employee) -> Employee {
    // For simplicity, just returning back the same Employee instance
    return input
}