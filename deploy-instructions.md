# Kaygez Deployment Guide

## ✅ What Was Changed

### Per-Client Traffic Multiplier (Factor)
- Added `UsageMultiplier` field to clients (default: 1.0)
- **Stacking multipliers**: Inbound 2x + Client 2x = 4x total
- **No cap**: Can set any value ≥ 1.0 (removed 10x limit)
- UI field when creating/editing users
- Database auto-migration on first run

## 🚀 Deployment Steps

### On Your Server:

```bash
# 1. Stop the current panel
systemctl stop x-ui

# 2. Backup your database (IMPORTANT!)
cp /etc/x-ui/x-ui.db /root/x-ui-backup-$(date +%Y%m%d).db

# 3. Download or upload your new code to /tmp/Kaygez

# 4. Install dependencies (if not already installed)
# Go 1.22+
apt install golang-go -y

# Node.js 20+
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# 5. Build frontend
cd /tmp/Kaygez/frontend
npm install
npm run build

# 6. Build backend
cd /tmp/Kaygez
go build -o kaygez main.go

# 7. Replace the binary
cp /usr/local/x-ui/x-ui /usr/local/x-ui/x-ui.backup
cp kaygez /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/x-ui

# 8. Start the panel
systemctl start x-ui

# 9. Check if it's running
systemctl status x-ui

# 10. Check logs
journalctl -u x-ui -f
```

### Database Migration

The `usage_multiplier` column will be automatically added to the `clients` table when the app starts (GORM AutoMigrate).

No manual SQL needed!

### Verify It Works

1. Log into your panel
2. Go to Clients page
3. Create or edit a client
4. You should see **"Traffic Multiplier (Factor)"** field
5. Set it to 2.0 for a test user
6. If that user connects to an inbound with 2x multiplier, they'll consume 4x traffic!

## 🔧 Troubleshooting

### If the build fails:
```bash
# Check Go version
go version  # Should be 1.22+

# Check Node version
node --version  # Should be 20+
```

### If the database migration fails:
```bash
# Check logs
journalctl -u x-ui -n 100

# If you see errors about the column, you can manually add it:
sqlite3 /etc/x-ui/x-ui.db
ALTER TABLE clients ADD COLUMN usage_multiplier REAL DEFAULT 1.0;
.quit
```

### If the UI doesn't show the field:
- Clear your browser cache
- Hard refresh (Ctrl+F5)
- Check if frontend/build was successful

## 📝 Summary of Files Changed

**Backend:**
- `internal/database/model/model.go` - Added UsageMultiplier fields
- `internal/web/service/client_inbound_billing.go` - Removed cap, added stacking
- `internal/web/translation/en-US.json` - Added UI labels

**Frontend:**
- `frontend/src/pages/clients/ClientFormModal.tsx` - Added form field
- `frontend/src/schemas/client.ts` - Added schema validation

## 🎉 Expected Behavior

- **Default**: Every client has 1.0x (no change)
- **Client 2x + Inbound 1x** = 2x total
- **Client 2x + Inbound 2x** = 4x total
- **Client 5x + Inbound 3x** = 15x total
- **No upper limit** (was capped at 10x, now unlimited)
