package cjxe.args

import std.collection.HashMap

public class ArgMatches {
    public let args: HashMap<String, MatchedArg> = HashMap()
    public var usage: ?String = None
    public var subcommand: ?SubCommand = None

    public func valueOf(name: String): ?String {
        if (let Some(arg) <- this.args.get(name) && let Some(values) <- arg.values && let Some(value) <- values.first) {
            return Some(value)
        }
        None
    }

    public func valuesOf(name: String):?Array<String> {
        if (let Some(arg) <- this.args.get(name) && let Some(values) <- arg.values) {
            return Some(values.toArray())
        }
        None
    }

    public func isPresent(name: String): Bool {
        if (let Some(sc) <- this.subcommand) {
            if (sc.name == name) {
                return true
            }
        }
        if (this.args.contains(name)) {
            return true
        }
        false
    }

    public func occurencesOf(name: String): UInt8 {
        if (let Some(arg) <- this.args.get(name)) {
            return arg.occurences
        }
        0
    }

    public func subcommandMatches(name: String): ?ArgMatches {
        if (let Some(sc) <- this.subcommand) {
            if (sc.name != name) {
                return None
            }
            return sc.matches
        }
        None
    }
}