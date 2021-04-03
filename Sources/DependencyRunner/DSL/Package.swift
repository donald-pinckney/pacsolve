struct Package : Equatable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    let name: String
    
    init (stringLiteral value: String) {
        self.name = value
    }
    
    var description: String {
        name
    }
}
