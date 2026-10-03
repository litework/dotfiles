#!/bin/sh
# install.sh — install packages and symlink configs into $HOME with GNU Stow.
# Existing files that would conflict are moved to ~/.dotfiles-backup/<timestamp>/.
set -eu
cd "$(dirname "$0")"

PKGS="sway swaybg swayidle swaylock xorg-xwayland xdg-desktop-portal-wlr xdg-desktop-portal-gtk
waybar fuzzel mako foot ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono grim slurp wl-clipboard brightnessctl libnotify
pipewire pipewire-pulse pipewire-alsa wireplumber blueman pavucontrol
zsh zsh-autosuggestions zsh-syntax-highlighting starship fzf zoxide eza bat ripgrep fd
neovim tree-sitter-cli yazi mpd mpc ncmpcpp mpv stow rust"
STOW="bin chrome foot fuzzel mako mpd mpv nvim profile starship sway wallust waybar zsh"

sudo pacman -S --needed $PKGS
command -v wallust >/dev/null || [ -x "$HOME/.cargo/bin/wallust" ] || cargo install --locked wallust

backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
for pkg in $STOW; do
    (cd "$pkg" && find . -type f -o -type l) | while read -r f; do
        target="$HOME/${f#./}"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$backup/$(dirname "${f#./}")"
            mv "$target" "$backup/${f#./}"
            echo "backed up $target"
        fi
    done
done

mkdir -p "$HOME/Music" "$HOME/.local/share/mpd/playlists" "$HOME/.local/state/mpd"
stow --no-folding --restow -t "$HOME" $STOW
systemctl --user enable --now pipewire-pulse.socket wireplumber.service mpd.service

echo "Done. Set a wallpaper with: wallpaper <image>"
