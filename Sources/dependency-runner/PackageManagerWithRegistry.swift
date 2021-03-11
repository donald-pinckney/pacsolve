import Files

protocol PackageManagerWithRegistry: PackageManager {
    func initRegistry()
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) -> [String : String]
    
    
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String]
    
    func publish(package: Package, version: Version, pkgDir: String)
    func solveCommand(forMainPath: String) -> SolveCommand
}

extension PackageManagerWithRegistry {
    func generate(inSourceDir: String, dependencies: Dependencies) -> SolveCommand {
        let pkgs = dependencies.allPackages()
        for pkg in pkgs {
            for v in pkg.versions {
                let deps = dependencies.non_main_deps[pkg]?[v] ?? []
                generate(inDir: inSourceDir, package: pkg, version: v, dependencies: deps)
            }
        }
        
        let mainPath = generateMain(inDir: inSourceDir, dependencies: dependencies.main_deps)
        
        for pkg in pkgs {
            for v in pkg.versions {
                let pkgDir = "\(inSourceDir)\(pkg.name)/\(v.directoryName)/"
                publish(package: pkg, version: v, pkgDir: pkgDir)
            }
        }
        
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
        let destParentDir = "\(inDir)\(package.name)/"
        mkdir_p(path: destParentDir)
        let destParentFolder = try! Folder(path: destParentDir)
        
        try! self.packageTemplateDir.copy(to: destParentFolder)
        
        let tmpFolder = try! Folder(path: "\(destParentDir)\(self.packageTemplateDir.name)")
        try! tmpFolder.rename(to: version.directoryName)
        
        let destFolder = try! Folder(path: "\(destParentDir)\(version.directoryName)")

//        print("Generating:\n\tPackage: \(destFolder.path)\n\tdependencies:\(dependencies)\n")

        let substitutions = self.packageTemplateSubstitutions(package: package, version: version, dependencies: dependencies)
        
        
        for f in destFolder.files.recursive {
            rewriteTemplate(file: f, substitutions: substitutions)
        }
        
        for f in destFolder.subfolders.recursive {
            rewriteTemplate(folder: f, substitutions: substitutions)
        }
    }
    
    func generateMain(inDir: String, dependencies: [(Package, VersionSpecifier)]) -> String {
        let mainPkgName = "__main_pkg__"
        
        let destParentDir = inDir
        mkdir_p(path: destParentDir)
        let destParentFolder = try! Folder(path: destParentDir)
        
        try! self.mainTemplateDir.copy(to: destParentFolder)
        
        let tmpFolder = try! Folder(path: "\(destParentDir)\(self.mainTemplateDir.name)")
        try! tmpFolder.rename(to: mainPkgName)
        
        let destFolder = try! Folder(path: "\(destParentDir)\(mainPkgName)")

//        print("Generating:\n\tMain package: \(destFolder)\n\tdependencies:\(dependencies)\n")
        
        let substitutions = mainTemplateSubstitutions(dependencies: dependencies)
        for f in destFolder.files.recursive {
            rewriteTemplate(file: f, substitutions: substitutions)
        }
        
        for f in destFolder.subfolders.recursive {
            rewriteTemplate(folder: f, substitutions: substitutions)
        }
        
        return destFolder.path
    }
}
