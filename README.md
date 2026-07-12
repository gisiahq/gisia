# Gisia

<p>
<a href="README.md">English</a>
<a href="docs/i18n/zh_CN/README.md">简体中文</a>
</p>


> **The lightweight self-hosted DevOps platform your AI agent already knows how to use.**

Gisia is an open-source DevOps platform designed for individuals and small teams who want full control over their development workflow. It provides essential Git hosting, CI/CD automation, and issue tracking — and every project exposes machine-readable skill files so AI agents can operate it through the API.

## 🤔 Why Choose Gisia?

- **Private** — your code stays on your server.
- **Lightweight** — lean code, fast responses.
- **AI-ready** — agents learn your project API from a single `skill.md` URL.
- **Full control** — no vendor lock-in, no usage limits, no surprise pricing.
- **Open source** — full transparency, every line of code is yours to read and trust.

## 🤖 Built for AI Agents

Every Gisia project includes a skill introduction. Paste the instruction into any agent that can fetch a URL — OpenClaw, Claude Code, or your own bot — and it learns how to clone, push, and manage issues, epics, and labels through the REST API. No plugin, no integration to install.

<video src="https://github.com/user-attachments/assets/d8270349-f084-4cea-a9f2-7c0c09030c44"></video>

See the [AI Bot Skills guide](https://gisia.dev/docs/ai-bot-skills.html) for a full walkthrough.



> [!WARNING]
> 
> This project is under active development and may contain bugs or breaking changes between versions.

- **Regularly back up your repositories, configurations, and data — always before upgrading.**
- Features and APIs may change without notice.


## 🛠️ Installation

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

[Official Docs](https://gisia.dev/docs)

## ⏫ Upgrade

check the `docs/releases` to see how to upgrade to a specified version

## 🚀 Features

| Feature | Status | Notes |
|----------|---------|-------|
| **AI Bot Skills** | ✅ Done | Machine-readable skill files, so AI bots can clone, push, and manage issues and epics via the API |
| **Git Repository Hosting** | ✅ Done | Lightweight Git server with SSH and HTTP(S) access |
| **CI/CD Pipelines** | ✅ Done | Basic runner support and pipeline definitions in YAML |
| **Issue Tracking** | ✅ Done| Simple issue board for personal or small team usage |
| **Merge Requests** | ✅ Done | Inline diffs and comment threads |
| **Webhooks** | ✅ Done | Webhooks to call URL of 3rd party services|
| **Code Review** | ✅ Done | Comment notifications |
| **Namespace Runners** | ✅ Done | Project/Group level runners|
| **User Authentication** | ✅ Done | Local accounts |

## 💡 Dev Philosophy

Gisia is built with these principles in mind:

- **Developer-first design** — prioritizing tools and workflows that enhance developer productivity.
- **Transparency** — open source, auditable codebase.
- **Simplicity over complexity** — lightweight core, no heavy dependencies


## 🤝 Contributing

Thank you for your interest in Gisia! This repository is currently a **mirror** of our main development branch. We are **not** accepting community contributions at this time.

We appreciate your support and understanding — please feel free to open an issue to share feedback or suggestions.


### Legal Note
All contributions are subject to the [Contributor License Agreement](CLA.md).

Thank you for helping improve the project!

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**.

Please refer to the `NOTICE` and `.licenses` folders for detailed information on third-party licenses.

### ⚠️ Third-Party References Disclaimer

You may notice references to **"GitLab"** in server responses, logs, or internal messages.
These come from reused **GitLab FOSS (MIT-licensed) components** or code segments.

**Gisia is not affiliated with, endorsed by, or associated with GitLab Inc.**
All trademarks and brand names belong to their respective owners.
