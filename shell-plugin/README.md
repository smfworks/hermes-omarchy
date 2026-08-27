# smf.hermes

Third-party Omarchy shell plugin: Hermes Agent on the bar.

## Contract

- `schemaVersion: 1`
- id `smf.hermes` (not `omarchy.*` — that namespace is reserved)
- kind `bar-widget`, entry `BarWidget.qml`
- No symlinks in this folder (`omarchy plugin validate` refuses them)

## Install

From this toolkit (copies files; does not symlink):

```bash
omarchy plugin add https://github.com/smfworks/smf-hermes.git --enable --yes
# or via the toolkit (copies files; does not symlink):
bin/hermes-omarchy-setup install --no-ollama --no-autostart --no-skills --no-plugin
```

Left click: panel. Right click: launch Hermes desktop. Middle click: refresh.
Panel: Enter/L launch, R refresh `omarchy agent usage-update hermes` (no-op until W4 merges).
