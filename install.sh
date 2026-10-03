#!/bin/sh
# install.sh — set up this desktop on a fresh Arch Linux install (also safe to re-run).
#
# Run it as your normal user (not root) from a text console:
#     git clone https://github.com/litework/dotfiles ~/dotfiles && ~/dotfiles/install.sh
# then reboot. It installs everything, links the configs into your home folder, and
# sets the computer to log you straight into the desktop.
set -eu
cd "$(dirname "$0")"
DOT=$(pwd)

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
note() { printf '\033[1;33m    %s\033[0m\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as your normal user, not as root (it uses sudo when it needs to)."; exit 1
fi
say "Checking sudo (you may be asked for your password)"
sudo -v

# ---------------------------------------------------------------------------- packages
PKGS="git base-devel rust stow curl
swaybg swayidle swaylock xorg-xwayland xdg-desktop-portal-wlr xdg-desktop-portal-gtk
waybar fuzzel mako foot grim slurp wl-clipboard brightnessctl libnotify wtype cliphist wlsunset
gtklock xsettingsd gnome-themes-extra capitaine-cursors papirus-icon-theme archlinux-wallpaper xdg-user-dirs
ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono adwaita-fonts noto-fonts noto-fonts-emoji
gtk4 gtk4-layer-shell libadwaita python-gobject playerctl
pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol bluez bluez-utils
networkmanager nm-connection-editor tlp pacman-contrib reflector
lightdm lightdm-gtk-greeter
zsh zsh-autosuggestions zsh-syntax-highlighting starship fzf zoxide eza bat ripgrep fd fastfetch cmatrix
neovim tree-sitter-cli yazi thunar mpd mpc mpd-mpris ncmpcpp mpv
code qbittorrent piper"
STOW="appearance bin edge foot fuzzel gtk gtklock location mako mpd mpv nvim profile quickpanel starship sway thunar wallust waybar zsh"

say "Installing packages (this takes a while the first time)"
# shellcheck disable=SC2086
sudo pacman -Syu --needed --noconfirm $PKGS

# ---------------------------------------------------------------------------- AUR
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

if ! command -v yay >/dev/null; then
    say "Installing yay (helper for the Arch User Repository)"
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build/yay-bin"
    (cd "$build/yay-bin" && makepkg -si --noconfirm)
fi

fx=on
if ! pacman -Q swayfx >/dev/null 2>&1; then
    say "Building SwayFX (sway with blur, rounded corners and shadows)"
    if (cd "$build" && yay -G swayfx >/dev/null && cd swayfx &&
        { pacman -Si scenefx0.5 >/dev/null 2>&1 || sed -i 's/"scenefx0.5"/"scenefx>=0.5"/' PKGBUILD; } &&
        makepkg -s --noconfirm && sudo pacman -U --noconfirm --ask=4 ./swayfx-*-x86_64.pkg.tar.zst); then
        :
    else
        note "SwayFX didn't build; installing plain sway instead (no blur/rounded corners)."
        sudo pacman -S --needed --noconfirm sway
        fx=off
    fi
fi

say "Installing Microsoft Edge"
yay -S --needed --noconfirm microsoft-edge-stable-bin || note "Edge didn't install; you can retry later with: yay -S microsoft-edge-stable-bin"

if ! command -v wallust >/dev/null && [ ! -x "$HOME/.cargo/bin/wallust" ]; then
    say "Installing wallust (colours from your wallpaper)"
    cargo install --locked wallust
fi

# PragmataPro is a paid font, so it can't be downloaded here. If you have a package for it
# (otf-pragmata*.pkg.tar.*) next to this script or in your home folder, it gets installed.
font_pkg=$(ls "$DOT"/otf-pragmata*.pkg.tar.* "$HOME"/otf-pragmata*.pkg.tar.* 2>/dev/null | head -1 || true)
if [ -n "$font_pkg" ]; then
    say "Installing PragmataPro font"
    sudo pacman -U --needed --noconfirm "$font_pkg"
elif ! fc-list | grep -qi pragmata; then
    note "PragmataPro font not found; a free monospace font will be used instead."
fi

# ---------------------------------------------------------------------------- configs
say "Linking configs into your home folder"
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
for pkg in $STOW; do
    (cd "$pkg" && find . -type f -o -type l) | while read -r f; do
        target="$HOME/${f#./}"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$backup/$(dirname "${f#./}")"
            mv "$target" "$backup/${f#./}"
            echo "    backed up $target"
        fi
    done
done
mkdir -p "$HOME/Music" "$HOME/.local/share/mpd/playlists" "$HOME/.local/state/mpd"
# shellcheck disable=SC2086
stow --no-folding --restow -t "$HOME" $STOW
xdg-user-dirs-update

if [ "$fx" = off ]; then
    sed -i 's|^include ~/.config/sway/fx.conf$|# include ~/.config/sway/fx.conf  (SwayFX only)|' "$DOT/sway/.config/sway/config"
fi

if [ ! -e "$HOME/.local/state/wallpaper" ]; then
    say "Setting a first wallpaper and generating colours"
    mkdir -p "$HOME/.local/state"
    ln -sfn /usr/share/backgrounds/archlinux/archwave.png "$HOME/.local/state/wallpaper"
    "$HOME/.cargo/bin/wallust" run -q -s "$HOME/.local/state/wallpaper"
fi

# ---------------------------------------------------------------------------- system
say "System settings: power saving, mirrors, services"
sudo install -Dm644 system/etc/tlp.d/10-local.conf /etc/tlp.d/10-local.conf
sudo install -Dm644 system/etc/xdg/reflector/reflector.conf /etc/xdg/reflector/reflector.conf
sudo systemctl enable bluetooth.service tlp.service paccache.timer reflector.timer
sudo systemctl enable --force lightdm.service   # replaces any other login screen
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Don't fight another network manager: only enable NetworkManager if nothing else is set up.
other=""
for unit in systemd-networkd.service iwd.service dhcpcd.service netctl.service; do
    systemctl is-enabled "$unit" >/dev/null 2>&1 && other="$other $unit"
done
if [ -z "$other" ]; then
    sudo systemctl enable NetworkManager.service
elif ! systemctl is-enabled NetworkManager.service >/dev/null 2>&1; then
    note "Your network is managed by:$other — left as is. The Wi-Fi menu needs NetworkManager;"
    note "to switch later: sudo systemctl disable$other && sudo systemctl enable NetworkManager"
fi

systemctl --user enable pipewire-pulse.socket wireplumber.service mpd.service mpd-mpris.service appearance.timer ||
    note "Couldn't enable user services now; re-run this script after logging in to finish."

say "Logging in automatically to the desktop (LightDM)"
sudo groupadd -rf autologin
sudo gpasswd -a "$USER" autologin >/dev/null
conf=/etc/lightdm/lightdm.conf
[ -e "$conf.orig" ] || sudo cp "$conf" "$conf.orig"
sudo sed -i \
    -e "s/^#\{0,1\}autologin-user=.*/autologin-user=$USER/" \
    -e "s/^#\{0,1\}autologin-user-timeout=.*/autologin-user-timeout=0/" \
    -e "s/^#\{0,1\}autologin-session=.*/autologin-session=sway/" \
    "$conf"

case "$(getent passwd "$USER" | cut -d: -f7)" in
    */zsh) ;;
    *) say "Making zsh your shell"; sudo chsh -s /usr/bin/zsh "$USER" ;;
esac

say "All done! Restart the computer to start the desktop:  sudo reboot"
note "Change your city for weather and night light in ~/.config/location.conf"
