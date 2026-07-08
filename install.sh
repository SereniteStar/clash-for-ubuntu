#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SOURCE="${1:-${CONFIG_URL:-}}"
MIHOMO_VERSION="${MIHOMO_VERSION:-latest}"

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing command: $1"
        echo "Install dependencies first, for example: sudo apt update && sudo apt install -y curl gzip tar python3"
        exit 1
    fi
}

install_mihomo() {
    if [ -x "$HOME/.local/bin/mihomo" ]; then
        echo "Mihomo already exists: $HOME/.local/bin/mihomo"
        return
    fi

    need_cmd curl
    need_cmd gzip
    need_cmd python3

    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="armv7" ;;
        *)
            echo "Unsupported CPU architecture: $(uname -m)"
            exit 1
            ;;
    esac

    echo "Downloading Mihomo core ($arch)..."
    if [ "$MIHOMO_VERSION" = "latest" ]; then
        release_api="https://api.github.com/repos/MetaCubeX/mihomo/releases/latest"
    else
        release_api="https://api.github.com/repos/MetaCubeX/mihomo/releases/tags/$MIHOMO_VERSION"
    fi

    download_url="$(python3 - "$release_api" "$arch" <<'PY'
import json
import sys
import urllib.request

api_url, arch = sys.argv[1], sys.argv[2]
with urllib.request.urlopen(api_url, timeout=20) as response:
    release = json.load(response)

candidates = []
for asset in release.get('assets', []):
    name = asset.get('name', '').lower()
    url = asset.get('browser_download_url', '')
    if 'linux' in name and arch in name and name.endswith('.gz'):
        candidates.append((name, url))

preferred = [item for item in candidates if 'compatible' not in item[0] and 'go' not in item[0]]
chosen = (preferred or candidates or [(None, '')])[0][1]
print(chosen)
PY
)"

    if [ -z "$download_url" ]; then
        echo "Could not find a Mihomo download for linux-$arch"
        exit 1
    fi

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT
    curl -fL "$download_url" -o "$tmp_dir/mihomo.gz"
    gzip -dc "$tmp_dir/mihomo.gz" > "$tmp_dir/mihomo"
    install -Dm755 "$tmp_dir/mihomo" "$HOME/.local/bin/mihomo"
    echo "Mihomo installed to: $HOME/.local/bin/mihomo"
}

install_config() {
    mkdir -p "$HOME/.config/mihomo"

    if [ -n "$CONFIG_SOURCE" ]; then
        if [ -f "$CONFIG_SOURCE" ]; then
            cp "$CONFIG_SOURCE" "$HOME/.config/mihomo/config.yaml"
        else
            need_cmd curl
            curl -fL "$CONFIG_SOURCE" -o "$HOME/.config/mihomo/config.yaml"
        fi
        echo "Config installed to: $HOME/.config/mihomo/config.yaml"
    elif [ ! -f "$HOME/.config/mihomo/config.yaml" ]; then
        cat > "$HOME/.config/mihomo/config.yaml" <<'YAML'
# Replace this file with your Mihomo/Clash subscription config.
# It needs usable proxies/proxy-providers and a proxy group named PROXY.

mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
external-controller: 127.0.0.1:9097

proxies: []
proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - DIRECT
rules:
  - MATCH,PROXY
YAML
        echo "Sample config created: $HOME/.config/mihomo/config.yaml"
        echo "Replace it with your subscription config before running clash on."
    fi

    python3 - "$HOME/.config/mihomo/config.yaml" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
append = []
if not re.search(r'(?m)^\s*(mixed-port|port|socks-port)\s*:', text):
    append.append('mixed-port: 7890')
if not re.search(r'(?m)^\s*external-controller\s*:', text):
    append.append('external-controller: 127.0.0.1:9097')
if append:
    text = text.rstrip() + '\n\n# Added by clash-for-ubuntu\n' + '\n'.join(append) + '\n'
    path.write_text(text)
PY
}

install_shell_integration() {
    if [ ! -f "$HOME/.bash_aliases" ]; then
        touch "$HOME/.bash_aliases"
    fi

    START_MARKER="# >>> clash-for-ubuntu >>>"
    END_MARKER="# <<< clash-for-ubuntu <<<"
    SOURCE_LINE="source \"$ROOT_DIR/shell/clash.sh\""

    python3 - "$HOME/.bash_aliases" "$START_MARKER" "$END_MARKER" "$SOURCE_LINE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
start = sys.argv[2]
end = sys.argv[3]
source_line = sys.argv[4]
block = f'{start}\n{source_line}\n{end}\n'
text = path.read_text() if path.exists() else ''

if start in text and end in text:
    before, rest = text.split(start, 1)
    _, after = rest.split(end, 1)
    text = before.rstrip() + '\n\n' + block + after.lstrip('\n')
elif source_line not in text:
    text = text.rstrip() + '\n\n' + block

path.write_text(text)
PY

    if [ -f "$HOME/.zshrc" ]; then
        python3 - "$HOME/.zshrc" "$START_MARKER" "$END_MARKER" "$SOURCE_LINE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
start = sys.argv[2]
end = sys.argv[3]
source_line = sys.argv[4]
block = f'{start}\n{source_line}\n{end}\n'
text = path.read_text() if path.exists() else ''

if start in text and end in text:
    before, rest = text.split(start, 1)
    _, after = rest.split(end, 1)
    text = before.rstrip() + '\n\n' + block + after.lstrip('\n')
elif source_line not in text:
    text = text.rstrip() + '\n\n' + block

path.write_text(text)
PY
    fi
}

install_mihomo
install_config
install -Dm755 "$ROOT_DIR/bin/proxy-on" "$HOME/.local/bin/proxy-on"
install -Dm755 "$ROOT_DIR/bin/proxy-off" "$HOME/.local/bin/proxy-off"
install -Dm644 "$ROOT_DIR/systemd/user/mihomo.service" "$HOME/.config/systemd/user/mihomo.service"
install_shell_integration

systemctl --user daemon-reload
systemctl --user enable mihomo >/dev/null

echo "Installation complete."
echo "Open a new terminal, or run: source ~/.bash_aliases"
echo "Common commands: clash on / clash off / clash list / clash switch [node-number]"
