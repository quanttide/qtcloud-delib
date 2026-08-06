//! 决议模型：与服务端（provider）JSON 契约对齐。

use serde::{Deserialize, Serialize};

/// 决议：决策记录。
///
/// `id` 为 UUID；`name` 为决议标识（slug，取自文件名）。
/// `title` 概括"决定了什么"，`content` 展开决议陈述。
/// `category` 标注决议分类（如：治理、审计、档案、技术等）。
/// 结构从实际议事档案标本中长出，不预设执行字段。
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Resolution {
    pub id: String,
    pub name: String,
    pub title: String,
    pub content: String,
    pub category: String,
}

/// 创建决议的请求体（`POST /resolutions`）。
///
/// `name` / `title` 必填；`id` 由服务端生成，不在此携带。
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct NewResolution {
    pub name: String,
    pub title: String,
    pub content: String,
    pub category: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = r###"{
        "id": "7e670a1f-2531-402f-847b-bbc2c2512773",
        "name": "data-contract",
        "title": "数据契约",
        "content": "## 背景与目的",
        "category": "数据工程"
    }"###;

    #[test]
    fn parses_resolution_from_server_json() {
        let r: Resolution = serde_json::from_str(SAMPLE).expect("解析失败");
        assert_eq!(r.id, "7e670a1f-2531-402f-847b-bbc2c2512773");
        assert_eq!(r.name, "data-contract");
        assert_eq!(r.title, "数据契约");
        assert_eq!(r.category, "数据工程");
    }

    #[test]
    fn serializes_new_resolution_without_id() {
        let input = NewResolution {
            name: "weekly-vote".into(),
            title: "周会实行记名表决制".into(),
            content: String::new(),
            category: "治理".into(),
        };
        let json = serde_json::to_string(&input).expect("序列化失败");
        assert!(json.contains(r#""name":"weekly-vote""#));
        assert!(json.contains(r#""title":"周会实行记名表决制""#));
        assert!(!json.contains("id"), "id 应由服务端生成，请求体不应携带");
    }
}
