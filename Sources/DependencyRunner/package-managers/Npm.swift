import Files
import ShellOut

struct Npm : PackageManagerVerdaccioBased {
    init() {}
    let name = "npm"
    
    func solveCommand(package: Package, version: Version) -> String {
        """
            npm install --silent --registry http://localhost:4873
            node main.js
        """
    }
    
}
