# omarship-powerline-themes

Theme-aware Starship powerline prompt for **all Omarchy users**. Automatically detects and extracts colors from any Omarchy theme using multiple fallback sources for maximum compatibility.

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

## Color Source Priority

The script automatically detects and extracts colors from Omarchy themes using a fallback hierarchy:

1. **`custom_theme.json`** (highest priority) - Direct color definitions from theme metadata
2. **`alacritty.toml`** (medium priority) - Colors extracted from Alacritty terminal configuration  
3. **Fallback colors** (lowest priority) - Default Dracula-inspired color palette when no theme colors are found
4. **Neutral config** (failsafe) - Clean minimal prompt when color extraction fails

This ensures compatibility with all Omarchy themes, whether they have modern `custom_theme.json` files, legacy `alacritty.toml` configurations, or minimal color definitions.

## Safety and scope

- This project does **not** modify `~/.local/share/omarchy/`.
- This project only writes to user paths under `~/.config`.
- Existing `~/.config/starship.toml` is backed up and can be restored with `uninstall.sh`.
