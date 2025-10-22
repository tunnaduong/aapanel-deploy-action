# 🚀 aaPanel Auto Deploy Action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-aaPanel%20Deploy%20Action-blue?logo=github)](https://github.com/marketplace)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub tag](https://img.shields.io/github/v/tag/tunnaduong/aapanel-deploy-action?label=version)](https://github.com/tunnaduong/aapanel-deploy-action/releases)

A lightweight GitHub Action to automatically trigger an **aaPanel webhook** after every push and optionally send **notifications via ntfy** when deployment succeeds or fails.

---

## 🧩 Features

- 🔹 Simple one-line integration with your aaPanel server
- 📱 Instant push notifications via [ntfy.sh](https://ntfy.sh) or your own ntfy instance
- ⚙️ Fully configurable for any aaPanel host and access key
- 🧊 Runs in an ultra-light Alpine container (only curl + bash)

---

## ⚡️ Example Usage

```yaml
name: Auto Deploy to aaPanel

on:
  push:
    branches: [main]

jobs:
  phplint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - uses: michaelw90/PHP-Lint@master

  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      actions: read
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to aaPanel
        uses: tunnaduong/aapanel-deploy-action@main
        with:
          panel_url: https://panel.example.com
          webhook_key: ${{ secrets.AAPANEL_WEBHOOK_KEY }}
          ntfy_topic: tunnapi-git-pulls
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
