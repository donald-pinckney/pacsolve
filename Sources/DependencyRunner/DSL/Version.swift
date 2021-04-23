struct Version : Equatable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
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
}
