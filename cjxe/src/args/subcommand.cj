package cjxe.args

public class SubCommand {
    let name: String
    let matches: ArgMatches

    public init(name: String, matches: ArgMatches) {
        this.name = name
        this.matches = matches
    }
}