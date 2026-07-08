# Clash/Mihomo proxy shortcuts
CLASH_FOR_UBUNTU_VERSION="1.0.0"
CLASH_FOR_UBUNTU_AUTHOR="SereniteStar"
CLASH_FOR_UBUNTU_SERVICE="mihomo.service"
CLASH_FOR_UBUNTU_API_BASE="http://127.0.0.1:9097"
CLASH_FOR_UBUNTU_PROXY_HOST="127.0.0.1"
CLASH_FOR_UBUNTU_PROXY_PORT="7890"
CLASH_FOR_UBUNTU_PROXY_GROUP="PROXY"

_clash_header() {
    cat <<'EOF'
🚀 Clash for Ubuntu
EOF
}

_clash_menu() {
    cat <<EOF
╭────────────────────────────────────────────╮
│ 🚀 Clash for Ubuntu                        │
│ Mihomo proxy management shortcuts          │
╰────────────────────────────────────────────╯

📦 Version : $CLASH_FOR_UBUNTU_VERSION
👤 Author  : $CLASH_FOR_UBUNTU_AUTHOR
🛠  Service : $CLASH_FOR_UBUNTU_SERVICE
🌐 API     : $CLASH_FOR_UBUNTU_API_BASE
🔌 Proxy   : $CLASH_FOR_UBUNTU_PROXY_HOST:$CLASH_FOR_UBUNTU_PROXY_PORT
🧩 Group   : $CLASH_FOR_UBUNTU_PROXY_GROUP

Usage:
  clash <command> [options]

🧭 Commands:
  ▶ on                         Start Mihomo and enable the GNOME system proxy
  ▶ off                        Disable the GNOME system proxy and stop Mihomo
  ▶ status                     Show Mihomo service status and proxy settings
  ▶ restart                    Restart Mihomo and enable the system proxy
  ▶ list                       List nodes in the PROXY proxy group
  ▶ switch <node-number>       Switch to a node shown by "clash list"
  ▶ import <url-or-file>       Import a Clash/Mihomo subscription or config file

✨ Typical workflow:
  → clash import <subscription-url-or-config-file>
  → clash restart
  → clash list
  → clash switch <node-number>
  → clash status

Examples:
  clash on
  clash list
  clash switch 3
  clash import 'https://example.com/your-clash-subscription'

💡 Tip:
  Run "clash status" if the proxy does not work as expected.
EOF
}

_clash_unknown_command() {
    cat <<EOF
⚠️  Error:
  Unknown command: $1

Run:
  clash

Available commands:
  on, off, status, restart, list, switch, import
EOF
}

_clash_status() {
    local service_state proxy_mode config_file api_state api_label service_label proxy_label config_label

    service_state="$(systemctl --user is-active mihomo 2>/dev/null || true)"
    [ -n "$service_state" ] || service_state="unknown"

    proxy_mode="$(gsettings get org.gnome.system.proxy mode 2>/dev/null | tr -d "'" || true)"
    [ -n "$proxy_mode" ] || proxy_mode="unknown"

    config_file="$HOME/.config/mihomo/config.yaml"

    if [ "$service_state" = "active" ]; then
        service_label="OK"
    else
        service_label="Warning ($service_state)"
    fi

    if [ "$proxy_mode" = "manual" ]; then
        proxy_label="manual"
    else
        proxy_label="Warning ($proxy_mode)"
    fi

    if [ -f "$config_file" ]; then
        config_label="$config_file"
    else
        config_label="missing: $config_file"
    fi

    api_state="$(python3 - <<'PY'
import json
import urllib.request

try:
    with urllib.request.urlopen('http://127.0.0.1:9097/proxies/PROXY', timeout=3) as response:
        json.load(response)
    print('OK')
except Exception as exc:
    print(f'Warning ({exc})')
PY
)"
    api_label="$api_state"

    cat <<EOF
🚀 Clash for Ubuntu

📊 Status summary:
  Service      : $service_state
  GNOME proxy  : $proxy_mode
  Local proxy  : 127.0.0.1:7890
  API endpoint : http://127.0.0.1:9097
  Config file  : $config_label

🩺 Health checks:
  ✓ Mihomo service       : $service_label
  ✓ External controller  : $api_label
  ✓ GNOME proxy mode     : $proxy_label

🔎 Details:
  systemctl --user status mihomo --no-pager
  journalctl --user -u mihomo -e
EOF
}

clash() {
    case "${1:-}" in
        "")
            _clash_menu
            ;;
        on)
            "$HOME/.local/bin/proxy-on"
            ;;
        off)
            "$HOME/.local/bin/proxy-off"
            ;;
        status)
            _clash_status
            ;;
        restart)
            echo "🚀 Clash for Ubuntu"
            echo
            echo "▶ Action:"
            echo "  Restarting Mihomo service..."
            echo
            systemctl --user restart mihomo
            echo "✅ Result:"
            echo "  Mihomo restarted successfully."
            echo
            "$HOME/.local/bin/proxy-on"
            ;;
        list)
            python3 - <<'PY'
import json
import urllib.request

api_url = 'http://127.0.0.1:9097/proxies/PROXY'

try:
    data = json.load(urllib.request.urlopen(api_url, timeout=5))
except Exception as exc:
    print('⚠️  Error:')
    print('  Could not connect to Clash API.')
    print()
    print('📌 Details:')
    print(f'  Endpoint : {api_url}')
    print(f'  Reason   : {exc}')
    print()
    print('🛠 Possible fixes:')
    print('  • Run "clash on"')
    print('  • Run "clash status"')
    print('  • Check that your config contains: external-controller: 127.0.0.1:9097')
    print('  • Check that your config has a proxy group named PROXY')
    raise SystemExit(1)

current = data.get('now')
nodes = data.get('all', [])
current_index = next((index for index, name in enumerate(nodes, 1) if name == current), None)

print('🚀 Clash for Ubuntu')
print()
print('🧩 Proxy group:')
print('  PROXY')
print()
print('★ Current node:')
if current_index is None:
    print(f'  {current or "Unknown"}')
else:
    print(f'  {current_index:02d} {current}')
print()
print('📜 Available nodes:')
for index, name in enumerate(nodes, 1):
    marker = '*' if name == current else ' '
    print(f'  {marker} {index:02d} {name}')
print()
print('➡ Next step:')
print('  clash switch <node-number>')
PY
            ;;
        switch)
            shift
            python3 - "$@" <<'PY'
import json
import sys
import urllib.error
import urllib.request

if len(sys.argv) != 2:
    print('⚠️  Error:')
    print('  Missing node number.')
    print()
    print('Usage:')
    print('  clash switch <node-number>')
    print()
    print('Example:')
    print('  clash list')
    print('  clash switch 3')
    raise SystemExit(2)

try:
    target_index = int(sys.argv[1])
except ValueError:
    print('⚠️  Error:')
    print('  Node number must be numeric.')
    print()
    print('Received:')
    print(f'  {sys.argv[1]}')
    print()
    print('Usage:')
    print('  clash switch <node-number>')
    raise SystemExit(2)

api_url = 'http://127.0.0.1:9097/proxies/PROXY'

try:
    data = json.load(urllib.request.urlopen(api_url, timeout=5))
    nodes = data.get('all', [])
except Exception as exc:
    print('⚠️  Error:')
    print('  Could not connect to Clash API.')
    print()
    print('📌 Details:')
    print(f'  Endpoint : {api_url}')
    print(f'  Reason   : {exc}')
    print()
    print('🛠 Possible fixes:')
    print('  • Run "clash on"')
    print('  • Run "clash status"')
    print('  • Check that your config contains: external-controller: 127.0.0.1:9097')
    print('  • Check that your config has a proxy group named PROXY')
    raise SystemExit(1)

if not 1 <= target_index <= len(nodes):
    print('⚠️  Error:')
    print('  Node number out of range.')
    print()
    print('Valid range:')
    print(f'  1-{len(nodes)}')
    print()
    print('Received:')
    print(f'  {target_index}')
    print()
    print('Run:')
    print('  clash list')
    raise SystemExit(2)

node = nodes[target_index - 1]
request = urllib.request.Request(
    api_url,
    data=json.dumps({'name': node}).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='PUT',
)

try:
    urllib.request.urlopen(request, timeout=5).read()
except urllib.error.HTTPError as exc:
    print('⚠️  Error:')
    print(f'  Switch failed: HTTP {exc.code} {exc.reason}')
    raise SystemExit(1)
except Exception as exc:
    print('⚠️  Error:')
    print(f'  Switch failed: {exc}')
    raise SystemExit(1)

print('🚀 Clash for Ubuntu')
print()
print('▶ Action:')
print('  Switching proxy node...')
print()
print('✅ Result:')
print('  Proxy node switched successfully.')
print()
print('★ Selected node:')
print(f'  {target_index:02d} {node}')
print()
print('💡 Tip:')
print('  Run "clash list" to confirm the active node.')
PY
            ;;
        import)
            shift
            python3 - "$@" <<'PY'
from pathlib import Path
from datetime import datetime
import re
import shutil
import sys
import urllib.request

if len(sys.argv) != 2:
    print('⚠️  Error:')
    print('  Missing subscription URL or config file.')
    print()
    print('Usage:')
    print('  clash import <subscription-url-or-config-file>')
    print()
    print('Examples:')
    print("  clash import 'https://example.com/your-clash-subscription'")
    print('  clash import /path/to/config.yaml')
    raise SystemExit(2)

source = sys.argv[1]
config_dir = Path.home() / '.config' / 'mihomo'
config_path = config_dir / 'config.yaml'
config_dir.mkdir(parents=True, exist_ok=True)

print('🚀 Clash for Ubuntu')
print()
print('▶ Action:')
print('  Importing Clash/Mihomo configuration...')
print()
print('📥 Source:')
print(f'  {source}')
print()

try:
    if Path(source).is_file():
        content = Path(source).read_text()
    else:
        request = urllib.request.Request(
            source,
            headers={'User-Agent': 'clash-for-ubuntu/1.0'},
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            content = response.read().decode('utf-8')
except Exception as exc:
    print('⚠️  Error:')
    print(f'  Import failed: {exc}')
    raise SystemExit(1)

if not content.strip():
    print('⚠️  Error:')
    print('  Import failed because the subscription/config is empty.')
    print()
    print('No changes were applied.')
    raise SystemExit(1)

append = []
if not re.search(r'(?m)^\s*(mixed-port|port|socks-port)\s*:', content):
    append.append('mixed-port: 7890')
if not re.search(r'(?m)^\s*external-controller\s*:', content):
    append.append('external-controller: 127.0.0.1:9097')
if append:
    content = content.rstrip() + '\n\n# Added by clash-for-ubuntu\n' + '\n'.join(append) + '\n'

print('🛟 Backup:')
if config_path.exists():
    backup_path = config_path.with_suffix(f'.yaml.backup-{datetime.now().strftime("%Y%m%d%H%M%S")}')
    shutil.copy2(config_path, backup_path)
    print(f'  Created: {backup_path}')
else:
    print('  None needed.')
print()

config_path.write_text(content)
print('✅ Result:')
print('  Config imported successfully.')
print()
print('📄 Config file:')
print(f'  {config_path}')
print()
print('🧩 Compatibility additions:')
if append:
    for item in append:
        print(f'  • {item}')
else:
    print('  None needed.')
print()
print('➡ Next steps:')
print('  clash restart')
print('  clash status')
print('  clash list')
PY
            ;;
        *)
            _clash_unknown_command "$1"
            return 2
            ;;
    esac
}
