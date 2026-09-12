#!/bin/bash
# Kaygez Build and Deploy Script
# Run this on your server after uploading the code

set -e  # Exit on error

echo "🚀 Kaygez Build and Deploy Script"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -f "main.go" ]; then
    echo "❌ Error: main.go not found. Are you in the Kaygez directory?"
    exit 1
fi

# 1. Stop the service
echo "📴 Stopping x-ui service..."
systemctl stop x-ui || echo "Service was not running"

# 2. Backup database
BACKUP_FILE="/root/x-ui-backup-$(date +%Y%m%d_%H%M%S).db"
if [ -f "/etc/x-ui/x-ui.db" ]; then
    echo "💾 Backing up database to $BACKUP_FILE..."
    cp /etc/x-ui/x-ui.db "$BACKUP_FILE"
    echo "✅ Database backed up"
else
    echo "⚠️  No existing database found (fresh install?)"
fi

# 3. Check Go version
echo ""
echo "🔍 Checking Go version..."
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Installing..."
    apt update
    apt install -y golang-go
fi
go version

# 4. Check Node version
echo ""
echo "🔍 Checking Node.js version..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
fi
node --version
npm --version

# 5. Build Frontend
echo ""
echo "🎨 Building frontend..."
cd frontend
npm install
npm run build
cd ..
echo "✅ Frontend built successfully"

# 6. Build Backend
echo ""
echo "🔨 Building backend..."
go build -o kaygez main.go
if [ ! -f "kaygez" ]; then
    echo "❌ Build failed - kaygez binary not found"
    exit 1
fi
echo "✅ Backend built successfully"

# 7. Backup old binary
if [ -f "/usr/local/x-ui/x-ui" ]; then
    echo ""
    echo "💾 Backing up old binary..."
    cp /usr/local/x-ui/x-ui /usr/local/x-ui/x-ui.backup-$(date +%Y%m%d_%H%M%S)
fi

# 8. Install new binary
echo ""
echo "📦 Installing new binary..."
mkdir -p /usr/local/x-ui
cp kaygez /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/x-ui
echo "✅ Binary installed"

# 9. Start service
echo ""
echo "▶️  Starting x-ui service..."
systemctl start x-ui
sleep 2

# 10. Check status
echo ""
echo "🔍 Checking service status..."
if systemctl is-active --quiet x-ui; then
    echo "✅ Service is running!"
    echo ""
    echo "🎉 Deployment successful!"
    echo ""
    echo "📊 Service status:"
    systemctl status x-ui --no-pager -l
    echo ""
    echo "📝 To view logs: journalctl -u x-ui -f"
    echo "🌐 Panel should be accessible at your configured port"
    echo ""
    echo "⚠️  Don't forget to:"
    echo "   1. Log into the panel"
    echo "   2. Check the new 'Traffic Multiplier (Factor)' field when creating/editing clients"
    echo "   3. Test with a client to verify multipliers work"
else
    echo "❌ Service failed to start"
    echo "📝 Check logs with: journalctl -u x-ui -n 50"
    exit 1
fi
