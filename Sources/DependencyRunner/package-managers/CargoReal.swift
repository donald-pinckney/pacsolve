import ShellOut
import Foundation

class CargoRealImpl {
    let dirManager = GenDirManager(baseName: "cargo-real")
    var templateManager = TemplateManager(templateName: "cargo-real")
    
    fileprivate init() {
        self.templateManager.delegate = self
    }
}

extension CargoRealImpl : InternalPackageManager {
    var uniqueName: String { "cargo-real" }
    var shouldRenameVars: Bool { true }
        
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) -> PublishResult {
//        let sourceDir = dirManager.generateUniqueSourceDirectory(forPackage: package, version: version)
        let sourceDir = dirManager.newSourceDirectory(package: package, version: version)
        
        do {
            try templateManager.instantiatePackageTemplate(intoDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
            try shellOut(to: "cargo", arguments: ["publish", "--token", "cioPzxOEZonw5VGcJa44lS3mAFyg4H6W9pr", "--no-verify", "--allow-dirty"], at: sourceDir)
        } catch {
            return .failure(PublishError(message: "\(error)"))
        }
        return .success(())
    }
    
    func yank(package: Package, version: Version) -> YankResult {
        do {
            try shellOut(to: "cargo", arguments: ["yank", "--vers", "\(version)", "\(package)", "--token", "cioPzxOEZonw5VGcJa44lS3mAFyg4H6W9pr"])
        } catch {
            return .failure(YankError(message: "\(error)"))
        }
        return .success(())
    }
    
    func makeSolveContext() -> SolveContext {
        let contextDir = dirManager.newContextDirectory()
        
        let context = CargoSolveContext(contextDir: contextDir, templateManager: self.templateManager)
        return context.solve
    }
    
    func startup() {}
    func shutdown() {}
}


extension CargoRealImpl : TemplateManagerDelegate {
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) throws -> [String : String] {
        let depStrings = try dependencies.map { try $0.cargoRealFormat() }
        return [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.description,
            "$DEPENDENCIES_TOML_FRAGMENT" : depStrings.joined(separator: "\n"),
//            "$DEPENDENCY_IMPORTS" : dependencies.map() { "use \($0.packageToDependOn);" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn)::dep_tree(indent + 1, do_inc);" }.joined(separator: "\n    ")

        ]
    }
}

extension DependencyExpr {
    func cargoRealFormat() throws -> String {
        "\(self.packageToDependOn) = { version = \"\(try self.constraint.cargoFormat())\" }"
    }
}

func CargoReal() -> LocalPackageManager {
    LocalPackageManager(pm: WaitForUpdateManager(wrapping: CargoRealImpl(), sleepTime: 60))
}
