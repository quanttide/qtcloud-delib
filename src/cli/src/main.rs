//! qtcloud-delib-cli 量潮议事云命令行工具。
//!
//! 对接 provider（Go 服务端）的决议接口：
//!   GET  /resolutions  → `{"resolutions": [Resolution, ...]}`
//!   POST /resolutions  → 创建决议，返回创建的决议（201）
//!
//! 服务端地址默认 `http://localhost:8080`，可用 `--server` 或
//! 环境变量 `DELIB_API_BASE_URL` 覆盖（与 studio 客户端对齐）。

mod api;
mod resolution;

use std::process::ExitCode;

use clap::{Args, Parser, Subcommand};
use serde::Serialize;

use crate::api::ResolutionApi;
use crate::resolution::{NewResolution, Resolution};

/// 量潮议事云命令行工具。
#[derive(Debug, Parser)]
#[command(name = "qtcloud-delib", version, about = "量潮议事云命令行工具")]
struct Cli {
    /// 服务端地址（默认 http://localhost:8080）
    #[arg(
        long,
        global = true,
        env = "DELIB_API_BASE_URL",
        default_value = "http://localhost:8080"
    )]
    server: String,

    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// 决议管理
    Resolutions(ResolutionsArgs),
}

#[derive(Debug, Args)]
struct ResolutionsArgs {
    #[command(subcommand)]
    command: ResolutionCommand,
}

#[derive(Debug, Subcommand)]
enum ResolutionCommand {
    /// 决议清单（GET /resolutions）
    List(ListArgs),
    /// 创建决议（POST /resolutions）
    Create(CreateArgs),
}

#[derive(Debug, Args)]
struct ListArgs {
    /// 以 JSON 输出（含 content 全文）
    #[arg(long)]
    json: bool,
}

#[derive(Debug, Args)]
struct CreateArgs {
    /// 决议标识（slug，取自文件名）
    name: String,
    /// 决议标题（概括"决定了什么"）
    title: String,
    /// 决议陈述（纯文本）
    #[arg(long)]
    content: Option<String>,
    /// 决议分类（如：治理、审计、档案、技术）
    #[arg(long)]
    category: Option<String>,
    /// 以 JSON 输出
    #[arg(long)]
    json: bool,
}

fn main() -> ExitCode {
    let cli = Cli::parse();
    match run(cli) {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("qtcloud-delib: {err}");
            ExitCode::FAILURE
        }
    }
}

fn run(cli: Cli) -> Result<(), Box<dyn std::error::Error>> {
    let api = ResolutionApi::new(cli.server);
    match cli.command {
        Command::Resolutions(args) => match args.command {
            ResolutionCommand::List(args) => list(&api, args.json),
            ResolutionCommand::Create(args) => create(&api, args),
        },
    }
}

/// 决议清单。
fn list(api: &ResolutionApi, json: bool) -> Result<(), Box<dyn std::error::Error>> {
    let resolutions = api.list()?;
    if json {
        print_json(&resolutions);
    } else if resolutions.is_empty() {
        println!("（无决议）");
    } else {
        for r in &resolutions {
            print_row(r);
        }
    }
    Ok(())
}

/// 创建决议。
fn create(api: &ResolutionApi, args: CreateArgs) -> Result<(), Box<dyn std::error::Error>> {
    let created = api.create(&NewResolution {
        name: args.name,
        title: args.title,
        content: args.content.unwrap_or_default(),
        category: args.category.unwrap_or_default(),
    })?;
    if args.json {
        print_json(&created);
    } else {
        print_row(&created);
    }
    Ok(())
}

/// 以缩进 JSON 输出（可脚本化消费）。
fn print_json(value: &impl Serialize) {
    println!(
        "{}",
        serde_json::to_string_pretty(value).expect("序列化失败")
    );
}

/// 单行输出：`id name title category`（content 过长，仅在 --json 中展示）。
fn print_row(r: &Resolution) {
    println!("{}  {}  {}  {}", r.id, r.name, r.title, r.category);
}
