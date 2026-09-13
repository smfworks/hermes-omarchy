# hermes-omarchy

**Hermes on Omarchy in ~15 minutes.**

Starter kit from [SMF Works](https://www.smfclearinghouse.com) for people who already run [Omarchy Linux](https://omarchy.org) and want [Hermes Agent](https://hermes-agent.nousresearch.com/) to boot cleanly, stay launched, and show up on the bar.

This repo is user-local glue: one idempotent setup script, a small Hermes plugin, and Hyprland helpers. It is **not** a fork of [omacom/omarchy](https://github.com/omacom/omarchy).

## Who this is for

- You are on an **Omarchy** host (Arch + Hyprland, `/usr/share/omarchy` present).
- You have **Hermes Agent** installed (desktop and/or CLI).
- You want Hermes to autostart, talk to Omarchy, and appear on the bar — without hunting tribal notes.

If you are looking for a token-usage meter, that is a different project (see [What this is not](#what-this-is-not)).

## Prerequisites

| Need | Notes |
|---|---|
| Omarchy Linux | A working Omarchy install. This script refuses to run elsewhere. |
| Hermes Agent | On Omarchy: **Install → AI → Hermes Desktop** (first launch writes `~/.hermes`). Or the official [Hermes installer](https://hermes-agent.nousresearch.com/docs/getting-started/installation). The setup script looks for the packaged Electron binary under `~/.hermes/hermes-agent/apps/desktop/release/linux-unpacked/Hermes`. |
| Ollama | Optional. Needed only if you want local models on `127.0.0.1:11434`. Install with `omarchy-pkg-add ollama` if you do not have it yet. Skip with `--no-ollama`. |

## Happy path

On the Omarchy machine:

```bash
git clone https://github.com/smfworks/hermes-omarchy
cd hermes-omarchy
bin/hermes-omarchy-setup install
```

Then add the sister bar widget ([smfworks/smf-hermes](https://github.com/smfworks/smf-hermes), id `smf.hermes`, `schemaVersion: 1`):

```bash
omarchy plugin add https://github.com/smfworks/smf-hermes.git --enable --yes
```

Confirm:

```bash
bin/hermes-omarchy-setup check
```

Re-login (or reboot) once so autostart and the exclusive workspace load. Skills and the Omarchy Hermes plugin take effect on the next Hermes session.

No Ollama? Use `bin/hermes-omarchy-setup install --no-ollama`.

`install` is idempotent. Re-run it after a Hermes upgrade if the desktop entry or plugin link looks stale.

## What `install` does

| Part | What you get |
|---|---|
| Ollama | systemd **user** unit (`WantedBy=default.target`), enabled at login, serving `127.0.0.1:11434`. Leaves an existing unit untouched. |
| Desktop entry | Packaged Electron `…/linux-unpacked/Hermes --no-sandbox`. A user systemd path unit restores that `Exec` if `hermes desktop` rewrites the file. |
| Autostart | `o.launch_on_start("<unpacked Hermes> --no-sandbox")`. Not the `hermes` CLI, and not `hermes desktop` (that path needs a TTY). |
| Skills | Symlinks Omarchy's `omarchy` and `diagnose-crash` skills into `~/.hermes/skills` and every `~/.hermes/profiles/*/skills`. |
| Plugin | Symlinks this repo's `plugin/` into `~/.hermes/plugins/omarchy` and runs `hermes plugins enable omarchy`. Allowlisted theme / plugin / bar / menu / screenshot / shell-ping verbs. Hidden off non-Omarchy hosts. |
| Exclusive WS | Class `Hermes` stays on workspace 1 (full tile). Other apps that would open there go to workspace 2+. Dialogs, PiP, webcam, and screensaver stay. Skip with `--no-exclusive-ws`. |

The bar widget is **not** installed by this script. Use [smf-hermes](https://github.com/smfworks/smf-hermes) as shown above.

## Bar widget: smf-hermes

Published repo: [https://github.com/smfworks/smf-hermes](https://github.com/smfworks/smf-hermes)

Contract (from that README):

- `schemaVersion: 1`
- id `smf.hermes` (not `omarchy.*` — that namespace is reserved)
- kind `bar-widget`, entry `BarWidget.qml`
- No symlinks in the plugin folder (`omarchy plugin validate` refuses them)

Install and enable (exact command from that repo):

```bash
omarchy plugin add https://github.com/smfworks/smf-hermes.git --enable --yes
```

Left click: panel. Right click: launch Hermes desktop. Middle click: refresh.

Move it if you need to:

```bash
omarchy bar move smf.hermes --section right
```

This toolkit can copy a bundled stub with `bin/hermes-omarchy-setup install --shell-plugin`. Prefer the published repo so `omarchy plugin update` works. Do not enable both — two Hermes pills on the bar.

## Commands

```bash
bin/hermes-omarchy-setup install     # apply everything (idempotent)
bin/hermes-omarchy-setup check       # health probe; exit 0/1
bin/hermes-omarchy-setup remove      # revert autostart + exclusive-ws
bin/hermes-omarchy-setup remove --all
```

Useful flags on `install`:

- `--no-ollama` / `--no-autostart` / `--no-skills` / `--no-plugin` — skip that part
- `--no-exclusive-ws` — do not pin Hermes to workspace 1
- `--shell-plugin` — copy the bundled `smf.hermes` stub (off by default; prefer [smf-hermes](https://github.com/smfworks/smf-hermes))

`remove --all` also disables the Ollama user unit and unlinks skills / plugin / bundled shell widget. The desktop entry stays; delete it yourself if you do not want it.

## Troubleshooting

### Hermes will not autostart (`chrome-sandbox` / `--no-sandbox`)

`hermes desktop` tries to `sudo chown` Electron's `chrome-sandbox` and `sys.exit(1)` when there is no TTY — which is exactly how Hyprland autostart runs. This setup launches the packaged binary with `--no-sandbox` instead.

Check that autostart points at the unpacked binary:

```bash
grep linux-unpacked/Hermes ~/.config/hypr/autostart.lua
```

If the packaged binary is missing, launch Hermes Desktop once (Install → AI, or `hermes desktop` from a real terminal) so it builds `~/.hermes/hermes-agent/apps/desktop/release/linux-unpacked/Hermes`, then re-run `bin/hermes-omarchy-setup install`.

### Ollama: user unit, not the system package unit

The distro `ollama.service` runs as a separate `ollama` user with models in `/var/lib/ollama`. This script enables **your** user unit so it shares `~/.ollama` and starts at login (`default.target`). Running both fights over port `11434`.

```bash
systemctl --user status ollama
journalctl --user -u ollama -e
curl -sf http://127.0.0.1:11434/ && echo up
```

If the system unit is enabled, stop it before relying on the user unit. `install` leaves an existing user unit file untouched.

### `hermes desktop` rewrote `hermes.desktop`

`hermes desktop` can rewrite `~/.local/share/applications/hermes.desktop` to a mise/Python `Exec`. That breaks after a Python upgrade and is the wrong launcher for autostart.

This setup writes `Exec=…/linux-unpacked/Hermes --no-sandbox` and enables `hermes-desktop-entry-guard.path`, which restores that line on change.

```bash
systemctl --user status hermes-desktop-entry-guard.path
grep '^Exec=' ~/.local/share/applications/hermes.desktop
```

If the guard is off, re-run `bin/hermes-omarchy-setup install`.

### Exclusive workspace (Hermes on WS1)

After install, class `Hermes` stays on workspace 1. Other mapped windows that would open there go to 2+. Dialogs and pinned overlays stay.

This is **your** Hyprland config (`~/.config/hypr/hermes-exclusive.lua` plus a `require` in `hyprland.lua`). It never writes `/usr/share/omarchy`.

Skip on install: `--no-exclusive-ws`. Remove later:

```bash
bin/hermes-omarchy-setup remove          # drops exclusive-ws + autostart
# or edit ~/.config/hypr/hyprland.lua and delete the hermes-exclusive require
```

Then reload Hyprland (`hyprctl reload`).

### Plugin or skills missing in Hermes

The installer symlinks this repo's `plugin/` and Omarchy's skill dirs. If you moved the clone, re-run `install`. Enable by hand if needed:

```bash
hermes plugins enable omarchy --no-allow-tool-override
```

The plugin stays hidden on non-Omarchy hosts.

## Optional extras

Camera / demo helpers in this repo — not part of the 15-minute path:

| Script | What it is |
|---|---|
| `bin/hermes-omarchy-demo on\|off\|check` | Reversible camera mode (rounding, slim bar, presentation floats). |
| `bin/hermes-omarchy-scene` | Overlay `smf.scene-card` lower-third. Not a bar widget. |
| `bin/hermes-omarchy-roll beat\|hide\|preview` | Raise the scene card at the start of a shot. |
| `bin/hermes-omarchy-fire` | Park a window on a headless output for Fire VNC (Apps → **Fire Display**). |

## What this is not

- **Not upstream Omarchy.** Do not treat this as a fork of [omacom/omarchy](https://github.com/omacom/omarchy). File desktop bugs there; this repo only writes user-local config.
- **Not Mustafa's usage widget.** [okurmustafa/omarchy-hermes](https://github.com/okurmustafa/omarchy-hermes) (`mustafaokur.hermes`) is a token-usage meter (local `state.db` / remote gateway). Different job. Do not run it next to `smf.hermes` unless you want two pills.
- **Not the published bar widget.** The widget lives at [smfworks/smf-hermes](https://github.com/smfworks/smf-hermes). `shell-plugin/` here is a bundled copy for `--shell-plugin` only.

## Related

- [smfworks/smf-hermes](https://github.com/smfworks/smf-hermes) — bar widget
- [Hermes Agent](https://hermes-agent.nousresearch.com/) — the agent
- [Omarchy](https://omarchy.org) — the desktop
- [SMF Clearinghouse](https://www.smfclearinghouse.com) — practitioner notes from [SMF Works](https://github.com/smfworks)
- [hermes-ai-team](https://github.com/smfworks/hermes-ai-team) — turning one Hermes install into a team (after this starter kit)

## License

MIT
