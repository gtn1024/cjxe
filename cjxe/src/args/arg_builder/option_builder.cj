package cjxe.args.arg_builder

import std.collection.{HashSet, TreeSet}

public class OptionBuilder {
    public let name: String
    public var short: ?Rune = None
    public var long: ?String = None
    public var help: ?String = None
    public var multiple: Bool = false
    public var blacklist: ?HashSet<String> = None
    public var required: Bool = false
    public var possibleValues: ?TreeSet<String> = None
    public var requires: ?HashSet<String> = None

    public init(name: String) {
        this.name = name
    }
}