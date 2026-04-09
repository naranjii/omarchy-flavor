"$schema" = "https://starship.rs/config-schema.json"

command_timeout = 2000
add_newline = false

format = """
[](fg:{{ color1 }})\
$os\
$username\
[](fg:{{ color1 }} bg:{{ color4 }})\
$directory\
[](fg:{{ color4 }} bg:{{ color3 }})\
$git_branch\
$git_status\
[](fg:{{ color3 }} bg:{{ color2 }})\
$nodejs\
$python\
$rust\
$golang\
$java\
$php\
$docker_context\
$package\
[](fg:{{ color2 }} bg:{{ accent }})\
$cmd_duration\
[ ](fg:{{ accent }})\
$line_break\
$character
"""

[os]
disabled = false
style = "fg:{{ background }} bg:{{ color1 }}"

[os.symbols]
Alpine = ""
Amazon = ""
Android = ""
Arch = "󰣇"
Artix = "󰣇"
CentOS = ""
Debian = "󰣚"
Fedora = "󰣛"
Gentoo = "󰣨"
Linux = "󰌽"
Macos = "󰀵"
Manjaro = ""
Mint = "󰣭"
NixOS = ""
openSUSE = ""
Pop = ""
Raspbian = "󰐿"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"
SUSE = ""
Ubuntu = "󰕈"
Unknown = ""
Windows = ""

[username]
show_always = true
style_user = "fg:{{ background }} bg:{{ color1 }}"
style_root = "fg:{{ background }} bg:{{ color1 }}"
format = "[ $user ]($style)"

[directory]
style = "fg:{{ background }} bg:{{ color4 }}"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = ".../"
read_only = " 󰌾"
read_only_style = "fg:{{ background }} bg:{{ color4 }}"

[directory.substitutions]
Documents = "󰈙"
Downloads = ""
Music = "󰝚"
Pictures = ""
Developer = "󰲋"

[git_branch]
symbol = ""
style = "fg:{{ background }} bg:{{ color3 }}"
format = "[ $symbol $branch ]($style)"

[git_status]
style = "fg:{{ background }} bg:{{ color3 }}"
format = "[($all_status$ahead_behind )]($style)"
up_to_date = "✓ "

[nodejs]
symbol = ""
style = "fg:{{ background }} bg:{{ color2 }}"
format = "[ $symbol( $version) ]($style)"

[python]
symbol = ""
style = "fg:{{ background }} bg:{{ color2 }}"
format = "[ $symbol( $version)(\\($virtualenv\\)) ]($style)"

[rust]
symbol = ""
style = "fg:{{ background }} bg:{{ color2 }}"
format = "[ $symbol( $version) ]($style)"

[golang]
symbol = ""
style = "fg:{{ background }} bg:{{ color2 }}"
format = "[ $symbol( $version) ]($style)"

[java]
symbol = ""
style = "fg:{{ background }} bg:{{ color2 }}"
format = "[ $symbol( $version) ]($style)"

[php]
symbol = ""
style = "fg:{{ background }} bg:{{ color2 }}"
format = "[ $symbol( $version) ]($style)"

[docker_context]
symbol = ""
style = "fg:{{ background }} bg:{{ color2 }}"
format = "[ $symbol( $context) ]($style)"

[package]
symbol = "󰏗"
style = "fg:{{ background }} bg:{{ color2 }}"
format = "[ $symbol( $version) ]($style)"

[cmd_duration]
min_time = 500
show_milliseconds = true
style = "fg:{{ background }} bg:{{ accent }}"
format = "[ 󱎫 $duration ]($style)"

[line_break]
disabled = false

[character]
success_symbol = "[❯](bold fg:{{ color10 }})"
error_symbol = "[❯](bold fg:{{ color1 }})"
vimcmd_symbol = "[❮](bold fg:{{ color10 }})"
vimcmd_replace_one_symbol = "[❮](bold fg:{{ color11 }})"
vimcmd_replace_symbol = "[❮](bold fg:{{ color11 }})"
vimcmd_visual_symbol = "[❮](bold fg:{{ color3 }})"
