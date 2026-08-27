# hermes-omarchy

Reusable Hermes ↔ Omarchy integration tooling by SMF Works.

## What's here

### `bin/hermes-omarchy-setup`

One idempotent script that sets up boot integration for Hermes desktop + Ollama
on any Omarchy machine:

| Part | What it does |
|---|---|
| Ollama | systemd **user** service (`WantedBy=default.target`), enabled at login, verified serving `127.0.0.1:11434`. Uses the existing unit if present. |
| Desktop entry | Writes `~/.local/share/applications/hermes.desktop` pointing at the **self-contained venv launcher** (`~/.hermes/hermes-agent/venv/bin/hermes desktop`) — survives Python upgrades, unlike entries pinning a mise/python-version path. |
| Autostart | `o.launch_on_start("<unpacked Hermes> --no-sandbox")`. Not `hermes` (CLI) and not `hermes desktop` (sudo chrome-sandbox, no TTY → exit 1). |
| Skills | Symlinks Omarchy's `omarchy` and `diagnose-crash` skills into `~/.hermes/skills` and every `~/.hermes/profiles/*/skills`. Same contract as `omarchy-provision-user`. |
| Plugin | Symlinks this repo's `plugin/` into `~/.hermes/plugins/omarchy` (and existing profiles) and runs `hermes plugins enable omarchy`. Allowlisted theme/plugin/bar/menu/screenshot/shell-ping verbs; `--yes` on mutating plugin commands. Hidden off non-Omarchy hosts. |

Bar **usage** is not this repo. Use Mustafa's widget (local `state.db` + remote gateway):

```bash
omarchy plugin add https://github.com/okurmustafa/omarchy-hermes.git --enable --yes
```

`shell-plugin/` (`smf.hermes`) is an optional launch/status stub only (`install --shell-plugin`). Do not run it next to Mustafa's meter.

### Usage

```bash
git clone https://github.com/smfworks/hermes-omarchy
cd hermes-omarchy
bin/hermes-omarchy-setup install     # or: check | remove
```

- `install` — apply everything (idempotent; safe to re-run)
- `install --no-ollama` / `--no-autostart` / `--no-skills` / `--no-plugin` — opt out per part
- `install --shell-plugin` — opt in the `smf.hermes` launch stub (off by default)
- `check` — verify current state, exit 0/1 (scriptable health probe)
- `remove` — revert autostart; `remove --all` also disables ollama and unlinks skills/plugin/shell widget

### Design notes

- **Ollama: user unit, not system unit.** The system package unit runs as a
  separate `ollama` user with models in `/var/lib/ollama`. Running both is a
  port conflict. The user unit shares your `~/.ollama` models and starts at
  login (default.target), no graphical session needed.
- **Desktop entry: venv launcher, not mise python.** Mise paths bake in a
  Python version; the first `mise` upgrade breaks the entry.
- **Autostart: packaged Electron `--no-sandbox`, not `hermes desktop`.** The Python wrapper `sudo chown`s `chrome-sandbox` and `sys.exit(1)` when there is no TTY.
- **Idempotent + reversible.** `check` mode for health probes; `remove` for
  teardown; nothing force-overwritten silently.

Tested on Omarchy (Arch, Hyprland) with Hermes git-install v0.20.6, Ollama
0.32.15, 2026-08-27.

## Roadmap

Sequenced with the vault's [[hermes-omarchy-integration-plan]]:

- **W1** — Omarchy agent skill symlinked for Hermes — done (installer + upstream PR)
- **W2** — `hermes` as an `omarchy default agent` option — closed #8617 in favor of #7392
- **W3** — `omarchy-theme-set-hermes` — closed #8622 in favor of #6644
- **W4** — `omarchy-agent-usage-hermes` collector — closed #8626 in favor of #6647
- **W5** — Hermes plugin wrapping the `omarchy` CLI + shell IPC — done (this installer)
- **W6** — bar widget: use [okurmustafa/omarchy-hermes](https://github.com/okurmustafa/omarchy-hermes); `smf.hermes` stub is opt-in only

## License

MIT