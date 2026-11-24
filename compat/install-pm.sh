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
#    Сохранить/переименовать в "install-pm.sh" и запустить.
#    (Будет установлен в /usr/local/bin, а сам установщик будет удалён.)
#-> или:
#    "install-pm.sh ~/bin", если в PATH
#
#-> Проверка:
#    ---------
#    "pm --version"..................Должен вернуть номера версий
#    "pm list installed | head"......Должен вернуть несколько строк с установленными пакетами
#
#-> Бэкенд: $PKG

set -o pipefail

# Common vars
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
SELF_DIR="$(dirname "${SELF}")"
PARENT_DIR="$(dirname "${SELF_DIR}")"

ME_SELF="${SELF##*/}"
ME_CLEAN="${ME_SELF%.*}"

me_name="${0##*/}"
me_args=( "$@" )

#-> Static vars:
PROGRAM="pm"
BIN_DIR="/usr/local/bin"
assume_yes=0 # Автоматически отвечать "да" на все вопросы (для скриптов/cron)
DEF_OK_RE="true|success|^0$"
DEF_FAIL_RE="false|Error|^1$"
OUT=""      # вывод последней команды из overlay_cmd
RC=0        # реальный код последней команды из overlay_cmd

dbg=1

#    [ "${me_name}" != "install-pmmd.sh" ] && ([ "$1" = "-h" ] || [ "$1" = "--help" ]) && { usage; exit 0; }
   case "${me_name}" in
       install-pm.sh|install-pm)   set -- -i "$@" ;;
       *) set -- -i "$@" ;;
   esac

if [ -t 0 ]; then
    cmd()        { printf '[\033[1;33m✨\033[0m]#: ' >&2; printf '%q ' "$@" >&2; printf '\033[0m\n' >&2; }
    answer_box() { printf '\033[1;33m ⚡ %s\033[0m\n' "$*"; }
    ok()        { local rc="$?" m="${1:-}"; [ -z "$m" ] && m="rc=${rc}"; [ "$rc" -eq 0 ] && printf '\033[1;32m √ %s\033[0m\n' "$m" || printf '\033[1;31m ✘ %s\033[0m\n' "$m"; return "$rc"; }
    tg_ask()     { [ -n "${TG_TOKEN:-}" ] && [ -n "${TG_CHAT:-}" ] || die "tg_ask: не заданы TG_TOKEN/TG_CHAT"; curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d chat_id="${TG_CHAT}" -d text="${1:-Требуется подтверждение}" >/dev/null; die "tg_ask: ожидание ответа через getUpdates — не реализовано (заглушка)"; }
    log()  { printf '\033[1;34m 📋 INFO:\033[0;8m [%s] - %s.\033[0m\n' "$me_name" "$*"; }
    warn() { printf '\033[1;33m ⚡ WARN:\033[0;1m [%s] - %s.\033[0m\n' "$me_name" "$*" >&2; }
    err()  { printf '\033[0;31m ⚫ ERROR:\033[0;1m [%s] - %s!\033[0m\n' "$me_name" "$*" >&2; }
    die()  { printf '\033[1;31m ❌ CRITICAL:\033[0;1m [%s] - %s!\033[0m\n' "$me_name" "$*" >&2; exit 1; }
    prompt_yn() { local d="${2,,}"; [ "$d" = "y" ] && printf '\033[1m%s [Y/n]:\033[0m ' "$1" || printf '\033[1m%s [y/N]:\033[0m ' "$1"; }
    ask()        { local a; if [ -t 0 ]; then read -r -p "$(prompt_yn "${1:-Продолжить?}" "${2:-Y}")" a < /dev/tty; case "${a,,}" in y|yes) return 0;; *) return 1;; esac; else tg_ask "$1"; fi; }
else
    cmd()        { printf '[*]#: ' >&2; printf '%q ' "$@" >&2; printf '\n' >&2; }    
    answer_box() { printf ' ⚡ %s\n' "$*"; }
    ok()        { local rc="$?" m="${1:-}"; [ -z "$m" ] && m="rc=${rc}"; [ "$rc" -eq 0 ] && printf ' √ %s\n' "$m" || printf ' ✘ %s\n' "$m"; return "$rc"; }
    tg_ask()     { [ -n "${TG_TOKEN:-}" ] && [ -n "${TG_CHAT:-}" ] || die "tg_ask: не заданы TG_TOKEN/TG_CHAT"; curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d chat_id="${TG_CHAT}" -d text="${1:-Требуется подтверждение}" >/dev/null; die "tg_ask: ожидание ответа через getUpdates — не реализовано (заглушка)"; }
    log()  { printf '[INFO] [%s] - %s.\n' "$me_name" "$*"; }
    warn() { printf '[WARN] [%s] - %s.\n' "$me_name" "$*" >&2; }
    err()  { printf '[ERROR] [%s] - %s!\n' "$me_name" "$*" >&2; }
    die()  { printf '[CRITICAL] [%s] - %s!\n' "$me_name" "$*" >&2; exit 1; }
    rompt_yn() { local d="${2,,}"; [ "$d" = "y" ] && printf '%s [Y/n]: ' "$1" || printf '%s [y/N]: ' "$1"; }
    ask()        { local a; if [ -t 0 ]; then read -r -p "$(prompt_yn "${1:-Продолжить?}" "${2:-Y}")" a < /dev/tty; case "${a,,}" in y|yes) return 0;; *) return 1;; esac; else tg_ask "$1"; fi; }
fi

overlay_cmd() { local fork="$1"; shift; [ "$1" = "--" ] && shift; local out rc v msg; out="$("$@")"; rc=$?; RC=$rc; OUT="$out"; if [ "$fork" = "--" ]; then if [ "$rc" -eq 0 ] && [[ "$out" =~ (${DEF_OK_RE}) ]]; then v=0; msg="$out"; elif [ "$rc" -eq 0 ] && [ -z "$out" ]; then v=0; msg="пусто (уже выполнено)"; elif [[ "$out" =~ (${DEF_FAIL_RE}) ]] || [ "$rc" -ne 0 ]; then v=1; msg="$out"; else [ "$dbg" -eq 1 ] && answer_box "Неожиданный вывод: ${out:-пусто}"; [ "${TG_NOTIFY:-0}" = 1 ] && tg_notify "${me_name}: неожиданный вывод: ${out:-пусто}"; v=1; msg=""; fi; [ "$v" -eq 0 ]; ok "$msg"; return "$v"; fi; [[ "$(declare -p "$fork" 2>/dev/null)" == "declare -A"* ]] || die "overlay_cmd: '$fork' — не ассоциативный массив"; local tk="${fork}[true]" fk="${fork}[false]" ak="${fork}[answer]"; local ok_re="${!tk}" fail_re="${!fk}" ans_re="${!ak}"; if [ "$rc" -eq 0 ] && [ -n "$ok_re" ] && [[ "$out" =~ ($ok_re) ]]; then v=0; elif [ -n "$fail_re" ] && [[ "$out" =~ ($fail_re) ]]; then v=1; elif [ "$rc" -ne 0 ]; then v=1; else v=2; fi; return "$v"; }
input_cmd()   { [ "$dbg" -eq 1 ] && cmd "${@:3}"; overlay_cmd "$@"; }
run_cmd()     { [ "$dbg" -eq 1 ] && cmd "$@"; "$@"; }
tg_notify()   { [ -n "${TG_TOKEN:-}" ] && [ -n "${TG_CHAT:-}" ] || die "tg_notify: не заданы TG_TOKEN/TG_CHAT"; curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d chat_id="${TG_CHAT}" -d text="$*" >/dev/null; }

confirm() { local a; [ "${assume_yes:-0}" = "1" ] && { log "Автоподтверждение: -y"; return 0; }; [ -t 0 ] || [ -t 1 ] || die "Нет интерактивного терминала — используйте -y"; read -r -p "$(prompt_yn "${1:-Уверены?}" "${2:-n}")" a < /dev/tty || die "Поток ввода закрыт — используйте -y"; case "${a,,}" in y|yes) return 0;; *) warn "Отменено пользователем"; exit 0;; esac; }

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
    [ "$1" = "-h" ] || [ "$1" = "--help" ] && { install_usage; exit 0; }
    [[ -n "$1" ]] && assume_yes="$1"; [[ -n "$2" ]] && BIN_DIR="$2"
    local src
    if [ -r "$SELF" ] && [ -s "$SELF" ]; then src="$SELF"; else
        src="$(mktemp -t install-fwcmd-XXXXXX)" || die "Не удалось создать временный файл"
        cat > "$src" || die "Не удалось прочитать сам скрипт из stdin (curl | bash)"
        chmod 755 "$src"; trap 'rm -f "$src"' EXIT
        log "Источник установки: stdin -> ${src}"
    fi
    [ -d "$BIN_DIR" ] || mkdir -p "$BIN_DIR" || die "Не могу создать ${BIN_DIR}"
    if [ -f "$BIN_DIR/$PROGRAM" ]; then
        cmp -s "$src" "$BIN_DIR/$PROGRAM" && { ok "Уже установлена та же версия: ${BIN_DIR}/${PROGRAM}"; exit 0; }
        confirm "Установлена другая версия — заменить на текущую?" "y" && ok "Замена подтверждена" || { ok "Обновление отменено"; exit 0; }
    else
        confirm "Установить ${PROGRAM} в ${BIN_DIR}?" "y" && ok "Установка подтверждена" || { ok "Установка отменена"; exit 0; }
    fi
    install -m 755 "$src" "$BIN_DIR/$PROGRAM" || die "Ошибка установки ${PROGRAM}"
    log "установлена в ${BIN_DIR}/${PROGRAM}"
    [ -f "$SELF" ] && [ "${SELF%/*}" != "$BIN_DIR" ] && { rm -f "$SELF"; log "Установщик удалён: ${SELF}"; }
    trap - EXIT
    if [ "$fail" -eq 0 ]; then ok "Установка завершена."; else err "Установлено частично: ${fail} симлинк(ов) не создан(о) — перечислено выше"; exit 1; fi
}

usage() { sed -n '2,38p' "${SELF}" | sed 's/^# \{0,1\}//'; }
install_usage() { sed -n '2,38p' "${SELF}" | sed 's/^# \{0,1\}//'; }

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
    --version)
        case "$PKG" in apt) run_cmd apt-get --version; run_cmd apt --version ;; *) run_cmd "$PKG" --version; run_cmd rpm --version ;; esac ;;
    -i|--install) pm_install "$@" ;;
    -h|--help|help|"") usage ;;
    *) { err "Неизвестный аргумент '$1'"; ctl_usage; exit 2; } ;;
esac
