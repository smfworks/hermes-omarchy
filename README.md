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
| Autostart | Adds `o.launch_on_start("hermes")` to `~/.config/hypr/autostart.lua` — the Omarchy-native verb. Resolves the desktop entry via `uwsm-app` at `hyprland.start`. |
| Skills | Symlinks Omarchy's `omarchy` and `diagnose-crash` skills into `~/.hermes/skills` and every `~/.hermes/profiles/*/skills`. Same contract as `omarchy-provision-user`. |

### Usage

```bash
git clone https://github.com/smfworks/hermes-omarchy
cd hermes-omarchy
bin/hermes-omarchy-setup install     # or: check | remove
```

- `install` — apply everything (idempotent; safe to re-run)
- `install --no-ollama` / `--no-autostart` / `--no-skills` — opt out per part
- `check` — verify current state, exit 0/1 (scriptable health probe)
- `remove` — revert autostart; `remove --all` also disables the ollama service and unlinks skills

### Design notes

- **Ollama: user unit, not system unit.** The system package unit runs as a
  separate `ollama` user with models in `/var/lib/ollama`. Running both is a
  port conflict. The user unit shares your `~/.ollama` models and starts at
  login (default.target), no graphical session needed.
- **Desktop entry: venv launcher, not mise python.** Mise paths bake in a
  Python version; the first `mise` upgrade breaks the entry.
- **Autostart: `o.launch_on_start`, not `exec-once`.** Goes through uwsm-app →
  desktop entry → proper Wayland/uwsm session integration.
- **Idempotent + reversible.** `check` mode for health probes; `remove` for
  teardown; nothing force-overwritten silently.

Tested on Omarchy (Arch, Hyprland) with Hermes git-install v0.20.6, Ollama
0.32.15, 2026-08-27.

## Roadmap

Sequenced with the vault's [[hermes-omarchy-integration-plan]]:

- **W1** — Omarchy agent skill symlinked for Hermes (`~/.hermes/skills`) — **done** (this installer; upstream Omarchy PR pending)
- **W2** — `hermes` as an `omarchy default agent` option (upstream PR)
- **W3** — `omarchy-theme-set-hermes` (theme → Hermes skin sync)
- **W4** — `omarchy-agent-usage-hermes` collector (agents bar panel)
- **W5** — Hermes plugin wrapping the `omarchy` CLI + shell IPC
- **W6** — Omarchy shell widget for Hermes sessions

## License

MIT