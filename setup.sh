#!/usr/bin/env bash
set -Eeuo pipefail

base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

ensure_local_file() {
    local path="$1"

    if [ ! -e "$path" ]; then
        touch "$path"
    fi
}

link_file() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "Skipping existing path: $dest"
        return
    fi

    ln -s "$src" "$dest"
}

backup_file() {
    local path="$1"
    local backup="${path}.old"
    local counter=1

    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="${path}.old.${counter}"
        counter=$((counter + 1))
    done

    mv "$path" "$backup"
}

# emacs stuff

mkdir -p "$HOME/.emacs.d"

ensure_local_file "$HOME/.emacs.d/local.el"

for ifile in "$base"/emacs/*
do
    if [ "$(basename "$ifile")" = "local.el" ]; then
        continue
    fi

    link_file "$ifile" "$HOME/.emacs.d/$(basename "$ifile")"
done


# tmux
link_file "$base/tmux/.tmux.conf" "$HOME/.tmux.conf"
ensure_local_file "$HOME/.tmux.local.conf"

# bashrc
if [ -e "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
    backup_file "$HOME/.bashrc"
fi
link_file "$base/bash/.bashrc" "$HOME/.bashrc"


# Oh-my-posh
# sudo apt install fontconfig
# if [ ! -x ~/.local/bin/oh-my-posh ]; then
#     if [ ! -d ~/.local/bin ]; then
#         mkdir -p ~/.local/bin
#     fi
#     curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin/
# fi

# ln -s ${base}/kali.omp.json .omp.json

mkdir -p "$HOME/.local/share/fonts"
font_file="$HOME/.local/share/fonts/DroidSansMNerdFont-Regular.otf"
if [ ! -f "$font_file" ]; then
    curl -fLo "$font_file" https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf
fi

link_file "$base/bash/.bashrc.aliases" "$HOME/.bashrc.aliases"
link_file "$base/bash/.bashrc.functions" "$HOME/.bashrc.functions"

ensure_local_file "$HOME/.bashrc.local"

# zsh
link_file "$base/zsh/zshrc" "$HOME/.zshrc"
ensure_local_file "$HOME/.zshrc.local"

# ipython
if [ -d ~/.ipython/profile_default/startup/ ]; then
    link_file "$base/ipython/01-ipython.ipy" "$HOME/.ipython/profile_default/startup/01-ipython.ipy"
fi

# matplotlib
if [ -d ~/.config/matplotlib ]; then
    link_file "$base/matplotlibrc" "$HOME/.config/matplotlib/matplotlibrc"
fi
