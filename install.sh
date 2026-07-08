#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -Dm755 "$ROOT_DIR/bin/proxy-on" "$HOME/.local/bin/proxy-on"
install -Dm755 "$ROOT_DIR/bin/proxy-off" "$HOME/.local/bin/proxy-off"
install -Dm644 "$ROOT_DIR/systemd/user/mihomo.service" "$HOME/.config/systemd/user/mihomo.service"

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

systemctl --user daemon-reload
systemctl --user enable mihomo >/dev/null

echo "安装完成。请运行: source ~/.bash_aliases"
echo "然后可以使用: clash on / clash off / clash list / clash switch [节点编号]"
