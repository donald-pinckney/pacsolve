import Files
//import Glibc

protocol PackageManagerWithRegistry: PackageManager {
    associatedtype PublishData
    
    func initRegistry()
    
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) -> [String : String]
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String]
    
    func publish(package: Package, version: Version, pkgDir: String, dependencies: [(Package, VersionSpecifier)]) -> PublishData
    
    func finalizeRegistry(publishingData: [Package : [Version : PublishData]])
    
    func solveCommand(forMainPath: String) -> SolveCommand
}

extension PackageManagerWithRegistry {
    func generate(inSourceDir: String, dependencies: Dependencies) -> SolveCommand {
        initRegistry()
        
        let pkgs = dependencies.allPackages()
        for pkg in pkgs {
            for v in pkg.versions {
                let deps = dependencies.non_main_deps[pkg]?[v] ?? []
                generate(inDir: inSourceDir, package: pkg, version: v, dependencies: deps)
            }
        }
        
        let mainPath = generateMain(inDir: inSourceDir, dependencies: dependencies.main_deps)
        
        var pkgVersionPublishDataMap: [Package : [Version : PublishData]] = [:]
        
        for pkg in pkgs {
            // Should sort versions, otherwise verdaccio thinks
            // the most recently submitted is the "latest" version.
            let versions = pkg.versions.sorted(by: <)
            for v in versions {
                let pkgDir = "\(inSourceDir)\(pkg.name)/\(v.directoryName)/"
                let deps = dependencies.non_main_deps[pkg]?[v] ?? []
                let pubData = publish(package: pkg, version: v, pkgDir: pkgDir, dependencies: deps)
                pkgVersionPublishDataMap[pkg, default: [:]][v] = pubData
            }
        }
        
        finalizeRegistry(publishingData: pkgVersionPublishDataMap)
        
        return solveCommand(forMainPath: mainPath)
    }
    
    
    func rewriteTemplate(file: File, substitutions: [String : String]) {
        var contents = try! file.readAsString()
        for (templateVar, sub) in substitutions {
            contents = contents.replacingOccurrences(of: templateVar, with: sub)
        }
        try! file.write(contents)
    }
    
    func rewriteTemplate(folder: Folder, substitutions: [String : String]) {
        guard let sub = substitutions[folder.name] else {
            return
        }
        
        try! folder.rename(to: sub)
    }
    
    func generate(inDir: String, package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) {
        let destDir = "\(inDir)\(package.name)/\(version.directoryName)/"
        mkdir_p(path: destDir)
        try! cp_contents(from: self.packageTemplateDir, to: destDir)
        
//        print("Generating:\n\tPackage: \(destFolder.path)\n\tdependencies:\(dependencies)\n")

        let substitutions = self.packageTemplateSubstitutions(package: package, version: version, dependencies: dependencies)
        
        let destFolder = try! Folder(path: destDir)
        
        for f in destFolder.files.recursive.includingHidden {
            print("Rewriting: \(f.path)")
            
            rewriteTemplate(file: f, substitutions: substitutions)
        }
        
        for f in destFolder.subfolders.recursive {
            print("Rewriting folder: \(f.path)")
            rewriteTemplate(folder: f, substitutions: substitutions)
        }
    }
    
    func generateMain(inDir: String, dependencies: [(Package, VersionSpecifier)]) -> String {
        let mainPkgName = "__main_pkg__"
        
        let destDir = "\(inDir)\(mainPkgName)/"
        mkdir_p(path: destDir)
        try! cp_contents(from: self.mainTemplatePath, to: destDir)

        let destFolder = try! Folder(path: destDir)

//        print("Generating:\n\tMain package: \(destFolder)\n\tdependencies:\(dependencies)\n")

        let substitutions = mainTemplateSubstitutions(dependencies: dependencies)
        for f in destFolder.files.recursive.includingHidden {
            rewriteTemplate(file: f, substitutions: substitutions)
        }

        for f in destFolder.subfolders.recursive.includingHidden {
            rewriteTemplate(folder: f, substitutions: substitutions)
        }

        return destDir
    }
}
