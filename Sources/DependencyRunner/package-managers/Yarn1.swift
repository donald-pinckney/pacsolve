import Files
import ShellOut

struct Yarn1 : PackageManagerVerdaccioBased {
    init() {}

    let uniqueName = "yarn1"
    
    func solveCommand(package: Package, version: Version) -> String {
        """
            yarn install --silent --registry http://localhost:4873
            node index.js
        """
    }
}
