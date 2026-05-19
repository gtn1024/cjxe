# cjxe

[![CI](https://github.com/gtn1024/cjxe/actions/workflows/ci.yml/badge.svg)](https://github.com/gtn1024/cjxe/actions/workflows/ci.yml)

仓颉语言命令行参数解析库。

[English](README.md)

## 特性

- **Builder API**：流畅接口定义参数、标志、选项和子命令
- **自动帮助和版本**：自动生成 `-h`/`--help` 和 `-v`/`--version`
- **子命令**：支持嵌套子命令，子命令可以拥有自己的参数
- **位置参数**：基于索引的位置参数，支持多值
- **参数校验**：可选值限制、必填参数、互斥参数（`blacklist`）、参数依赖（`requires`）
- **错误处理**：`ArgError` 异常附带用法提示，而非静默失败

## 环境要求

- 仓颉工具链 >= 1.1.0

## 安装

在 `cjpm.toml` 中添加依赖：

```toml
[dependencies]
  cjxe = { git = "https://github.com/gtn1024/cjxe.git", tag = "0.2.0" }
```

## 快速入门

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

## API 参考

### App

命令行参数解析器的主入口。

| 方法 | 说明 |
|------|------|
| `init(name: String)` | 创建指定名称的 App |
| `version(version: String): App` | 设置版本号 |
| `author(author: String): App` | 设置作者信息 |
| `about(about: String): App` | 设置应用描述 |
| `usage(u: String): App` | 覆盖用法字符串 |
| `afterHelp(h: String): App` | 在帮助信息后追加文本 |
| `arg(arg: Arg): App` | 添加参数定义 |
| `args(args: Array<Arg>): App` | 添加多个参数定义 |
| `subcommand(subcmd: App): App` | 添加子命令 |
| `subcommands(subcmds: Array<App>): App` | 添加多个子命令 |
| `getMatches(): ArgMatches` | 从 `std.env.getCommandLine()` 解析命令行参数 |
| `getMatchesFrom(args: Array<String>): ArgMatches` | 从给定数组解析参数 |
| `getMatchesOrExit(): ArgMatches` | 解析参数，出错时打印错误信息并退出 |

### Arg

定义单个参数（标志、选项或位置参数）。

| 属性 / 方法 | 说明 |
|-------------|------|
| `init(name!: String, short!: ?Rune, long!: ?String)` | 创建 Arg，可选短名称/长名称 |
| `setHelp(help: String): Arg` | 设置帮助文本 |
| `setRequired(required: Bool): Arg` | 标记为必填参数 |
| `setTakesValue(takesValue: Bool): Arg` | 设置参数接受值（选项） |
| `setIndex(index: UInt8): Arg` | 设置位置参数索引 |
| `setMultiple(multiple: Bool): Arg` | 允许参数多次出现 |
| `setBlacklist(blacklist: Array<String>): Arg` | 设置互斥参数 |
| `setPossibleValues(possibleValues: Array<String>): Arg` | 限制为指定有效值 |
| `setRequires(requires: Array<String>): Arg` | 设置必须同时存在的参数 |

### ArgMatches

保存解析结果。

| 方法 | 说明 |
|------|------|
| `valueOf(name: String): ?String` | 返回指定参数的值 |
| `valuesOf(name: String): ?Array<String>` | 返回多值参数的所有值 |
| `isPresent(name: String): Bool` | 检查参数或子命令是否存在 |
| `occurrencesOf(name: String): UInt8` | 返回参数出现的次数 |
| `subcommandMatches(name: String): ?ArgMatches` | 返回子命令的解析结果 |

### ArgError

解析错误时抛出的异常。

| 属性 | 说明 |
|------|------|
| `message: String` | 错误描述 |
| `showUsage: Bool` | 是否显示用法提示 |

## 参数类型

cjxe 根据配置自动将参数分类：

| 类型 | 定义方式 | 示例 |
|------|----------|------|
| **标志（Flag）** | 有 `short` 或 `long`，无 `takesValue`，无 `index` | `-d`、`--verbose` |
| **选项（Option）** | 有 `short` 或 `long` + `takesValue(true)` | `-c value`、`--config=value` |
| **位置参数** | 设置 `index()` 或既没有 `short` 也没有 `long` | `<file>` |

## 运行测试

```bash
cjpm test
```

## 许可证

基于 [MIT 许可证](../LICENSE) 授权。
