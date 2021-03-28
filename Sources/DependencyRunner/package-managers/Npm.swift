import Files
import ShellOut

public struct Npm : PackageManagerVerdaccioBased {
    public init() {}
    public let name = "npm"

    let solveCommandString =
    """
        npm install --silent --registry http://localhost:4873
        node main.js
    """
    
}
