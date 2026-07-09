# clash-for-ubuntu

Command-line shortcuts for managing Clash/Mihomo on Ubuntu.

## Quick install

On another Ubuntu computer, run:

```bash
git clone https://github.com/SereniteStar/clash-for-ubuntu.git
cd clash-for-ubuntu
./install.sh
source ~/.bash_aliases
clash
```

`install.sh` automatically:

- downloads and installs the Mihomo core to `~/.local/bin/mihomo` if it is missing
- creates a sample `~/.config/mihomo/config.yaml` if no config exists
- installs `proxy-on` and `proxy-off`
- installs the `mihomo.service` user service
- adds the `clash` command to bash, and to zsh if `~/.zshrc` exists

If you already have a config file, pass it during installation:

```bash
./install.sh /path/to/config.yaml
```

You can also pass a subscription/config URL:

```bash
./install.sh 'https://example.com/your-config.yaml'
```

Or use an environment variable:

```bash
CONFIG_URL='https://example.com/your-config.yaml' ./install.sh
```

> Note: this repository does not store your subscription URL or provider config. Provide it separately on each computer.

## Command menu

Run `clash` with no arguments to open the command menu.

## Usage

After installation, the `clash` command is available:

```bash
clash                                # Open the command menu
clash on                             # Start Mihomo and enable the GNOME system proxy
clash off                            # Stop Mihomo and disable the GNOME system proxy
clash restart                        # Restart Mihomo and enable the system proxy
clash status                         # Show service, proxy, config, and API health
clash list                           # List nodes in the PROXY proxy group
clash switch <node-number>           # Switch to a node shown by clash list
clash import <url-or-file>           # Import a Clash subscription/config
```

If no config is provided during first install, the script creates a sample file:

```bash
~/.config/mihomo/config.yaml
```

Replace it with your own Mihomo/Clash config, or import a Clash subscription URL:

```bash
clash import 'https://example.com/your-clash-subscription'
clash restart
```

Then run:

```bash
clash on
clash list
clash switch 1
```

## Import a Clash subscription

Most VPN providers can copy a Clash subscription URL. Import it with:

```bash
clash import 'https://example.com/your-clash-subscription'
clash restart
```

You can also import a local config file:

```bash
clash import /path/to/config.yaml
clash restart
```

The import command writes to:

```bash
~/.config/mihomo/config.yaml
```

If an old config already exists, it creates a timestamped backup next to it before replacing the file.

## Config requirements

To support `clash list` and `clash switch`, your config needs:

```yaml
external-controller: 127.0.0.1:9097
```

It also needs a proxy group named `PROXY`.

If the config does not contain `external-controller` or a proxy port, the installer appends:

```yaml
mixed-port: 7890
external-controller: 127.0.0.1:9097
```

## Update

```bash
cd clash-for-ubuntu
git pull
./install.sh
```

## Uninstall

```bash
./uninstall.sh
```

The uninstall script removes the scripts and systemd user service installed by this project. It does not remove your Mihomo config directory or the Mihomo core binary.

## Defaults

- Proxy port: `7890`
- API endpoint: `http://127.0.0.1:9097`
- Proxy group: `PROXY`
- systemd user service: `mihomo.service`
