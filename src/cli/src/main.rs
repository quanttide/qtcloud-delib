//! qtcloud-delib-cli 量潮议事云命令行工具。

use std::env;

const VERSION: &str = env!("CARGO_PKG_VERSION");

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();

    match args.first().map(String::as_str) {
        Some("--version") | Some("-V") => {
            println!("qtcloud-delib {VERSION}");
        }
        Some("--help") | Some("-h") | None => {
            println!("qtcloud-delib {VERSION} — 量潮议事云命令行工具");
            println!();
            println!("用法: qtcloud-delib [选项]");
            println!();
            println!("选项:");
            println!("  -h, --help     显示帮助");
            println!("  -V, --version  显示版本");
        }
        Some(unknown) => {
            eprintln!("未知选项: {unknown}");
            std::process::exit(1);
        }
    }
}
