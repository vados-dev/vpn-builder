#!/usr/bin/env bash

#### pm — единый фронтенд для apt и dnf, apt-подобный синтаксис
##############################################################
#-> Пути:
#    -----
#    "/usr/local/bin/pm"
#
#-> Использование:
#    --------------
#    "pm <команда> [аргументы]"
#
#-> Таблица соответствий:
#    ---------------------
#    update .......................... обновить индексы (apt update / dnf refresh)
#    upgrade ......................... обновить пакеты (apt upgrade / dnf upgrade)
#    full-upgrade|dist-upgrade ....... полное обновление (apt full-upgrade / dnf upgrade)
#    install <pkg...> ................ установить (работает и с ./local.deb|./local.rpm)
#    reinstall <pkg...> .............. переустановить
#    remove <pkg...> ................. удалить
#    purge <pkg...> .................. удалить с конфигами (apt purge / dnf remove)
#    autoremove ...................... убрать мусор (apt autoremove / dnf autoremove)
#    clean ........................... очистить кэш
#    search <query> .................. поиск по имени/описанию
#    show <pkg> ...................... информация о пакете
#    list [installed|upgradable|all] . списки пакетов
#    info <pkg> ...................... псевдоним show
#    whatprovides <file> ............. кто владеет файлом (dpkg -S / dnf provides)
#    version <pkg> ................... установленная версия
#    hold <pkg> / unhold <pkg> ....... закрепить/отпустить версию
#
#-> Установка:
#    ----------
#    "install-pm.sh -i"
#-> или:
#    "install-pm.sh -i ~/bin", если в PATH
#    "pm list installed | head"
#
#-> Бэкенд: $PKG

set -o pipefail

# Common vars
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
SELF_DIR="$(dirname "${SELF}")"
ME_SELF="${SELF##*/}"
ME_CLEAN="${ME_SELF%.*}"
PROGRAM="${0##*/}"
ARGS=( "$@" )
PARENT_DIR="$(dirname "${SELF_DIR}")"
dbg=0
ME="${PROGRAM}"

case "$ME" in
  install-pm.sh|install-pm)
    case " ${ARGS[*]-} " in
      *" -i "*|*" --install "*) : ;;   # ключ уже задан — не дублируем
      *) set -- -i "$@" ;;
    esac
    ;;
esac

if [ -t 0 ]; then
  cmd()  { printf '[\033[1;33m✨\033[0m]#: `\033[1m%s\033[0m`\n' "$*"; }
  color_cmd() { local cmd="$*"; { out="$($cmd)"; exit_code=$?; } && printf '\033[1;32m%s\033[0m\n' "$out" || { printf '\033[1;31m%s\033[0m\n' "$out"; }; }
  log()  { printf '\033[1;34m 📋 INFO:\033[0;8m [%s] - %s.\033[0m\n' "$PROGRAM" "$*"; }
  warn() { printf '\033[1;33m ⚡ WARN:\033[0;1m [%s] - %s.\033[0m\n' "$PROGRAM" "$*" >&2; }
  err()  { printf '\033[0;31m ⚫ ERROR:\033[0;1m [%s] - %s!\033[0m\n' "$PROGRAM" "$*" >&2; }
  die()  { printf '\033[1;31m ❌ CRITICAL:\033[0;1m [%s] - %s!\033[0m\n' "$PROGRAM" "$*" >&2; exit 1; }
else
  cmd()  { printf '[*]#: `%s`\n' "$*"; }
  color_cmd() { local cmd="$*"; { out="$($cmd)"; exit_code=$?; } && printf '%s\n' "$out" || { printf '%s\n' "$out"; }; }
  log()  { printf '[INFO] [%s] - %s.\n' "$PROGRAM" "$*"; }
  warn() { printf '[WARN] [%s] - %s.\n' "$PROGRAM" "$*" >&2; }
  err()  { printf '[ERROR] [%s] - %s!\n' "$PROGRAM" "$*" >&2; }
  die()  { printf '[CRITICAL] [%s] - %s!\n' "$PROGRAM" "$*" >&2; exit 1; }
fi

dbg_cmd() { cmd "$*"; color_cmd "$*"; }
run_cmd() { [[ "$dbg" = 0 ]] > /dev/null 2>&1 && color_cmd "$*" || dbg_cmd "$*"; }

# --- определение бэкенда ---
if command -v dnf >/dev/null 2>&1; then
    PKG=dnf
elif command -v yum >/dev/null 2>&1; then
    PKG=yum
elif command -v apt >/dev/null 2>&1; then
    PKG=apt
else
    die "pm: не найден ни dnf/yum, ни apt" >&2
fi

# sudo не нужен, если запущены от root
maybe_sudo() {
    if [ "$(id -u)" = "0" ]; then run_cmd "$@"; else run_cmd sudo "$@"; fi
}

pm_install() {
    local bin_dir="/usr/local/bin" prg="pm"
    [[ -z "$1" ]] || bin_dir="$1"
    [ -d "$bin_dir" ] || mkdir -p "$bin_dir"
    install -m 755 ${ME} "${bin_dir}/${prg}" > /dev/null 2>&1 || die "Ошибка установки ${prg}!"
    log "${ME} успешно установлен в ${bin_dir}/${prg}"
}

usage() { sed -n '2,38p' "${SELF}" | sed 's/^# \{0,1\}//'; }

pkg_is_local() { case "$1" in ./*|/*) return 0 ;; *) return 1 ;; esac; }

install_pkgs() {
    local ok=1 p
    for p in "$@"; do
        if pkg_is_local "$p"; then
            case "${p##*.}" in
                deb) [ "$PKG" = apt ] && maybe_sudo apt-get install -y "$p" || echo "pm: пакет $p — .deb, но бэкенд $PKG" >&2 && ok=0 ;;
                rpm) [ "$PKG" != apt ] && maybe_sudo "$PKG" install -y "$p" || echo "pm: пакет $p — .rpm, но бэкенд apt" >&2 && ok=0 ;;
                *) echo "pm: не знаю, как ставить $p" >&2; ok=0 ;;
            esac
        else
            case "$PKG" in
                apt) maybe_sudo apt-get install -y "$p" ;;
                *)   maybe_sudo "$PKG" install -y "$p" ;;
            esac
        fi
    done
    return $ok
}

list_pkgs() {
    case "${1:-installed}" in
        installed)  [ "$PKG" = apt ] && run_cmd dpkg -l | awk '/^ii/{print $2, $3}' || run_cmd "$PKG" list installed ;;
        upgradable) [ "$PKG" = apt ] && run_cmd apt list --upgradable || run_cmd "$PKG" check-update ;;
        all)        [ "$PKG" = apt ] && run_cmd apt-cache pkgnames || run_cmd "$PKG" list available ;;
    esac
}

cmd="${1:-}"; shift || true
case "$cmd" in
    update)
        case "$PKG" in apt) maybe_sudo apt-get update ;; *) maybe_sudo "$PKG" makecache --refresh 2>/dev/null || maybe_sudo "$PKG" makecache ;; esac ;;
    upgrade)
        case "$PKG" in apt) maybe_sudo apt-get upgrade -y ;; *) maybe_sudo "$PKG" upgrade -y ;; esac ;;
    full-upgrade|dist-upgrade)
        case "$PKG" in apt) maybe_sudo apt-get full-upgrade -y ;; *) maybe_sudo "$PKG" upgrade -y ;; esac ;;
    install|reinstall)
        [ $# -eq 0 ] && { echo "pm: укажите пакет(ы)" >&2; exit 2; }
        if [ "$cmd" = reinstall ]; then
            if [ "$PKG" = apt ]; then maybe_sudo apt-get install -y --reinstall "$@";
            else maybe_sudo "$PKG" reinstall -y "$@"; fi
        else
            install_pkgs "$@"
        fi ;;
    remove)
        case "$PKG" in apt) maybe_sudo apt-get remove -y "$@" ;; *) maybe_sudo "$PKG" remove -y "$@" ;; esac ;;
    purge)
        case "$PKG" in apt) maybe_sudo apt-get purge -y "$@" ;; *) maybe_sudo "$PKG" remove -y "$@" ;; esac ;;
    autoremove)
        case "$PKG" in apt) maybe_sudo apt-get autoremove -y ;; *) maybe_sudo "$PKG" autoremove -y ;; esac ;;
    clean)
        case "$PKG" in apt) maybe_sudo apt-get clean; maybe_sudo apt-get autoclean ;; *) maybe_sudo "$PKG" clean all ;; esac ;;
    search)
        [ $# -eq 0 ] && { echo "pm: укажите запрос" >&2; exit 2; }
        case "$PKG" in apt) run_cmd apt-cache search "$@" ;; *) run_cmd "$PKG" search "$@" ;; esac ;;
    show|info)
        case "$PKG" in apt) run_cmd apt-cache show "$@" ;; *) run_cmd "$PKG" info "$@" ;; esac ;;
    whatprovides)
        case "$PKG" in apt) run_cmd dpkg -S "$@" ;; *) run_cmd "$PKG" provides "$@" ;; esac ;;
    version)
        case "$PKG" in apt) run_cmd dpkg-query -W -f '${Package} ${Version}\n' "$@" ;; *) run_cmd rpm -q "$@" ;; esac ;;
    list) list_pkgs "$@" ;;
    hold)
        case "$PKG" in apt) maybe_sudo apt-mark hold "$@" ;; *) maybe_sudo "$PKG" versionlock add "$@" ;; esac ;;
    unhold)
        case "$PKG" in apt) maybe_sudo apt-mark unhold "$@" ;; *) maybe_sudo "$PKG" versionlock delete "$@" ;; esac ;;
    -i|--install) pm_install "$@" ;;
    -h|--help|help|"") usage ;;
    *) err "pm: неизвестная команда '$cmd'" >&2; usage >&2; exit 2 ;;
esac
