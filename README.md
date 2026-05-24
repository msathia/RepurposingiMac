# Repurposing iMac — Lean AI Machine Blueprint

Turn a **2017 Intel iMac (8 GB RAM / 1 TB HDD)** into a dual-boot system: macOS Ventura (~250 GB) + **Xubuntu Minimal** (~750 GB) with local Ollama inference and a Telegram bot interface.

## Repository Layout

```
.
├── ai_bot/
│   ├── ai_bot.py              # Telegram ↔ Ollama polling bot
│   └── requirements.txt       # Python dependencies
├── nanobot/skills/
│   └── yt-recommender/
│       ├── SKILL.md           # Agent directive for video recommendations
│       └── scripts/
│           └── search_yt.py   # On-demand yt-dlp metadata worker
├── deploy/
│   ├── apt/nosnap.pref        # Blocks snapd re-install
│   └── systemd/aibot.service  # Systemd unit template
└── scripts/
    ├── post-install.sh        # Post-Xubuntu setup automation
    └── install-service.sh     # Deploy and enable systemd service
```

---

## Part 1: Cleaning and Disk Partitioning (macOS Side)

Before touching the Linux installer, partition inside **macOS Ventura**.

### Step 1: Disk Utility Breakdown

1. Open **Disk Utility**.
2. **View → Show All Devices**.
3. Select the main internal physical storage container (e.g. **APPLE HDD**).
4. Click **Partition**.

### Step 2: Slice the Volumes

1. Allocate **~250 GB** for macOS.
2. Click **+** to create a new zone:
   - **Name:** Linux Space (or generic)
   - **Format:** MS-DOS (FAT) or ExFAT (temporary divider)
   - **Size:** ~750 GB
3. Click **Apply** and wait for the resize to finish.
4. Select the new 750 GB slice → **Erase** → **Free Space** (unallocated). This leaves raw space for the Linux installer.

---

## Part 2: Installing Xubuntu Minimal

### Step 1: Boot the Live Installer

1. Shut down the iMac.
2. Insert the flash drive, hold **Option (⌥)** while powering on.
3. Select the **EFI Boot** volume with your Linux image.
4. On the GRUB menu, choose **Try or Install Xubuntu**.

### Step 2: Installer Wizard

| Screen | Setting |
|--------|---------|
| Installation type | **Xubuntu Minimal** (~591 MB idle RAM vs ~771 MB full) |
| Third-party software | **Checked** (Intel graphics + Broadcom Wi-Fi) |
| Additional media formats | **Unchecked** |

### Step 3: Manual Partitioning ("Something Else")

Enable **Manual Installation**, then map:

| Partition | Action |
|-----------|--------|
| **sda1** (VFAT ~200 MB) | Leave **Format** unchecked. Mount: `/boot/efi` |
| **sda2** (APFS ~250 GB) | **Do not touch** — macOS volume |
| **free space** (~750 GB) | Create primary **Ext4**, mount `/`, **Format checked** |

**Boot loader:** `/dev/sda` (top-level drive, not sda1/sda3).

Complete username, password, and installation.

---

## Part 3: Post-Install Optimization

Clone this repo on the iMac, then run from the repo root:

```bash
git clone <this-repo-url> ~/RepurposingiMac
cd ~/RepurposingiMac
chmod +x scripts/*.sh
./scripts/post-install.sh
```

Or run steps manually:

### Snap Removal

```bash
snap list
sudo snap remove --purge snapd-desktop-integration
sudo snap remove --purge bare
sudo snap remove --purge core22
sudo snap remove --purge snapd

sudo systemctl stop snapd.service
sudo systemctl disable snapd.service
sudo systemctl mask snapd.service

sudo apt purge snapd -y
rm -rf ~/snap
sudo rm -rf /var/cache/snapd/

sudo cp deploy/apt/nosnap.pref /etc/apt/preferences.d/nosnap.pref
```

### Lightweight Browser

```bash
sudo apt update
sudo apt install midori -y
```

---

## Part 4: AI Pipeline

### Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
systemctl status ollama
ollama pull llama3.2:3b
```

### Python Virtual Environment

```bash
pkill -f ai_bot.py || true
sudo apt install python3-venv python3-pip -y
mkdir -p ~/ai_bot && cd ~/ai_bot
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Copy `ai_bot.py` from this repo (or use `post-install.sh` which deploys to `~/ai_bot`).

### Telegram Token

1. Message [@BotFather](https://t.me/BotFather) on Telegram to create a bot and get a token.
2. Export it:

```bash
export TELEGRAM_TOKEN="your_token_here"
```

Or copy `.env.example` to `.env` and fill in the token (`.env` is gitignored).

---

## Part 5: Nanobot Skills

Skills live under `~/nanobot/skills/`. The **yt-recommender** skill:

- **SKILL.md** — tells the agent how to use search results.
- **search_yt.py** — runs `yt-dlp` on demand (~50 MB RAM briefly).

Test the worker:

```bash
python3 ~/nanobot/skills/yt-recommender/scripts/search_yt.py "machine learning tutorials"
```

The bot auto-invokes this skill when messages mention youtube, video, watch, or recommend.

---

## Part 6: Systemd Service (Always-On)

From the repo root on the iMac:

```bash
./scripts/install-service.sh sathia YOUR_TELEGRAM_TOKEN
```

Replace `sathia` with your Xubuntu username.

Manual equivalent:

```bash
sudo cp deploy/systemd/aibot.service /etc/systemd/system/aibot.service
# Edit paths, User=, and TELEGRAM_TOKEN=
sudo systemctl daemon-reload
sudo systemctl enable aibot.service
sudo systemctl start aibot.service
```

### Debugging

```bash
journalctl -u aibot -f
```

---

## Hardware Notes

- **RAM:** 8 GB — use `llama3.2:3b` or similarly small models.
- **Storage:** 1 TB HDD — expect slower model loads than SSD; minimal install reduces background I/O.
- **Wi-Fi:** Enable third-party drivers during install for Broadcom Apple Wi-Fi.

---

## License

Personal homelab project — adapt freely.
