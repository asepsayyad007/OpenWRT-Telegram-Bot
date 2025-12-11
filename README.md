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
------------------------------------------------------------------------------------------



Make persistent

We will create a special control file in /etc/init.d/.

Create the file:

Bash

vi /etc/init.d/router_bot
Paste this code exactly. It tells the router to treat your script like a critical system service:

Bash

#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    procd_open_instance
    # 1. The command to run
    procd_set_param command /usr/bin/hourly_update.sh

    # 2. Respawn automatically if it dies
    # (wait 3600s if it crashes too fast, wait 5s before restart, retry forever)
    procd_set_param respawn 3600 5 0

    # 3. Log output so you can see errors (logread)
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

Save and exit (Esc, :wq, Enter).

Make it executable:

Bash

chmod +x /etc/init.d/router_bot
Step 2: Clean up Old Methods
To avoid running two copies (which causes conflicts/loops), remove the old startup command.

Open rc.local:

Bash

vi /etc/rc.local
Delete the line /usr/bin/hourly_update.sh &.

Save and exit.

Kill any currently running scripts:

Bash

killall hourly_update.sh
Step 3: Enable and Start the Permanent Service
Now, tell OpenWrt to enable the "Respawn" protection and start the bot.

Bash

# Enable start on boot
service router_bot enable

# Start it right now
service router_bot start
How to check if it's working?
If the script crashes or you kill it manually, the router will now restart it within 5 seconds automatically.

You can verify it is running as a service with:

Bash

service router_bot status
(It should say "running").
