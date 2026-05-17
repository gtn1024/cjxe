package cjxe_tests

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.{ArrayList, HashMap}

import cjxe.args.{Arg, ArgMatches, MatchedArg, SubCommand}

@Test
func testArgMatchesValueOf_present() {
    let matches = ArgMatches()
    let ma = MatchedArg("config")
    let values = ArrayList<String>()
    values.add("myconfig.toml")
    ma.values = values
    matches.args.add("config", ma)

    let result = matches.valueOf("config")
    @Expect(result.isSome())
    @Expect(result.getOrThrow() == "myconfig.toml")
}

@Test
func testArgMatchesValueOf_absent() {
    let matches = ArgMatches()
    let result = matches.valueOf("config")
    @Expect(result.isNone())
}

@Test
func testArgMatchesValueOf_emptyValues() {
    let matches = ArgMatches()
    let ma = MatchedArg("config")
    ma.values = ArrayList<String>()
    matches.args.add("config", ma)

    let result = matches.valueOf("config")
    @Expect(result.isNone())
}

@Test
func testArgMatchesValuesOf_single() {
    let matches = ArgMatches()
    let ma = MatchedArg("file")
    let values = ArrayList<String>()
    values.add("a.txt")
    ma.values = values
    matches.args.add("file", ma)

    let result = matches.valuesOf("file")
    @Expect(result.isSome())
    let arr = result.getOrThrow()
    @Expect(arr.size == 1)
    @Expect(arr[0] == "a.txt")
}

@Test
func testArgMatchesValuesOf_multiple() {
    let matches = ArgMatches()
    let ma = MatchedArg("file")
    let values = ArrayList<String>()
    values.add("a.txt")
    values.add("b.txt")
    values.add("c.txt")
    ma.values = values
    matches.args.add("file", ma)

    let result = matches.valuesOf("file")
    @Expect(result.isSome())
    let arr = result.getOrThrow()
    @Expect(arr.size == 3)
    @Expect(arr[0] == "a.txt")
    @Expect(arr[1] == "b.txt")
    @Expect(arr[2] == "c.txt")
}

@Test
func testArgMatchesValuesOf_absent() {
    let matches = ArgMatches()
    let result = matches.valuesOf("file")
    @Expect(result.isNone())
}

@Test
func testArgMatchesIsPresent_arg() {
    let matches = ArgMatches()
    let ma = MatchedArg("debug")
    ma.occurrences = 1
    matches.args.add("debug", ma)

    @Expect(matches.isPresent("debug"))
    @Expect(!matches.isPresent("verbose"))
}

@Test
func testArgMatchesIsPresent_subcommand() {
    let matches = ArgMatches()
    let subMatches = ArgMatches()
    matches.subcommand = SubCommand("test", subMatches)

    @Expect(matches.isPresent("test"))
    @Expect(!matches.isPresent("build"))
}

@Test
func testArgMatchesIsPresent_absent() {
    let matches = ArgMatches()
    @Expect(!matches.isPresent("anything"))
}

@Test
func testArgMatchesOccurencesOf() {
    let matches = ArgMatches()
    let ma = MatchedArg("debug")
    ma.occurrences = 3
    matches.args.add("debug", ma)

    @Expect(matches.occurrencesOf("debug") == 3)
    @Expect(matches.occurrencesOf("verbose") == 0)
}

@Test
func testArgMatchesSubcommandMatches_found() {
    let matches = ArgMatches()
    let subMatches = ArgMatches()
    let subMa = MatchedArg("list")
    subMa.occurrences = 1
    subMatches.args.add("list", subMa)
    matches.subcommand = SubCommand("test", subMatches)

    let result = matches.subcommandMatches("test")
    @Expect(result.isSome())
    @Expect(result.getOrThrow().isPresent("list"))
}

@Test
func testArgMatchesSubcommandMatches_wrongName() {
    let matches = ArgMatches()
    let subMatches = ArgMatches()
    matches.subcommand = SubCommand("test", subMatches)

    let result = matches.subcommandMatches("build")
    @Expect(result.isNone())
}

@Test
func testArgMatchesSubcommandMatches_none() {
    let matches = ArgMatches()
    let result = matches.subcommandMatches("test")
    @Expect(result.isNone())
}

@Test
func testArgConstruction() {
    let arg = Arg(name: "config", short: r'c', long: "config")
    @Expect(arg.name == "config")
    @Expect(arg.short == r'c')
    @Expect(arg.long == "config")
    @Expect(arg.help.isNone())
    @Expect(!arg.required)
    @Expect(!arg.takesValue)
    @Expect(arg.index.isNone())
    @Expect(!arg.multiple)
    @Expect(arg.blacklist.isNone())
    @Expect(arg.possibleValues.isNone())
    @Expect(arg.requires.isNone())
}

@Test
func testArgDefaults() {
    let arg = Arg(name: "test")
    @Expect(arg.short.isNone())
    @Expect(arg.long.isNone())
}

@Test
func testArgSetters() {
    let arg = Arg(name: "output")
        .setHelp("Output file")
        .setRequired(true)
        .setTakesValue(true)
        .setIndex(1)
        .setMultiple(true)
        .setBlacklist(["config"])
        .setPossibleValues(["json", "xml"])
        .setRequires(["config"])

    @Expect(arg.help.getOrThrow() == "Output file")
    @Expect(arg.required)
    @Expect(arg.takesValue)
    @Expect(arg.index.getOrThrow() == 1)
    @Expect(arg.multiple)
    @Expect(arg.blacklist.getOrThrow().size == 1)
    @Expect(arg.possibleValues.getOrThrow().size == 2)
    @Expect(arg.requires.getOrThrow().size == 1)
}

@Test
func testMatchedArgDefaults() {
    let ma = MatchedArg("test")
    @Expect(ma.name == "test")
    @Expect(ma.occurrences == 0)
    @Expect(ma.values.isNone())
}

@Test
func testSubCommandConstruction() {
    let matches = ArgMatches()
    let subMatches = ArgMatches()
    let subMa = MatchedArg("list")
    subMatches.args.add("list", subMa)
    let sc = SubCommand("build", subMatches)
    matches.subcommand = sc

    let result = matches.subcommandMatches("build")
    @Expect(result.isSome())
    @Expect(result.getOrThrow().isPresent("list"))
}
