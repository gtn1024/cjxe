package cjxe.args.arg_builder

import std.collection.HashSet

public class FlagBuilder {
    public let name: String
    public var long: ?String = None
    public var help: ?String = None
    public var multiple: Bool = false
    public var blacklist: ?HashSet<String> = None
    public var requires: ?HashSet<String> = None
    public var short: ?Rune = None

    public init(name: String) {
        this.name = name
    }
}