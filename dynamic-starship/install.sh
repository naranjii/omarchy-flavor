#!/usr/bin/env bash
set -euo pipefail

MANAGED_HOOK_START="# >>> starship-powerline managed block >>>"
MANAGED_HOOK_END="# <<< starship-powerline managed block <<<"

usage() {
  cat <<'EOF'
Usage: install.sh [--home PATH] [--no-refresh]

Installs Omarchy-aware Starship powerline integration.
EOF
}

TARGET_HOME=${HOME}
REFRESH=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home)
      TARGET_HOME=${2:-}
      shift 2
      ;;
    --no-refresh)
      REFRESH=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET_HOME" ]]; then
  echo "Target home cannot be empty" >&2
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_SRC="$SCRIPT_DIR/starship.toml.tpl"

if [[ ! -f "$TEMPLATE_SRC" ]]; then
  echo "Template not found: $TEMPLATE_SRC" >&2
  exit 1
fi

CONFIG_DIR="$TARGET_HOME/.config"
OMARCHY_DIR="$CONFIG_DIR/omarchy"
THEMED_DIR="$OMARCHY_DIR/themed"
CURRENT_THEME_DIR="$OMARCHY_DIR/current/theme"
HOOKS_DIR="$OMARCHY_DIR/hooks"
THEME_HOOK_PATH="$HOOKS_DIR/theme-set"
STARSHIP_PATH="$CONFIG_DIR/starship.toml"
TARGET_STARSHIP="$CURRENT_THEME_DIR/starship.toml"
BACKUP_DIR="$OMARCHY_DIR/backups/starship-powerline"
STATE_FILE="$OMARCHY_DIR/.starship-powerline-state"
INSTALLED_TEMPLATE="$THEMED_DIR/starship.toml.tpl"
NEUTRAL_CONFIG="$THEMED_DIR/starship-neutral.toml"

if [[ ! -d "$OMARCHY_DIR" ]]; then
  echo "Omarchy config not found at: $OMARCHY_DIR" >&2
  exit 1
fi

mkdir -p "$THEMED_DIR" "$BACKUP_DIR" "$HOOKS_DIR"

BACKUP_PATH=""
if [[ -e "$STARSHIP_PATH" || -L "$STARSHIP_PATH" ]]; then
  if [[ -L "$STARSHIP_PATH" ]]; then
    CURRENT_LINK=$(readlink "$STARSHIP_PATH" || true)
    if [[ "$CURRENT_LINK" != "$TARGET_STARSHIP" ]]; then
      BACKUP_PATH="$BACKUP_DIR/starship.toml.link.$(date +%Y%m%d-%H%M%S)"
      mv "$STARSHIP_PATH" "$BACKUP_PATH"
    fi
  else
    BACKUP_PATH="$BACKUP_DIR/starship.toml.$(date +%Y%m%d-%H%M%S)"
    cp -a "$STARSHIP_PATH" "$BACKUP_PATH"
  fi
fi

install -m 0644 "$TEMPLATE_SRC" "$INSTALLED_TEMPLATE"

cat >"$NEUTRAL_CONFIG" <<'EOF'
add_newline = false
command_timeout = 2000

format = "[$username@$hostname]($style) [$directory]($style) $character"

[username]
show_always = true
format = "$user"

[hostname]
ssh_only = false
format = "$hostname"

[directory]
truncation_length = 3
truncation_symbol = ".../"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
EOF

if [[ ! -f "$THEME_HOOK_PATH" ]]; then
  cat >"$THEME_HOOK_PATH" <<'EOF'
#!/usr/bin/env bash
EOF
fi

if ! grep -Fq "$MANAGED_HOOK_START" "$THEME_HOOK_PATH"; then
  cat >>"$THEME_HOOK_PATH" <<'EOF'

# >>> starship-powerline managed block >>>
STARSHIP_TEMPLATE="$HOME/.config/omarchy/themed/starship.toml.tpl"
STARSHIP_NEUTRAL="$HOME/.config/omarchy/themed/starship-neutral.toml"
STARSHIP_TARGET="$HOME/.config/omarchy/current/theme/starship.toml"
STARSHIP_COLORS="$HOME/.config/omarchy/current/theme/colors.toml"

starship_powerline_render() {
  local tmp_file
  local sed_script
  local key
  local value

  [[ -f "$STARSHIP_TEMPLATE" && -f "$STARSHIP_COLORS" ]] || return 1

  sed_script=$(mktemp)
  while IFS='=' read -r key value; do
    key="${key//[\"\' ]/}"
    [[ -n "$key" && "$key" != \#* ]] || continue
    value="${value#*[\"\']}"
    value="${value%%[\"\']*}"
    printf 's|{{ %s }}|%s|g\n' "$key" "$value"
    printf 's|{{ %s_strip }}|%s|g\n' "$key" "${value#\#}"
  done <"$STARSHIP_COLORS" >"$sed_script"

  tmp_file=$(mktemp)
  sed -f "$sed_script" "$STARSHIP_TEMPLATE" >"$tmp_file"
  rm -f "$sed_script"

  if STARSHIP_CONFIG="$tmp_file" starship print-config >/dev/null 2>&1; then
    mv "$tmp_file" "$STARSHIP_TARGET"
    return 0
  fi

  rm -f "$tmp_file"
  return 1
}

starship_powerline_fallback() {
  [[ -f "$STARSHIP_NEUTRAL" ]] || return 1
  cp "$STARSHIP_NEUTRAL" "$STARSHIP_TARGET"
  STARSHIP_CONFIG="$STARSHIP_TARGET" starship print-config >/dev/null 2>&1
}

if ! starship_powerline_render; then
  starship_powerline_fallback || true
fi

# <<< starship-powerline managed block <<<
EOF
fi

chmod +x "$THEME_HOOK_PATH"

ln -sfn "$TARGET_STARSHIP" "$STARSHIP_PATH"

cat >"$STATE_FILE" <<EOF
TARGET_HOME="$TARGET_HOME"
STARSHIP_PATH="$STARSHIP_PATH"
INSTALLED_TEMPLATE="$INSTALLED_TEMPLATE"
NEUTRAL_CONFIG="$NEUTRAL_CONFIG"
TARGET_STARSHIP="$TARGET_STARSHIP"
THEME_HOOK_PATH="$THEME_HOOK_PATH"
MANAGED_HOOK_START="$MANAGED_HOOK_START"
MANAGED_HOOK_END="$MANAGED_HOOK_END"
BACKUP_PATH="$BACKUP_PATH"
EOF

if [[ $REFRESH -eq 1 ]]; then
  if command -v omarchy-theme-refresh >/dev/null 2>&1; then
    omarchy-theme-refresh
  else
    echo "Warning: omarchy-theme-refresh not found, skipping refresh" >&2
  fi
fi

echo "Installed template: $INSTALLED_TEMPLATE"
echo "Linked config: $STARSHIP_PATH -> $TARGET_STARSHIP"
if [[ -n "$BACKUP_PATH" ]]; then
  echo "Backup saved: $BACKUP_PATH"
fi
