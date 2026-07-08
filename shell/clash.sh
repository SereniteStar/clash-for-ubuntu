# Clash/Mihomo proxy shortcuts
clash() {
    case "${1:-}" in
        on)
            "$HOME/.local/bin/proxy-on"
            ;;
        off)
            "$HOME/.local/bin/proxy-off"
            ;;
        status)
            systemctl --user status mihomo
            ;;
        restart)
            systemctl --user restart mihomo && "$HOME/.local/bin/proxy-on"
            ;;
        list)
            python3 - <<'PY'
import json
import urllib.request

try:
    data = json.load(urllib.request.urlopen('http://127.0.0.1:9097/proxies/PROXY', timeout=5))
except Exception as exc:
    print(f'Could not connect to Clash API: {exc}')
    raise SystemExit(1)

current = data.get('now')
for index, name in enumerate(data.get('all', []), 1):
    marker = '*' if name == current else ' '
    print(f'{marker} {index:02d} {name}')
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
    print('Usage: clash switch [node-number]')
    raise SystemExit(2)

try:
    target_index = int(sys.argv[1])
except ValueError:
    print('Node number must be numeric')
    raise SystemExit(2)

api_url = 'http://127.0.0.1:9097/proxies/PROXY'

try:
    data = json.load(urllib.request.urlopen(api_url, timeout=5))
    nodes = data.get('all', [])
except Exception as exc:
    print(f'Could not connect to Clash API: {exc}')
    raise SystemExit(1)

if not 1 <= target_index <= len(nodes):
    print(f'Node number out of range: 1-{len(nodes)}')
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
    print(f'Switch failed: HTTP {exc.code} {exc.reason}')
    raise SystemExit(1)
except Exception as exc:
    print(f'Switch failed: {exc}')
    raise SystemExit(1)

print(f'Switched to {target_index:02d} {node}')
PY
            ;;
        *)
            echo -e "clash on Start proxy\nclash off Stop proxy\nclash restart Restart proxy\nclash status Show proxy status\nclash list List nodes\nclash switch [node-number] Switch proxy node"
            return 2
            ;;
    esac
}
