#!/usr/bin/env bash

#### nmcmd — помощник с командами NetworkManager (nmcli)
###########################################
#-> Пути по умолчанию:
#    ------------------
#    Сам скрипт..."/usr/local/bin/nmcmd"
#    Симлинки....."/usr/local/bin/nmimport"
#                 "/usr/local/bin/nmexport"
#                 "/usr/local/bin/nmup"
#                 "/usr/local/bin/nmdown"
#                 "/usr/local/bin/nmls"
#                 "/usr/local/bin/nmshow"
#                 "/usr/local/bin/nmget"
#                 "/usr/local/bin/nmmod"
#                 "/usr/local/bin/nmctl"
#
#-> HELP-INSTALL:
#-> Установка:
#    ----------
#    Сохранить/переименовать в "install-nmcmd.sh" и запустить.
#    (После подтверждения будет установлен со всеми симлинками в /usr/local/bin, а сам установщик удалён.)
#-> или:
#    "install-nmcmd.sh 1" — неинтерактивный режим, автоподтверждение (1 — да, 0 — нет).
#    "install-nmcmd.sh [0|1] ~/bin" — если каталог в PATH.
#
#-> Проверка:
#    ---------
#    "nmcmd --version"...Должен вернуть номер версии
#    "nmls"..............Должен перечислить соединения
#-> END-INSTALL:
#
#######################################################
#-> HELP:
#-> Использование:
#    --------------
#    Сам скрипт один, при установке создаёт симлинки на самого себя.
#    Имя файла (симлинка) — первый аргумент (команда) при запуске. Отсюда:
#    `nmcmd`..........................`nmcli` - Примет любое количество, любых аргументов.
#                                               Ответ — сырой вывод nmcli.
#    `nmimport <тип> <файл>`.........`nmcli connection import type <тип> file <файл>`.
#                                       Тип — любой, что умеет NM: wireguard, vpn,
#                                       ethernet, wifi, ovs, bond... (полный список:
#                                       "nmcli -f TYPE connection show" или man nm-settings-nmcli).
#                                       Имя соединения = имя файла без расширения.
#                                       Пример: nmimport wireguard ~/awg-ams.conf
#                                               nmimport vpn ~/office.nmconnection-впн
#    `nmexport <имя>`.................`nmcli connection export <имя>` — в stdout.
#                                       ВНИМАНИЕ: включает PrivateKey. Перенаправляйте в файл 600.
#    `nmup <имя>`.....................`nmcli connection up <имя>` — поднять соединение.
#    `nmdown <имя>`...................`nmcli connection down <имя>` — опустить (спросит подтверждение).
#    `nmls [--active]`................`nmcli connection show` — список профилей.
#    `nmshow <имя>`...................`nmcli connection show <имя>` — всё дерево свойств.
#    `nmget <свойство> <имя>`.........`nmcli -g <свойство> connection show <имя>` — одно значение,
#                                       без шапки — для скриптов и разбора.
#    `nmmod <имя> <изменения...>`.....`nmcli connection modify <имя> ...` — любой синтаксис:
#                                       nmmod awg-ams +ipv4.routes "10.20.0.0/16"
#                                       nmmod awg-ams ipv4.never-default yes
#                                       nmmod awg-ams connection.zone vpn-tunnel
#                                       (+ добавить, - убрать, без префикса — заменить).
#    `nmctl [аргумент]`...............Управление службой NetworkManager (см. HELP-CTL).
#    `[команда] [-h|--help]`..........Справка.
#
#    Маршрутизация (примеры для nmmod):
#     - маршрут через туннель......nmmod awg-myvpn +ipv4.routes "10.20.0.0/16"
#     - policy routing.............nmmod awg-myvpn ipv4.route-table 100
#                                  nmmod awg-myvpn +ipv4.routing-rules "priority 100 from 192.168.1.50 table 100"
#     - туннель не дефолт..........nmmod awg-myvpn ipv4.never-default yes
#     - применить без реворка......nmcli device reapply <ifname> (nmcmd device reapply <ifname>)
#-> END-HELP:
#
#-> HELP-CTL:
#    Управление службой:
#     - `nmctl [аргумент]`
#    Аргументы:
#     ----------
#     -e |enable.........Включить службу.
#     -d |disable........Выключить службу.
#     -en|enable-now.....Включить службу немедленно.
#     -dn|disable-now....Выключить службу немедленно.
#     -s |start..........Запустить службу.
#     -k |stop...........Остановить службу.
#     -r |restart........Перезапустить службу.
#     -rl|reload.........Перечитать и применить конфиги.
#     -st|status.........Показать статус службы.
#     -j |journ..........Показать журнал службы.
#     -h |--help.........Эта справка.
#-> END-CTL:

set -o pipefail

_c() { [ $# == 0 ] && printf "\e[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\e[\1m/g'; }
[ $# == 0 ] && cecho() { printf "$(_c "$1")%b\033[0m\n" "$2"; }; ok_color() { cecho Gs "$*"; }; err_color() { cecho Rs "$*"; } || cecho() { printf '%b\n' "$2"; }; ok_color() { echo "$*"; }; err_color() { echo "$*"; }

R='\033[38;5;203m'; G='\033[0;32m'; Y='\033[0;33m'; B='\033[1;94m'; M='\033[1;35m'; C='\033[0;36m'; W='\033[1;37m'; D='\033[0;53m'; N='\033[0m'

ok()   { echo -e "${G}  √ $*${N}"; }
err()  { echo -e "${R}  × $*${N}"; }
warn() { echo -e "${Y}  ▲ $*${N}"; }
info() { echo -e "${C}  → $*${N}"; }
dim()  { echo -e "${D}    $*${N}"; }

LINE='━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
hdr() {
  echo -e "${B}${LINE}${N}"
  echo -e "  ${W}$*${N}"
  echo -e "${B}${LINE}${N}"
}
success_box() {
  echo -e "${G}${LINE}${N}"
  echo -e "  ${W}$*${N}"
  echo -e "${G}${LINE}${N}"
}

#-> Dynamic vars:
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
SELF_DIR="$(dirname "${SELF}")"
PARENT_DIR="$(dirname "${SELF_DIR}")"

ME_SELF="${SELF##*/}"
ME_CLEAN="${ME_SELF%.*}"

me_name="${0##*/}"
ARGS=( "$@" )

#-> Static vars:
VERSION="1.0.0"
PROGRAM="nmcmd"
BIN_DIR="/usr/local/bin"
SYMLINKS=( "nmimport" "nmexport" "nmup" "nmdown" "nmls" "nmshow" "nmget" "nmmod" "nmctl" )
AUTO_MODE=0
DEF_OK_RE="true|success|^0$"
DEF_FAIL_RE="false|Error|^1$"
OUT=""      # вывод последней команды из overlay_cmd
RC=0        # реальный код последней команды из overlay_cmd

nm_exec="nmcli"
nm_service="NetworkManager.service"
nmctl_exec="systemctl"

#-> Telegram bot vars:
TG_NOTIFY=1
TG_CONFIG="/etc/awg-bot.conf"
# Выводить отладочные сообщения
dbg=1

[ "$TG_NOTIFY" = 1 ] && source "$TG_CONFIG"

if [ -t 0 ]; then
    cmd()        { printf '[\033[1;33m✨\033[0m]#: ' >&2; printf '%q ' "$@" >&2; printf '\033[0m\n' >&2; }
    answer_box() { printf '\033[1;33m ⚡ %s\033[0m\n' "$*"; }
    ok()        { local rc="$?" m="${1:-}"; [ -z "$m" ] && m="rc=${rc}"; [ "$rc" -eq 0 ] && printf '\033[1;32m √ %s\033[0m\n' "$m" || printf '\033[1;31m ✘ %s\033[0m\n' "$m"; return "$rc"; }
    tg_ask()     { [ -n "${BOT_TOKEN:-}" ] && [ -n "${ADMIN_ID:-}" ] || die "tg_ask: не заданы BOT_TOKEN/ADMIN_ID"; curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d chat_id="${ADMIN_ID}" -d text="${1:-Требуется подтверждение}" >/dev/null; die "tg_ask: ожидание ответа через getUpdates — не реализовано (заглушка)"; }
    log()  { printf '\033[1;34m 📋 INFO:\033[0;8m [%s] - %s.\033[0m\n' "$me_name" "$*"; }
    warn() { printf '\033[1;33m ⚡ WARN:\033[0;1m [%s] - %s.\033[0m\n' "$me_name" "$*" >&2; }
    err()  { printf '\033[0;31m ⚫ ERROR:\033[0;1m [%s] - %s!\033[0m\n' "$me_name" "$*" >&2; }
    die()  { printf '\033[1;31m ❌ CRITICAL:\033[0;1m [%s] - %s!\033[0m\n' "$me_name" "$*" >&2; exit 1; }
    prompt_yn() { local d="${2,,}"; [ "$d" = "y" ] && printf '\033[1m%s [Y/n]:\033[0m ' "$1" || printf '\033[1m%s [y/N]:\033[0m ' "$1"; }
else
    cmd()        { printf '[*]#: ' >&2; printf '%q ' "$@" >&2; printf '\n' >&2; }
    answer_box() { printf ' ⚡ %s\n' "$*"; }
    ok()        { local rc="$?" m="${1:-}"; [ -z "$m" ] && m="rc=${rc}"; [ "$rc" -eq 0 ] && printf ' √ %s\n' "$m" || printf ' ✘ %s\n' "$m"; return "$rc"; }
    tg_ask()     { [ -n "${BOT_TOKEN:-}" ] && [ -n "${ADMIN_ID:-}" ] || die "tg_ask: не заданы BOT_TOKEN/ADMIN_ID"; curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d chat_id="${ADMIN_ID}" -d text="${1:-Требуется подтверждение}" >/dev/null; die "tg_ask: ожидание ответа через getUpdates — не реализовано (заглушка)"; }
    log()  { printf '[INFO] [%s] - %s.\n' "$me_name" "$*"; }
    warn() { printf '[WARN] [%s] - %s.\n' "$me_name" "$*" >&2; }
    err()  { printf '[ERROR] [%s] - %s!\n' "$me_name" "$*" >&2; }
    die()  { printf '[CRITICAL] [%s] - %s!\n' "$me_name" "$*" >&2; exit 1; }
    prompt_yn() { local d="${2,,}"; [ "$d" = "y" ] && printf '%s [Y/n]: ' "$1" || printf '%s [y/N]: ' "$1"; }
fi

ask() { local a d="${2:-Y}"; if [ -t 0 ]; then read -r -p "$(prompt_yn "${1:-Продолжить?}" "$d")" a < /dev/tty; a="${a:-$d}"; case "${a,,}" in y|yes) return 0;; *) return 1;; esac; else tg_ask "$1"; fi; }
overlay_cmd() { local fork="$1"; shift; [ "$1" = "--" ] && shift; local out rc v msg; out="$("$@")"; rc=$?; RC=$rc; OUT="$out"; if [ "$fork" = "--" ]; then if [ "$rc" -eq 0 ] && [[ "$out" =~ (${DEF_OK_RE}) ]]; then v=0; msg="$out"; elif [ "$rc" -eq 0 ] && [ -z "$out" ]; then v=0; msg="успех без вывода"; elif [[ "$out" =~ (${DEF_FAIL_RE}) ]] || [ "$rc" -ne 0 ]; then v=1; msg="$out"; else [ "$dbg" -eq 1 ] && answer_box "Неожиданный вывод: ${out:-пусто}"; [ "${TG_NOTIFY:-0}" = 1 ] && tg_notify "${me_name}: неожиданный вывод: ${out:-пусто}"; v=1; msg=""; fi; [ "$v" -eq 0 ]; ok "$msg"; return "$v"; fi; [[ "$(declare -p "$fork" 2>/dev/null)" == "declare -A"* ]] || die "overlay_cmd: '$fork' — не ассоциативный массив"; local tk="${fork}[true]" fk="${fork}[false]" ak="${fork}[answer]"; local ok_re="${!tk}" fail_re="${!fk}" ans_re="${!ak}"; if [ "$rc" -eq 0 ] && [ -n "$ok_re" ] && [[ "$out" =~ ($ok_re) ]]; then v=0; elif [ -n "$fail_re" ] && [[ "$out" =~ ($fail_re) ]]; then v=1; elif [ "$rc" -ne 0 ]; then v=1; else v=2; fi; return "$v"; }
input_cmd()   { [ "$dbg" -eq 1 ] && cmd "${@:3}"; overlay_cmd "$@"; }
run_cmd()     { [ "$dbg" -eq 1 ] && cmd "$@"; "$@"; }
tg_notify()   { [ -n "${BOT_TOKEN:-}" ] && [ -n "${ADMIN_ID:-}" ] || die "tg_notify: не заданы BOT_TOKEN/ADMIN_ID"; curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d chat_id="${ADMIN_ID}" -d text="$*" >/dev/null; }

confirm() { local a; [ "${AUTO_MODE:-0}" = "1" ] && { log "Автоподтверждение: -y"; return 0; }; [ -t 0 ] || [ -t 1 ] || die "Нет интерактивного терминала — используйте -y"; read -r -p "$(prompt_yn "${1:-Уверены?}" "${2:-n}")" a < /dev/tty || die "Поток ввода закрыт — используйте -y"; a="${a:-${2:-n}}"; case "${a,,}" in y|yes) return 0;; *) warn "Отменено пользователем"; exit 0;; esac; }

#-> Справка: маркеры вместо sed-диапазонов строк — правка шапки больше не
#   сдвигает нумерацию молча. Маркерные строки срезаются 1d;$d.
usage()         { sed -n '/#-> HELP:/,/#-> END-HELP:/p' "${SELF}" | sed '1d;$d;s/^# \{0,1\}//'; }
install_usage() { sed -n '/#-> HELP-INSTALL:/,/#-> END-INSTALL:/p' "${SELF}" | sed '1d;$d;s/^# \{0,1\}//'; }
ctl_usage()     { sed -n '/#-> HELP-CTL:/,/#-> END-CTL:/p' "${SELF}" | sed '1d;$d;s/^# \{0,1\}//'; }

nmctl_cmd() {
    [ $# -gt 0 ] || { err "Пустые аргументы"; ctl_usage; exit 2; }
    case $1 in
        -e |enable)       run_cmd $nmctl_exec enable $nm_service ;;
        -d |disable)      run_cmd $nmctl_exec disable $nm_service ;;
        -en|enable-now)   run_cmd $nmctl_exec enable --now $nm_service ;;
        -dn|disable-now)  run_cmd $nmctl_exec disable --now $nm_service ;;
        -s |start)        run_cmd $nmctl_exec start $nm_service ;;
        -k |stop)         run_cmd $nmctl_exec stop $nm_service ;;
        -r |restart)      run_cmd $nmctl_exec restart $nm_service ;;
        -rl|reload)       run_cmd $nmctl_exec reload $nm_service ;;
        -st|status)       run_cmd $nmctl_exec status $nm_service ;;   # сырой вывод, краски systemctl сохранены
        -j |journ)        run_cmd journalctl -xeu $nm_service ;;
        -h |--help)       ctl_usage ;;
          *) { err "Неизвестный аргумент '$1'"; ctl_usage; exit 2; } ;;
    esac
}

nmcmd_install() {
    [ "$1" = "-h" ] || [ "$1" = "--help" ] && { install_usage; exit 0; }
    [[ -n "$1" ]] && AUTO_MODE="$1"; [[ -n "$2" ]] && BIN_DIR="$2"
    local src
    if [ -r "$SELF" ] && [ -s "$SELF" ]; then src="$SELF"; else
        src="$(mktemp -t install-nmcmd-XXXXXX)" || die "Не удалось создать временный файл"
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
    log "создаю симлинки..."
    local fail=0
    for link in "${SYMLINKS[@]}"; do
        if ln -sfn "$PROGRAM" "${BIN_DIR}/${link}" 2>/dev/null; then
            log "- ${link} -> ${PROGRAM}"
        elif [ -e "${BIN_DIR}/${link}" ] && [ ! -L "${BIN_DIR}/${link}" ]; then
            if rm -rf "${BIN_DIR:?}/${link}" 2>/dev/null; then
                if ln -sfn "$PROGRAM" "${BIN_DIR}/${link}"; then
                    log "- ${link} -> ${PROGRAM} (перезаписан)"
                else
                    warn "Не смог создать симлинк ${BIN_DIR}/${link} после удаления"; fail=$((fail+1))
                fi
            else
                warn "Не смог удалить ${BIN_DIR}/${link} (не файл/каталог? права?)"; fail=$((fail+1))
            fi
        else
            warn "Не смог создать симлинк ${BIN_DIR}/${link} — проверьте права на ${BIN_DIR}"
            fail=$((fail+1))
        fi
    done
    [ -f "$SELF" ] && [ "${SELF%/*}" != "$BIN_DIR" ] && { rm -f "$SELF"; log "Установщик удалён: ${SELF}"; }
    trap - EXIT
    if [ "$fail" -eq 0 ]; then ok "Установка завершена."; else err "Установлено частично: ${fail} симлинк(ов) не создан(о) — перечислено выше"; exit 1; fi
}

nm_cmd() {
    if [ "${me_name}" != "install-nmcmd.sh" ] && ([ "$1" = "-h" ] || [ "$1" = "--help" ]); then usage; exit 0; fi
    [ "$1" = "--version" ] && { echo "${PROGRAM} ${VERSION}"; exit 0; }
    case "${me_name}" in
        nmcmd)             run_cmd "$nm_exec" "$@" ;;
        nmimport) [ $# -lt 2 ] && { err "nmimport требует <тип> <файл>"; usage; exit 2; }; input_cmd -- "$nm_exec" connection import type "$1" file "$2" ;;
        nmexport)          [ $# -eq 0 ] && { err "nmexport требует <имя-соединения>"; usage; exit 2; }; run_cmd "$nm_exec" connection export "$1" ;;
        nmup)              [ $# -eq 0 ] && { err "nmup требует <имя-соединения>"; usage; exit 2; }; input_cmd -- "$nm_exec" connection up "$1" ;;
        nmdown)            [ $# -eq 0 ] && { err "nmdown требует <имя-соединения>"; usage; exit 2; }; confirm "Опустить соединение '$1'?" "n" && input_cmd -- "$nm_exec" connection down "$1" ;;
        nmls)              run_cmd "$nm_exec" connection show "$@" ;;
        nmshow)            [ $# -eq 0 ] && { err "nmshow требует <имя-соединения>"; usage; exit 2; }; run_cmd "$nm_exec" connection show "$1" ;;
        nmget)             [ $# -lt 2 ] && { err "nmget требует <свойство> <имя-соединения>"; usage; exit 2; }; run_cmd "$nm_exec" -g "$1" connection show "$2" ;;
        nmmod)             [ $# -lt 2 ] && { err "nmmod требует <имя> <изменения...>"; usage; exit 2; }; input_cmd -- "$nm_exec" connection modify "$@" ;;
        nmctl)             nmctl_cmd "$@" ;;
        install-nmcmd.sh)  nmcmd_install "$@" ;;
        *)                 run_cmd "$nm_exec" "$@" ;;
    esac
}

nm_cmd "$@"
