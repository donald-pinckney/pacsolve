struct Version : Equatable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible, Codable {
    let major : Int
    let minor : Int
    let bug : Int
    
    init(major: Int, minor: Int, bug: Int) {
        self.major = major
        self.minor = minor
        self.bug = bug
    }
    
    init(stringLiteral value: String) {
        let semverTerms: [Int] = value.split(separator: ".").map { Int.init($0)! }
        self.init(major: semverTerms[0], minor: semverTerms[1], bug: semverTerms[2])
    }
    
    var description: String {
        "\(major).\(minor).\(bug)"
    }
    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encode(self.description)
//    }
//    
//    init(from decoder: Decoder) throws {
//        let str = try decoder.singleValueContainer().decode(String.self)
//        self.init(stringLiteral: str)
//    }
}
