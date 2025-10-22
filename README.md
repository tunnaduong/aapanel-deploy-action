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

## 📋 Prerequisites

Before using this action, you need:

1. **aaPanel server** with webhook plugin installed
2. **GitHub repository** with Actions enabled
3. **ntfy.sh account** (optional, for notifications)

---

## 🚀 Quick Setup Guide

### Step 1: Create GitHub Workflow

1. Go to your GitHub repository
2. Click on the **Actions** tab
3. Click **Skip this and set up a workflow yourself**
4. Copy and paste the following workflow:

```yaml
name: Auto Deploy to aaPanel

on:
  push:
    branches: [main]

jobs:
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
          ntfy_topic: your-ntfy-topic
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

5. **Replace the following values:**

   - `https://panel.example.com` → Your actual aaPanel URL
   - `your-ntfy-topic` → Your ntfy topic name (see [ntfy.sh](https://ntfy.sh) for details)

6. Save the workflow file

### Step 2: Configure GitHub Secrets

1. Go to your repository **Settings**
2. Navigate to **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secret:
   - **Name:** `AAPANEL_WEBHOOK_KEY`
   - **Value:** (You'll get this from aaPanel in the next step)

### Step 3: Install aaPanel Webhook Plugin

1. Log into your aaPanel
2. Go to **App Store**
3. Search for and install the **Webhook** plugin
4. Open the Webhook plugin settings
5. Click **Add** to create a new webhook
6. Fill in the following details:

**Name:** `Auto Deploy`

**Command:**

```bash
PROJECT_DIR="/www/wwwroot/your-domain.com"
echo "========== $(date) =========="
cd "$PROJECT_DIR" || { echo "CD failed"; exit 1; }

# Pull git under www user
sudo -u www git fetch origin
sudo -u www git reset --hard origin/main

# Clean but exclude pull.log
sudo -u www git clean -fd -e public/pull.log
sudo -u www git pull origin main

# Ensure proper permissions
sudo chown -R www:www "$PROJECT_DIR"

echo "Deploy completed successfully"
```

**Important:** Replace `/www/wwwroot/your-domain.com` with your actual project directory path.

7. **Save** the webhook
8. Click **View key** to get your webhook key
9. Copy this key and paste it into the `AAPANEL_WEBHOOK_KEY` secret in GitHub

### Step 4: Configure ntfy Notifications (Optional)

1. Visit [ntfy.sh](https://ntfy.sh) and download the app
2. Subscribe to your chosen topic (e.g., `your-ntfy-topic`)
3. Update the `ntfy_topic` in your workflow file with your topic name

---

## ⚙️ Configuration Options

| Parameter     | Required | Description                  | Example                              |
| ------------- | -------- | ---------------------------- | ------------------------------------ |
| `panel_url`   | ✅ Yes   | Your aaPanel URL             | `https://panel.yourdomain.com`       |
| `webhook_key` | ✅ Yes   | Webhook key from aaPanel     | `${{ secrets.AAPANEL_WEBHOOK_KEY }}` |
| `ntfy_topic`  | ❌ No    | ntfy topic for notifications | `my-deploy-notifications`            |

---

## 🔧 Advanced Usage

### Custom Deployment Script

You can customize the deployment script in aaPanel webhook settings. Here's an example for a Laravel project:

```bash
PROJECT_DIR="/www/wwwroot/your-laravel-app"
echo "========== $(date) =========="
cd "$PROJECT_DIR" || { echo "CD failed"; exit 1; }

# Pull latest changes
sudo -u www git fetch origin
sudo -u www git reset --hard origin/main
sudo -u www git clean -fd -e public/pull.log
sudo -u www git pull origin main

# Laravel specific commands
sudo -u www composer install --no-dev --optimize-autoloader
sudo -u www php artisan config:cache
sudo -u www php artisan route:cache
sudo -u www php artisan view:cache

# Ensure proper permissions
sudo chown -R www:www "$PROJECT_DIR"

echo "Laravel deployment completed successfully"
```

### Multiple Branches

To deploy different branches to different environments:

```yaml
name: Auto Deploy to aaPanel

on:
  push:
    branches: [main, staging]

jobs:
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
          ntfy_topic: ${{ github.ref == 'refs/heads/main' && 'production-deploys' || 'staging-deploys' }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 🐛 Troubleshooting

### Common Issues

1. **Webhook not triggering:**

   - Check if the webhook key is correct
   - Verify the aaPanel URL is accessible
   - Ensure the webhook plugin is properly configured

2. **Permission denied errors:**

   - Make sure the deployment script uses `sudo -u www` for git operations
   - Check file permissions in your project directory

3. **Git pull fails:**
   - Ensure the repository is properly cloned in aaPanel
   - Check if the branch exists and is accessible

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## ⭐ Support

If you find this action helpful, please give it a star! ⭐
