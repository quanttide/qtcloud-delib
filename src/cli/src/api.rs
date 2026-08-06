//! provider 服务端 API 客户端。
//!
//! 对接 provider（Go 服务端）的决议接口：
//!   GET  /resolutions  → 200 `{"resolutions": [Resolution, ...]}`
//!   POST /resolutions  → 201 创建的决议（id 由服务端生成）
//! 错误统一为 `{"error": "..."}`：入参不合法 400，服务端错误 500。

use std::time::Duration;

use serde::Deserialize;

use crate::resolution::{NewResolution, Resolution};

const TIMEOUT: Duration = Duration::from_secs(10);

/// API 调用失败原因。
#[derive(Debug)]
pub enum ApiError {
    /// 网络 / 传输错误（连接失败、超时等）。
    Transport(String),
    /// 服务端返回非预期状态码，携带 `{"error": "..."}` 信息。
    Server { status: u16, message: String },
    /// 响应体解析失败。
    Decode(String),
}

impl std::fmt::Display for ApiError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ApiError::Transport(msg) => write!(f, "无法连接服务端：{msg}"),
            ApiError::Server { status, message } => {
                write!(f, "服务端错误（HTTP {status}）：{message}")
            }
            ApiError::Decode(msg) => write!(f, "解析服务端响应失败：{msg}"),
        }
    }
}

impl std::error::Error for ApiError {}

/// 决议 API 客户端。
pub struct ResolutionApi {
    base_url: String,
}

impl ResolutionApi {
    /// 创建客户端，`base_url` 如 `http://localhost:8080`。
    pub fn new(base_url: String) -> Self {
        Self { base_url }
    }

    /// 决议清单：`GET /resolutions`（按 name 排序）。
    pub fn list(&self) -> Result<Vec<Resolution>, ApiError> {
        let resp = ureq::get(&format!("{}/resolutions", self.base_url))
            .timeout(TIMEOUT)
            .call()
            .map_err(map_ureq_err)?;
        let body = resp
            .into_string()
            .map_err(|e| ApiError::Decode(e.to_string()))?;
        let payload: ListResponse =
            serde_json::from_str(&body).map_err(|e| ApiError::Decode(e.to_string()))?;
        Ok(payload.resolutions)
    }

    /// 创建决议：`POST /resolutions`（name / title 必填，id 由服务端生成）。
    pub fn create(&self, input: &NewResolution) -> Result<Resolution, ApiError> {
        let body = serde_json::to_string(input).map_err(|e| ApiError::Decode(e.to_string()))?;
        let resp = ureq::post(&format!("{}/resolutions", self.base_url))
            .timeout(TIMEOUT)
            .set("Content-Type", "application/json")
            .send_string(&body)
            .map_err(map_ureq_err)?;
        let body = resp
            .into_string()
            .map_err(|e| ApiError::Decode(e.to_string()))?;
        serde_json::from_str(&body).map_err(|e| ApiError::Decode(e.to_string()))
    }
}

/// `GET /resolutions` 响应体。
#[derive(Debug, Deserialize)]
struct ListResponse {
    resolutions: Vec<Resolution>,
}

/// 统一转换 ureq 错误：非 2xx 提取 `{"error": "..."}`，其余归为传输错误。
fn map_ureq_err(err: ureq::Error) -> ApiError {
    match err {
        ureq::Error::Status(status, resp) => {
            let message = resp
                .into_string()
                .ok()
                .and_then(|body| serde_json::from_str::<serde_json::Value>(&body).ok())
                .and_then(|v| v.get("error").and_then(|e| e.as_str()).map(str::to_owned))
                .unwrap_or_else(|| format!("HTTP {status}"));
            ApiError::Server { status, message }
        }
        other => ApiError::Transport(other.to_string()),
    }
}

#[cfg(test)]
mod tests {
    use std::io::{Read, Write};
    use std::net::{TcpListener, TcpStream};

    use super::*;

    const SAMPLE: &str = r###"{
        "id": "7e670a1f-2531-402f-847b-bbc2c2512773",
        "name": "data-contract",
        "title": "数据契约",
        "content": "## 背景与目的",
        "category": "数据工程"
    }"###;

    /// 本地 mock 服务端：读入请求（忽略内容），返回固定状态码与响应体。
    fn mock_server(status: u16, response_body: &'static str) -> String {
        let listener = TcpListener::bind("127.0.0.1:0").expect("绑定端口失败");
        let addr = listener.local_addr().expect("获取地址失败");
        std::thread::spawn(move || {
            for stream in listener.incoming().flatten() {
                let mut stream = stream;
                drain_request(&mut stream);
                let body = response_body;
                let head = format!(
                    "HTTP/1.1 {status} OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                    body.len()
                );
                let _ = stream.write_all(head.as_bytes());
                let _ = stream.write_all(body.as_bytes());
            }
        });
        format!("http://{addr}")
    }

    /// 读请求头与请求体（小 body 单次读完即可，mock 不关心内容）。
    fn drain_request(stream: &mut TcpStream) {
        let mut buf = [0u8; 8192];
        let mut total = 0usize;
        while total < buf.len() {
            match stream.read(&mut buf[total..]) {
                Ok(0) | Err(_) => break,
                Ok(n) => {
                    total += n;
                    if buf[..total].windows(4).any(|w| w == b"\r\n\r\n") {
                        break; // 请求头已读完；本地回环小 body 已在缓冲内
                    }
                }
            }
        }
    }

    #[test]
    fn list_returns_resolutions() {
        let base = mock_server(
            200,
            r#"{"resolutions": [{"id": "a", "name": "n1", "title": "t1", "content": "", "category": ""}]}"#,
        );
        let api = ResolutionApi::new(base);
        let got = api.list().expect("list 失败");
        assert_eq!(got.len(), 1);
        assert_eq!(got[0].name, "n1");
    }

    #[test]
    fn list_empty_resolutions() {
        let base = mock_server(200, r#"{"resolutions": []}"#);
        let api = ResolutionApi::new(base);
        let got = api.list().expect("list 失败");
        assert!(got.is_empty());
    }

    #[test]
    fn list_server_error_carries_message() {
        let base = mock_server(500, r#"{"error": "list failed"}"#);
        let api = ResolutionApi::new(base);
        let err = api.list().expect_err("应返回错误");
        match err {
            ApiError::Server { status, message } => {
                assert_eq!(status, 500);
                assert_eq!(message, "list failed");
            }
            other => panic!("期望 Server 错误，得到 {other:?}"),
        }
    }

    #[test]
    fn create_returns_created_resolution() {
        let base = mock_server(201, SAMPLE);
        let api = ResolutionApi::new(base);
        let input = NewResolution {
            name: "data-contract".into(),
            title: "数据契约".into(),
            content: "## 背景与目的".into(),
            category: "数据工程".into(),
        };
        let got = api.create(&input).expect("create 失败");
        assert_eq!(got.id, "7e670a1f-2531-402f-847b-bbc2c2512773");
        assert_eq!(got.title, "数据契约");
    }

    #[test]
    fn create_invalid_input_returns_400_message() {
        let base = mock_server(400, r#"{"error": "name and title are required"}"#);
        let api = ResolutionApi::new(base);
        let input = NewResolution {
            name: String::new(),
            title: String::new(),
            content: String::new(),
            category: String::new(),
        };
        let err = api.create(&input).expect_err("应返回错误");
        match err {
            ApiError::Server { status, message } => {
                assert_eq!(status, 400);
                assert_eq!(message, "name and title are required");
            }
            other => panic!("期望 Server 错误，得到 {other:?}"),
        }
    }
}
