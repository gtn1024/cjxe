package cjxe.args

public class Arg {
    public let name: String
    public let short: ?Rune
    public let long: ?String
    public var help: ?String = None
    public var required: Bool = false
    public var takesValue: Bool = false
    public var index: ?UInt8 = None
    public var multiple: Bool = false
    public var blacklist: ?Array<String> = None
    public var possibleValues: ?Array<String> = None
    public var requires: ?Array<String> = None

    public init(name!: String, short!: ?Rune = None, long!: ?String = None) {
        this.name = name
        this.short = short
        this.long = long
    }

    public func setHelp(help: String): Arg {
        this.help = help
        this
    }

    public func setRequired(required: Bool): Arg {
        this.required = required
        this
    }

    public func setTakesValue(takesValue: Bool): Arg {
        this.takesValue = takesValue
        this
    }

    public func setIndex(index: UInt8): Arg {
        this.index = index
        this
    }

    public func setMultiple(multiple: Bool): Arg {
        this.multiple = multiple
        this
    }

    public func setBlacklist(blacklist: Array<String>): Arg {
        this.blacklist = blacklist
        this
    }

    public func setPossibleValues(possibleValues: Array<String>): Arg {
        this.possibleValues = possibleValues
        this
    }

    public func setRequires(requires: Array<String>): Arg {
        this.requires = requires
        this
    }
}