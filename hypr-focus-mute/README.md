1. Move hypr-focus-mute file to .local/bin/
2. Bind the script to hypr configuration file, e.g.:

lua
`o.bind("SUPER + SHIFT + XF86AudioMute", "Focused window mute", "omarchy-mute-focused-window")`

hyprlang
`bindd = SUPER ALT, XF86AudioMute, Mute Focused Window, exec, omarchy-mute-focused-window`

3. Reload hyprland `hyprctl reload`
