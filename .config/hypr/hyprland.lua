hl.monitor({
  output = "",
  mode = "1366x768",
  position = "auto",
  scale = 1
})

local terminal = "kitty"
local file_manager = "thunar"
local menu = "rofi -modi drun,run -show drun"

local wallpaper_dir = "~/Wallpapers"

hl.on("hyprland.start", function ()
  hl.exec_cmd("udiskie &")
  hl.exec_cmd("fcitx5")
  hl.exec_cmd("waybar")
  hl.exec_cmd("dunst")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("pypr")
  hl.exec_cmd("sleep 10 && swww init")
  hl.exec_cmd("swaybg -i $(find ~/Wallpapers -type f | shuf -n 1) -m fill")
end)

hl.env("XCURSOR_SIZE", "24")

hl.config({
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    touchpad = {
      natural_scroll = true
    },
    sensitivity = 0
  }
})

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 20,
    border_size = 0,
    col = {
      active_border = {
        colors = {
          "rgba(33ccffee)",
          "rgba(00ff99ee)",
        },
        angle = 45
      },
      inactive_border = "rgba(595959aa)"
    },
    layout = "dwindle"
  }
})

hl.config({
  decoration = {
    rounding = 5,
    blur = {
      enabled = true,
      size = 10,
      passes = 2,
      ignore_opacity = true,
      xray = false,
      noise = 0
    },
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = 0xee1a1a1a
    },
    active_opacity = 1.0,
    inactive_opacity = 0.9,
    fullscreen_opacity = 1.0
  }
})

hl.config({
  animations = {
    enabled = true
  },
})

hl.config({
  dwindle = {
    preserve_split = true
  }
})

hl.config({
  misc ={
    disable_hyprland_logo = true
  }
})

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace"
})

local main_mod = "ALT"

hl.bind(main_mod .. " + Return", hl.dsp.exec_cmd(terminal))
local close_window_bind = hl.bind(main_mod .. " + C", hl.dsp.window.close())
-- close_window_bind:set_enabled(false)
hl.bind(main_mod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind(main_mod .. " + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + R", hl.dsp.exec_cmd(menu))
-- hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())
hl.bind(main_mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "left"}))
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "right"}))
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "up"}))
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "down"}))
for i = 1, 10 do
  local key = i % 10
  hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(main_mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(main_mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind(main_mod .. " + P", hl.dsp.exec_cmd('grim -g "$(slurp)"'))
hl.bind(main_mod .. " + SHIFT + P", hl.dsp.exec_cmd("grim"))
hl.bind(main_mod .. " + B", hl.dsp.exec_cmd("killall swaybg; swaybg -i $(find ~/Wallpapers -type f | shuf -n 1) -m fill"))
hl.bind(main_mod .. " + A", hl.dsp.exec_cmd("pypr toggle term"))
local dropterm = "^(kitty-dropterm)$"
hl.window_rule({
  name = "dropterm",
  match = {
    class = dropterm,
  },
  float = true,
  workspace = "special silent",
  size = "75% 60%"
})
