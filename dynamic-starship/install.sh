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
if [[ ! -f "$THEME_HOOK_PATH" ]]; then
  cat >"$THEME_HOOK_PATH" <<'EOF'
#!/usr/bin/env bash
EOF
fi

if grep -Fq "$MANAGED_HOOK_START" "$THEME_HOOK_PATH"; then
  # Remove existing managed block
  sed -i "/$MANAGED_HOOK_START/,/$MANAGED_HOOK_END/d" "$THEME_HOOK_PATH"
fi

# Add the updated managed block
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
  local required_vars=("color1" "color2" "color3" "color4" "accent" "background" "color10" "color11")
  local fallback_colors=(
    "color1:#ff5555"
    "color2:#50fa7b"
    "color3:#f1fa8c"
    "color4:#bd93f9"
    "accent:#ff79c6"
    "background:#282a36"
    "color10:#50fa7b"
    "color11:#f1fa8c"
  )

  [[ -f "$STARSHIP_TEMPLATE" ]] || return 1

  # If colors.toml doesn't exist, try to generate it from custom_theme.json
  if [[ ! -f "$STARSHIP_COLORS" ]]; then
    starship_generate_colors_from_theme || return 1
  fi

  [[ -f "$STARSHIP_COLORS" ]] || return 1

  sed_script=$(mktemp)
  
  # First pass: read existing colors
  declare -A color_map
  while IFS='=' read -r key value; do
    key="${key//[\"\' ]/}"
    [[ -n "$key" && "$key" != \#* ]] || continue
    value="${value#*[\"\']}"
    value="${value%%[\"\']*}"
    color_map["$key"]="$value"
  done <"$STARSHIP_COLORS"

  # Second pass: apply fallbacks for missing colors
  for fallback in "${fallback_colors[@]}"; do
    key="${fallback%%:*}"
    default_value="${fallback#*:}"
    if [[ -z "${color_map[$key]}" ]]; then
      printf 's|{{ %s }}|%s|g\n' "$key" "$default_value"
      printf 's|{{ %s_strip }}|%s|g\n' "$key" "${default_value#\#}"
    fi
  done

  # Third pass: apply existing colors
  for key in "${!color_map[@]}"; do
    value="${color_map[$key]}"
    printf 's|{{ %s }}|%s|g\n' "$key" "$value"
    printf 's|{{ %s_strip }}|%s|g\n' "$key" "${value#\#}"
  done >"$sed_script"

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

starship_extract_from_custom_theme() {
  local custom_theme_json="$1"
  
  # Extract colors from custom_theme.json and generate colors.toml
  if command -v jq >/dev/null 2>&1; then
    {
      # Extract primary colors
      jq -r '.colors.primary // empty | to_entries[] | "\(.key) = \"\(.value)\""' "$custom_theme_json" 2>/dev/null || true
      
      # Extract terminal colors as numbered colors
      jq -r '.colors.terminal // empty | 
        (.red // empty | "color1 = \"\(.)\""),
        (.green // empty | "color2 = \"\(.)\""),
        (.yellow // empty | "color3 = \"\(.)\""),
        (.blue // empty | "color4 = \"\(.)\""),
        (.magenta // empty | "color5 = \"\(.)\""),
        (.cyan // empty | "color6 = \"\(.)\"")' "$custom_theme_json" 2>/dev/null || true
      
      # Set some defaults for missing colors
      echo "accent = \"#ff79c6\""
      echo "color10 = \"#50fa7b\""
      echo "color11 = \"#f1fa8c\""
    } > "$STARSHIP_COLORS"
  else
    # Fallback to python if jq not available
    python3 -c "
import json
import sys
try:
    with open('$custom_theme_json', 'r') as f:
        data = json.load(f)
    
    colors = data.get('colors', {})
    
    # Primary colors
    primary = colors.get('primary', {})
    for key, value in primary.items():
        print(f'{key} = \"{value}\"')
    
    # Terminal colors
    terminal = colors.get('terminal', {})
    mapping = {
        'red': 'color1',
        'green': 'color2', 
        'yellow': 'color3',
        'blue': 'color4',
        'magenta': 'color5',
        'cyan': 'color6'
    }
    for term_key, color_key in mapping.items():
        if term_key in terminal:
            print(f'{color_key} = \"{terminal[term_key]}\"')
    
    # Defaults
    print('accent = \"#ff79c6\"')
    print('color10 = \"#50fa7b\"')
    print('color11 = \"#f1fa8c\"')
except:
    pass
" > "$STARSHIP_COLORS" 2>/dev/null || true
  fi
  
  [[ -s "$STARSHIP_COLORS" ]] || return 1
  return 0
}

starship_extract_from_alacritty() {
  local alacritty_toml="$1"
  local background foreground red green yellow blue magenta cyan
  
  # Extract colors from alacritty.toml using regex
  # This is a simple parser that works for the TOML format used by these themes
  
  # Extract primary colors
  background=$(grep -E "^background\s*=" "$alacritty_toml" | head -1 | sed 's/.*= *//' | tr -d "'\"")
  foreground=$(grep -E "^foreground\s*=" "$alacritty_toml" | head -1 | sed 's/.*= *//' | tr -d "'\"")
  
  # Extract normal colors
  red=$(grep -E "^red\s*=" "$alacritty_toml" | head -1 | sed 's/.*= *//' | tr -d "'\"")
  green=$(grep -E "^green\s*=" "$alacritty_toml" | head -1 | sed 's/.*= *//' | tr -d "'\"")
  yellow=$(grep -E "^yellow\s*=" "$alacritty_toml" | head -1 | sed 's/.*= *//' | tr -d "'\"")
  blue=$(grep -E "^blue\s*=" "$alacritty_toml" | head -1 | sed 's/.*= *//' | tr -d "'\"")
  magenta=$(grep -E "^magenta\s*=" "$alacritty_toml" | head -1 | sed 's/.*= *//' | tr -d "'\"")
  cyan=$(grep -E "^cyan\s*=" "$alacritty_toml" | head -1 | sed 's/.*= *//' | tr -d "'\"")
  
  # Generate colors.toml
  {
    [[ -n "$background" ]] && echo "background = \"$background\""
    [[ -n "$foreground" ]] && echo "foreground = \"$foreground\""
    [[ -n "$red" ]] && echo "color1 = \"$red\""
    [[ -n "$green" ]] && echo "color2 = \"$green\""
    [[ -n "$yellow" ]] && echo "color3 = \"$yellow\""
    [[ -n "$blue" ]] && echo "color4 = \"$blue\""
    [[ -n "$magenta" ]] && echo "color5 = \"$magenta\""
    [[ -n "$cyan" ]] && echo "color6 = \"$cyan\""
    
    # Generate accent color (use blue if available, otherwise a default)
    if [[ -n "$blue" ]]; then
      echo "accent = \"$blue\""
    else
      echo "accent = \"#bd93f9\""
    fi
    
    # Generate color10 and color11 (bright versions if available, otherwise defaults)
    if [[ -n "$green" ]]; then
      echo "color10 = \"$green\""
    else
      echo "color10 = \"#50fa7b\""
    fi
    
    if [[ -n "$yellow" ]]; then
      echo "color11 = \"$yellow\""
    else
      echo "color11 = \"#f1fa8c\""
    fi
  } > "$STARSHIP_COLORS"
  
  [[ -s "$STARSHIP_COLORS" ]] || return 1
  return 0
}

starship_generate_colors_from_theme() {
  local theme_name theme_dir custom_theme_json alacritty_toml
  
  # Get current theme name
  theme_name=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null)
  theme_dir="$HOME/.config/omarchy/themes/$theme_name"
  
  # Try custom_theme.json first (highest priority)
  custom_theme_json="$theme_dir/custom_theme.json"
  if [[ -f "$custom_theme_json" ]]; then
    starship_extract_from_custom_theme "$custom_theme_json" || return 1
    return 0
  fi
  
  # Try alacritty.toml second
  alacritty_toml="$theme_dir/alacritty.toml"
  if [[ -f "$alacritty_toml" ]]; then
    starship_extract_from_alacritty "$alacritty_toml" || return 1
    return 0
  fi
  
  # If no theme files found, return failure so fallback colors are used
  return 1
}

starship_powerline_fallback() {
  # Generate a grayscale powerline config with black text
  cat << 'STARSHIP_FALLBACK_EOF' > "$HOME/.config/omarchy/current/theme/starship.toml"
"$schema" = "https://starship.rs/config-schema.json"

command_timeout = 2000
add_newline = false

format = """
[](fg:#404040)\
$os\
$username\
[](fg:#404040 bg:#808080)\
$directory\
[](fg:#808080 bg:#a0a0a0)\
$git_branch\
$git_status\
[](fg:#a0a0a0 bg:#c0c0c0)\
$nodejs\
$python\
$rust\
$golang\
$java\
$php\
$docker_context\
$package\
[](fg:#c0c0c0 bg:#e0e0e0)\
$cmd_duration\
[ ](fg:#e0e0e0)\
$line_break\
$character
"""

[os]
disabled = false
style = "fg:#000000 bg:#404040"

[username]
show_always = true
style_user = "fg:#000000 bg:#404040"
style_root = "fg:#000000 bg:#404040"
format = "[ $user ]($style)"

[directory]
style = "fg:#000000 bg:#808080"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = ".../"
read_only = " 󰌾"
read_only_style = "fg:#000000 bg:#808080"

[git_branch]
symbol = ""
style = "fg:#000000 bg:#a0a0a0"
format = "[ $symbol $branch ]($style)"

[git_status]
style = "fg:#000000 bg:#a0a0a0"
format = "[($all_status$ahead_behind )]($style)"
up_to_date = "✓ "

[nodejs]
symbol = ""
style = "fg:#000000 bg:#c0c0c0"
format = "[ $symbol( $version) ]($style)"

[python]
symbol = ""
style = "fg:#000000 bg:#c0c0c0"
format = "[ $symbol( $version)(\\($virtualenv\\)) ]($style)"

[rust]
symbol = ""
style = "fg:#000000 bg:#c0c0c0"
format = "[ $symbol( $version) ]($style)"

[golang]
symbol = ""
style = "fg:#000000 bg:#c0c0c0"
format = "[ $symbol( $version) ]($style)"

[java]
symbol = ""
style = "fg:#000000 bg:#c0c0c0"
format = "[ $symbol( $version) ]($style)"

[php]
symbol = ""
style = "fg:#000000 bg:#c0c0c0"
format = "[ $symbol( $version) ]($style)"

[docker_context]
symbol = ""
style = "fg:#000000 bg:#c0c0c0"
format = "[ $symbol( $context) ]($style)"

[package]
symbol = "󰏗"
style = "fg:#000000 bg:#c0c0c0"
format = "[ $symbol( $version) ]($style)"

[cmd_duration]
min_time = 500
show_milliseconds = true
style = "fg:#000000 bg:#e0e0e0"
format = "[ 󱎫 $duration ]($style)"

[line_break]
disabled = false

[character]
success_symbol = "[❯](bold fg:#000000)"
error_symbol = "[❯](bold fg:#ff0000)"
vimcmd_symbol = "[❮](bold fg:#000000)"
vimcmd_replace_one_symbol = "[❮](bold fg:#ff0000)"
vimcmd_replace_symbol = "[❮](bold fg:#ff0000)"
vimcmd_visual_symbol = "[❮](bold fg:#808080)"
STARSHIP_FALLBACK_EOF

  STARSHIP_CONFIG="$HOME/.config/omarchy/current/theme/starship.toml" starship print-config >/dev/null 2>&1
}

if ! starship_powerline_render; then
  starship_powerline_fallback || true
fi

# <<< starship-powerline managed block <<<
EOF

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
