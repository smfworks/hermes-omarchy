# smf.hermes

Optional Omarchy bar **launch/status** stub. Not the usage meter.

For tokens / local vs remote gateway, install Mustafa's widget instead:

```bash
omarchy plugin add https://github.com/okurmustafa/omarchy-hermes.git --enable --yes
```

Do not enable this stub next to that plugin — two Hermes pills.

## This stub

- id `smf.hermes` (not `omarchy.*`)
- kind `bar-widget`
- No symlinks (`omarchy plugin validate` refuses them)

```bash
# toolkit opt-in only
bin/hermes-omarchy-setup install --shell-plugin
```

Left click: panel. Right click: launch Hermes desktop. Middle click: refresh.
