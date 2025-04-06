package cjxe

import cjxe.args.{ArgMatches, MatchedArg, SubCommand, Arg}
import cjxe.args.arg_builder.{FlagBuilder, OptionBuilder, PositionalBuilder}
import std.env.{getCommandLine, exit}
import std.fs.Path
import std.collection.{HashMap, TreeMap, ArrayList, HashSet, TreeSet}

const tab = "    "

public class App {
    let _name: String
    var _author: ?String = None
    var _version: ?String = None
    var _about: ?String = None
    var _binName: ?String = None
    var _needsLongHelp: Bool = true
    var _needsShortHelp: Bool = true
    var _needsSubcommandHelp: Bool = true
    var _needsLongVersion: Bool = true
    var _needsShortVersion: Bool = true
    let _flags: HashMap<String, FlagBuilder> = HashMap()
    let _opts: HashMap<String, OptionBuilder> = HashMap()
    let _subcommands: HashMap<String, App> = HashMap()
    let _required: HashSet<String> = HashSet()
    let _matchedReqs: HashSet<String> = HashSet()
    let _argList: ArrayList<String> = ArrayList()
    let _shortList: ArrayList<Rune> = ArrayList()
    let _longList: ArrayList<String> = ArrayList()
    var _moreHelp: ?String = None
    var _usageStr: ?String = None
    let _positionalIdx: TreeMap<UInt8, PositionalBuilder> = TreeMap()
    let _blacklist: HashSet<String> = HashSet()

    public init(name: String) {
        this._name = name
    }

    public func author(author: String): App {
        this._author = Some(author)
        this
    }

    public func afterHelp(h: String): App {
        this._moreHelp = Some(h)
        this
    }

    public func version(version: String): App {
        this._version = Some(version)
        this
    }

    public func usage(u: String): App {
        this._usageStr = Some(u)
        this
    }

    public func about(about: String): App {
        this._about = Some(about)
        this
    }

    public func subcommand(subcmd: App): App {
        if (subcmd._name == "help") {
            this._needsSubcommandHelp = false
        }
        this._subcommands.add(subcmd._name, subcmd)
        this
    }

    public func subcommands(subcmds: Array<App>): App {
        for (subcmd in subcmds) {
            this.subcommand(subcmd)
        }
        this
    }

    private func handlePositionalArg(arg: Arg): Unit {
        let i = arg.index.getOrDefault { => UInt8(this._positionalIdx.size + 1) }

        if (arg.short.isSome() || arg.long.isSome()) {
            this.reportError("Argument \"${arg.name}\" has conflicting requirements, both index() and short(), or long(), were supplied", true, true)
        }

        if (this._positionalIdx.contains(i)) {
            this.reportError("Argument \"${arg.name}\" has the same index as another positional argument", true, true)
        }
        if (arg.takesValue) {
            this.reportError("Argument \"${arg.name}\" has conflicting requirements, both index() and takes_value(true) were supplied", true, true)
        }

        let pb = PositionalBuilder(arg.name)
        pb.index = i
        pb.required = arg.required
        pb.multiple = arg.multiple
        pb.help = arg.help
        // Check if there is anything in the blacklist (mutually excludes list) and add any values
        if (let Some(bl) <- arg.blacklist) {
            let bhs = HashSet<String>()
            for (n in bl) {
                bhs.add(n)
            }
            pb.blacklist = Some(bhs)
        }
        // Check if there is anything in the requires list and add any values
        if (let Some(r) <- arg.requires) {
            let rhs = HashSet<String>()
            // without derefing n = &&str
            for (n in r) { 
                rhs.add(n)
            }
            pb.requires = Some(rhs)
        }
        // Check if there is anything in the possible values and add those as well
        if (let Some(p) <- arg.possibleValues) {
            let phs = TreeSet<String>()
            // without derefing n = &&str
            for (n in p) {
                phs.add(n)
            }
            pb.possibleValues = Some(phs)
        }
        this._positionalIdx.add(i, pb)
    }

    private func handleOptionArg(arg: Arg): Unit {
        if (arg.short.isNone() && arg.long.isNone()) {
            this.reportError("Argument \"${arg.name}\" has conflicting requirements, neither short(), and long(), were supplied", true, true)
        }
        let ob = OptionBuilder(arg.name)
        ob.short = arg.short
        ob.long = arg.long
        ob.multiple = arg.multiple
        ob.help = arg.help
        ob.required = arg.required
        if (let Some(bl) <- arg.blacklist) {
            let bhs = HashSet<String>()
            for (n in bl) {
                bhs.add(n)
            }
            ob.blacklist = Some(bhs)
        }
        if (let Some(r) <- arg.requires) {
            let rhs = HashSet<String>()
            for (n in r) {
                rhs.add(n)
            }
            ob.requires = Some(rhs)
        }
        if (let Some(p) <- arg.possibleValues) {
            let phs = TreeSet<String>()
            for (n in p) {
                phs.add(n)
            }
            ob.possibleValues = Some(phs)
        }
        this._opts.add(arg.name, ob)
    }

    private func handleFlagArg(arg: Arg): Unit {
        if (arg.short.isNone() && arg.long.isNone()) {
            this.reportError("Argument \"${arg.name}\" has conflicting requirements, neither short(), and long(), were supplied", true, true)
        }
        if (arg.required) {
            this.reportError("Argument \"${arg.name}\" has conflicting requirements, because it has no index() or takesValue(true)", true, true)
        }
        if (arg.possibleValues.isSome()) {
            this.reportError("Argument \"${arg.name}\" cannot have a specific value set because it doesn't have takesValue(true) set", true, true)
        }

        let fb = FlagBuilder(arg.name)
        fb.short = arg.short
        fb.long = arg.long
        fb.help = arg.help
        fb.multiple = arg.multiple
        if (let Some(bl) <- arg.blacklist) {
            let bhs = HashSet<String>()
            for (n in bl) {
                bhs.add(n)
            }
            fb.blacklist = Some(bhs)
        }
        if (let Some(r) <- arg.requires) {
            let rhs = HashSet<String>()
            for (n in r) {
                rhs.add(n)
            }
            fb.requires = Some(rhs)
        }
        this._flags.add(arg.name, fb)
    }

    public func arg(arg: Arg): App {
        if (this._argList.contains(arg.name)) {
            this.reportError("Argument \"${arg.name}\" is already defined", true, true)
        } else {
            this._argList.add(arg.name)
        }
        if (let Some(short) <- arg.short) {
            if (this._shortList.contains(short)) {
                this.reportError("Short argument \"-${short}\" is already defined", true, true)
            } else {
                this._shortList.add(short)
            }
            if (short == r"h") {
                this._needsShortHelp = false
            } else if (short == r"v") {
                this._needsShortVersion = false
            }
        }
        if (let Some(long) <- arg.long) {
            if (this._longList.contains(long)) {
                this.reportError("Long argument \"--${long}\" is already defined", true, true)
            } else {
                this._longList.add(long)
            }
            if (long == "help") {
                this._needsLongHelp = false
            } else if (long == "version") {
                this._needsLongVersion = false
            }
        }
        if (arg.required) {
            this._required.add(arg.name)
        }
        if (arg.index.isSome() || (arg.short.isNone() && arg.long.isNone())) {
            this.handlePositionalArg(arg)
        } else if (arg.takesValue) {
            this.handleOptionArg(arg)
        } else {
            this.handleFlagArg(arg)
        }
        this
    }

    public func args(args: Array<Arg>): App {
        for (arg in args) {
            this.arg(arg)
        }
        this
    }

    public func getMatches(): ArgMatches {
        this.verifyPositionals()
        for (sc in this._subcommands.values()) {
            sc.verifyPositionals()
        }

        let matches = ArgMatches()

        let args = getCommandLine()
        let it = args.iterator()
        if (let Some(name) <- it.next()) {
            try {
                this._binName = Some(Path(name).fileName)
            } catch(e: IllegalArgumentException) {
                this._binName = None
            }
        }
        this.getMatchesFrom(matches, it)

        matches
    }

    func verifyPositionals() {
        if (let Some((idx, p)) <- this._positionalIdx.last) {
            if (idx != UInt8(this._positionalIdx.size)) {
                this.reportError("Positional argument \"${p.name}\" has an index that is not the last index", true, true)
            }
        }
        if (let Some(p) <- this._positionalIdx.values().iterator().filter { a => a.multiple}.filter { a => a.index != UInt8(this._positionalIdx.size) }.first()) {
            this.reportError("Positional argument \"${p.name}\" is not the last positional argument", true, true)
        }

        var found = false
        let revPositionalIdx = this._positionalIdx.toArray()
        revPositionalIdx.reverse()
        for ((_, p) in revPositionalIdx) {
            if (found) {
                p.required = true
                this._required.add(p.name)
                continue
            }
            if (p.required) {
                found = true
            }
        }
    }

    func createHelpAndVersion() {
        if (this._needsLongHelp) {
            let arg = FlagBuilder("hcjxe_help")
            arg.long = "help"
            arg.help = "Prints help information"
            if (this._needsShortHelp) {
                arg.short = r'h'
            }
            this._flags.add("hcjxe_help", arg)
        }
        if (this._needsLongVersion) {
            let arg = FlagBuilder("vclap_version")
            arg.long = "version"
            arg.help = "Prints version information"
            if (this._needsShortVersion) {
                arg.short = r'v';
            }
            this._flags.add("vcjxe_version", arg);
        }
        if (this._needsSubcommandHelp && !this._subcommands.isEmpty()) {
            this._subcommands.add("help", App("help").about("Prints this message"))
        }
    }

    func printFlagHelp(longestFlag: Int64) {
        println()
        println("FLAGS:")
        for (v in this._flags.values()) {
            let sb = StringBuilder()
            sb.append(tab)
            if (let Some(s) <- v.short) {
                sb.append("-${s}")
            } else {
                sb.append(tab)
            }
            if (let Some(l) <- v.long) {
                if (v.short.isSome()) {
                    sb.append(", ")
                }
                sb.append("--${l}")
                sb.append(this.getSpaces((longestFlag + 4) - (l.size + 2)))
            } else {
                sb.append(this.getSpaces(longestFlag + 6))
            }
            sb.append(v.help.getOrDefault { => tab })
            println(sb.toString())
        }
    }

    func printOptHelp(longestOpt: Int64) {
        println()
        println("OPTIONS:")
        for (v in this._opts.values()) {
            let mult = if (v.multiple) { 3 } else { 0 }
            let sb = StringBuilder()
            sb.append(tab)
            if (let Some(s) <- v.short) {
                sb.append("-${s}")
            } else {
                sb.append(tab)
            }
            if (let Some(l) <- v.long) {
                if (v.short.isSome()) {
                    sb.append(", ")
                }
                sb.append("--${l}=")
            } else {
                sb.append(" ")
            }
            sb.append(v.name)
            if (v.multiple) {
                sb.append("...")
            }
            if (let Some(l) <- v.long) {
                sb.append(this.getSpaces((longestOpt + 4) - (l.size + v.name.size + 2 + mult)))
            } else {
                sb.append(this.getSpaces((longestOpt + 6) - (v.name.size + mult)))
            }
            if (let Some(h) <- v.help) {
                sb.append(h)
                if (let Some(pv) <- v.possibleValues) {
                    let pvStr = pv.iterator().fold(StringBuilder()) { acc, name =>
                        acc.append(" ${name}")
                        acc
                    }
                    sb.append(" [values:${pvStr.toString()}]")
                }
            } else {
                sb.append(tab)
            }
            println(sb.toString())
        }
    }

    func printPosHelp(longestPos: Int64) {
        println()
        println("POSITIONAL ARGUMENTS:")
        for (v in this._positionalIdx.values()) {
            let mult = if (v.multiple) { 3 } else { 0 }
            let sb = StringBuilder()
            sb.append(tab)
            if (v.multiple) {
                sb.append("${v.name}...")
            } else {
                sb.append(v.name)
            }
            sb.append(this.getSpaces((longestPos + 4) - (v.name.size + mult)))
            if (let Some(h) <- v.help) {
                sb.append(h)
                if (let Some(pv) <- v.possibleValues) {
                    let pvStr = pv.iterator().fold(StringBuilder()) { acc, name =>
                        acc.append(" ${name}")
                        acc
                    }
                    sb.append(" [values:${pvStr.toString()}]")
                }
            } else {
                sb.append(tab)
            }
            println(sb.toString())
        }
    }

    func printSubcommandHelp(longestSubcommand: Int64) {
        println()
        println("SUBCOMMANDS:")
        for (sc in this._subcommands.values()) {
            let sb = StringBuilder()
            sb.append(tab)
            sb.append(sc._name)
            sb.append(this.getSpaces((longestSubcommand + 4) - (sc._name.size)))
            if (let Some(a) <- sc._about) {
                sb.append(a)
            } else {
                sb.append(tab)
            }
            println(sb.toString())
        }
    }

    func printHelp() {
        this.printVersion(false)
        let flags = !this._flags.isEmpty()
        let pos = !this._positionalIdx.isEmpty()
        let opts = !this._opts.isEmpty()
        let subcmds =!this._subcommands.isEmpty()

        var longestFlag = 0
        for (fl in this._flags.values().iterator().filterMap { f => f.long }.map { l => l.size + 2 }) {
            if (longestFlag < fl) {
                longestFlag = fl
            }
        }
        var longestOpt = 0
        for (ol in this._opts.values().iterator().filterMap { o => 
            if (o.long.isSome()) {
                let mult = if (o.multiple) { 3 } else { 0 }
                Some(o.long.getOrThrow().size + mult + o.name.size + 3)
            } else {
                None<Int64>
            }
        }) {
            if (longestOpt < ol) {
                longestOpt = ol
            }
        }
        var longestPos = 0
        for (pl in this._positionalIdx.values().iterator().map { f => if (f.multiple) { f.name.size + 3 } else { f.name.size } }) {
            if (longestPos < pl) {
                longestPos = pl
            }
        }
        var longestSubcommand = 0
        for (scl in this._subcommands.values().iterator().map {sc => sc._name.size}) {
            if (longestSubcommand < scl) {
                longestSubcommand = scl
            }
        }

        if (let Some(author) <- this._author) {
            println(author)
        }
        if (let Some(about) <- this._about) {
            println(about)
        }
        println()
        this.printUsage(false)
        if (flags || opts || pos || subcmds) {
            println()
        }
        if (flags) {
            printFlagHelp(longestFlag)
        }
        if (opts) {
            printOptHelp(longestOpt)
        }
        if (pos) {
            printPosHelp(longestPos)
        }
        if (subcmds) {
            printSubcommandHelp(longestSubcommand)
        }

        if (let Some(h) <- this._moreHelp) {
            println()
            println(h)
        }

        exit(0)
    }

    func getSpaces(num: Int64): String {
        match (num) {
            case 0 => ""
            case 1 => " "
            case 2 => "  "
            case 3 => "   "
            case 4 => "    "
            case 5 => "     "
            case 6 => "      "
            case 7 => "       "
            case 8 => "        "
            case 9 => "         "
            case 10 => "          "
            case 11 => "           "
            case 12 => "            "
            case 13 => "             "
            case 14 => "              "
            case 15 => "               "
            case 16 => "                "
            case 17 => "                 "
            case 18 => "                  "
            case 19 => "                   "
            case 20 => "                    "
            case 21 => "                     "
            case 22 => "                      "
            case 23 => "                       "
            case 24 => "                        "
            case 25 => "                         "
            case 26 => "                          "
            case 27 => "                           "
            case 28 => "                            "
            case _  => "                             "
        }
    }

    func printVersion(quit: Bool) {
        println("${this._name} ${this._version.getOrDefault { => "" }}")
        if (quit) {
            exit(0)
        }
    }

    func printUsage(moreInfo: Bool) {
        print(this.createUsage())
        if (moreInfo) {
            println("\nFor more information try --help")
        }
    }

    func createUsage(): String {
        let usage = StringBuilder()
        usage.append("USAGE:\n")
        usage.append(tab)
        if (let Some(u) <- this._usageStr) {
            usage.append(u)
        } else {
            let flags = !this._flags.isEmpty()
            let pos = !this._positionalIdx.isEmpty()
            let opts = !this._opts.isEmpty()
            let subcmds =!this._subcommands.isEmpty()
            let matchedPosReqs = HashSet<String>()
            // If it's required we also need to ensure all previous positionals are required too
            var found = false
            let positional = this._positionalIdx.values().toArray()
            positional.reverse()
            for (p in positional) {
                if (found) {
                    matchedPosReqs.add(p.name)
                    continue
                }
                if (this._matchedReqs.contains(p.name)) {
                    matchedPosReqs.add(p.name)
                    found = true
                }
            }
            
            let requiredPositionalArgs = this._positionalIdx.values().iterator().filterMap { p =>
                if (p.required || matchedPosReqs.contains(p.name)) {
                    if (p.multiple) {
                        Some("${p.name}...")
                    } else {
                        Some(p.name)
                    }
                } else {
                    None<String>
                }
            }
            let numRequiredPos = requiredPositionalArgs.count()
            let requiredPositionalArgsStr = requiredPositionalArgs.fold(StringBuilder()) { acc, name =>
                acc.append("${name} ")
                acc
            }.toString()
            let requiredOpts = this._opts.values().iterator().filterMap { o =>
                if (o.required || this._matchedReqs.contains(o.name)) {
                    Some(o)
                } else {
                    None<OptionBuilder>
                }
            }
            let numRequiredOpts = requiredOpts.count()
            let requiredOptsStr = requiredOpts.fold(StringBuilder()) { acc, o =>
                let sb = StringBuilder("-")
                if (let Some(l) <- o.long) {
                    sb.append("-${l}")
                } else {
                    sb.append(o.short.getOrThrow())
                }
                sb.append("${o.name} ")
                acc.append(sb)
                acc
            }.toString()

            usage.append(this._binName.getOrDefault { => this._name })
            if (flags) {
                usage.append(" [FLAGS]")
            }
            if (opts) {
                var s = ""
                if (numRequiredPos != this._opts.size && !requiredOptsStr.isEmpty()) {
                    s = "[OPTIONS] ${requiredOptsStr}"
                } else if (requiredOptsStr.isEmpty()) {
                    s = "[OPTIONS]"
                } else {
                    s = requiredOptsStr
                }
                usage.append(" ${s}")
            }
            if (pos) {
                var s = ""
                if (numRequiredPos != this._positionalIdx.size && !requiredPositionalArgsStr.isEmpty()) {
                    s = "[POSITIONAL] ${requiredPositionalArgsStr}"
                } else if (requiredPositionalArgsStr.isEmpty()) {
                    s = "[POSITIONAL]"
                } else {
                    s = requiredPositionalArgsStr
                }
                usage.append(" ${s}")
            }
            if (subcmds) {
                usage.append(" [SUBCOMMAND]")
            }
        }

        usage.toString()
    }

    func reportError(msg: String, usage: Bool, quit: Bool) {
        println(msg)
        if (usage) {
            printUsage(true)
        }
        if (quit) {
            exit(1)
        }
    }

    func parseOptions(matches: ArgMatches, argName: ?String, argValue: ?String, opt: OptionBuilder): ?String {
        if (matches.args.contains(opt.name)) {
            if (!opt.multiple) {
                this.reportError("Argument \"${argName}\" cannot be specified more than once", true, true)
            }
            if (let Some(pVals) <- opt.possibleValues && let Some(argValue) <- argValue && !pVals.contains(argValue))  {
                let validOpts = String.join(pVals.toArray(), delimiter: ", ")
                let msg = "\n    ${argName} requires one of ${validOpts}\n"
                this.reportError("\"${argValue}\" is not a valid value for ${argName}${msg}", true, true)
            }
            if (let Some(av) <- argValue && let Some(o) <- matches.args.get(opt.name)) {
                o.occurences += 1
                if (let Some(values) <- o.values) {
                    values.add(av)
                }
            }
        } else {
            let ma = MatchedArg(opt.name)
            ma.occurences = if (argValue.isSome()) { 1 } else { 0 }
            let al = ArrayList<String>()
            if (let Some(argValue) <- argValue) {
                al.add(argValue)
            }
            ma.values = Some(al)
            matches.args.add(opt.name, ma)
        }

        this._required.remove(opt.name)

        if (let Some(reqs) <- opt.requires) {
            for (n in reqs) {
                this._matchedReqs.add(n)
                if (matches.args.contains(n)) {
                    continue
                }

                this._required.add(n)
            }
        }
        match (argValue) {
            case None => return Some(opt.name)
            case _ => return None
        }
    }

    func parseFlags(matches: ArgMatches, argName: ?String, flag: FlagBuilder): ?String {
        if (matches.args.contains(flag.name) && !flag.multiple) {
            this.reportError("Argument \"${argName}\" cannot be specified more than once", true, true)
        }

        var done = false
        if (let Some(f) <- matches.args.get(flag.name)) {
            done = true
            f.occurences = if (flag.multiple) { f.occurences + 1 } else { 1 }
        }
        if (!done) {
            let ma = MatchedArg(flag.name)
            ma.occurences = 1
            matches.args.add(flag.name, ma)
        }

        this._required.remove(flag.name)

        if (let Some(reqs) <- flag.requires) {
            for (n in reqs) {
                this._matchedReqs.add(n)
                if (matches.args.contains(n)) {
                    continue
                }
                this._required.add(n)
            }
        }
        None
    }

    func parseLongArg(matches: ArgMatches, fullArg: String): ?String {
        var arg = fullArg.trimStart { c => c == r'-' }

        if (arg == "help" && this._needsLongHelp) {
            this.printHelp()
        } else if (arg == "version" && this._needsLongVersion) {
            this.printVersion(true)
        }

        var argVal: ?String = None

        if (arg.contains("=")) {
            let args = arg.split("=")
            arg = args[0]
            if (args[1].size == 0) {
                this.reportError("Argument \"${arg}\" requires a value", true, true)
            }
            argVal = Some(args[1])
        }
        let argName = arg
        let argValue = argVal

        if (let Some(opt) <- this._opts.values().iterator().filter { opt => opt.long.isSome() }.filter { opt => opt.long == argName }.first()) { 
            return this.parseOptions(matches, argName, argValue, opt)
        }

        if (let Some(flag) <- this._flags.values().iterator().filter { flag => flag.long.isSome() }.filter { flag => flag.long == argName }.first()) {
            return this.parseFlags(matches, argName, flag)
        }

        this.reportError("Argument \"${argName}\" is not recognized", true, true)
        None
    }

    func checkForHelpAndVersion(arg: Rune) {
        if (arg == r'h' && this._needsShortHelp) {
            this.printHelp();
        } else if (arg == r'v' && this._needsShortVersion) {
            this.printVersion(true);
        }
    }

    func parseSingleShortFlag(matches: ArgMatches, arg: Rune): Bool {
        if (let Some(flag) <- this._flags.values().iterator().filter { flag => flag.short == arg}.first()) {
            if (this._blacklist.contains(flag.name)) {
                this.reportError("Argument \"-${arg} cannot be used with one or more of the other specified arguments", true, true)
            }

            if (matches.args.contains(flag.name) && !flag.multiple) {
                this.reportError("Argument \"-${arg}\" cannot be specified more than once", true, true)
            }

            var done = false
            if (let Some(f) <- matches.args.get(flag.name)) {
                done = true
                f.occurences = if (flag.multiple) { f.occurences + 1 } else { 1 }
            }
            if (!done) {
                let ma = MatchedArg(flag.name)
                ma.occurences = 1
                matches.args.add(flag.name, ma)
            }

            this._required.remove(flag.name)

            if (let Some(bl) <- flag.blacklist) {
                for (name in bl) {
                    this._blacklist.add(name)
                    this._required.remove(name)
                }
            }

            if (let Some(reqs) <- flag.requires) {
                for (n in reqs) {
                    this._matchedReqs.add(n)
                    if (matches.args.contains(n)) {
                        continue
                    }
                    this._required.add(n)
                }
            }
            return true
        }
        false
    }

    func parseShortArg(matches: ArgMatches, fullArg: String):?String {
        let arg = fullArg.trimStart { c => c == r'-'}
        if (arg.size > 1) {
            // Multiple flags using short flags, i.e. -xvzf
            for (c in arg.runes()) {
                this.checkForHelpAndVersion(c)
                if (!this.parseSingleShortFlag(matches, c)) {
                    this.reportError("Argument -${arg} is not valid", true, true)
                }
            }
            return None
        }
        // short flag or opt
        let argC = arg.runes().first().getOrThrow()

        this.checkForHelpAndVersion(argC)

        if (this.parseSingleShortFlag(matches, argC)) {
            return None
        }

        if (let Some(v) <- this._opts.values().iterator().filter { opt => opt.short == argC}.first()) {
            if (this._blacklist.contains(v.name)) {
                this.reportError("Argument \"-${argC}\" cannot be used with one or more of the other specified arguments", true, true)
            }

            if (matches.args.contains(v.name)) {
                if (!v.multiple) {
                    this.reportError("Argument \"-${argC}\" cannot be specified more than once", true, true)
                }
            } else {
                let ma = MatchedArg(v.name)
                ma.occurences = 0
                ma.values = Some(ArrayList())
                matches.args.add(v.name, ma)
            }
            if (let Some(bl) <- v.blacklist) {
                for (name in bl) {
                    this._blacklist.add(name)
                    this._required.remove(name)
                }
            }

            this._required.remove(v.name)

            if (let Some(reqs) <- v.requires) {
                for (n in reqs) {
                    this._matchedReqs.add(n)
                    if (matches.args.contains(n)) {
                        continue
                    }
                    this._required.add(n)
                }
            }
            return Some(v.name)
        }

        this.reportError("Argument -${arg} is not valid", true, true)
        None
    }

    func getMatchesFrom(matches: ArgMatches, it: Iterator<String>): Unit {
        this.createHelpAndVersion()

        var posOnly = false
        var subcmd_name: ?String = None
        var needsValueOf: ?String = None
        var posCounter: UInt8 = 1
        while (let Some(arg) <- it.next()) {
            var skip = false
            if (!posOnly && let Some(nvo) <- needsValueOf && let Some(opt) <- this._opts.get(nvo)) {
                if (let Some(pvals) <- opt.possibleValues) {
                    if (!pvals.isEmpty() && !pvals.contains(arg)) {
                        let optName = if (opt.long.isSome()) {
                            "--${opt.long}"
                        } else {
                            "-${opt.short}"
                        }
                        let validOpts = String.join(pvals.toArray(), delimiter: ", ")
                        let msg = "\n    ${optName} requires one of ${validOpts}\n"
                        this.reportError("\"${arg}\" is not a valid value for ${optName}${msg}", true, true)
                    }
                }
                if (let Some(o) <- matches.args.get(opt.name)) {
                    if (let Some(values) <- o.values) {
                        values.add(arg)
                    }
                    o.occurences = if (opt.multiple) { o.occurences + 1 } else { 1 }
                }

                skip = true
            }
            if (skip) {
                needsValueOf = None
                continue
            }

            if (arg.startsWith("--") && !posOnly) {
                // Process long(--) arguments
                if (arg.size == 2) {
                    posOnly = true
                    continue
                }
                needsValueOf = this.parseLongArg(matches, arg)
            } else if (arg.startsWith("-") && arg.size != 1 && !posOnly) {
                // Process short(-) arguments
                needsValueOf = this.parseShortArg(matches, arg)
            } else {
                // Process positional or subcommand arguments
                if (this._subcommands.contains(arg)) {
                    if (arg == "help") {
                        this.printHelp()
                    }
                    subcmd_name = Some(arg)
                    break
                }

                if (this._positionalIdx.isEmpty()) {
                    this.reportError("Argument \"${arg}\" is not recognized", true, true)
                }
                if (let Some(p) <- this._positionalIdx.get(posCounter)) {
                    if (this._blacklist.contains(p.name)) {
                        this.reportError("Argument \"${arg}\" cannot be used with one or more of the other specified arguments", true, true)
                    }

                    if (let Some(pVals) <- p.possibleValues && !pVals.isEmpty() && !pVals.contains(arg)) {
                        let validOpts = pVals.iterator().fold(StringBuilder()) { acc, name =>
                            acc.append(" ${name}")
                            acc
                        }.toString()
                        this.reportError("\"${arg}\" isn't a valid value for ${p.name}\n    [valid values:${validOpts}]", true, true)
                    }
                    var done = false
                    if (p.multiple) {
                        if (let Some(pos) <- matches.args.get(p.name)) {
                            done = true
                            pos.occurences += 1
                            if (let Some(vals) <- pos.values) {
                                vals.add(arg)
                            }
                        }
                    } else {
                        posCounter += 1
                    }
                    if (!done) {
                        let ma = MatchedArg(p.name)
                        ma.occurences = 1
                        ma.values = ArrayList([arg])
                        matches.args.add(p.name, ma)
                    }

                    if (let Some(bl) <- p.blacklist) {
                        for (name in bl) {
                            this._blacklist.add(name)
                            this._required.remove(name)
                        }
                    }

                    this._required.remove(p.name)
                    if (let Some(reqs) <- p.requires) {
                        for (n in reqs) {
                            this._matchedReqs.add(n)
                            if (matches.args.contains(n)) {
                                continue
                            }
                            this._required.add(n)
                        }
                    }
                } else {
                    this.reportError("Argument \"${arg}\" is not recognized", true, true)
                }
            }
        }
        match (needsValueOf) {
            case Some(nvo) => this.reportError("Argument \"${nvo}\" requires a value", true, true)
            case _ =>()
        }

        if (!this._required.isEmpty()) {
            this.reportError("One or more required arguments were not specified", true, true)
        }

        matches.usage = Some(this.createUsage())

        if (let Some(subcmd_name) <- subcmd_name && let Some(sc) <- this._subcommands.get(subcmd_name)) {
            let newMatches = ArgMatches()
            sc._binName = Some("${this._binName ?? "" }${if (this._binName.isSome()) { " " } else { "" }}${sc._name}")
            sc.getMatchesFrom(newMatches, it)
            matches.subcommand = Some(SubCommand(sc._name, newMatches))
        }
    }
}