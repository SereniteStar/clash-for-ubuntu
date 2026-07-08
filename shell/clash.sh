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
    print(f'无法连接 Clash API: {exc}')
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
    print('用法: clash switch [节点编号]')
    raise SystemExit(2)

try:
    target_index = int(sys.argv[1])
except ValueError:
    print('节点编号必须是数字')
    raise SystemExit(2)

api_url = 'http://127.0.0.1:9097/proxies/PROXY'

try:
    data = json.load(urllib.request.urlopen(api_url, timeout=5))
    nodes = data.get('all', [])
except Exception as exc:
    print(f'无法连接 Clash API: {exc}')
    raise SystemExit(1)

if not 1 <= target_index <= len(nodes):
    print(f'节点编号超出范围: 1-{len(nodes)}')
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
    print(f'切换失败: HTTP {exc.code} {exc.reason}')
    raise SystemExit(1)
except Exception as exc:
    print(f'切换失败: {exc}')
    raise SystemExit(1)

print(f'已切换到 {target_index:02d} {node}')
PY
            ;;
        *)
            echo -e "clash on 开启代理\nclash off 关闭代理\nclash restart 重启代理\nclash status 查询代理状态\nclash list 节点列表\nclash switch [节点编号] 切换代理节点"
            return 2
            ;;
    esac
}
