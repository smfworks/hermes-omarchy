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
bin/hermes-omarchy-scene show "Talking to the machine" --duration 0
bin/hermes-omarchy-scene hide
```

Or:

```bash
omarchy-shell shell summon smf.scene-card '{"title":"Installing Tailscale","subtitle":"official verb","duration":5000}'
omarchy-shell shell hide smf.scene-card
```

Escape is not captured (clicks pass through, like OSD). Duration 0 keeps it up until `hide`.

## Remove

```bash
bin/hermes-omarchy-scene remove
```
