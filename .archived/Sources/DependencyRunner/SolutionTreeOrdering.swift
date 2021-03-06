
extension ResolvedPackage {
    func normalizedOrder() -> ResolvedPackage {
        ResolvedPackage(
            package: package,
            version: version,
            data: data,
            children: children.map { $0.normalizedOrder() }.sorted(by: <)
        )
    }
    
    static func <(_ lhs: ResolvedPackage, _ rhs: ResolvedPackage) -> Bool {
        if lhs.package == rhs.package {
            if lhs.version == rhs.version {
                return lhs.children < rhs.children
            } else {
                return lhs.version < rhs.version
            }
        } else {
            return lhs.package < rhs.package
        }
    }
}

    
func < <D>(_ lhs: Array<ResolvedPackage<D>>, _ rhs:  Array<ResolvedPackage<D>>) -> Bool {
    if lhs.count < rhs.count {
        return true
    } else if lhs.count > rhs.count {
        return false
    } else {
        for (l, r) in zip(lhs, rhs) {
            if l < r {
                return true
            }
        }
        return false
    }
}

private extension Version {
    static func <(lhs: Version, rhs: Version) -> Bool {
        // Lexicographic ordering
        (lhs.major, lhs.minor, lhs.bug) < (rhs.major, rhs.minor, rhs.bug)
    }
}

//private extension Package {
//    static func <(lhs: Package, rhs: Package) -> Bool {
//        lhs.description < rhs.description
//    }
//}
