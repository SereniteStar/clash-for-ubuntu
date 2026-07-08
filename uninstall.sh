#!/usr/bin/env bash
set -euo pipefail

systemctl --user disable --now mihomo 2>/dev/null || true
rm -f "$HOME/.local/bin/proxy-on" "$HOME/.local/bin/proxy-off"
rm -f "$HOME/.config/systemd/user/mihomo.service"
systemctl --user daemon-reload

if [ -f "$HOME/.bash_aliases" ]; then
    python3 - "$HOME/.bash_aliases" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
start = '# >>> clash-for-ubuntu >>>'
end = '# <<< clash-for-ubuntu <<<'
text = path.read_text()

if start in text and end in text:
    before, rest = text.split(start, 1)
    _, after = rest.split(end, 1)
    text = before.rstrip() + '\n' + after.lstrip('\n')
    path.write_text(text)
PY
fi

echo "Uninstall complete. Mihomo config directory and core binary were not removed."
