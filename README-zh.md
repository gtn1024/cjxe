<div align="center">
  <h1>cjxe</h1>
  <p>仓颉语言命令行参数解析库</p>
</div>
<p align="center">
  <img alt="" src="https://github.com/gtn1024/cjxe/actions/workflows/ci.yml/badge.svg" style="display: inline-block;" />
</p>

[English](README.md)

## 特性

- **Builder API**：流畅接口定义参数、标志、选项和子命令
- **自动帮助和版本**：自动生成 `-h`/`--help` 和 `-v`/`--version`
- **子命令**：支持嵌套子命令，子命令可以拥有自己的参数
- **位置参数**：基于索引的位置参数，支持多值
- **参数校验**：可选值限制、必填参数、互斥参数、参数依赖
- **错误处理**：`ArgError` 异常附带用法提示

## 环境要求

- 仓颉工具链 >= 1.1.0

## 安装

在 `cjpm.toml` 中添加依赖：

```toml
[dependencies]
  cjxe = "0.3.0"
```

## 快速入门

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

更多示例见 [cjxe_examples](cjxe_examples)。完整 API 文档见 [cjxe/README-zh.md](cjxe/README-zh.md)。

## 运行测试

```bash
cjpm test
```

## 许可证

基于 [MIT 许可证](LICENSE) 授权。
