# 📡 GL.iNet Cellular SMS on Boot

Send an SMS from a **GL.iNet cellular router** when it boots — ideal for alerts after **power outages** or unexpected reboots.

This project targets **GL.iNet / OpenWrt firmware** that includes the built-in `sendsms` utility (for example: **GL-XE3000** (**Puli AX**), **GL-X3000** (**Spitz AX**) and other cellular models).

---

## ✨ Features

- 📲 Sends an SMS on router boot
- 🔌 Great for power-outage notifications
- 🌐 Automatically detects the active cellular WAN interface
- 🕒 Built-in cooldown to prevent SMS spam
- 🛠 Uses GL.iNet’s native `sendsms` backend (same path as the web UI)

---

**Manual install instructions incoming**

## 🚀 One-Line Install

Replace `<YOURNUMBER>` with the phone number that should receive the SMS:

Example including country code: +13038675309

For the textbelt version replace '<YOURNUMBER>' and '<YOUR_TEXTBELT_KEY>'

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/techrelay/GL.iNet-CellularModels-SMSonBoot/main/install.sh)" -- <YOURNUMBER>


sh -c "$(curl -fsSL https://raw.githubusercontent.com/zippyy/GL.iNet-CellularModels-SMSonBoot/main/install_textbelt.sh)" -- <YOURNUMBER> <YOUR_TEXTBELT_KEY>
