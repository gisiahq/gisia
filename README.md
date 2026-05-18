# Gisia

<p>
<a href="README.md">English</a>
<a href="docs/i18n/zh_CN/README.md">简体中文</a>
</p>


> **Self-hosted personal DevOps platform — lightweight, private, and fully yours.**

Gisia is an open-source, DevOps platform designed for individuals and small teams who want full control over their development workflow. It provides essential Git hosting, CI/CD automation, issue tracking.

<p align="center">
<img src="docs/images/readme-banner.jpg" title="usage screenshots">
</p>

AI bot skills demo

<video src="https://github.com/user-attachments/assets/70181798-058b-462f-a769-cf09537dcab9"></video>


> [!WARNING]
> ⚠️ Gisia is approaching v1.0
> 
> That means it is under active development and may contain bugs or breaking changes between versions.

- **Regularly back up your repositories, configurations, and data — always before upgrading.**
- Features and APIs may change without notice.


## 🚀 Features

| Feature | Status | Notes |
|----------|---------|-------|
| **User Authentication** | ✅ Done | Local accounts |
| **Git Repository Hosting** | ✅ Done | Lightweight Git server with SSH and HTTP(S) access |
| **CI/CD Pipelines** | ✅ Done | Basic runner support and pipeline definitions in YAML |
| **Issue Tracking** | ✅ Done| Simple issue board for personal or small team usage |
| **Merge Requests ** | ✅ Done | Inline diffs and comment threads |
| **Webhooks** | ✅ Done | Webhooks to call URL of 3rd party services|
| **AI Bot Skills** | ✅ Done | Machine-readable skill files, so AI bots can clone, push, and manage issues and epics via the API |
| **Code Review** | 🔜 Working on | comment notifications |


## 🛠️ Installation

[How To Install](docs/how-to/1-quick-start.md)

[Official Docs](https://gisia.dev/docs)

## ⏫ Upgrade

check the `docs/releases` to see how to upgrade to a specified version

## 💡 Dev Philosophy

Gisia is built with these principles in mind:

- **Developer-first design** — prioritizing tools and workflows that enhance developer productivity.
- **Transparency** — open source, auditable codebase.
- **Simplicity over complexity** — lightweight core, no heavy dependencies


## 🤝 Contributing

Thank you for your interest in Gisia! This repository is currently a **mirror** of our main development branch. We are not accepting community contributions at this time.

We appreciate your support and understanding — please feel free to open an issue to share feedback or suggestions.


### Legal Note
All contributions are subject to the [Contributor License Agreement](CLA.md).

Thank you for helping improve the project!

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**.

Please refer to the `NOTICE` and `.licenses` folders for detailed information on third-party licenses.

### Commercial License

If you need to use Gisia without the AGPLv3 obligations (e.g. keeping modifications private), a commercial license is available. See [COMMERCIAL_LICENSE.md](COMMERCIAL_LICENSE.md) or contact us to discuss terms.

### ⚠️ Third-Party References Disclaimer

You may notice references to **"GitLab"** in server responses, logs, or internal messages.
These come from reused **GitLab FOSS (MIT-licensed) components** or code segments.

**Gisia is not affiliated with, endorsed by, or associated with GitLab Inc.**
All trademarks and brand names belong to their respective owners.
