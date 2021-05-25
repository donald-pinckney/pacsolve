import Foundation
import CryptoSwift

struct Utils {

    static private func cd(path: String) {
        FileManager().changeCurrentDirectoryPath(path)
    }


    static private func projectRootDir() -> URL {
        let myPath = URL(fileURLWithPath: #filePath)
        return myPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }


    static private var didSetWd = false

    static func cdToProjectRoot() {
        if !didSetWd {
            didSetWd = true
            cd(path: projectRootDir().path)
        }
    }
}


extension String {
    func quoted() -> String {
        "'\(self)'"
    }
}

//enum EcosystemOp: Codable {
//    case publish(package: Package, version: Version, dependencies: [DependencyExpr])
//    case yank(package: Package, version: Version)
//    case solve(inContext: ContextVar, constraints: [DependencyExpr])
//
//    enum CodingKeys: CodingKey {
//        case op_publish
//        case op_yank
//        case op_solve
//    }
//
//    enum InnerKeys: CodingKey {
//        case package
//        case version
//        case dependencies
//        case context
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        switch self {
//        case let .publish(package: p, version: v, dependencies: deps):
//            var args = container.nestedContainer(keyedBy: InnerKeys.self, forKey: .op_publish)
//            try args.encode(p, forKey: .package)
//            try args.encode(v, forKey: .version)
//            try args.encode(deps, forKey: .dependencies)
//        case let .yank(package: p, version: v):
//            var args = container.nestedContainer(keyedBy: InnerKeys.self, forKey: .op_yank)
//            try args.encode(p, forKey: .package)
//            try args.encode(v, forKey: .version)
//        case let .solve(inContext: ctx, constraints: cs):
//            var args = container.nestedContainer(keyedBy: InnerKeys.self, forKey: .op_solve)
//            try args.encode(ctx, forKey: .context)
//            try args.encode(cs, forKey: .dependencies)
//        }
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let keys = container.allKeys
//        if keys.count != 1 {
//            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected exactly 1 key when decoding EcosystemOp"))
//        }
//
//        let k = keys[0]
//        switch k {
//        case .op_publish:
//            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
//            try self = .publish(
//                package: inner.decode(Package.self, forKey: .package),
//                version: inner.decode(Version.self, forKey: .version),
//                dependencies: inner.decode([DependencyExpr].self, forKey: .dependencies))
//        case .op_yank:
//            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
//            try self = .yank(
//                package: inner.decode(Package.self, forKey: .package),
//                version: inner.decode(Version.self, forKey: .version))
//        case .op_solve:
//            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
//            try self = .solve(
//                inContext: inner.decode(ContextVar.self, forKey: .context),
//                constraints: inner.decode([DependencyExpr].self, forKey: .dependencies))
//        }
//    }
//}

extension Result: Codable where Success: Codable, Failure: Codable {
    enum CodingKeys: CodingKey {
        case result_success
        case result_failure
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keys = container.allKeys
        if keys.count != 1 {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected exactly 1 key when decoding EcosystemOp"))
        }

        let k = keys[0]
        switch k {
        case .result_success: self = .success(try container.decode(Success.self, forKey: k))
        case .result_failure: self = .failure(try container.decode(Failure.self, forKey: k))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .success(let x): try container.encode(x, forKey: .result_success)
        case .failure(let err): try container.encode(err, forKey: .result_failure)
        }
    }
    
    
    //    init(from decoder: Decoder) throws {
    //        let container = try decoder.container(keyedBy: CodingKeys.self)
    //        let keys = container.allKeys
    //        if keys.count != 1 {
    //            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected exactly 1 key when decoding EcosystemOp"))
    //        }
    //
    //        let k = keys[0]
    //        switch k {
    //        case .op_publish:
    //            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
    //            try self = .publish(
    //                package: inner.decode(Package.self, forKey: .package),
    //                version: inner.decode(Version.self, forKey: .version),
    //                dependencies: inner.decode([DependencyExpr].self, forKey: .dependencies))
    //        case .op_yank:
    //            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
    //            try self = .yank(
    //                package: inner.decode(Package.self, forKey: .package),
    //                version: inner.decode(Version.self, forKey: .version))
    //        case .op_solve:
    //            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
    //            try self = .solve(
    //                inContext: inner.decode(ContextVar.self, forKey: .context),
    //                constraints: inner.decode([DependencyExpr].self, forKey: .dependencies))
    //        }
    //    }
    
}
