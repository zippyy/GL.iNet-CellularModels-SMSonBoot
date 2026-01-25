# 📡 GL.iNet Cellular SMS on Boot

Send an SMS from a **GL.iNet cellular router** when it boots — ideal for alerts after **power outages** or unexpected reboots.

This project targets **GL.iNet / OpenWrt firmware** that includes the built-in `sendsms` utility (for example: **GL-XE3000** (**Puli AX**), **GL-X3000** (**Spitz AX**) and other cellular models). It also includes a **Textbelt** option for devices without a cellular modem.

---

## ✨ Features

- 📲 Sends an SMS on router boot
- 🔌 Great for power-outage notifications
- 🌐 Automatically detects the active cellular WAN interface
- 🕒 Built-in cooldown to prevent SMS spam
- 🛠 Uses GL.iNet’s native `sendsms` backend (same path as the web UI)
---

## ✅ Prerequisites

- Root access on the router (`ssh root@<router-ip>`)
- Internet access to fetch installer scripts
- For the **sendsms** version: GL.iNet firmware with `sendsms` available
- For the **Textbelt** version: a Textbelt API key

## 🚀 One-Line Install

Replace `<YOURNUMBER>` with the phone number that should receive the SMS:

Example including country code: +13038675309

For the textbelt version replace `<YOURNUMBER>` and `<YOUR_TEXTBELT_KEY>`

```sh
# SENDSMS (Cellular SIM) Version
sh -c "$(curl -fsSL https://raw.githubusercontent.com/techrelay/GL.iNet-CellularModels-SMSonBoot/main/install.sh)" -- <YOURNUMBER>

# Textbelt Version
sh -c "$(curl -fsSL https://raw.githubusercontent.com/techrelay/GL.iNet-CellularModels-SMSonBoot/main/install_textbelt.sh)" -- <YOURNUMBER> <YOUR_TEXTBELT_KEY>

# Combined Version (interactive, no arguments)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/techrelay/GL.iNet-CellularModels-SMSonBoot/main/install_combined.sh)"
```

  ![35BF6268-8DBB-4A14-99C2-8406653029FB_1_105_c](https://github.com/user-attachments/assets/0372f6cc-ef24-485f-a133-c45d68f73a19)

---

## 🧰 Manual Install (no curl on router)

### Option A: sendsms (Cellular SIM)
1. Copy `sms_on_boot.sh` to `/usr/bin/sms_on_boot.sh`
2. Edit the `PHONE` value inside the script.
3. Create an init script:
   ```sh
   cat > /etc/init.d/sms_on_boot <<'EOF'
   #!/bin/sh /etc/rc.common
   START=99
   start() {
     /usr/bin/sms_on_boot.sh &
   }
   EOF
   chmod +x /etc/init.d/sms_on_boot
   /etc/init.d/sms_on_boot enable
   ```

### Option B: Textbelt
1. Copy `sms_on_boot_textbelt.sh` to `/usr/bin/sms_on_boot_textbelt.sh`
2. Edit `PHONE` and `TEXTBELT_KEY` inside the script.
3. Create an init script:
   ```sh
   cat > /etc/init.d/sms_on_boot_textbelt <<'EOF'
   #!/bin/sh /etc/rc.common
   START=99
   start() {
     /usr/bin/sms_on_boot_textbelt.sh &
   }
   EOF
   chmod +x /etc/init.d/sms_on_boot_textbelt
   /etc/init.d/sms_on_boot_textbelt enable
   ```

### Option C: Combined (prefers one, falls back to the other)
1. Copy `sms_on_boot_combined.sh` to `/usr/bin/sms_on_boot_combined.sh`
2. Create `/etc/sms_on_boot_combined.conf`:
   ```sh
   cat > /etc/sms_on_boot_combined.conf <<'EOF'
   PHONE="+17192291657"
   PREFER="textbelt" # or sendsms
   TEXTBELT_KEY="textbelt"
   EOF
   chmod 600 /etc/sms_on_boot_combined.conf
   ```
3. Create init script:
   ```sh
   cat > /etc/init.d/sms_on_boot_combined <<'EOF'
   #!/bin/sh /etc/rc.common
   START=99
   start() {
     /usr/bin/sms_on_boot_combined.sh &
   }
   EOF
   chmod +x /etc/init.d/sms_on_boot_combined
   /etc/init.d/sms_on_boot_combined enable
   ```

---

## 🔧 Configuration & Logs

- **Cooldown:** Each script has a `COOLDOWN` setting (default 300s) to prevent SMS spam.
- **Logs:**
  - `/tmp/sms_on_boot.log`
  - `/tmp/sms_on_boot_textbelt.log`
  - `/tmp/sms_on_boot_combined.log`

## 🧪 Test Without Reboot

```sh
rm -f /etc/sms_on_boot.last && /usr/bin/sms_on_boot.sh && cat /tmp/sms_on_boot.log
```

```sh
rm -f /etc/sms_on_boot_textbelt.last && /usr/bin/sms_on_boot_textbelt.sh && cat /tmp/sms_on_boot_textbelt.log
```

```sh
rm -f /etc/sms_on_boot_combined.last && /usr/bin/sms_on_boot_combined.sh && cat /tmp/sms_on_boot_combined.log
```

## 🗑️ Uninstall

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/techrelay/GL.iNet-CellularModels-SMSonBoot/main/uninstall.sh)"
```

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/techrelay/GL.iNet-CellularModels-SMSonBoot/main/uninstall_textbelt.sh)"
```

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/techrelay/GL.iNet-CellularModels-SMSonBoot/main/uninstall_combined.sh)"
```
