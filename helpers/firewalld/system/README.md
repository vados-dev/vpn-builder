# Раздел helpers/firewalld/system

<div align="left">

### Содержание раздела
1. [Описание fwcmd](#описание-fwcmd)
2. [Установка и запуск fwcmd](#установка-и-запуск-fwcmd)

</div>

---

## 📋 Описание `fwcmd`
`fwcmd` -- этопомощник с командами firewalld.

### 📂 Пути по умолчанию:
```text
/usr/local/bin/fwcmd
              /@fwreload
              /@fwperm

```

> - Сам скрипт..."/usr/local/bin/fwcmd"

Симлинки: 

  / fwreload
  / fwctl


## 🛠 Установка:

  Сохранить/переименовать в "install-fwcmd.sh" и запустить.
    (После подтверждения, будет установлен со всеми симлинками в /usr/local/bin, а сам установщик будет удалён.)
   или:
    "install-fwcmd.sh 1, если в неинтерактивном режиме, с автоподтверждением (1 — да, 0 — нет).
    "install-fwcmd.sh [0|1] ~/bin", если в PATH.

-> Проверка:
    ---------
    "fwcmd --version"....Должен вернуть номер версии
    "fwcmdreload"........Должен ответить "success"

---
### Использование:
   
    Сам скрипт один, при установке создаёт симлинки на самого себя.
    Имя файла (симлинка), является первым аргументом (командой/функцией) при запуске скрипта. 
    Отсюда:
    `fwcmd`.............................`firewall-cmd`  - Примет любое количество, любых аргументов.
                                                          Ответ будет получен от самомго firewall-cmd.
    `fwreload`.................`firewall-cmd --reload`  - Перечитает правила. Аргументы не требуются.
    `fwperm`................`firewall-cmd --permanent`  - Добавит/удалит соответствующее правило постоянно.
                                                          Примет любое количество, любых аргументов.
                                                          Ответ будет получен от самомго firewall-cmd.
    `fwchk`.......`firewall-offline-cmd --check-config` - Проверит конфигурацию без применения.
                                                          Аргументы не требуются.
    `fwctl`..............`systemctl [команды] [служба]` - Управление служюой firewalld.
    `[команда] [-h|--help]`...............................Покажет справку по fwcmd.


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


## 🚀 Установка и Запуск pm
Быстрая команда (установка в /usr/local/bin):
```bash
curl -fsSL -o /tmp/install-pm.sh https://raw.githubusercontent.com/vados-dev/vpn-builder/master/compat/install-pm.sh \
  && sudo bash /tmp/install-pm.sh -i \
  && rm -f /tmp/install-pm.sh
```
    Проверка: pm --help и pm list installed | head.

Вариант без root (в ~/bin):
```bash
mkdir -p ~/bin \
  && curl -fsSL -o /tmp/install-pm.sh https://raw.githubusercontent.com/vados-dev/vpn-builder/master/compat/install-pm.sh \
  && sudo bash /tmp/install-pm.sh -i ~/bin \
  && rm -f /tmp/install-pm.sh
```
    Проверка: pm --help и pm list installed | head.

Разовое использование без установки:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/vados-dev/vpn-builder/master/compat/install-pm.sh)" pm list installed
```
    Работает, потому что -i и usage() не задействуются, а $0 подменяется на pm.

## Как работает

### Команды

| Команда	| apt	| dnf / yum |
|---|---|---|
| `pm update` |	`apt-get update` | `dnf makecache --refresh` |
| `pm upgrade` |	`apt-get upgrade -y` | `dnf upgrade -y` |
| `pm full-upgrade` |	`apt-get full-upgrade -y` | `dnf upgrade -y` |
| `pm install <pkg…>` |	`apt-get install -y` | `dnf install -y` |
| `pm reinstall <pkg…>` |	`apt-get install --reinstall` | `dnf reinstall` |
| `pm remove <pkg…>` |	`apt-get remove -y` | `dnf remove -y` |
| `pm purge <pkg…>` |	`apt-get purge -y` | `dnf remove -y` |
| `pm autoremove` |	`apt-get autoremove -y` | `dnf autoremove -y` |
| `pm clean` |	`apt-get clean + autoclean` | `dnf clean all` |
| `pm search <query>` |	`apt-cache search` | `dnf search` |
| `pm show <pkg>` |	`apt-cache show` | `dnf info` |
| `pm info <pkg>` |	псевдоним `show` |	псевдоним `show` |
| `pm list installed` |	`dpkg -l` | `dnf list installed` |
| `pm list upgradable` |	`apt list --upgradable` | `dnf check-update`|
| `pm list all` |	`apt-cache pkgnames` | `dnf list available` |
| `pm whatprovides <file>` |	`dpkg -S` | `dnf provides` |
| `pm version <pkg>` |	`dpkg-query -W` |	`rpm -q` |
| `pm hold <pkg>` |	`apt-mark hold` | `dnf versionlock add` |
| `pm unhold <pkg>` |	`apt-mark unhol` | `dnf versionlock delete` |
>:warning: В dnf нет понятия conffiles, поэтому purge полностью эквивалентен remove — так и задумано.


