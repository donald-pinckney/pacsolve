import Files
import ShellOut

public struct Yarn1 : PackageManagerVerdaccioBased {
    public init() {}

    public let name = "yarn1"
    
    let solveCommandString =
    """
        yarn install --silent --registry http://localhost:4873
        node main.js
    """
}
