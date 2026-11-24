## Вопрос



Ветка tty:
```
    ok()         { local rc="$?"; if [ "${AMBIG:-0}" = "1" ]; then answer_box "${1:-Неоднозначный вывод}"; AMBIG=0; return "$rc"; fi; [ "$rc" -eq 0 ] && printf '\033[1;32m √ %s\033[0m\n' "${1:-Ok}" || printf '\033[1;31m ✘ %s\033[0m\n' "${1:-Fail}"; return "$rc"; }
    answer_box() { printf '\033[1;33m ⚡ %s\033[0m\n' "$*"; }
    ask()        { local a; if [ -t 0 ]; then read -r -p "$(prompt_yn "${1:-Продолжить?}" "${2:-Y}")" a < /dev/tty; case "${a,,}" in y|yes) return 0;; *) return 1;; esac; else tg_ask "$1"; fi; }
    tg_ask()     { [ -n "${TG_TOKEN:-}" ] && [ -n "${TG_CHAT:-}" ] || die "tg_ask: не заданы TG_TOKEN/TG_CHAT"; curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d chat_id="${TG_CHAT}" -d text="${1:-Требуется подтверждение}" >/dev/null; die "tg_ask: ожидание ответа через getUpdates — не реализовано (заглушка)"; }
```
После else — те же, без краски и без prompt_yn-краски:

```
    ok()         { local rc="$?"; if [ "${AMBIG:-0}" = "1" ]; then answer_box "${1:-Неоднозначный вывод}"; AMBIG=0; return "$rc"; fi; [ "$rc" -eq 0 ] && printf ' √ %s\n' "${1:-Ok}" || printf ' ✘ %s\n' "${1:-Fail}"; return "$rc"; }
    answer_box() { printf ' ⚡ %s\n' "$*"; }
    ask()        { local a; if [ -t 0 ]; then read -r -p "$(prompt_yn "$    {1:-Продолжить?}" "${2:-Y}")" a < /dev/tty; case "${a,,}" in y|yes) return 0;; *) return 1;; esac; else tg_ask "$1"; fi; }
    tg_ask()     { [ -n "${TG_TOKEN:-}" ] && [ -n "${TG_CHAT:-}" ] || die "tg_ask: не заданы TG_TOKEN/TG_CHAT"; curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d chat_id="${TG_CHAT}" -d text="${1:-Требуется подтверждение}" >/dev/null; die "tg_ask: ожидание ответа через getUpdates — не реализовано (заглушка)"; }

```


