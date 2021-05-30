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
}

