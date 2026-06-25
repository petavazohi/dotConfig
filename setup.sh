#!/usr/bin/env bash
set -Eeuo pipefail

base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

dry_run=0
force=0
network=1
with_fonts=0
refresh_zsh_completion_cache=0

usage() {
    cat <<'EOF'
Usage:
  ./setup.sh [options]

Options:
  --dry-run                      Print intended actions without changing files.
  --force                        Back up existing files before replacing them.
  --no-network                   Do not perform network actions.
  --with-fonts                   Install the configured Nerd Font if missing.
  --refresh-zsh-completion-cache Remove ~/.cache/zcompdump* after installing completions.
  -h, --help                     Show this help.

Defaults:
  - Existing files are skipped unless --force is used.
  - Network-dependent setup is skipped unless explicitly requested.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) dry_run=1 ;;
        --force) force=1 ;;
        --no-network) network=0 ;;
        --with-fonts) with_fonts=1 ;;
        --refresh-zsh-completion-cache) refresh_zsh_completion_cache=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

status() {
    if [ "$1" = "section" ]; then
        printf '\n== %s ==\n' "$2"
        return
    fi

    printf '%-10s %s\n' "$1" "$2"
}

run() {
    if [ "$dry_run" -eq 1 ]; then
        printf 'would run  '
        printf '%q ' "$@"
        printf '\n'
        return
    fi

    "$@"
}

require_cmd() {
    local cmd="$1"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required command: $cmd" >&2
        exit 1
    fi
}

check_dependencies() {
    require_cmd basename
    require_cmd cmp
    require_cmd dirname
    require_cmd install
    require_cmd ln
    require_cmd mkdir
    require_cmd mv
    require_cmd readlink
    require_cmd touch

    if [ "$with_fonts" -eq 1 ]; then
        require_cmd curl
    fi

    if ! command -v zsh >/dev/null 2>&1; then
        status "warn" "zsh not found; zsh config will still be installed"
    fi
}

ensure_dir() {
    local path="$1"

    if [ -d "$path" ]; then
        status "ok" "$path"
        return
    fi

    status "mkdir" "$path"
    run mkdir -p "$path"
}

ensure_local_file() {
    local path="$1"

    if [ -e "$path" ]; then
        status "ok" "$path"
        return
    fi

    status "touch" "$path"
    run mkdir -p "$(dirname "$path")"
    run touch "$path"
}

backup_path() {
    local path="$1"
    local backup="${path}.old"
    local counter=1

    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="${path}.old.${counter}"
        counter=$((counter + 1))
    done

    status "backup" "$path -> $backup"
    run mv "$path" "$backup"
}

link_file() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        status "ok" "$dest -> $src"
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$force" -eq 0 ]; then
            status "skip" "$dest exists; use --force to replace"
            return
        fi

        backup_path "$dest"
    fi

    status "link" "$dest -> $src"
    run ln -s "$src" "$dest"
}

install_file() {
    local src="$1"
    local dest="$2"
    local mode="$3"

    if [ ! -d "$(dirname "$dest")" ]; then
        status "mkdir" "$(dirname "$dest")"
        run mkdir -p "$(dirname "$dest")"
    fi

    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        status "ok" "$dest"
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        status "update" "$dest"
    else
        status "install" "$dest"
    fi

    run install -m "$mode" "$src" "$dest"
}

install_emacs() {
    local ifile

    status "section" "emacs"
    ensure_dir "$HOME/.emacs.d"
    ensure_local_file "$HOME/.emacs.d/local.el"

    for ifile in "$base"/emacs/*; do
        if [ "$(basename "$ifile")" = "local.el" ]; then
            continue
        fi

        link_file "$ifile" "$HOME/.emacs.d/$(basename "$ifile")"
    done
}

install_tmux() {
    status "section" "tmux"
    link_file "$base/tmux/.tmux.conf" "$HOME/.tmux.conf"
    ensure_local_file "$HOME/.tmux.local.conf"
}

install_shells() {
    status "section" "shells"
    link_file "$base/bash/.bashrc" "$HOME/.bashrc"
    link_file "$base/bash/.bashrc.aliases" "$HOME/.bashrc.aliases"
    link_file "$base/bash/.bashrc.functions" "$HOME/.bashrc.functions"
    ensure_local_file "$HOME/.bashrc.local"

    link_file "$base/zsh/zshrc" "$HOME/.zshrc"
    ensure_local_file "$HOME/.zshrc.local"
}

install_vpn() {
    status "section" "vpn"
    ensure_dir "$HOME/.local/bin"
    ensure_dir "$HOME/.local/share/zsh/site-functions"
    link_file "$base/vpn/load_vpn.sh" "$HOME/.local/bin/load_vpn.sh"
    link_file "$base/vpn/_load_vpn" "$HOME/.local/share/zsh/site-functions/_load_vpn"
}

install_fonts() {
    local font_file="$HOME/.local/share/fonts/DroidSansMNerdFont-Regular.otf"
    local font_url="https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf"

    status "section" "fonts"

    if [ "$with_fonts" -eq 0 ]; then
        status "skip" "font install disabled; use --with-fonts"
        return
    fi

    if [ "$network" -eq 0 ]; then
        echo "--with-fonts cannot be used with --no-network" >&2
        exit 1
    fi

    ensure_dir "$HOME/.local/share/fonts"

    if [ -f "$font_file" ]; then
        status "ok" "$font_file"
        return
    fi

    status "download" "$font_file"
    run curl -fLo "$font_file" "$font_url"
}

install_ipython() {
    status "section" "ipython"

    if [ -d "$HOME/.ipython/profile_default/startup" ]; then
        link_file "$base/ipython/01-ipython.ipy" "$HOME/.ipython/profile_default/startup/01-ipython.ipy"
    else
        status "skip" "$HOME/.ipython/profile_default/startup missing"
    fi
}

install_matplotlib() {
    status "section" "matplotlib"

    if [ -d "$HOME/.config/matplotlib" ]; then
        link_file "$base/matplotlibrc" "$HOME/.config/matplotlib/matplotlibrc"
    else
        status "skip" "$HOME/.config/matplotlib missing"
    fi
}

refresh_completion_cache() {
    status "section" "zsh completion cache"

    if [ "$refresh_zsh_completion_cache" -eq 0 ]; then
        status "skip" "cache refresh disabled; use --refresh-zsh-completion-cache"
        return
    fi

    status "remove" "$HOME/.cache/zcompdump*"
    if [ "$dry_run" -eq 1 ]; then
        printf 'would run  rm -f %q\n' "$HOME/.cache/zcompdump*"
    else
        rm -f "$HOME"/.cache/zcompdump*
    fi
}

main() {
    check_dependencies
    install_emacs
    install_tmux
    install_shells
    install_vpn
    install_fonts
    install_ipython
    install_matplotlib
    refresh_completion_cache
}

main "$@"
