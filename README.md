# vpn-builder

<div align="center">

![AmneziaWG](https://img.shields.io/badge/AmneziaWG-3.1-7C3AED?style=for-the-badge&logo=wireguard)
[![Release](https://img.shields.io/github/v/release/vados-dev/amneziawg-linux-kernel-module-vds?style=for-the-badge&logo=github)](https://github.com/vados-dev/amneziawg-linux-kernel-module-vds/releases)
![License](https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge)

** Разработка установщика для быстрого развёртывания VPN серверов **

[Описание](#описание) • [Features](#-features) • [Proxmox LXC](#-proxmox-lxc) • [MikroTik CHR](#-mikrotik-chr) • [Screenshots](#-screenshots) • [Troubleshooting](#-troubleshooting)

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