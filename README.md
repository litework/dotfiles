# dotfiles

![Demo: Start menu and search, calculator, Quick settings, light/dark mode, volume pop-up, calendar and weather](docs/demo.gif)

Arch Linux + Sway (Wayland). Colors are generated from the wallpaper with [wallust](https://codeberg.org/explosion-mental/wallust).
The previous bspwm/X11 setup lives in [litework/dotfiles-archive](https://github.com/litework/dotfiles-archive).

| Role         | Program                                   | Replaced                 |
|--------------|-------------------------------------------|--------------------------|
| Compositor   | `swayfx` (sway + blur, rounded corners, shadows; AUR) with `swayidle`, `gtklock`, `swaybg` | `bspwm` + `sxhkd`, `compton` |
| Taskbar      | `waybar`, Windows 11 layout: workspaces · Start + open windows · tray, status icons, clock | `polybar` / `lemonbar`   |
| Launcher     | `fuzzel`                                  | `rofi`                   |
| Notifications| `mako`                                    | —                        |
| Terminal     | `foot` (server + `footclient`)            | `urxvt` / `urxvtd`       |
| Shell        | `zsh` + `starship`, `fzf`, `zoxide`, `eza` | `powerlevel9k`           |
| Editor       | `neovim` (Lua, `vim.pack`, LSP, Treesitter) | `vim` + vim-plug         |
| Colors       | `wallust`                                 | `pywal`                  |
| Files        | `yazi`                                    | `ranger`                 |
| Music        | `mpd` + `ncmpcpp`                         | —                        |
| Network      | NetworkManager                             | dhcpcd + wpa_supplicant  |
| Shell UI     | `quick-panel` (GTK4 + layer-shell): Start menu, Quick settings, Wi-Fi/Bluetooth/Sound/Night light pages, Settings, calendar; Bluetooth pairing agent | blueman, rofi menus |
| Icons        | Papirus (apps, taskbar, menus)               | Adwaita                  |
| Light/dark   | `appearance`: auto by sunrise/sunset, or manual; gsettings + `xsettingsd` | always dark |
| Audio        | PipeWire (`wireplumber`, `wpctl`)          | PulseAudio               |
| Screenshots  | `grim` + `slurp`                          | `scrot`                  |

## Install

```sh
git clone https://github.com/litework/dotfiles ~/dotfiles
~/dotfiles/install.sh
wallpaper ~/path/to/image.jpg
```

Font: [PragmataPro](https://fsd.it/shop/fonts/pragmatapro/) (commercial, not in the repos) — install your own copy, e.g. a locally built `otf-pragmata` package. Icons fall back to `Symbols Nerd Font`.

Each top-level directory is a [GNU Stow](https://www.gnu.org/software/stow/) package mirroring `$HOME`.
`install.sh` installs packages, backs up conflicting files to `~/.dotfiles-backup/`, and links everything with `stow --no-folding`.

## Maintenance

- SwayFX comes from the AUR (`yay -S swayfx`). If it misbehaves, `swayfx-revert` reinstalls plain sway from the package cache and disables `fx.conf`.

- `wallust` comes from crates.io (the AUR package's checksum is broken); update it with `cargo install --locked wallust`.
- Neovim plugins are pinned in `nvim/.config/nvim/nvim-pack-lock.json`; update with `:lua vim.pack.update()` and commit the lockfile.
- `paccache.timer` trims the package cache and `reflector.timer` refreshes mirrors weekly; TLP handles power saving.

## Keys

`Super` is the modifier. Bindings follow the old sxhkd layout.

| Keys | Action |
|------|--------|
| `Super+Return` / `Super+Space` | terminal / Start menu |
| `Super+h/j/k/l` (`+Shift`) | focus (move) window |
| `Super+1…0` (`+Shift`) | workspace (move window to it) |
| `Super+;` / `Super+'` / `Super+Tab` | prev / next / last workspace |
| `Super+Ctrl+h/j/k/l` | split direction for next window |
| `Super+Alt+h/j/k/l` (`+Shift`) | grow (shrink) window |
| `Super+w` / `Super+m` / `Super+s` / `Super+f` | close / tabbed / float / fullscreen |
| `Super+-` / `Super+=` | shrink / grow gaps |
| `Super+F1` | scratchpad terminal |
| `Super+F2…F10` | yazi, thunar, edge, ncmpcpp, spotify, weechat, gimp, pavucontrol, qbittorrent |
| `Print` / `Shift+Print` | screenshot area / full screen |
| `Super+x` / `Super+Shift+Esc` | power menu / lock |
| `Super+v` | clipboard history |
| `Super+Esc` / `Super+Alt+Esc` | reload / exit sway |
