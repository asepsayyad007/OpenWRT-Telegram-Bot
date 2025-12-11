# \# OpenWRT Telegram Bot

### 

### A lightweight script to send hourly status updates from a TP-Link AC1750 (Archer C7 V2) router running the latest OpenWRT.



#### \## 🚀 Use Cases

\* \*\*Hourly Heartbeat:\*\* Confirms the router is alive and internet is working.

\* \*\*IP Monitoring:\*\* Notifies if the WAN IP address changes (useful for remote access).

\* \*\*Resource Tracking:\*\* Reports current CPU load and Free Memory.

\* \*\*Uptime Check:\*\* Sends current uptime duration.



#### \## 🛠️ Prerequisites

\* \*\*Hardware:\*\* TP-Link Archer C7 (AC1750) V2 or Similar device

\* \*\*Software:\*\* OpenWRT (Latest Firmware)

\* \*\*Packages:\*\* `curl` or `wget` (usually pre-installed)

\* \*\*Telegram Bot:\*\* A valid Bot Token and Chat ID.



#### \## 📖 Installation Guide



##### \### 1. Connect to Router

Open your terminal and SSH into the router:

```bash

ssh root@192.168.1.1

##### \### 2. Install the Script

1# Create the file

vi /root/hourly\_update.sh

chmod +x /root/hourly\_update.sh

/root/hourly\_update.sh


### ⏰ Automate (The Hourly Setup)

crontab -e

0 \* \* \* \* /root/hourly\_update.sh

/etc/init.d/cron restart

