package cjxe

public class ArgError <: Exception {
    public let showUsage: Bool

    public init(message: String, showUsage!: Bool = false) {
        super(message)
        this.showUsage = showUsage
    }
}
