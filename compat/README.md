# Раздел compat

<div align="left">

### Содержание раздела
1. [Описание pm](#описание-pm)
2. [Установка и запуск pm](#установка-и-запуск-pm)

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

⚠️Что тут важно знать
  >⚠️ Синтаксис apt — исполнение честное. Скрипт не эмулирует вывод, а вызывает настоящий бэкенд, поэтому возврат кодов и текст оригинальный. Отличия, которые осознанно встроены: **

  >⚠️ pm update на dnf — это makecache, аналог apt update.
  pm list upgradable на dnf — check-update (он же возвращает код 100, когда есть обновления, — как у apt, кстати).
  pm purge на dnf неотличим от remove (концепция conffiles там нет) — так и задумано.
  Локальные пакеты: pm install ./x.deb работает только на apt, ./x.rpm — только на dnf. Чужой формат скрипт откажется ставить с ясным сообщением, а не станет конвертировать.
  whatprovides/version и hold/unhold — это то, что в apt-мире обычно руками через dpkg/apt-mark, а в dnf — provides/versionlock. Тоже сведено в одно место.

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

  Команда	| apt	| dnf / yum
  pm update	apt-get update	dnf makecache --refresh
pm upgrade	apt-get upgrade -y	dnf upgrade -y
pm full-upgrade	apt-get full-upgrade -y	dnf upgrade -y
pm install <pkg…>	apt-get install -y	dnf install -y
pm reinstall <pkg…>	apt-get install --reinstall	dnf reinstall
pm remove <pkg…>	apt-get remove -y	dnf remove -y
pm purge <pkg…>	apt-get purge -y	dnf remove -y*
pm autoremove	apt-get autoremove -y	dnf autoremove -y
pm clean	apt-get clean + autoclean	dnf clean all
pm search <query>	apt-cache search	dnf search
pm show <pkg>	apt-cache show	dnf info
pm info <pkg>	псевдоним show	псевдоним show
pm list installed	dpkg -l	dnf list installed
pm list upgradable	apt list --upgradable	dnf check-update
pm list all	apt-cache pkgnames	dnf list available
pm whatprovides <file>	dpkg -S	dnf provides
pm version <pkg>	dpkg-query -W	rpm -q
pm hold <pkg>	apt-mark hold	dnf versionlock add
pm unhold <pkg>	apt-mark unhold	dnf versionlock delete
>⚠️[!WARNING]  В dnf нет понятия conffiles, поэтому purge полностью эквивалентен remove — так и задумано.