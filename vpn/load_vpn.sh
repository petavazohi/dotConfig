#!/usr/bin/env bash
set -euo pipefail

OPENVPN_CONFIG_DIR="${OPENVPN_CONFIG_DIR:-${OPENVPN_DIR:-/etc/openvpn}}"
OPENVPN_CREDENTIALS_FILE="${OPENVPN_CREDENTIALS_FILE:-${OPENVPN_CREDS:-$HOME/.openvpn-credentials}}"

usage() {
    cat <<'EOF'
Usage:
  load_vpn.sh <udp|tcp> <country> <city>
  load_vpn.sh --list-countries <udp|tcp>
  load_vpn.sh --list-cities <udp|tcp> <country>
  load_vpn.sh --list-files <udp|tcp>
  load_vpn.sh --dry-run <udp|tcp> <country> <city>
  load_vpn.sh -h|--help

Examples:
  load_vpn.sh udp US "New York"
  load_vpn.sh tcp uk london
  load_vpn.sh udp de berlin
  load_vpn.sh --list-cities udp US

Notes:
  - VPN configs are read from /etc/openvpn/udp and /etc/openvpn/tcp by default.
  - IPv6 is disabled while OpenVPN runs if it is currently enabled, then
    restored when OpenVPN exits.
  - Country matching is case-insensitive. "us" and "US" both work.
  - City matching ignores case, spaces, hyphens, punctuation, and a trailing
    " - Virtual" marker in the .ovpn filename.
  - The city may be passed as multiple words without quotes:
      load_vpn.sh udp US New York
  - Credentials default to ~/.openvpn-credentials.

Environment:
  OPENVPN_CONFIG_DIR          Override the OpenVPN base directory.
                              Default: /etc/openvpn
  OPENVPN_CREDENTIALS_FILE    Override the credentials file.
                              Default: ~/.openvpn-credentials

Compatibility environment variables:
  OPENVPN_DIR                 Alias for OPENVPN_CONFIG_DIR.
  OPENVPN_CREDS               Alias for OPENVPN_CREDENTIALS_FILE.
EOF
}

die() {
    printf 'load_vpn.sh: %s\n' "$*" >&2
    exit 1
}

protocol_dir() {
    local protocol="$1"
    case "${protocol,,}" in
        udp|tcp) printf '%s/%s\n' "$OPENVPN_CONFIG_DIR" "${protocol,,}" ;;
        *) die "protocol must be 'udp' or 'tcp'" ;;
    esac
}

file_parts() {
    local file="$1"
    local name country city proto

    name="$(basename -- "$file")"
    [[ "$name" == NCVPN-*-*.ovpn ]] || return 1

    name="${name%.ovpn}"
    proto="${name##*-}"
    name="${name%-"$proto"}"
    name="${name#NCVPN-}"
    country="${name%%-*}"
    city="${name#"$country"-}"
    city="${city% - Virtual}"

    [[ -n "$country" && -n "$city" && -n "$proto" ]] || return 1
    printf '%s\t%s\t%s\t%s\n' "$country" "$city" "${proto,,}" "$file"
}

normalized() {
    local value="${1,,}"
    value="${value% - virtual}"
    value="${value//[^[:alnum:]]/}"
    printf '%s\n' "$value"
}

sysctl_value() {
    sysctl -n "$1" 2>/dev/null
}

disable_ipv6_if_enabled() {
    IPV6_PREV_ALL="$(sysctl_value net.ipv6.conf.all.disable_ipv6)" || die "could not read IPv6 sysctl state"
    IPV6_PREV_DEFAULT="$(sysctl_value net.ipv6.conf.default.disable_ipv6)" || die "could not read IPv6 sysctl state"

    case "$IPV6_PREV_ALL:$IPV6_PREV_DEFAULT" in
        0:*|*:0)
            IPV6_CHANGED=1
            printf 'Disabling IPv6 while VPN is active.\n' >&2
            sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
            sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null
            ;;
        1:1)
            IPV6_CHANGED=0
            ;;
        *)
            die "unexpected IPv6 sysctl state: all=$IPV6_PREV_ALL default=$IPV6_PREV_DEFAULT"
            ;;
    esac
}

restore_ipv6_if_needed() {
    if [[ "${IPV6_CHANGED:-0}" != 1 ]]; then
        return
    fi

    printf 'Restoring IPv6.\n' >&2
    sudo sysctl -w "net.ipv6.conf.default.disable_ipv6=$IPV6_PREV_DEFAULT" >/dev/null || true
    sudo sysctl -w "net.ipv6.conf.all.disable_ipv6=$IPV6_PREV_ALL" >/dev/null || true
}

list_files() {
    local dir
    dir="$(protocol_dir "$1")"
    [[ -d "$dir" ]] || die "directory not found: $dir"
    find "$dir" -maxdepth 1 -type f -name '*.ovpn' -print | sort
}

list_countries() {
    local file
    while IFS= read -r file; do
        file_parts "$file" | awk -F '\t' '{print $1}'
    done < <(list_files "$1") | sort -u
}

list_cities() {
    local protocol="$1"
    local wanted_country="${2^^}"
    local file country city proto path

    while IFS= read -r file; do
        IFS=$'\t' read -r country city proto path < <(file_parts "$file") || continue
        [[ "${country^^}" == "$wanted_country" ]] || continue
        printf '%s\n' "$city"
    done < <(list_files "$protocol") | sort -u
}

find_config() {
    local protocol="$1"
    local wanted_country="${2^^}"
    local wanted_city_norm
    local file country city proto path city_norm
    local -a matches=()

    wanted_city_norm="$(normalized "$3")"

    while IFS= read -r file; do
        IFS=$'\t' read -r country city proto path < <(file_parts "$file") || continue
        [[ "${country^^}" == "$wanted_country" ]] || continue
        city_norm="$(normalized "$city")"
        [[ "$city_norm" == "$wanted_city_norm" ]] || continue
        matches+=("$path")
    done < <(list_files "$protocol")

    case "${#matches[@]}" in
        0)
            printf 'No matching VPN config for %s %s %s.\n' "$protocol" "$wanted_country" "$3" >&2
            printf 'Available cities for %s %s:\n' "$protocol" "$wanted_country" >&2
            list_cities "$protocol" "$wanted_country" >&2 || true
            exit 1
            ;;
        1)
            printf '%s\n' "${matches[0]}"
            ;;
        *)
            printf 'Multiple matches found:\n' >&2
            printf '  %s\n' "${matches[@]}" >&2
            exit 1
            ;;
    esac
}

main() {
    local dry_run=0
    local protocol country city config exit_status

    case "${1:-}" in
        -h|--help|'')
            usage
            exit 0
            ;;
        --list-files)
            [[ $# -eq 2 ]] || die "usage: load_vpn.sh --list-files <udp|tcp>"
            list_files "$2"
            exit 0
            ;;
        --list-countries)
            [[ $# -eq 2 ]] || die "usage: load_vpn.sh --list-countries <udp|tcp>"
            list_countries "$2"
            exit 0
            ;;
        --list-cities)
            [[ $# -eq 3 ]] || die "usage: load_vpn.sh --list-cities <udp|tcp> <country>"
            list_cities "$2" "$3"
            exit 0
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
    esac

    [[ $# -ge 3 ]] || die "usage: load_vpn.sh <udp|tcp> <country> <city>"

    protocol="${1,,}"
    country="$2"
    shift 2
    city="$*"

    [[ -r "$OPENVPN_CREDENTIALS_FILE" ]] || die "credentials file not readable: $OPENVPN_CREDENTIALS_FILE"

    config="$(find_config "$protocol" "$country" "$city")"

    if (( dry_run )); then
        local ipv6_dry_run_state
        ipv6_dry_run_state="$(sysctl_value net.ipv6.conf.all.disable_ipv6):$(sysctl_value net.ipv6.conf.default.disable_ipv6)"

        if [[ "$ipv6_dry_run_state" != "1:1" ]]; then
            printf 'sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1\n'
            printf 'sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1\n'
        fi
        printf 'sudo openvpn --config %q --auth-user-pass %q\n' "$config" "$OPENVPN_CREDENTIALS_FILE"
        if [[ "$ipv6_dry_run_state" != "1:1" ]]; then
            printf 'sudo sysctl -w net.ipv6.conf.default.disable_ipv6=<previous-value>\n'
            printf 'sudo sysctl -w net.ipv6.conf.all.disable_ipv6=<previous-value>\n'
        fi
        exit 0
    fi

    trap restore_ipv6_if_needed EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    disable_ipv6_if_enabled

    printf 'Starting OpenVPN with config: %s\n' "$config" >&2
    set +e
    sudo openvpn --config "$config" --auth-user-pass "$OPENVPN_CREDENTIALS_FILE"
    exit_status=$?
    set -e
    exit "$exit_status"
}

main "$@"
