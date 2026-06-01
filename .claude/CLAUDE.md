# 项目规则

## ⚠️ 提交规则

1. 用户明确叫提交才能提交，用户没叫不准提交
2. commit message 中**绝对禁止**加 `Co-Authored-By`

## 🟢 Novel Studio 工作流

以下关键词命中时，**读取 `~/.claude/agents/novel-coordinator.md` 作为工作流指南直接执行**（由主 agent 执行，不作为子 agent 调度）：

- "小说工作组"、"小说模式"、"小说工作室"、"Novel Studio"
- "写小说"、"创作小说"、"小说项目"
- "novel-coordinator"、"novel studio"、"novel group"
- "canon 同步"、"章节审校"、"风格校准"（Novel Studio 专属术语）

## 🟢 HyperFrames Studio 工作流

以下关键词命中时，**读取 `~/.claude/agents/hf-coordinator.md` 作为工作流指南直接执行**（由主 agent 执行，不作为子 agent 调度）：

- "视频模式"、"视频工作室"、"HyperFrames Studio"、"HF Studio"
- "做视频"、"生成视频"、"视频项目"
- "hf-coordinator"、"hyperframes"

## 🟢 ESP32 Studio 工作流

以下关键词命中时，**调度 `esp32-coordinator` 子 agent 执行**（通过 Task 工具调度）：

- "ESP32模式"、"嵌入式模式"、"硬件工作室"、"ESP32 Studio"
- "ESP32开发"、"固件开发"、"嵌入式开发"
- "esp32-coordinator"、"esp32 studio"
