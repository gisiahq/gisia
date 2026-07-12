# Gisia

<p>
<a href="../../../README.md">English</a>
<a href="README.md">简体中文</a>
</p>

> **轻量级自托管 DevOps 平台 — 你的 AI 智能体天生就会使用。**

Gisia 是一个开源 DevOps 平台，为那些希望完全掌控开发工作流程的个人和小团队而设计。它提供基本的 Git 托管、CI/CD 自动化、问题跟踪等功能 — 并且每个项目都暴露机器可读的技能文件，让 AI 智能体可以通过 API 操作项目。

## 🤔 为什么选择 Gisia？

- **私有** — 你的代码存储在你自己的服务器上。
- **轻量级** — 精简代码，响应速度快。
- **AI 就绪** — 智能体只需一个 `skill.md` URL 即可学会你的项目 API。
- **完全掌控** — 无供应商锁定，无使用限制，无意外收费。
- **开源** — 完全透明，每一行代码都由你自己审阅和信任。

## 🤖 为 AI 智能体而生

每个 Gisia 项目都在可预测的 URL（`/-/skill.md`、`/-/issues/skill.md` 等）提供纯 Markdown 技能文件。只需将一条指令粘贴给任何能抓取 URL 的智能体 — OpenClaw、Claude Code 或你自己的机器人 — 它就能学会通过 REST API 克隆、推送并管理问题、史诗和标签。无需插件，无需安装集成。

<video src="https://github.com/user-attachments/assets/d8270349-f084-4cea-a9f2-7c0c09030c44"></video>

完整教程请参阅 [AI Bot 技能指南](https://gisia.dev/docs/ai-bot-skills.html)。

## 📸 截图

<img src="../../images/readme-banner.jpg" title="usage screenshots">


> [!WARNING]
>
> 这意味着它正在积极开发中，可能存在漏洞或各个版本之间的破坏性变更。

- **定期备份你的仓库、配置和数据 — 升级前务必备份。**
- 功能和 API 可能会在没有通知的情况下改变。


## 🛠️ 安装

```shell
# Initialize and start Gisia
mkdir gisia && cd gisia
docker pull gisia/init:latest
docker run --rm -v ./:/output gisia/init:latest
cp .env.example .env
docker compose up -d

# Get your root password
docker exec -it gisia-web cat /rails/initial_root_password
```

[官方文档](https://gisia.dev/)

## ⏫ 升级

查看 `docs/releases` 了解如何升级到指定版本

## 🚀 功能

| 功能 | 状态 | 备注 |
|----------|---------|-------|
| **AI Bot 技能** | ✅ 已完成 | 机器可读的技能文件，让 AI 机器人可以通过 API 克隆、推送并管理问题和史诗 |
| **Git 仓库托管** | ✅ 已完成 | 轻量级 Git 服务器，支持 SSH 和 HTTP(S) 访问 |
| **CI/CD 流水线** | ✅ 已完成 | 基础 runner 支持和 YAML 格式的流水线定义 |
| **问题跟踪** | ✅ 已完成 | 简单的问题板，适合个人或小团队使用 |
| **合并请求** | ✅ 已完成 | 内联对比和评论线程 |
| **Webhooks** | ✅ 已完成 | Webhooks 调用第三方服务的 URL |
| **代码审查** | ✅ 已完成 | 评论通知 |
| **命名空间 Runner** | ✅ 已完成 | 项目/群组级别的 runner |
| **用户身份验证** | ✅ 已完成 | 本地账户 |

## 💡 开发哲学

Gisia 的构建遵循以下原则：

- **开发者优先设计** — 优先考虑能增强开发者生产力的工具和工作流程。
- **透明性** — 开源、可审计的代码库。
- **简洁胜于复杂** — 轻量级核心，无沉重依赖


## 🤝 贡献

感谢你对 Gisia 的关注！此仓库目前是我们主开发分支的**镜像**，暂时不接受社区贡献。

非常感谢你的理解与支持 — 如有反馈或建议，欢迎提交 issue 与我们交流。


### 法律说明
所有贡献须遵守[贡献者许可协议](../../../CLA.md)。

感谢你帮助改进项目！

## 📄 许可证

本项目根据 **GNU Affero 通用公共许可证 v3.0 (AGPLv3)** 授权。

请参考 `NOTICE` 和 `.licenses` 文件夹以了解第三方许可证的详细信息。


### ⚠️ 第三方引用免责声明

你可能会在服务器响应、日志或内部消息中看到对 **"GitLab"** 的引用。
这些来自重用的 **GitLab FOSS（MIT 许可）组件**或代码段。

**Gisia 与 GitLab Inc. 无任何关联，亦未获得其认可或支持。**
所有商标和品牌名称均属于其各自所有者。
