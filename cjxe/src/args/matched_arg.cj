package cjxe.args

import std.collection.ArrayList

public class MatchedArg {
    public let name: String
    public var occurences: UInt8 = 0
    public var values: ?ArrayList<String> = None

    public init(name: String) {
        this.name = name
    }
}