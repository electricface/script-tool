# codex-run 使用指南

`codex-run` 是一个轻量命令行工具，用于管理 [codex](https://github.com/openai/codex) 的 `model_provider` 切换，并在运行 codex 时自动注入对应的 API Key 环境变量。

## 前置条件

- 已安装 `codex` 命令并在 PATH 中
- 已存在 `~/.codex/config.toml` 配置文件（codex 自动生成）
- Python >= 3.11

## 初始配置

### 1. 创建认证文件

手动创建 `~/.config/codex-run/auth.json`，填入各 provider 的 API Key：

```json
{
  "yescode_API_KEY": "sk-your-yescode-key",
  "ikun_API_KEY": "sk-your-ikun-key"
}
```

Key 的命名规则为 `{provider名称}_API_KEY`，与 `~/.codex/config.toml` 中 `[model_providers.XXX]` 的 `XXX` 部分对应，大小写敏感。

### 2. 确认 codex 配置

确保 `~/.codex/config.toml` 中有 `model_providers` 段落，例如：

```toml
model_provider = "yescode"

[model_providers.yescode]
name = "yescode"
base_url = "https://co.yes.vg/v1"
wire_api = "responses"

[model_providers.ikun]
name = "ikun"
base_url = "https://api.ikuncode.cc/v1"
wire_api = "responses"
```

## 使用方法

### 列出所有 provider

```bash
codex-run -l
# 或
codex-run --list
```

输出示例：

```
  proxypilot
  cch
  ikun
* yescode (current)
```

`*` 标记表示当前激活的 provider。

### 切换 provider

```bash
codex-run -u ikun
# 或
codex-run --use ikun
```

此命令会更新 `~/.codex/config.toml` 中的 `model_provider = "ikun"`。

### 运行 codex

```bash
codex-run
```

自动根据当前 provider 从 `auth.json` 读取对应的 API Key，注入环境变量后运行 codex。运行前会打印环境变量名和密钥长度（不泄漏密钥内容）：

```
yescode_API_KEY (length: 28)
```

### 透传参数给 codex

使用 `--` 分隔，后面的所有参数原样传递给 codex：

```bash
# 恢复上次会话
codex-run -- resume

# 带额外参数
codex-run -- resume --some-flag
```

## 配置文件说明

| 文件 | 路径 | 说明 |
|------|------|------|
| codex 配置 | `~/.codex/config.toml` | codex 原生配置，含 model_provider 和 providers 定义（唯一权威来源） |
| 认证配置 | `~/.config/codex-run/auth.json` | API Key 存储，需手动创建 |

## 错误提示

| 场景 | 提示 |
|------|------|
| `~/.codex/config.toml` 不存在 | `Error: ~/.codex/config.toml not found` |
| 切换到不存在的 provider | `Error: provider 'xxx' not found. Available: ...` |
| `auth.json` 不存在 | `Error: ~/.config/codex-run/auth.json not found` |
| auth.json 中缺少对应 Key | `Error: xxx_API_KEY not found in ~/.config/codex-run/auth.json` |
| codex 命令不在 PATH | `Error: 'codex' command not found in PATH` |
