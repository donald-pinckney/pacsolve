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

