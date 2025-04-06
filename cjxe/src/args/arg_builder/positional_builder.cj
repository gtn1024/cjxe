package cjxe.args.arg_builder

import std.collection.{HashSet, TreeSet}

public class PositionalBuilder {
    public let name: String
    public var help: ?String = None
    public var required: Bool = false
    public var multiple: Bool = false
    public var requires: ?HashSet<String> = None
    public var blacklist: ?HashSet<String> = None
    public var possibleValues: ?TreeSet<String> = None
    public var index: UInt8 = 0

    public init(name: String) {
        this.name = name
    }
}