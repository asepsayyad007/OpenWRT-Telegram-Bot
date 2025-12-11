
# 🌑 OpenWRT Telegram Bot 🌑
Author: **Asep Sayyad**


---

![OpenWRT](https://img.shields.io/badge/OpenWRT-24.10.3-blue)  
![Router](https://img.shields.io/badge/Router-TP--Link%20Archer%20C7%20V2-green)  
![Telegram](https://img.shields.io/badge/Telegram-Bot%20Monitoring-0A66C2)  
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)

---

## 🔧 Hardware Information
- Router: TP-Link Archer C7 V2  
- CPU: Qualcomm Atheros QCA9558 @ 720 MHz  
- RAM: 128 MB  
- Flash: 16 MB  
- Wireless: AC1750 Dual-band  
- USB: 2 × USB 2.0  
- Limitations: No hardware VPN acceleration, low RAM but stable for Telegram monitoring  
- Tested Firmware: **OpenWRT 24.10.3**

---

## 🚀 Features
- Automated hourly status reports  
- WAN IP, uptime, load, memory, disk usage  
- Optional WAN IP‑change alerts  
- Lightweight — ideal for low‑power routers  
- Runs persistently using OpenWRT procd  
- Compatible with all modern OpenWRT builds  

---

## 📁 Project Structure
```
/usr/bin/hourly_update.sh    → main monitoring script
/etc/init.d/router_bot       → background service (procd)
/tmp/last_wan_ip             → WAN IP tracking file (optional)
```

---

## ⚙️ Installation

### 1. SSH into Router
```sh
ssh root@192.168.1.1
```

### 2. Create Script
```sh
cat > /usr/bin/hourly_update.sh <<'EOF'
#!/bin/sh

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

get_wan_ip() { curl -fsS http://ifconfig.me || echo "unknown"; }
get_uptime() { awk '{print int($1) " seconds"}' /proc/uptime; }
get_load()   { awk '{print $1" "$2" "$3}' /proc/loadavg; }
get_mem()    { free -m | awk '/Mem:/ {print $4 " MB free"}'; }
get_disk()   { df -h / | awk 'NR==2 {print $4 " free (" $5 " used)"}'; }

WAN_IP="$(get_wan_ip)"
UPTIME="$(get_uptime)"
LOAD="$(get_load)"
MEMORY="$(get_mem)"
DISK="$(get_disk)"

MESSAGE="
Router Status Update
WAN IP: $WAN_IP
Uptime: $UPTIME
Load: $LOAD
Memory: $MEMORY
Disk: $DISK
"

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  -d text="$MESSAGE" >/dev/null 2>&1
EOF

chmod +x /usr/bin/hourly_update.sh
```

### 3. Test Script
```sh
export TELEGRAM_BOT_TOKEN="your_token"
export TELEGRAM_CHAT_ID="your_chat_id"
/usr/bin/hourly_update.sh
```

---

## 🕒 Automatic Execution

### Cron Method (simple)
```
crontab -e
0 * * * * TELEGRAM_BOT_TOKEN="xxx" TELEGRAM_CHAT_ID="yyy" /usr/bin/hourly_update.sh
```

### Service Method (recommended)
```
cat > /etc/init.d/router_bot <<'EOF'
#!/bin/sh /etc/rc.common
START=99
USE_PROCD=1

start_service() {
  procd_open_instance
  procd_set_param command /usr/bin/hourly_update.sh
  procd_set_param respawn 3600 5 0
  procd_close_instance
}
EOF

chmod +x /etc/init.d/router_bot
service router_bot enable
service router_bot start
```

---

## 📡 Telegram Setup

### Create Bot
1. Open Telegram  
2. Search: **@BotFather**  
3. Send `/newbot`  
4. Save your **Bot Token**

### Get Chat ID
Send message to your bot and run:
```
https://api.telegram.org/botTOKEN/getUpdates
```
Look for `"chat":{"id":123456789}`

---

## 🔍 Verification
```
service router_bot status
logread | grep hourly_update.sh
ps | grep hourly_update.sh
```

---

## 🛠 Troubleshooting
- Install curl: `opkg update && opkg install curl`
- Ensure bot is started in Telegram  
- Validate token/chat ID via `getUpdates`  
- Script must be executable: `chmod +x`  

---

## 📘 License
Free to use and modify. Attribution appreciated.

---

## ✉ Contact  
Maintainer: **Asep Sayyad**

