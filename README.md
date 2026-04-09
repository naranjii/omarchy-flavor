# omarship-powerline-themes

Theme-aware Starship powerline prompt for Omarchy users.

This project installs a Starship template into Omarchy's user template directory and links `~/.config/starship.toml` to Omarchy's active theme output, so prompts follow the current Omarchy theme automatically.

## What it does

- Uses a powerline-style prompt inspired by Starship's `pastel-powerline` and `catppuccin-powerline` presets.
- Renders colors from Omarchy theme `colors.toml` values using Omarchy template placeholders.
- Keeps everything in safe user locations under `~/.config`.
- Supports clean uninstall and restore of the previous Starship config.

## Files in this repo

- `starship.toml.tpl`: Omarchy-compatible template with `{{ color }}` placeholders.
- `install.sh`: installs template, backups existing config, creates symlink, refreshes theme.
- `uninstall.sh`: removes integration and restores previous Starship config backup.

## Prerequisites

- Omarchy installed and configured.
- Starship installed and enabled in your shell.
- A Nerd Font enabled in your terminal.

## Install

```bash
chmod +x install.sh uninstall.sh
./install.sh
```

Optional flags:

```bash
./install.sh --no-refresh
./install.sh --home /path/to/test-home
```

## Uninstall

```bash
./uninstall.sh
```

Optional flags:

```bash
./uninstall.sh --no-refresh
./uninstall.sh --home /path/to/test-home
```

## How theme switching works

1. Omarchy sets a theme using `omarchy-theme-set`.
2. Omarchy renders templates from `~/.config/omarchy/themed/*.tpl` into `~/.config/omarchy/current/theme/*`.
3. `~/.config/starship.toml` points to `~/.config/omarchy/current/theme/starship.toml`.
4. Starship prompt updates with the new theme palette.

## Safety and scope

- This project does **not** modify `~/.local/share/omarchy/`.
- This project only writes to user paths under `~/.config`.
- Existing `~/.config/starship.toml` is backed up and can be restored with `uninstall.sh`.
