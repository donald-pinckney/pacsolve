struct Version : Equatable, Hashable, ExpressibleByStringLiteral {
    let major : Int
    let minor : Int
    let bug : Int
    
    init (major: Int, minor: Int, bug: Int) {
        self.major = major
        self.minor = minor
        self.bug = bug
    }
    
    init (stringLiteral value: String) {
        let semverTerms: [Int] = value.split(separator: ".").map { Int.init($0)! }
        self.init(major: semverTerms[0], minor: semverTerms[1], bug: semverTerms[2])
    }
    
    var directoryName : String {
        get {
            semverName
        }
    }
    
    var semverName : String {
        get {
            "\(major).\(minor).\(bug)"
        }
    }
    
    static func <(lhs: Version, rhs: Version) -> Bool {
        // Lexicographic ordering
        (lhs.major, lhs.minor, lhs.bug) < (rhs.major, rhs.minor, rhs.bug)
    }
}
