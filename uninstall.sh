#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--home PATH] [--no-refresh]

Removes Omarchy-aware Starship powerline integration.
EOF
}

TARGET_HOME=${HOME}
REFRESH=1

MANAGED_HOOK_START="# >>> starship-powerline managed block >>>"
MANAGED_HOOK_END="# <<< starship-powerline managed block <<<"

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

CONFIG_DIR="$TARGET_HOME/.config"
OMARCHY_DIR="$CONFIG_DIR/omarchy"
THEMED_DIR="$OMARCHY_DIR/themed"
CURRENT_THEME_DIR="$OMARCHY_DIR/current/theme"
STARSHIP_PATH="$CONFIG_DIR/starship.toml"
TARGET_STARSHIP="$CURRENT_THEME_DIR/starship.toml"
STATE_FILE="$OMARCHY_DIR/.starship-powerline-state"
INSTALLED_TEMPLATE="$THEMED_DIR/starship.toml.tpl"
NEUTRAL_CONFIG="$THEMED_DIR/starship-neutral.toml"
THEME_HOOK_PATH="$OMARCHY_DIR/hooks/theme-set"
BACKUP_PATH=""
FALLBACK_RESTORED=0

if [[ -f "$STATE_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$STATE_FILE"
fi

if [[ -L "$STARSHIP_PATH" ]]; then
  CURRENT_LINK=$(readlink "$STARSHIP_PATH" || true)
  if [[ "$CURRENT_LINK" == "$TARGET_STARSHIP" ]]; then
    rm -f "$STARSHIP_PATH"
  fi
fi

if [[ -n "${BACKUP_PATH:-}" && -e "$BACKUP_PATH" ]]; then
  mv "$BACKUP_PATH" "$STARSHIP_PATH"
fi

if [[ ! -e "$STARSHIP_PATH" && ! -L "$STARSHIP_PATH" ]]; then
  DEFAULT_STARSHIP_SOURCE=""

  if [[ -n "${OMARCHY_PATH:-}" && -f "$OMARCHY_PATH/config/starship.toml" ]]; then
    DEFAULT_STARSHIP_SOURCE="$OMARCHY_PATH/config/starship.toml"
  elif [[ -f "$TARGET_HOME/.local/share/omarchy/config/starship.toml" ]]; then
    DEFAULT_STARSHIP_SOURCE="$TARGET_HOME/.local/share/omarchy/config/starship.toml"
  fi

  if [[ -n "$DEFAULT_STARSHIP_SOURCE" ]]; then
    cp "$DEFAULT_STARSHIP_SOURCE" "$STARSHIP_PATH"
    FALLBACK_RESTORED=1
  fi
fi

rm -f "$INSTALLED_TEMPLATE"
rm -f "$NEUTRAL_CONFIG"

if [[ -f "$THEME_HOOK_PATH" ]] && grep -Fq "$MANAGED_HOOK_START" "$THEME_HOOK_PATH"; then
  tmp_hook=$(mktemp)
  awk -v start="$MANAGED_HOOK_START" -v end="$MANAGED_HOOK_END" '
    $0 == start { inside=1; next }
    $0 == end { inside=0; next }
    !inside { print }
  ' "$THEME_HOOK_PATH" >"$tmp_hook"

  if [[ -s "$tmp_hook" ]]; then
    mv "$tmp_hook" "$THEME_HOOK_PATH"
  else
    rm -f "$THEME_HOOK_PATH" "$tmp_hook"
  fi
fi

rm -f "$STATE_FILE"

if [[ $REFRESH -eq 1 ]]; then
  if command -v omarchy-theme-refresh >/dev/null 2>&1; then
    omarchy-theme-refresh
  else
    echo "Warning: omarchy-theme-refresh not found, skipping refresh" >&2
  fi
fi

echo "Removed template: $INSTALLED_TEMPLATE"
if [[ -e "$STARSHIP_PATH" || -L "$STARSHIP_PATH" ]]; then
  echo "Active config: $STARSHIP_PATH"
  if [[ $FALLBACK_RESTORED -eq 1 ]]; then
    echo "Restored fallback from Omarchy default starship config"
  fi
else
  echo "No active starship config found at: $STARSHIP_PATH"
fi
