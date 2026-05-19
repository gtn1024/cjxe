# cjxe

[![CI](https://github.com/gtn1024/cjxe/actions/workflows/ci.yml/badge.svg)](https://github.com/gtn1024/cjxe/actions/workflows/ci.yml)

A fast command line argument parser for the Cangjie (仓颉) programming language.

[中文文档](README-zh.md)

## Features

- **Builder API**: Fluent interface for defining arguments, flags, options, and subcommands
- **Automatic help and version**: Generates `-h`/`--help` and `-v`/`--version` automatically
- **Subcommands**: Supports nested subcommands with their own arguments
- **Positional arguments**: Index-based positional arguments with multiple-value support
- **Validation**: Possible values, required arguments, mutual exclusion (`blacklist`), and argument dependencies (`requires`)
- **Error handling**: `ArgError` exception with usage hints instead of silent failures

## Prerequisites

- Cangjie toolchain >= 1.1.0

## Installation

Add to your `cjpm.toml`:

```toml
[dependencies]
  cjxe = "0.3.0"
```

## Quick Start

```cangjie
package demo

import cjxe.{App}
import cjxe.args.{Arg}

main() {
    let matches = App("myapp")
        .version("1.0.0")
        .author("Author Name <email@example.com>")
        .about("Does something great")
        .arg(Arg(name: "config", short: r"c", long: "config")
            .setHelp("Sets a custom config file")
            .setTakesValue(true))
        .arg(Arg(name: "debug", short: r"d")
            .setMultiple(true)
            .setHelp("Turn debugging information on"))
        .arg(Arg(name: "output").setHelp("Sets an optional output file"))
        .subcommand(App("test")
            .about("does testing things")
            .arg(Arg(name: "list", short: r"l", long: "list")
                .setHelp("Lists test values")))
        .getMatchesOrExit()

    if (let Some(o) <- matches.valueOf("output")) {
        println("Value for output: ${o}")
    }

    if (let Some(c) <- matches.valueOf("config")) {
        println("Value for config: ${c}")
    }

    match (matches.occurrencesOf("debug")) {
        case 0 => println("Debug mode is off")
        case 1 => println("Debug mode is kind of on")
        case 2 => println("Debug mode is on")
        case _ => println("Crazzzzzzy")
    }

    if (let Some(testMatches) <- matches.subcommandMatches("test")) {
        if (testMatches.isPresent("list")) {
            println("Listing test values")
        }
    }
}
```

## API Reference

### App

The main entry point for building a command-line argument parser.

| Method | Description |
|--------|-------------|
| `init(name: String)` | Creates a new App with the given name |
| `version(version: String): App` | Sets the version string |
| `author(author: String): App` | Sets the author string |
| `about(about: String): App` | Sets the application description |
| `usage(u: String): App` | Overrides the usage string |
| `afterHelp(h: String): App` | Adds text after the help message |
| `arg(arg: Arg): App` | Adds an argument definition |
| `args(args: Array<Arg>): App` | Adds multiple argument definitions |
| `subcommand(subcmd: App): App` | Adds a subcommand |
| `subcommands(subcmds: Array<App>): App` | Adds multiple subcommands |
| `getMatches(): ArgMatches` | Parses command line arguments from `std.env.getCommandLine()` |
| `getMatchesFrom(args: Array<String>): ArgMatches` | Parses arguments from a given array |
| `getMatchesOrExit(): ArgMatches` | Parses arguments, prints error and exits on failure |

### Arg

Defines a single argument (flag, option, or positional).

| Property / Method | Description |
|-------------------|-------------|
| `init(name!: String, short!: ?Rune, long!: ?String)` | Creates an Arg with optional short/long names |
| `setHelp(help: String): Arg` | Sets the help text |
| `setRequired(required: Bool): Arg` | Marks the argument as required |
| `setTakesValue(takesValue: Bool): Arg` | Makes the argument take a value (option) |
| `setIndex(index: UInt8): Arg` | Sets the positional index |
| `setMultiple(multiple: Bool): Arg` | Allows the argument to appear multiple times |
| `setBlacklist(blacklist: Array<String>): Arg` | Sets mutually exclusive arguments |
| `setPossibleValues(possibleValues: Array<String>): Arg` | Restricts to a set of valid values |
| `setRequires(requires: Array<String>): Arg` | Sets arguments that must also be present |

### ArgMatches

Holds the parsed results.

| Method | Description |
|--------|-------------|
| `valueOf(name: String): ?String` | Returns the value of a named argument |
| `valuesOf(name: String): ?Array<String>` | Returns all values for a multi-value argument |
| `isPresent(name: String): Bool` | Checks if an argument or subcommand is present |
| `occurrencesOf(name: String): UInt8` | Returns how many times an argument appeared |
| `subcommandMatches(name: String): ?ArgMatches` | Returns the matches for a subcommand |

### ArgError

Exception thrown on parse errors.

| Property | Description |
|----------|-------------|
| `message: String` | Error description |
| `showUsage: Bool` | Whether to display usage hint |

## Argument Types

cjxe automatically classifies arguments based on their configuration:

| Type | How to define | Example |
|------|---------------|---------|
| **Flag** | `short` or `long`, no `takesValue`, no `index` | `-d`, `--verbose` |
| **Option** | `short` or `long` + `takesValue(true)` | `-c value`, `--config=value` |
| **Positional** | `index()` or neither `short` nor `long` | `<file>` |

## Running Tests

```bash
cjpm test
```

## License

Licensed under the [MIT License](../LICENSE).
