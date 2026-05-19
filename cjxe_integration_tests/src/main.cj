package cjxe_integration_tests

import cjxe.{App}
import cjxe.args.{Arg}

main() {
    let matches = App("testapp")
        .version("1.0.0")
        .about("A test app")
        .arg(Arg(name: "config", short: r'c', long: "config")
            .setHelp("Config file")
            .setTakesValue(true))
        .arg(Arg(name: "debug", short: r'd', long: "debug")
            .setMultiple(true)
            .setHelp("Debug mode"))
        .arg(Arg(name: "input")
            .setHelp("Input file")
            .setIndex(1))
        .arg(Arg(name: "output", short: r'o', long: "output")
            .setHelp("Output file"))
        .arg(Arg(name: "format", short: r'f', long: "format")
            .setTakesValue(true)
            .setPossibleValues(["json", "xml", "yaml"]))
        .arg(Arg(name: "required", short: r'r', long: "required")
            .setTakesValue(true)
            .setRequired(true))
        .arg(Arg(name: "port", short: r'P', long: "port")
            .setHelp("Port number")
            .setTakesValue(true)
            .setDefault("8080"))
        .arg(Arg(name: "mode")
            .setHelp("Run mode")
            .setIndex(2)
            .setDefault("dev"))
        .subcommand(App("add")
            .about("adds things")
            .arg(Arg(name: "verbose", short: r'v', long: "verbose")
                .setHelp("Verbose output")))
        .getMatchesOrExit()

    println("config=${matches.valueOf("config").getOrDefault { => "" }}")
    println("debug=${matches.occurrencesOf("debug").toString()}")
    println("input=${matches.valueOf("input").getOrDefault { => "" }}")
    println("output_present=${matches.isPresent("output")}")
    println("format=${matches.valueOf("format").getOrDefault { => "" }}")
    println("port=${matches.valueOf("port").getOrDefault { => "" }}")
    println("mode=${matches.valueOf("mode").getOrDefault { => "" }}")
    if (let Some(sub) <- matches.subcommandMatches("add")) {
        println("subcommand=add")
        println("add_verbose=${sub.isPresent("verbose")}")
    }
}
