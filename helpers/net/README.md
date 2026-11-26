# Раздел helpers/firewalld/system

<div align="left" style="border-bottom: 1.5px dotted #777;">

<img src="https://img.shields.io/badge/Содержание-раздела-rgb(0%200%200%20%2F%200%25)?style=plastic&logo=github&labelColor=rgb(0%200%200%20%2F%200%25)&logo=https://github.githubassets.com/favicons/favicon.png">

  - [📋 Описание fwcmd](#-описание-fwcmd)
  - [🚀 Быстрый запуск](#-быстрый-запуск)
  - [🛠 Установка](#-установка)
  - [🧪 Тестирование](#-тестирование)
  - [Команды](#команды)
  - [Использование](#использование)
  - [Перекати-поле](#перекати-поле)
  - [📂 Структура файлов](#-структура-файлов)
  - [🗂️ Исходные конфигурационные файлы](#️-исходные-конфигурационные-файлы)


</div>

## 📋 Описание fwcmd
fwcmd - этопомощник с командами firewalld.

<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>

## 🚀 Быстрый запуск

Быстрая команда (установка в /usr/local/bin):

```bash
curl -fsSL -o /tmp/install-fwcmd.sh https://github.com/vados-dev/vpn-builder/raw/refs/heads/master/helpers/net/install-fwcmd.sh && chmod +x /tmp/install-fwcmd.sh && sudo bash /tmp/install-fwcmd.sh
```

Вариант без root (в ~/bin):

```bash
curl -fsSL -o /tmp/install-fwcmd.sh https://github.com/vados-dev/vpn-builder/raw/refs/heads/master/helpers/net/install-fwcmd.sh && sudo bash /tmp/install-fwcmd.sh 1 ~/bin
```

Разовое использование без установки:

```bash
bash -c "$(curl -fsSL https://github.com/vados-dev/vpn-builder/raw/refs/heads/master/helpers/net/install-nmcmd.sh)"
```
<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>


## 🛠 Установка

Сохранить/переименовать в "install-fwcmd.sh" и запустить.
    (После подтверждения, будет установлен со всеми симлинками в /usr/local/bin, а сам установщик будет удалён.)
   или:
    "install-fwcmd.sh 1, если в неинтерактивном режиме, с автоподтверждением (1 — да, 0 — нет).
    "install-fwcmd.sh [0|1] ~/bin", если в PATH.

<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>

## 🧪 Тестирование

:exclamation:**для чистоты тестирования запускать лучше из любого места, чтобы удостовериться, что скрипт и симлинки доступны во всей системе**

Проверка версии firewalld
```bash
    fwcmd --version
```
Должен вернуть номер версии
> пример:
```example
    # fwcmd --version
    [✨]#: firewall-cmd --version
2.4.3
```
Проверка симлинка fwreload
```example
    fwreload
```
Должен ответить "success"
> пример:
```example
    # fwreload
    [✨]#: --reload
    √ success
```

<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>

## Команды

<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>

## Использование

Сам скрипт один, при установке создаёт симлинки на самого себя.
Имя файла (симлинка), является первым аргументом (командой/функцией) при запуске скрипта. 
   Отсюда:
   fwcmd.............................firewall-cmd  - Примет любое количество, любых аргументов.
                                                         Ответ будет получен от самомго firewall-cmd.
   fwreload.................firewall-cmd --reload  - Перечитает правила. Аргументы не требуются.
   fwperm................firewall-cmd --permanent  - Добавит/удалит соответствующее правило постоянно.
                                                         Примет любое количество, любых аргументов.
                                                         Ответ будет получен от самомго firewall-cmd.
   fwchk.......firewall-offline-cmd --check-config - Проверит конфигурацию без применения.
                                                         Аргументы не требуются.
   fwctl..............systemctl [команды] [служба] - Управление служюой firewalld.
   [команда] [-h|--help]...............................Покажет справку по fwcmd.
   Управление службой:
    - `fwctl [аргумент]`
   Аргументы:
    ----------
    -e |enable.........Включить службу.
    -d |disable........Выключить службу.
    -en|enable-now.....Включить службу немедленно.
    -dn|disable-now....Выключить службу немедленно.
    -s |start..........Запустить службу.
    -k |stop...........Остановить службу.
    -r |restart........Перезапустить службу.
    -rl|reload.........Перечитать и применить конфиги.
    -st|status.........Показать статус службы.
    -cc|chk_conf.......Проверить конфиги без применения (оффлайн).
    -j |journ..........Показать журнал службы.
    -h |--help.........Эта справка.
### :warning:**Что тут важно знать**

:exclamation:**Синтаксис apt — исполнение честное.
Скрипт не эмулирует вывод, а вызывает настоящий бэкенд, поэтому возврат кодов и текст оригинальный.**

<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>

## Перекати-поле

Как это встраивается

Ты создаёшь каталоги-носители:

```text
/root/.firewalld/
├── zones/
│   ├── new-VPN-trusted-ACCEPT -> /usr/local/bin/fwcmd
│   └── new-FOREIGN-ACCEPT     -> /usr/local/bin/fwcmd
└── policies/
    └── new-GW-VPN-to-world    -> /usr/local/bin/fwcmd
```
Удаляемое — переименованием: mv new-VPN-trusted-ACCEPT del-VPN-trusted-ACCEPT. Настройки зоны — mod--симлинком с аргументами: zones/mod-VPN --add-port=8080/tcp.

В fwcmd добавляются три вещи.

Блок парсинга (после static vars):
```bash#-> Перекати-поле: объекты firewalld по имени симлинка.
#    Грамматика: new|del|mod-<имя>[-TARGET], TARGET: ACCEPT|REJECT|DROP.
#    Тип объекта задаёт каталог симлинка: zones/ или policies/.
pw_parse() {
    local me="${me_name%.sh}"
    case "$me" in
        new-*|del-*|mod-*) ;;
        *) die "pw: '$me_name' не подходит под грамматику new|del|mod-<имя>[-TARGET]" ;;
    esac
    PW_VERB="${me%%-*}"; me="${me#*-}"; PW_TARGET=""
    case "${me##*-}" in
        ACCEPT|REJECT|DROP) PW_TARGET="${me##*-}"; me="${me%-*}" ;;
    esac
    PW_NAME="$me"
    [ -n "$PW_NAME" ] || die "pw: пустое имя объекта"
}

pw_kind() {  # каталог симлинка решает, ЧТО это (не разрешая сам симлинк!)
    local here; here="$(dirname "$0")"; here="$(cd "$here" 2>/dev/null && pwd)" || return 1
    case "${here##*/}" in
        zones)    PW_KIND="zones" ;;
        policies) PW_KIND="policies" ;;
        *)        return 1 ;;
    esac
}

pwperm() {
    declare -A RESP=([true]="success" [false]="error|fail" [answer]="")
    input_cmd RESP -- "$fw_exec" --permanent "$@" && return 0
    local rc=$?; [ "$rc" -eq 2 ] && warn "Ответ firewalld: $OUT"
    return "$rc"
}

pw_exists() {  # pw_exists zone|policy <имя>
    "$fw_exec" --permanent "--get-$1s" 2>/dev/null | grep -qw "$2"
}
```
Движок:
```bash
pw_cmd() {
    pw_parse
    pw_kind || die "pw: запускайте симлинк из каталога zones/ или policies/ (сейчас: '$(dirname "$0")')"

    local d="--zone=$PW_NAME"; [ "$PW_KIND" = policies ] && d="--policy=$PW_NAME"

    case "$PW_VERB" in
        new)
            if pw_exists "${PW_KIND%s}" "$PW_NAME"; then
                ok "${PW_KIND%s} $PW_NAME уже существует"
            else
                pwperm "--new-$PW_KIND=$PW_NAME" || die "не создать $PW_KIND $PW_NAME"
            fi
            [ -n "$PW_TARGET" ] && pwperm "$d" --set-target="$PW_TARGET"
            case "$PW_TARGET" in
                ACCEPT) pwperm "$d" --set-description="All network connections are accepted." ;;
                *)      pwperm "$d" --set-description="$PW_NAME" ;;
            esac
            pwperm "$d" --set-short="$PW_NAME" ;;
        del)
            pw_exists "${PW_KIND%s}" "$PW_NAME" || { ok "${PW_KIND%s} $PW_NAME уже нет"; return 0; }
            confirm "Удалить $PW_KIND '$PW_NAME'?" "y" || return 0
            pwperm "--delete-$PW_KIND=$PW_NAME" ;;
        mod)
            [ $# -gt 0 ] || die "mod требует аргументов firewalld: mod-$PW_NAME --add-port=8080/tcp"
            pwperm "$d" "$@" ;;
    esac
    input_cmd -- "$fw_exec" --reload
}
```

И строку в fw_cmd, до *):
```bash
        new-*|del-*|mod-*)  pw_cmd "$@" ;;
```
<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>

## 📂 Структура файлов

```
/
├── nginx-root/              # Root filesystem nginx контейнера
├── certbot-root/            # Root filesystem certbot контейнера
├── nginx-conf/              # Mount: конфиги nginx
│   └── default.conf         # Reverse proxy config
├── nginx-html/              # Mount: статические файлы (если нужно)
└── certbot-data/            # Mount: сертификаты и credentials
    ├── cloudflare.ini       # Cloudflare API token (создать вручную!)
    └── live/                # Let's Encrypt сертификаты
        └── your-domain.com/
            ├── fullchain.pem
            └── privkey.pem
```

<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>

## 🗂️ Исходные конфигурационные файлы

- Сам скрипт.../usr/local/bin/fwcmd
-инки: 

- fwreload
- fwctl
<div align="left"><a href="#"><img src="https://img.shields.io/badge/%E2%AC%86-up-151b23?style=flat-square&logoColor=white&labelColor=0000FF" /></a>
<div style="border-top: 1px dotted #6c5d53; opacity: 0.5;"></div></div>

<div align="center">

**сделано ❤️ для себя**

[![Link](https://img.shields.io/badge/%E2%AC%86-Вверх-151b23?style=for-the-badge&logoColor=white&labelColor=0000FF)](#раздел-helpers/firewalld/system)

</div>
