# Раздел compat

<div align="left">

### Содержание раздела
1. [Описание pm](#описание-pm)
2. [Установка и запуск pm](#установка-и-запуск-pm)
3. Как работает
4. Подключение к чужим скриптамG


</div>

---

## 📋 Описание pm
### pm - простой менеджер пакетов для Linux.

pm — единый фронтенд для apt и dnf.
<br />
pm — это shell-скрипт, который даёт один и тот же синтаксис для управления пакетами на Debian/Ubuntu (apt) и RHEL/Fedora/Rocky/AlmaLinux (dnf/yum). Скрипт сам определяет, какой пакетный менеджер есть в системе, и транслирует знакомые apt-команды в соответствующие вызовы.

Синтаксис apt-подобный, а исполнение — честное: pm не эмулирует вывод, а вызывает настоящий бэкенд (apt-get, dnf или yum), поэтому коды возврата и текст — оригинальные.

Зачем это нужно: 
Одна и та же команда pm install nginx работает и на сервере с Debian, и на сервере с RHEL — не надо вспоминать, чем тут ставится пакет.
Скрипт не притворяется apt: сторонние установщики, которые детектируют дистрибутив по наличию apt в PATH, ничего не путают. Поэтому бинарник называется pm, а не apt.
Локальные пакеты разруливаются по расширению: ./file.deb ставится только через apt, ./file.rpm — только через dnf. Чужой формат скрипт откажется ставить с понятным сообщением, а не сломает систему.

### :warning:**Что тут важно знать**

:exclamation:**Синтаксис apt — исполнение честное.
Скрипт не эмулирует вывод, а вызывает настоящий бэкенд, поэтому возврат кодов и текст оригинальный.**

> Отличия, которые осознанно встроены:
>  1. pm update на dnf — это makecache, аналог apt update.
>  2. pm list upgradable на dnf — check-update (он же возвращает код 100, когда есть обновления, — как у apt, кстати).
>  3. pm purge на dnf неотличим от remove (концепция conffiles там нет) — так и задумано.

> Локальные пакеты:
>  1. pm install ./x.deb работает только на apt, ./x.rpm — только на dnf. Чужой формат скрипт откажется ставить с ясным сообщением, а не станет конвертировать.
>  2. whatprovides/version и hold/unhold — это то, что в apt-мире обычно руками через dpkg/apt-mark, а в dnf — provides/versionlock. Тоже сведено в одно место.

## 🚀 Установка и Запуск pm
Быстрая команда (установка в /usr/local/bin):
```bash
    curl -fsSL -o /tmp/install-pm.sh https://raw.githubusercontent.com/vados-dev/vpn-builder/master/compat/install-pm.sh && \
    sudo bash /tmp/install-pm.sh -i && rm -f /tmp/install-pm.sh
```
    Проверка: pm --help и pm list installed | head.

Вариант без root (в ~/bin):
```bash
    curl -fsSL -o /tmp/install-pm.sh https://raw.githubusercontent.com/vados-dev/vpn-builder/master/compat/install-pm.sh && \
    sudo bash /tmp/install-pm.sh -i ~/bin && rm -f /tmp/install-pm.sh
```
    Проверка: pm --help и pm list installed | head.

Разовое использование без установки:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/vados-dev/vpn-builder/master/compat/install-pm.sh)" pm list installed
```
Работает, потому что -i и usage() не задействуются, а $0 подменяется на pm.
Как работает

#Команды


| Команда                | apt                         | dnf / yum               |
| ---------------------- | --------------------------- | ----------------------- |
| pm update              | apt-get update              | dnf makecache --refresh |
| pm upgrade             | apt-get upgrade -y          | dnf upgrade -y          |
| pm full-upgrade        | apt-get full-upgrade -y     | dnf upgrade -y          |
| pm install <pkg…>      | apt-get install -y          | dnf install -y          |
| pm reinstall <pkg…>    | apt-get install --reinstall | dnf reinstall           |
| pm remove <pkg…>       | apt-get remove -y           | dnf remove -y           |
| pm purge <pkg…>        | apt-get purge -y            | dnf remove -y           |
| pm autoremove          | apt-get autoremove -y       | dnf autoremove -y       |
| pm clean               | apt-get clean + autoclean   | dnf clean all           |
| pm search <query>      | apt-cache search            | dnf search              |
| pm show <pkg>          | apt-cache show              | dnf info                |
| pm info <pkg>          | псевдоним show              | псевдоним show          |
| pm list installed      | dpkg -l                     | dnf list installed      |
| pm list upgradable     | apt list --upgradable       | dnf check-update        |
| pm list all            | apt-cache pkgnames          | dnf list available      |
| pm whatprovides <file> | dpkg -S                     | dnf provides            |
| pm version <pkg>       | dpkg-query -W               | rpm -q                  |
| pm hold <pkg>          | apt-mark hold               | dnf versionlock add     |
| pm unhold <pkg>        | apt-mark unhol              | dnf versionlock delete  |






Вот теперь задача ясна, и у неё есть штатный механизм — ты угадала с функциями, а внедряются они через BASH_ENV + export -f. Двойной контур:

 - BASH_ENV — файл, который bash сам подгружает в каждый неинтерактивный скрипт перед выполнением.   Именно его читают чужие #!/bin/sh и #!/bin/bash скрипты.
 - export -f — экспортирует функции в окружение, чтобы они доехали и во вложенные bash-процессы, запущенные чужим скриптом.
 
## Шаг 1. Файл совместимости

/etc/pm-compat.sh — оверлей для чужих скриптов

```
apt() {
    case "$1" in
        update|upgrade|install|remove|autoremove|purge)
            pm "$@" ;;
        *) echo "pm-compat: apt $* — не поддерживается, ставь руками" >&2; return 1 ;;
    esac
}

apt-get() { apt "$@"; }

export -f apt apt-get
```

Функцию с дефисом bash разрешает (apt-get() {} — валидно), так что имя честное, скрипт даже не заметит подмены. Внутри ты можешь не только звать pm, но и просто проверять наличие пакета и делать no-op — раз, как ты говоришь, у тебя всё уже стоит.

Шаг 2. Включить глобально
Через PAM — это покроет SSH-сессии, логины и cron за один ход:

## Шаг 2. Включить глобально

```bash
echo 'BASH_ENV=/etc/pm-compat.sh' >> /etc/environment
```

Для systemd-сервисов PAM не работает, им отдельно:

```

```ini
# /etc/systemd/system.conf.d/pm-compat.conf
[Manager]
DefaultEnvironment=BASH_ENV=/etc/pm-compat.sh
```
и systemctl daemon-reexec (или ребут). После этого чужой скрипт с apt-get install foo просто вызовет твою функцию — ни один файл чужого репозитория трогать не надо.
Где эта схема честно не работает

  - скрипты не на bash. На RHEL-семействе /bin/sh — это bash, так  что #!/bin/sh покрыт. Но если попадётся настоящий dash или скрипт на zsh — функции не доедут.
  - Не-shell вызовы. Если чужой установщик — питоновский или перловый и зовёт apt-get через subprocess — функции он не увидит, оболочка в дело не вступает. Тут альтернативы, кроме инарника в PATH, не существует в принципе.
- Срипты, проверяющие не наличие команды, а исполнимость: [ -x "$(command -v apt-get)" ] вернёт ложь — функция не файл. Редко, но бывает.
- sudo. С настройками по умолчанию функции обычно проходят, нопри жёстком env_reset/secure_path могут отрезаться.Иодно предупреждающее: экспортируемые функции с чужими именами  это тот самый механизм shellshock, поэтому где-то в цепочке (sshd с фильтрами, hardened-окружения) их могут отрезать из оображений безопасности. Для своих машин это ок, для чужих — учитывай.
сли хочешь, напишу полную версию /etc/pm-compat.sh — с таблицей соответствий из нашего pm внутри (install/update/upgrade/remove/earch) и нормальными кодами возврата, чтобы чужой скрипт при шибке падал по-настоящему, а не тихо «успешно».

