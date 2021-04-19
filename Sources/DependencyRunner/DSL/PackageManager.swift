import ShellOut
import Foundation

protocol SolveContext {
    func solve(dependencies: [DependencyExpr]) -> SolveResult
}

protocol PackageManager {
    associatedtype TheSolveContext: SolveContext
    
    func publish(package: Package, version: Version, dependencies: [DependencyExpr])
    func yank(package: Package, version: Version)
    
    func makeSolveContext() -> TheSolveContext
    
    func shutdown()
}





//extension PackageManager {
//    var templateName: String {
//        uniqueName
//    }
//
//    func generate(ecosystem: Ecosystem) {
//        changeToProjectRoot()
//
//        logDebug("Generating dependencies...")
//
//        let _ = try? shellOut(to: "rm", arguments: ["-rf", self.genPathDir])
//        mkdir_p(path: self.genSourcesPathDir)
//
//        generate(inSourceDir: self.genSourcesPathDir, ecosystem: ecosystem)
//    }
//
//    var packageTemplateDir: String {
//        get {
//            "Templates/\(self.templateName)/package/"
//        }
//    }
//    var packageTemplateDir_name: String {
//        get {
//            "package"
//        }
//    }
//
//    var genPathDir: String {
//        get {
//            "generated/\(self.uniqueName)/"
//        }
//    }
//
//    var genSourcesPathDir: String {
//        get {
//            "generated/\(self.uniqueName)/sources/"
//        }
//    }
//}

