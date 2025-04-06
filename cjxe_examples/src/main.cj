package cjxe_examples

import cjxe.{App}
import cjxe.args.{Arg}

main() {
    let matches = App("cjxe")
        .version("1.0.0")
        .author("gtn1024 <gtn1024@foxmail.com>")
        .about("Do something")
        .arg(Arg(name: "config", short: r"c", long: "config")
            .setHelp("Sets a custom config file")
            .setTakesValue(true))
        .arg(Arg(name: "debug", short: r"d").setMultiple(true).setHelp("Turn debugging information on"))
        .arg(Arg(name: "output").setHelp("Sets an optional output file"))
        .subcommand(App("test")
            .about("does testing things")
            .arg(Arg(name: "list", short: r"l", long: "list").setHelp("Lists test vcalues"))
        )
        .getMatches()
    
    if (let Some(o) <- matches.valueOf("output")) {
        println("Value for output: ${o}")
    }

    if (let Some(c) <- matches.valueOf("config")) {
        println("Value for config: ${c}")
    }

    match (matches.occurencesOf("debug")) {
        case 0 => println("Debug mode is off")
        case 1 => println("Debug mode is kind of on")
        case 2 => println("Debug mode is on")
        case _ => println("Crazzzzzzy")
    }

    if (let Some(matches) <- matches.subcommandMatches("test")) {
        if (matches.isPresent("list")) {
            println("Listing test values")
        } else {
            println("No action specified")
        }
    }
}