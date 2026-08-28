# smf.scene-card

Lower-third overlay for Hermes-on-Omarchy camera demos. Not a bar widget.
Does not replace `mustafaokur.hermes`.

## Install

From this repo (copy, not symlink — `omarchy plugin validate` rejects symlinks):

```bash
bin/hermes-omarchy-scene install
```

## Use

```bash
bin/hermes-omarchy-scene show "Installing Tailscale" --subtitle "omarchy install service tailscale"
bin/hermes-omarchy-scene hide
```

Default duration is 5s. Dismiss anytime: **click the card**, **Escape**, or **Super+W**.
While the card is up, Super+W does **not** close Hermes (it is rebound only for the life of the layer).

`--duration 0` holds until dismiss. Do not leave it up unattended.

```bash
omarchy-shell shell summon smf.scene-card '{"title":"Installing Tailscale","subtitle":"official verb","duration":5000}'
omarchy-shell shell hide smf.scene-card
```

## Remove

```bash
bin/hermes-omarchy-scene remove
```
