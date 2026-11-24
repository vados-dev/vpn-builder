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
Одна строка в судье — откуда берётся «удивление» (AMBIG), в существующую overlay_cmd, в начало проверки:
```
    overlay_cmd(){ local out rc; out="$("$@")"; rc=$?; if [ "$rc" -eq 0 ] && [ -n "$out" ] && [[ "$out" =~ (${OK_PAT:-success|ok|done|active}) ]] && ! [[ "$out" =~ (${FAIL_PAT:-error|fail|denied|refused}) ]]; then AMBIG=0; elif [ "$rc" -ne 0 ] || [[ "$out" =~ (${FAIL_PAT:-error|fail|denied|refused}) ]]; then AMBIG=0; else AMBIG=1; fi; return "$rc"; }
```
### :warning:**Что тут важно знать**

:exclamation:**local rc="$?" первым оператором — не local rc="$?" x="y" и не после других команд, иначе $? уйдёт. Это контракт ok: «стою сразу за командой».**

:exclamation:**return "$rc" из ok — якорь не рвёт цепочку: ok "..." || { err "..."; exit 2; } работает, если понадобится добить жёстко.
AMBIG — глобал, судья его ставит, ok потребляет и сбрасывает. Один сигнал на один вызов; если забудете сбросить где-то в обход ok — следующий вызов окей удивится повторно, поэтому сброс живёт в самой ok.
answer_box теперь минимальна: только формат ⚡. Смысл («что это было») ей приносит текст от ok. Когда дойдёт до базы ответов — она станет местом, где будет разбираться конкретика.**

:exclamation:**tg_ask — честная заглушка: сообщение шлёт, ответ НЕ ждёт, умирает с явным текстом. Цикл getUpdates с offset и таймаутом — следующий шаг, когда определитесь с TG_CONFIRM (например: 1 — всегда ждать, 0 — считать подтверждением сам факт отправки).**

> Дальше по плану — fwcmd_install: mktemp + curl на лету, самоудаление, проверка уже установленного. Гоним её?