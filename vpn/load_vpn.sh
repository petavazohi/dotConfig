#!/usr/bin/env bash
set -euo pipefail

OPENVPN_CONFIG_DIR="${OPENVPN_CONFIG_DIR:-${OPENVPN_DIR:-/etc/openvpn}}"
OPENVPN_CREDENTIALS_FILE="${OPENVPN_CREDENTIALS_FILE:-${OPENVPN_CREDS:-$HOME/.openvpn-credentials}}"

usage() {
    cat <<'EOF'
Usage:
  load_vpn.sh [--mssfix <value>] <udp|tcp> <country> <city>
  load_vpn.sh --list-countries <udp|tcp>
  load_vpn.sh --list-cities <udp|tcp> <country>
  load_vpn.sh --list-files <udp|tcp>
  load_vpn.sh --dry-run [--mssfix <value>] <udp|tcp> <country> <city>
  load_vpn.sh -h|--help

Examples:
  load_vpn.sh udp "United States" "New York"
  load_vpn.sh --mssfix 1380 udp "United States" "New York"
  load_vpn.sh tcp "United Kingdom" london
  load_vpn.sh udp Germany berlin
  load_vpn.sh --list-cities udp "United States"

Notes:
  - VPN configs are read from /etc/openvpn/udp and /etc/openvpn/tcp by default.
  - IPv6 is disabled while OpenVPN runs if it is currently enabled, then
    restored when OpenVPN exits.
  - Country matching is case-insensitive. Full names and two-letter codes work.
  - City matching ignores case, spaces, hyphens, punctuation, and a trailing
    " - Virtual" marker in the .ovpn filename.
  - The country and city may be passed as multiple words without quotes:
      load_vpn.sh udp United States New York
  - Credentials default to ~/.openvpn-credentials.
  - UDP connections pass --mssfix 1400 to OpenVPN by default. TCP connections
    do not pass --mssfix unless --mssfix is provided.

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

init_country_maps() {
    if [[ "${COUNTRY_MAP_INITIALIZED:-0}" == 1 ]]; then
        return
    fi

    declare -gA COUNTRY_BY_NAME=(
        [andorra]=AD [unitedarabemirates]=AE [albania]=AL [armenia]=AM
        [argentina]=AR [austria]=AT [australia]=AU [azerbaijan]=AZ
        [bosniaandherzegovina]=BA [bangladesh]=BD [belgium]=BE [bulgaria]=BG
        [bermuda]=BM [brunei]=BN [bolivia]=BO [brazil]=BR [bahamas]=BS
        [bhutan]=BT [belize]=BZ [canada]=CA [switzerland]=CH [chile]=CL
        [colombia]=CO [costarica]=CR [cyprus]=CY [czechrepublic]=CZ
        [czechia]=CZ [germany]=DE [denmark]=DK [dominicanrepublic]=DO
        [algeria]=DZ [ecuador]=EC [estonia]=EE [egypt]=EG [spain]=ES
        [finland]=FI [france]=FR [georgia]=GE [ghana]=GH [greece]=GR
        [guatemala]=GT [hongkong]=HK [honduras]=HN [croatia]=HR [haiti]=HT
        [hungary]=HU [indonesia]=ID [ireland]=IE [israel]=IL [isleofman]=IM
        [india]=IN [iceland]=IS [italy]=IT [jersey]=JE [jamaica]=JM
        [jordan]=JO [japan]=JP [kenya]=KE [cambodia]=KH [southkorea]=KR
        [korea]=KR [caymanislands]=KY [kazakhstan]=KZ [laos]=LA [lebanon]=LB
        [liechtenstein]=LI [srilanka]=LK [lithuania]=LT [luxembourg]=LU
        [latvia]=LV [morocco]=MA [monaco]=MC [moldova]=MD [montenegro]=ME
        [northmacedonia]=MK [myanmar]=MM [mongolia]=MN [macau]=MO [macao]=MO
        [malta]=MT [mexico]=MX [malaysia]=MY [nigeria]=NG [nicaragua]=NI
        [netherlands]=NL [norway]=NO [nepal]=NP [newzealand]=NZ [panama]=PA
        [peru]=PE [papuanewguinea]=PG [philippines]=PH [pakistan]=PK
        [poland]=PL [puertorico]=PR [portugal]=PT [paraguay]=PY [romania]=RO
        [serbia]=RS [saudiarabia]=SA [sweden]=SE [singapore]=SG [slovenia]=SI
        [slovakia]=SK [thailand]=TH [turkey]=TR [trinidadandtobago]=TT
        [taiwan]=TW [ukraine]=UA [unitedkingdom]=UK [greatbritain]=UK
        [britain]=UK [england]=UK [unitedstates]=US [unitedstatesofamerica]=US
        [usa]=US [venezuela]=VE [vietnam]=VN [southafrica]=ZA
    )

    declare -gA COUNTRY_NAME_BY_CODE=(
        [AD]="Andorra" [AE]="United Arab Emirates" [AL]="Albania" [AM]="Armenia"
        [AR]="Argentina" [AT]="Austria" [AU]="Australia" [AZ]="Azerbaijan"
        [BA]="Bosnia and Herzegovina" [BD]="Bangladesh" [BE]="Belgium" [BG]="Bulgaria"
        [BM]="Bermuda" [BN]="Brunei" [BO]="Bolivia" [BR]="Brazil" [BS]="Bahamas"
        [BT]="Bhutan" [BZ]="Belize" [CA]="Canada" [CH]="Switzerland" [CL]="Chile"
        [CO]="Colombia" [CR]="Costa Rica" [CY]="Cyprus" [CZ]="Czechia" [DE]="Germany"
        [DK]="Denmark" [DO]="Dominican Republic" [DZ]="Algeria" [EC]="Ecuador"
        [EE]="Estonia" [EG]="Egypt" [ES]="Spain" [FI]="Finland" [FR]="France"
        [GE]="Georgia" [GH]="Ghana" [GR]="Greece" [GT]="Guatemala" [HK]="Hong Kong"
        [HN]="Honduras" [HR]="Croatia" [HT]="Haiti" [HU]="Hungary" [ID]="Indonesia"
        [IE]="Ireland" [IL]="Israel" [IM]="Isle of Man" [IN]="India" [IS]="Iceland"
        [IT]="Italy" [JE]="Jersey" [JM]="Jamaica" [JO]="Jordan" [JP]="Japan"
        [KE]="Kenya" [KH]="Cambodia" [KR]="South Korea" [KY]="Cayman Islands"
        [KZ]="Kazakhstan" [LA]="Laos" [LB]="Lebanon" [LI]="Liechtenstein"
        [LK]="Sri Lanka" [LT]="Lithuania" [LU]="Luxembourg" [LV]="Latvia"
        [MA]="Morocco" [MC]="Monaco" [MD]="Moldova" [ME]="Montenegro"
        [MK]="North Macedonia" [MM]="Myanmar" [MN]="Mongolia" [MO]="Macau"
        [MT]="Malta" [MX]="Mexico" [MY]="Malaysia" [NG]="Nigeria" [NI]="Nicaragua"
        [NL]="Netherlands" [NO]="Norway" [NP]="Nepal" [NZ]="New Zealand"
        [PA]="Panama" [PE]="Peru" [PG]="Papua New Guinea" [PH]="Philippines"
        [PK]="Pakistan" [PL]="Poland" [PR]="Puerto Rico" [PT]="Portugal"
        [PY]="Paraguay" [RO]="Romania" [RS]="Serbia" [SA]="Saudi Arabia"
        [SE]="Sweden" [SG]="Singapore" [SI]="Slovenia" [SK]="Slovakia"
        [TH]="Thailand" [TR]="Turkey" [TT]="Trinidad and Tobago" [TW]="Taiwan"
        [UA]="Ukraine" [UK]="United Kingdom" [US]="United States" [UY]="Uruguay"
        [VE]="Venezuela" [VN]="Vietnam" [ZA]="South Africa"
    )

    COUNTRY_MAP_INITIALIZED=1
}

country_code() {
    local input="$*"
    local key code

    init_country_maps
    key="$(normalized "$input")"

    if [[ -n "${COUNTRY_BY_NAME[$key]+x}" ]]; then
        printf '%s\n' "${COUNTRY_BY_NAME[$key]}"
        return 0
    fi

    code="${key^^}"
    if [[ "$code" =~ ^[A-Z]{2}$ ]]; then
        printf '%s\n' "$code"
        return 0
    fi

    return 1
}

country_name() {
    local code="${1^^}"

    init_country_maps
    printf '%s\n' "${COUNTRY_NAME_BY_CODE[$code]:-$code}"
}

parse_country_and_city() {
    local -n country_out="$1"
    local -n city_out="$2"
    shift 2

    local end candidate code
    for ((end=$#; end>=1; end--)); do
        candidate="${*:1:end}"
        if code="$(country_code "$candidate")"; then
            country_out="$code"
            city_out="${*:end+1}"
            [[ -n "$city_out" ]] || die "city is required"
            return 0
        fi
    done

    die "unknown country: $*"
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
    local file country city proto path
    while IFS= read -r file; do
        IFS=$'\t' read -r country city proto path < <(file_parts "$file") || continue
        country_name "$country"
    done < <(list_files "$1") | sort -u
}

list_cities() {
    local protocol="$1"
    local wanted_country
    local file country city proto path

    wanted_country="$(country_code "${*:2}")" || die "unknown country: ${*:2}"

    while IFS= read -r file; do
        IFS=$'\t' read -r country city proto path < <(file_parts "$file") || continue
        [[ "${country^^}" == "$wanted_country" ]] || continue
        printf '%s\n' "$city"
    done < <(list_files "$protocol") | sort -u
}

find_config() {
    local protocol="$1"
    local wanted_country="$2"
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
            printf 'No matching VPN config for %s %s %s.\n' "$protocol" "$(country_name "$wanted_country")" "$3" >&2
            printf 'Available cities for %s %s:\n' "$protocol" "$(country_name "$wanted_country")" >&2
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

validate_mssfix() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]] || die "--mssfix must be a positive integer"
    (( value > 0 )) || die "--mssfix must be a positive integer"
}

print_command() {
    local -a command=("$@")
    printf '%q' "${command[0]}"
    printf ' %q' "${command[@]:1}"
    printf '\n'
}

main() {
    local dry_run=0
    local protocol country city config exit_status mssfix=''
    local -a openvpn_command=()

    while (($#)); do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --dry-run)
                dry_run=1
                shift
                ;;
            --mssfix)
                [[ $# -ge 2 ]] || die "usage: load_vpn.sh --mssfix <value> <udp|tcp> <country> <city>"
                validate_mssfix "$2"
                mssfix="$2"
                shift 2
                ;;
            --mssfix=*)
                mssfix="${1#--mssfix=}"
                validate_mssfix "$mssfix"
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    case "${1:-}" in
        '')
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
            [[ $# -ge 3 ]] || die "usage: load_vpn.sh --list-cities <udp|tcp> <country>"
            list_cities "$2" "${@:3}"
            exit 0
            ;;
    esac

    [[ $# -ge 3 ]] || die "usage: load_vpn.sh <udp|tcp> <country> <city>"

    protocol="${1,,}"
    shift
    parse_country_and_city country city "$@"

    [[ -r "$OPENVPN_CREDENTIALS_FILE" ]] || die "credentials file not readable: $OPENVPN_CREDENTIALS_FILE"

    config="$(find_config "$protocol" "$country" "$city")"
    if [[ -z "$mssfix" && "$protocol" == udp ]]; then
        mssfix=1400
    fi

    openvpn_command=(sudo openvpn --config "$config" --auth-user-pass "$OPENVPN_CREDENTIALS_FILE")
    if [[ -n "$mssfix" ]]; then
        openvpn_command+=(--mssfix "$mssfix")
    fi

    if (( dry_run )); then
        local ipv6_dry_run_state
        ipv6_dry_run_state="$(sysctl_value net.ipv6.conf.all.disable_ipv6):$(sysctl_value net.ipv6.conf.default.disable_ipv6)"

        if [[ "$ipv6_dry_run_state" != "1:1" ]]; then
            printf 'sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1\n'
            printf 'sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1\n'
        fi
        print_command "${openvpn_command[@]}"
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
    "${openvpn_command[@]}"
    exit_status=$?
    set -e
    exit "$exit_status"
}

main "$@"
