struct Version : Equatable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible, Codable {
    let major : Int
    let minor : Int
    let bug : Int
    let prerelease : String?
    let build : String?
    
    init(major: Int, minor: Int, bug: Int, prerelease: String? = nil, build: String? = nil) {
        self.major = major
        self.minor = minor
        self.bug = bug
        self.prerelease = prerelease
        self.build = build
    }
    
    init(stringLiteral value: String) {
        let semverTerms: [Int] = value.split(separator: ".").map { Int.init($0)! }
        self.init(major: semverTerms[0], minor: semverTerms[1], bug: semverTerms[2])
    }
    
    var description: String {
        let preStr = prerelease.map { "-\($0)" } ?? ""
        let buildStr = build.map { "+\($0)" } ?? ""
        return "\(major).\(minor).\(bug)\(preStr)\(buildStr)"
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
