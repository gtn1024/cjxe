<div align="center">
  <h1>cjxe</h1>
  <p>A Fast Command Line Argument Parser for Cangjie.</p>
</div>
<p align="center">
  <img alt="" src="https://github.com/gtn1024/cjxe/actions/workflows/ci.yml/badge.svg" style="display: inline-block;" />
</p>

[中文文档](README-zh.md)

## Features

- **Builder API**: Fluent interface for defining arguments, flags, options, and subcommands
- **Automatic help and version**: Generates `-h`/`--help` and `-v`/`--version` automatically
- **Subcommands**: Supports nested subcommands with their own arguments
- **Positional arguments**: Index-based positional arguments with multiple-value support
- **Validation**: Possible values, required arguments, mutual exclusion, and argument dependencies
- **Default values**: Set defaults for options and positional arguments, displayed in help output
- **Error handling**: `ArgError` exception with usage hints

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

See [cjxe_examples](cjxe_examples) for more examples. For full API documentation, see [cjxe/README.md](cjxe/README.md).

## Running Tests

```bash
cjpm test
```

## License

Licensed under the [MIT License](LICENSE).
