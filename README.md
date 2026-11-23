# vpn-builder

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square&labelColor=grey)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/CentOS%209%2B-8A2BE2?style=flat-square&logo=centos&logoColor=white&labelColor=black)](https://www.centos.org/)
[![Platform](https://img.shields.io/badge/Ubuntu%2024%20%2F%20Debian%2012%2B-E95420?style=flat-square&logo=ubuntu&logoColor=white&labelColor=black)](https://ubuntu.com/)
[![AmneziaWG](https://img.shields.io/badge/AmneziaWG%203.1-red?style=flat-square&logo=wireguard&logoColor=red&labelColor=black)](#)
[![Release](https://img.shields.io/github/v/release/vados-dev/amneziawg-linux-kernel-module-vds?style=flat-square&logo=github)](https://github.com/vados-dev/amneziawg-linux-kernel-module-vds/releases)


** Разработка установщика для быстрого развёртывания VPN серверов **

[Описание](#описание) • [Features](#-features) • [Installation](#-installation) • [Screenshots](#-screenshots) • [Troubleshooting](#-troubleshooting)

</div>

---

## 📋 Описание










## Установка и Запуск pm
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