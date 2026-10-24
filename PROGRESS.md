# PROGRESS.md: статус по модулям

Состояние на 2026-10-24. Постоянные сведения о проекте в `CLAUDE.md`; здесь только статус.

Шкала (важно: слово «готово» здесь **не** означает «работает»):
- **ГОТОВО**: код написан целиком и проходит доступные статические проверки. Ни один модуль ни разу не запускался в настоящем Hyprland/Quickshell.
- **ЗАГЛУШКА**: упрощено или зависит от того, чего нельзя проверить.
- **НЕ НАЧАТО**: кода нет.

## 1. Статус модулей

### Nix / сборка
| Модуль | Статус | Заметки |
|---|---|---|
| `flake.nix` | ГОТОВО (парсился раньше; добавленный `nixosConfigurations.iso` НЕ парсился, нет nix) | `flake.lock` есть в репозитории (его создал CI, коммит `04770e9`), пины: nixpkgs `02c087f3fe67`, home-manager `6750249c6996`, quickshell `9b0f339b1905`. |
| `nix/nixos.nix` | ГОТОВО (парсится, не вычислялся) | assert на Hyprland >= 0.55; pipewire, NetworkManager, bluetooth, upower, power-profiles-daemon, polkit + user-сервис hyprpolkitagent, порталы, dconf. |
| `nix/home.nix` | ГОТОВО (парсится, не вычислялся) | Самый рискованный файл: опции home-manager (`gtk.gtk4.theme = null`, `gtk.gtk4.extraCss`), `xdg.configFile` для целых каталогов, activation `material-theme init`. |
| `nix/scripts.nix` | ГОТОВО (парсится, не собирался) | `writeShellApplication` оборачивает скрипты и проверяет их shellcheck'ом при сборке; shellcheck локально нет, так что **возможны ошибки сборки** из-за его замечаний. |
| `scripts/material-theme.sh` | ГОТОВО (`bash -n`) | Команды init/wallpaper/random/mode/variant/apply. Не запускался: matugen, jq, dconf, hyprctl в песочнице нет. |
| `scripts/material-screenshot.sh` | ГОТОВО (`bash -n`) | region/full/window через grim/slurp/wl-copy. Не запускался. |

### Hyprland (Lua)
| Модуль | Статус | Заметки |
|---|---|---|
| `hyprland.lua` + `modules/*.lua` (variables, env, monitors, input, look, animations, binds, rules, autostart, colors_fallback) | ГОТОВО (мок-харнесс) | Выполняется целиком с моком `hl` с и без `colors.lua`: 92 `bind`, 17 `window_rule`, 2 `layer_rule`, 8 `animation`, 16 `env`. Мок написан по документации, список методов задан мной: проходит то, что я считаю API. Настоящий Hyprland не запускался. |
| Значения `hl.dsp.window.fullscreen` | НЕ ПОДТВЕРЖДЕНО | В `binds.lua` использованы режимы «fullscreen»/«maximized», по документации не сверялись. |
| `monitors.lua` | ЗАГЛУШКА | Одна общая запись монитора (авто); конфигурации под конкретные мониторы нет. |

### matugen
| Модуль | Статус | Заметки |
|---|---|---|
| `config/matugen/config.toml` + 6 шаблонов | ГОТОВО (не рендерились) | Шаблоны (shell.json, hypr.lua, kitty.conf, starship.toml, gtk.css, qt6ct.conf) написаны под синтаксис v3; имена переменных и флаги `-m`/`-t` не сверялись с реальной версией. Пользовательские цвета green/yellow заданы в config.toml. |

### Quickshell (QML, 64 файла, около 4800 строк)
| Модуль | Статус | Заметки |
|---|---|---|
| `shell.qml`, `config/` (Appearance, Colors, Config) | ГОТОВО | Токены форм/шрифтов/движения; M3 Expressive не внедрён (см. §3). |
| `components/` (13 штук) | ГОТОВО | StyledText, MaterialIcon, StateLayer, Tile, M3Slider, ProgressRing, ... |
| `services/` (13 синглтонов) | ГОТОВО | Audio, Brightness, Network (nmcli), Notifs, SystemUsage, Weather (wttr.in, нужна сеть, оффлайн-запасного варианта нет), Wallpapers, Media, Power, Lockscreen, Hypr, Time, Visibilities. |
| `modules/Drawers`, `PanelRegion`, `Idle`, `Ipc` | ГОТОВО | Ядро: один слой на монитор с маской, IPC, простой через `IdleMonitor`. Самое рискованное место: логика `Region`-маски и фокус-грабов. |
| `modules/bar` | ГОТОВО | Вертикальный pill-бар: workspaces, active window, tray, notif, часы, статусы. |
| `modules/launcher` | ГОТОВО | Приложения, `=calc`, `>actions`, `:clipboard`. Запуск `Terminal=true` приложений через `DesktopEntry.execute` не подтверждён. |
| `modules/notifications` | ГОТОВО | Попапы + центр (через `NotificationServer`). |
| `modules/dashboard` | ГОТОВО | Часы, календарь, медиа, ресурсы, gauge. |
| `modules/controlcenter` | ГОТОВО | Wifi/Bluetooth/Audio/Power-панели; Bluetooth через `Quickshell.Bluetooth`, API не подтверждён. |
| `modules/sidebar`, `osd`, `session`, `wallpaper` | ГОТОВО | Сайдбар, OSD, меню сессии, выбор обоев. |
| `modules/lock` | ГОТОВО (самое чувствительное) | `WlSessionLock` + `PamContext`, сервис PAM «login». Ошибка в локскрине может заблокировать сессию: тестировать в вложенном/тестовом режиме, не на единственной сессии. |
| `modules/background` | ГОТОВО | Обои через Quickshell с плавным переходом. |

### Прочее
| Что | Статус |
|---|---|
| Стартовые обои `wallpapers/aurora.png` | ГОТОВО (сгенерированы кодом, ~3 МБ) |
| Курсор, GTK, Qt (qt6ct), kitty, fish, starship | ГОТОВО в Nix-модуле, не запускались |
| `README.md` | НЕ НАЧАТО |
| Установщик: `installer/src` (UI на C++), `installer/apply.sh`, `installer/bootstrap.sh`, `nix/installer.nix` | ГОТОВО (UI и apply.sh прогнаны без дисплея и без Nix; см. ниже) | Всё сценарий-тестируется офлайн, но на NixOS не запускалось. `main_sdl.cpp` (окно, мышь, ресайз) компилировался только против самописной заглушки SDL2, `nix/installer.nix` и правка `flake.nix` не парсились (нет nix в песочнице). |
| Применение M3 Expressive (пружины, радиусы 20/32/48, emphasized-веса) | НЕ НАЧАТО (исследование готово: `docs/M3-EXPRESSIVE.md`) |
| `flake.lock` | ЕСТЬ в репозитории (создан workflow `flake-lock.yml`, не мной); в песочнице получить не удалось (сеть), см. §2 |
| Тесты | НЕТ; `tools/` только самодельные проверки |

### ISO (live-образ) — этапы 1-4 (подробности и требования в `CLAUDE.md`, раздел «ISO»)
| Этап | Статус | Что есть / чего нет |
|---|---|---|
| 1. `nixosConfigurations.iso` (`nix/iso.nix`, выход в `flake.nix`) | **ЗАГЛУШКА: код написан, ни разу не вычислялся и не собирался** | Нет доказательств, которые вы требовали: `nix build` не выполнен, образ в QEMU не загружен (в песочнице нет nix, qemu, KVM и сети; `iso-env-probe.txt`). Проверено только: баланс скобок самодельным скриптом (не парсер), `flake.lock` не изменён (хеш и `git diff`), источники решений собраны (`iso-stage1-sources.txt`, **не на пиннутой ревизии nixpkgs**). Риск: assert Hyprland >= 0.55 в `nix/nixos.nix` на пиннутом nixpkgs; конфликты опций `installation-cd-base.nix` с `nixosModules.default` не исключены; точный состав `installation-cd-base.nix` на ревизии 2026 года не сверен. |
| 2. Автозапуск live-сессии (cage + GUI) | НЕ НАЧАТО | |
| 3. Установка на диск | НЕ НАЧАТО | |
| 4. GitHub Actions: Release + освобождение места | НЕ НАЧАТО | Существующий `flake-lock.yml` не трогался. |

## 2. Что проверено и чем

### Проверено (запускалось, вывод в `docs/logs/`)
| Что | Чем | Результат | Лог |
|---|---|---|---|
| Lua-конфиг Hyprland исполняется без ошибок | `texlua tools/harness.lua config/hypr`: **самодельный** строгий мок `hl`, не lupa и не Hyprland | OK с fallback-цветами и со сгенерированными | `lua-harness.txt` |
| QML: типы/импорты/ссылки на id/скобки | `node tools/qmlcheck.js`: **самодельная** статика, не qmllint | OK, 64 файла | `qmlcheck.txt` |
| Синтаксис shell-скриптов | `bash -n` | OK, 2 файла | `bash-n-scripts.txt` |
| Синтаксис Nix | `nix-instantiate --parse`, 4 файла | OK (только парсинг, не вычисление) | `nix-parse.txt` |
| UI установщика в стиле Google Pixel: 12 экранов, клавиатура и мышь, поиск в списках, валидация, дочерний процесс, прогресс, провал + повтор | `installer/pixeldots-installer-headless` (тот же `app.cpp`, что в SDL-сборке) со сценариями `tests/flow.txt`, `tests/mouse.txt`, `tests/fail.txt` и заглушкой `tests/fake-apply.sh`; скриншоты 1920x1080 и 1080x2400 просмотрены глазами и сверены с присланным скриншотом мастера Pixel | OK. Первая версия была пиксель-артом (недоразумение), переделана. Найдено и исправлено: «Fran??ais» (нет Latin-1 в шрифте), пятна слишком огромные в портрете, подпись слишком близко к заголовку, аватар перекрывал имя | `installer-headless.txt` |
| `apply.sh`: валидация, генерация `flake.nix` + `pixeldots-local.nix`, хеш пароля, `user.lua`, `state.json` | `PD_DRY_RUN=1` с поддельным `/etc/nixos`; в песочнице root, поэтому проверка «не root» отключена в dry-run | OK; пароль в открытом виде нигде не появляется (`grep -c`), `a;b` как hostname и неизвестный id приложения отклоняются | `installer-dry-run.txt` |
| Синтаксис `installer/*.sh`; `main_sdl.cpp` | `bash -n`; `g++ -fsyntax-only` с самописной заглушкой `SDL2/SDL.h` | OK (для SDL: только имена и типы, не настоящий API) | `installer-checks.txt` |
| ISO этап 1: баланс скобок/строк в `flake.nix`, `nix/*.nix` | самодельный скрипт (НЕ `nix-instantiate --parse`, nix в песочнице нет) | OK для 6 файлов; это НЕ проверка синтаксиса Nix | `iso-stage1-static.txt` |
| `flake.lock` не изменён этапом 1 | `sha256sum -c` по хешу, снятому до правок + `git diff --quiet -- flake.lock` | OK | `iso-stage1-static.txt` |

Ранний `qmlcheck.js` нашёл 10 проблем (неразрешённый тип `Anim`, ссылки на `id: panel`, несбалансированные скобки в `Weather.qml`); все исправлены до этой сессии. Исходный вывод в `earlier-session-failures.txt`.

### Попытки проверки, которые не удались
| Что хотели | Чем | Почему не вышло | Лог |
|---|---|---|---|
| `flake.lock` (в песочнице; позже его создал CI) | `nix flake lock` | api.github.com → 403 («GitHub access … not enabled for this session»); git.outfoxxed.me → CONNECT 403 | `nix-flake-lock.txt`, `net-probe.txt` |
| ISO этап 1: `nix build .#nixosConfigurations.iso.config.system.build.isoImage` и загрузка в QEMU | не запускалось | В песочнице нет nix, qemu-system-x86_64, xorriso, mksquashfs, `/dev/kvm`; 1 CPU, 4 ГБ RAM, ~10 ГБ диска; DNS не резолвится (curl exit 6), pip и apt тоже. Сборка ISO здесь невозможна в принципе. | `iso-env-probe.txt` |
| ISO этап 1: `nix-instantiate --parse` новых файлов | не запускалось | nix не установлен (в более ранней песочнице был 2.34.6) | `iso-env-probe.txt` |
| `nix build` / `nix flake check` | не запускались (без lock и сети бессмысленно) | | |
| Настоящий Lua (lupa) | `pip install lupa` | PyPI недоступен; через прокси 403 | `pip-lupa.txt`, `earlier-session-failures.txt` |
| `qmllint` | PySide6 (`pip install PySide6-Essentials`) | PyPI недоступен | `pip-pyside6.txt`, `missing-tools.txt` |
| shellcheck | отсутствует в системе | | `missing-tools.txt` |
| `hyprland --verify-config` | Hyprland не установлен | | `missing-tools.txt` |
| Запуск Quickshell / matugen | не установлены | | `missing-tools.txt` |
| Fengari (Lua на JS) / npm | `npm install fengari` | registry.npmjs.org недоступен | `earlier-session-failures.txt` |

### Написано БЕЗ проверки (ни разу не запускалось)
- ISO этап 1 целиком: `nix/iso.nix` + `nixosConfigurations.iso` (вычисление, сборка, загрузка). Ожидаемые риски перечислены в таблице ISO выше.
- Google Sans Flex как шрифт установщика: `tools/gen-font-sdf.py` умеет оси вариативных шрифтов (проверено на Lora-Variable), но самого файла Flex не было, в атласе по-прежнему Outfit.
- Установщик на живой системе: `nix build .#pixeldots-installer-session` (SDL2 из nixpkgs, `cage`), SDL2 на Wayland под `cage` (окно, текстовый ввод, масштаб), `nixos-rebuild switch` на сгенерированном flake, `sudo -n` после `sudo -v`, `exec Hyprland` через login-shell. Сгенерированные `.nix` только прочитаны глазами: `services.xserver.xkb.*`, `pixeldots.inputs.nixpkgs` и `.inputs.home-manager` из подключаемого flake, дедупликация `hardware-configuration.nix` при двойном импорте, `hashedPassword` при `mutableUsers`, `hl.config` из `user.lua` поверх `input.lua`.
- Вычисление и сборка любого Nix-кода; опции home-manager (`gtk.gtk4.theme = null` и др.); результат `writeShellApplication` + shellcheck.
- Любой QML на загрузку и в рантайме. Особо сомнительные API: `QsMenuAnchor` (`anchor.item`), `Hyprland.activeToplevel.lastIpcObject`, `DesktopEntry.execute` для Terminal-приложений, `PamContext`/`WlSessionLock`, `Quickshell.Bluetooth`, `Mpris`, `UPower`, `NotificationServer`, `IdleMonitor`.
- Семантика `hyprctl dispatch '<lua>'` и `hyprctl eval` (используются в `services/Hypr.qml`), `hyprctl reload` для выхода из game mode.
- Значения `hl.dsp.window.fullscreen`; реальные имена и сигнатуры функций `hl.*` вообще (только по документации, мок проверяет мои же вызовы).
- Шаблоны matugen и флаги CLI; запись в `~/.config/gtk-4.0/colors.css` и т.д.
- Работа PAM-сервиса «login» для локскрина на NixOS.
- Всё про приоритет `hyprland.lua` над `hyprland.conf`: из форума, не из вики.

## 3. Что делать дальше (порядок)

1. На машине с сетью (flake.lock уже есть, не пересоздавать): `nix flake check` → `nix build .#material-theme .#material-screenshot`; исправить ошибки опций. 
2. Поставить Hyprland >= 0.55 и Quickshell; `hyprctl configerrors`; исправить Lua; сверить `fullscreen` и `hyprctl dispatch/eval`.
3. `qs -c material log`, починить QML по месту (начать с `Drawers`, `PanelRegion`, `bar`); локскрин проверять последним и осторожно.
4. Прогнать `matugen` на `aurora.png`, убедиться, что все 7 выходов создаются.
5. Внедрить M3 Expressive по `docs/M3-EXPRESSIVE.md` §4.
6. Написать `README.md`.
0. ISO этап 1: на машине с nix выполнить две команды из `CLAUDE.md` («ISO»), приложить вывод; либо запушить в main и посмотреть `nix flake check --no-build` в workflow `flake-lock` (это даст вычисление, но не сборку и не QEMU). Только после этого этап 2.
7. Установщик: запустить `bash installer/bootstrap.sh --dry-run`, затем без флагов в ВМ с NixOS (`--software`), не на основной системе; починить по логу `~/.local/state/pixeldots-installer/install.log`.

## 4. Приложение: сырые выводы (целиком, без сокращений)

Те же файлы лежат в `docs/logs/`. Здесь продублированы для читающего только этот файл.

### docs/logs/lua-harness.txt

````text
$ texlua tools/harness.lua config/hypr
fallback colours (no colors.lua): OK
  calls: animation=8 bind=92 config=2 curve=5 dsp.exec_cmd=32 dsp.focus=18 dsp.group.next=1 dsp.group.toggle=1 dsp.layout=1 dsp.window.center=1 dsp.window.close=1 dsp.window.drag=1 dsp.window.float=1 dsp.window.fullscreen=2 dsp.window.kill=1 dsp.window.move=25 dsp.window.pin=1 dsp.window.resize=5 dsp.workspace.toggle_special=1 env=16 exec_cmd=5 gesture=1 layer_rule=2 monitor=1 on=1 window_rule=17
generated colours: OK
  calls: animation=8 bind=92 config=2 curve=5 dsp.exec_cmd=32 dsp.focus=18 dsp.group.next=1 dsp.group.toggle=1 dsp.layout=1 dsp.window.center=1 dsp.window.close=1 dsp.window.drag=1 dsp.window.float=1 dsp.window.fullscreen=2 dsp.window.kill=1 dsp.window.move=25 dsp.window.pin=1 dsp.window.resize=5 dsp.workspace.toggle_special=1 env=16 exec_cmd=5 gesture=1 layer_rule=2 monitor=1 on=1 window_rule=17
  exec_cmd(dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user start hyprpolkitagent.service)
  exec_cmd(material-theme init)
  exec_cmd(qs -c material)
  exec_cmd(wl-paste --type text  --watch cliphist store)
  exec_cmd(wl-paste --type image --watch cliphist store)
[exit=0]

````

### docs/logs/qmlcheck.txt

````text
$ node tools/qmlcheck.js config/quickshell/material
OK: 64 QML files, no problems found
[exit=0]

````

### docs/logs/bash-n-scripts.txt

````text
$ bash -c for f in scripts/*.sh; do echo "bash -n $f"; bash -n "$f" && echo ok; done
bash -n scripts/material-screenshot.sh
ok
bash -n scripts/material-theme.sh
ok
[exit=0]

````

### docs/logs/nix-parse.txt

````text
$ bash -c for f in flake.nix nix/*.nix; do echo "nix-instantiate --parse $f"; nix-instantiate --parse "$f" >/dev/null && echo ok; done
nix-instantiate --parse flake.nix
ok
nix-instantiate --parse nix/home.nix
ok
nix-instantiate --parse nix/nixos.nix
ok
nix-instantiate --parse nix/scripts.nix
ok
[exit=0]

````

### docs/logs/nix-flake-lock.txt

````text
error:
       … while updating the lock file of flake 'path:/home/claude/material-dots?lastModified=1792671163&narHash=sha256-nJCrPowvgQ48HbMn9Zq2Th5hdEp/eP9M3wDJ/B1e2bs%3D'

       … while updating the flake input 'home-manager'

       … while fetching the input 'github:nix-community/home-manager'

       error: unable to download 'https://api.github.com/repos/nix-community/home-manager/commits/HEAD': HTTP error 403

       response body:

       {"message":"GitHub access to this repository is not enabled for this session. Use add_repo to request access. If add_repo answers that read access is already available and you need GitHub API or write access, call add_repo again with access:\"push\" to attach the repository with credentials.","documentation_url":"https://docs.anthropic.com/en/docs/claude-code/github-actions"}
exit=1

````

### docs/logs/net-probe.txt

````text
curl: (56) CONNECT tunnel failed, response 403
outfoxxed http=000
github http=403

````

### docs/logs/pip-lupa.txt

````text
$ pip install --break-system-packages lupa
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f08979bd160>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/lupa/
WARNING: Retrying (Retry(total=3, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f0897b52490>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/lupa/
WARNING: Retrying (Retry(total=2, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f0897b52710>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/lupa/
WARNING: Retrying (Retry(total=1, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f0897b52990>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/lupa/
WARNING: Retrying (Retry(total=0, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f0897b52c10>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/lupa/
ERROR: Could not find a version that satisfies the requirement lupa (from versions: none)
ERROR: No matching distribution found for lupa
[exit=1]

````

### docs/logs/pip-pyside6.txt

````text
$ pip install --break-system-packages PySide6-Essentials
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f65f53e1400>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/pyside6-essentials/
WARNING: Retrying (Retry(total=3, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f65f55fa850>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/pyside6-essentials/
WARNING: Retrying (Retry(total=2, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f65f55faad0>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/pyside6-essentials/
WARNING: Retrying (Retry(total=1, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f65f55fad50>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/pyside6-essentials/
WARNING: Retrying (Retry(total=0, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7f65f55fafd0>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/pyside6-essentials/
ERROR: Could not find a version that satisfies the requirement PySide6-Essentials (from versions: none)
ERROR: No matching distribution found for PySide6-Essentials
[exit=1]

````

### docs/logs/missing-tools.txt

````text
$ command -v qmllint
(not found)
$ command -v qmlformat
(not found)
$ command -v pyside6-qmllint
(not found)
$ command -v lua
(not found)
$ command -v luajit
(not found)
$ command -v lupa
(not found)
$ command -v shellcheck
(not found)
$ command -v Hyprland
(not found)
$ command -v hyprland
(not found)
$ command -v quickshell
(not found)
$ command -v qs
(not found)
$ command -v matugen
(not found)

````

### docs/logs/earlier-session-failures.txt

````text
# Сырые выводы упавших/предупреждавших команд из ранней части сессии (до сжатия контекста).
# Источник: журнал сессии. Вывод приведён целиком; тело длинных heredoc-команд обрезано до 300 символов (в логе только команды, не вывод).
# Хронологически: 46 (генерация обоев, информативно), 48-51 (сеть/pip/npm/nix), 124 (qmlcheck.js нашёл 10 проблем, все исправлены).

===== tool result #46 (журнал, строка 131), is_error=False =====
$ python3 - <<'EOF'
# Procedural default wallpaper (pure python, no deps): soft multi-blob gradient on dark base.
import zlib, struct, math, random
W,H=1920,1080
random.seed(7)
blobs=[(0.22,0.30,0.55,(124,92,255)),(0.78,0.22,0.45,(255,110,170)),(0.62,0.80,0.60,(40,190,200)),(0.10,0.85,0.40,(90,120,255 [...команда обрезана]
--- вывод (полностью) ---
3063 KiB
total 3072
drwxr-xr-x 2 root root    4096 Oct 21 23:54 .
drwxr-xr-x 6 root root    4096 Oct 21 23:53 ..
-rw-r--r-- 1 root root 3137116 Oct 21 23:54 aurora.png
WARNING: Retrying (Retry(total=0, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7fbbe7817250>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/lupa/
ERROR: Could not find a version that satisfies the requirement lupa (from versions: none)
ERROR: No matching distribution found for lupa

===== tool result #48 (журнал, строка 141), is_error=False =====
$ cat /root/.config/pip/pip.conf; echo ---; curl -sS http://127.0.0.1:43165/__agentproxy/status | head -30
--- вывод (полностью) ---
cat: /root/.config/pip/pip.conf: No such file or directory
---
{
  "enabled": true,
  "port": 43165,
  "caBundlePath": "/root/.ccr/ca-bundle.crt",
  "hasSystemCa": true,
  "bundleCoversEveryHost": true,
  "noProxy": "localhost,127.0.0.1,::1,127.0.0.0/8,0.0.0.0/8,::,169.254.0.0/16,api.anthropic.com,api-staging.anthropic.com,api-pr-preview.anthropic.com,mcp-proxy.anthropic.com,mcp-proxy-staging.anthropic.com,registry.npmjs.org,jsr.io,npm.jsr.io,pypi.org,files.pythonhosted.org,index.crates.io,proxy.golang.org,host.docker.internal,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10,.svc.cluster.local,*.svc.cluster.local",
  "selective": false,
  "standalone": false,
  "toolScoped": false,
  "installedProxyPreconfiguredClis": [
    "bq",
    "gcloud",
    "gh",
    "gsutil"
  ],
  "javaTrustStorePath": "/etc/ssl/certs/java/cacerts",
  "javaTrustStoreType": "JKS",
  "readmePath": "/root/.ccr/README.md",
  "gitConfigInjection": true,
  "gitSshRewrite": true,
  "recentRelayFailures": [],
  "downloadQueuedBytes": 0,
  "downloadQueuedPeakBytes": 0,
  "downloadReceivePauseSupported": true,
  "downloadReceiveGateEnabled": true,
  "uploadPausedClients": 0,
  "uploadPauses": 0,
  "uploadPauseSupported": true,
  "uploadGateEnabled": true,

===== tool result #49 (журнал, строка 149), is_error=False =====
$ S=/tmp/claude-0/-home-claude/74278f5d-b604-534f-b3a3-35137dadc5af/scratchpad; mkdir -p $S/pylibs; env -u no_proxy -u NO_PROXY pip install --break-system-packages --quiet --target $S/pylibs --proxy "$HTTPS_PROXY" --cert /root/.ccr/ca-bundle.crt lupa 2>&1 | tail -3; ls $S/pylibs | head
--- вывод (полностью) ---
WARNING: Retrying (Retry(total=0, connect=None, read=None, redirect=None, status=None)) after connection broken by 'ProxyError('Cannot connect to proxy.', OSError('Tunnel connection failed: 403 Forbidden'))': /simple/lupa/
ERROR: Could not find a version that satisfies the requirement lupa (from versions: none)
ERROR: No matching distribution found for lupa

===== tool result #50 (журнал, строка 154), is_error=False =====
$ S=/tmp/claude-0/-home-claude/74278f5d-b604-534f-b3a3-35137dadc5af/scratchpad; mkdir -p $S/npm && cd $S/npm && npm init -y >/dev/null 2>&1; npm install fengari --silent 2>&1 | tail -2; ls node_modules | head -3; echo ---nix; cd /home/claude && timeout 90 nix --extra-experimental-features 'nix-command [...команда обрезана]
--- вывод (полностью) ---
ls: cannot access 'node_modules': No such file or directory
---nix
warning: unable to download 'https://channels.nixos.org/flake-registry.json': Failure when receiving data from the peer (56) CONNECT tunnel failed, response 403; retrying in 1269 ms (attempt 3/5)
warning: unable to download 'https://channels.nixos.org/flake-registry.json': Failure when receiving data from the peer (56) CONNECT tunnel failed, response 403; retrying in 2137 ms (attempt 4/5)
error: unable to download 'https://channels.nixos.org/flake-registry.json': Failure when receiving data from the peer (56) CONNECT tunnel failed, response 403

===== tool result #51 (журнал, строка 159), is_error=False =====
$ S=/tmp/claude-0/-home-claude/74278f5d-b604-534f-b3a3-35137dadc5af/scratchpad; cd $S/npm && npm install fengari 2>&1 | tail -8; cd /home/claude/material-dots; echo ---; timeout 60 nix --extra-experimental-features 'nix-command flakes' flake metadata github:NixOS/nixpkgs/nixos-unstable --no-use-regist [...команда обрезана]
--- вывод (полностью) ---
npm error errno ENOTFOUND
npm error network request to https://registry.npmjs.org/fengari failed, reason: getaddrinfo ENOTFOUND registry.npmjs.org
npm error network This is a problem related to network connectivity.
npm error network In most cases you are behind a proxy or have bad network settings.
npm error network
npm error network If you are behind a proxy, please make sure that the
npm error network 'proxy' config is set properly.  See: 'npm help config'
npm error A complete log of this run can be found in: /home/claude/.npm/_logs/2026-10-21T18_55_27_695Z-debug-0.log
---

       response body:

       {"message":"GitHub access to this repository is not enabled for this session. Use add_repo to request access. If add_repo answers that read access is already available and you need GitHub API or write access, call add_repo again with access:\"push\" to attach the repository with credentials.","documentation_url":"https://docs.anthropic.com/en/docs/claude-code/github-actions"}

===== tool result #124 (журнал, строка 438), is_error=True =====
$ S=/tmp/claude-0/-home-claude/74278f5d-b604-534f-b3a3-35137dadc5af/scratchpad; cat > $S/test/qmlcheck.js <<'EOF'
// Static sanity checker for the Quickshell config (no QML toolchain available offline).
const fs = require('fs'), path = require('path');
const root = process.argv[2];
const files = [];
( [...команда обрезана]
--- вывод (полностью) ---
Exit code 1
modules/Drawers.qml: unresolved type Anim
modules/PanelRegion.qml: reference to id 'panel' not declared in this file
modules/PanelRegion.qml: reference to id 'panel' not declared in this file
modules/PanelRegion.qml: reference to id 'panel' not declared in this file
modules/PanelRegion.qml: reference to id 'panel' not declared in this file
modules/PanelRegion.qml: reference to id 'panel' not declared in this file
modules/PanelRegion.qml: reference to id 'panel' not declared in this file
modules/bar/ActiveWindow.qml: unresolved type Anim
modules/bar/ActiveWindow.qml: unresolved type Anim
services/Weather.qml: unbalanced brackets (1)

10 problem(s)

````

### docs/logs/iso-env-probe.txt

````text
$ date -u
Sat Oct 24 05:24:32 UTC 2026

$ command -v for the tools stage 1 needs
nix: NOT FOUND
nix-build: NOT FOUND
nix-instantiate: NOT FOUND
nix-store: NOT FOUND
qemu-system-x86_64: NOT FOUND
qemu-img: NOT FOUND
xorriso: NOT FOUND
mksquashfs: NOT FOUND
genisoimage: NOT FOUND
grub-mkrescue: NOT FOUND
docker: NOT FOUND
podman: NOT FOUND

$ ls -l /dev/kvm
ls: cannot access '/dev/kvm': No such file or directory

$ nproc; free -m; df -h /
1
               total        used        free      shared  buff/cache   available
Mem:            3995         186        3901          14          54        3808
/dev/vda        252G  8.7G  9.9G  47% /

$ network probes (curl -m 10)
https://cache.nixos.org/nix-cache-info -> 000
curl exit 6
https://github.com -> 000
curl exit 6
https://raw.githubusercontent.com/NixOS/nixpkgs/master/README.md -> 000
curl exit 6
https://channels.nixos.org -> 000
curl exit 6
https://pypi.org/simple/pip/ -> 000
curl exit 6
http://archive.ubuntu.com/ubuntu/ -> 000
curl exit 6

$ pip download probe
ERROR: Could not find a version that satisfies the requirement tree-sitter-nix (from versions: none)
ERROR: No matching distribution found for tree-sitter-nix

$ apt probe
W: Download is performed unsandboxed as root as file '/home/claude/p/pixeldots/qemu-system-x86_1%3a8.2.2+ds-0ubuntu1.16_amd64.deb' couldn't be accessed by user '_apt'. - pkgAcquire::Run (13: Permission denied)
E: Failed to fetch http://security.ubuntu.com/ubuntu/pool/main/q/qemu/qemu-system-x86_8.2.2%2bds-0ubuntu1.16_amd64.deb  Could not resolve 'archive.ubuntu.com'

````

### docs/logs/iso-stage1-static.txt

````text
$ python3 /tmp/nixbalance.py flake.nix nix/*.nix   (crude delimiter check, NOT nix-instantiate --parse: nix is not installed in this sandbox)
balanced  flake.nix
balanced  nix/home.nix
balanced  nix/installer.nix
balanced  nix/iso.nix
balanced  nix/nixos.nix
balanced  nix/scripts.nix
[exit=0]

$ sha256sum -c flake.lock hash recorded before any edit (d5139479...)
flake.lock: OK

$ git diff --stat -- flake.lock  (empty = unchanged vs HEAD)
flake.lock: no diff vs HEAD

$ git log --oneline -- flake.lock
04770e9 flake.lock: update

$ pinned inputs in flake.lock
nixpkgs: rev 02c087f3fe673c9e317f206a627cb6b910336dbe
home-manager: rev 6750249c69969d09d952efaf3fab88a2bdac7ec6
quickshell: rev 9b0f339b19057f4731bf3b48293307d7ef241671

````

### docs/logs/iso-stage1-sources.txt

````text
# Откуда взято каждое решение в nix/iso.nix и flake.nix (этап 1). Поиск шёл через инструмент web_search 2026-10-24;
# сеть песочницы закрыта, поэтому ВСЕ эти источники НЕ на пиннутой ревизии nixpkgs (02c087f3fe673c9e317f206a627cb6b910336dbe), а на
# тех ревизиях, что вернул поиск. Окончательная сверка с пином возможна только настоящим `nix eval`/`nix build` (см. PROGRESS.md).

1. Каркас `nixpkgs.lib.nixosSystem { modules = [ ... imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-*.nix") ]; ]; }`
   и результат в `config.system.build.isoImage`:
   - https://wiki.nixos.org/wiki/Creating_a_NixOS_live_CD/en  (пример с exampleIso и modulesPath)
   - https://github.com/NixOS/nixpkgs/issues/21840  (`nix-build -A config.system.build.isoImage`)

2. Почему installation-cd-base.nix, а не installation-cd-minimal.nix:
   - minimal ставит `fonts.fontconfig.enable = lib.mkForce false;` и `isoImage.edition = lib.mkForce "minimal";`
     (текст файла в копии https://github.com/LunNova/nixos-configs/blob/dev/nixos-minimal-installer.nix, она переписана с nixpkgs;
     оригинал nixpkgs в поиск не попал; сам `environment.noXlibs` / fontconfig см. также
     https://git.uninsane.org/colin/nixpkgs/src/commit/46b6619cb39e7e4d68c61aab724157ba27a8f94d/nixos/modules/config/no-x-libs.nix)
   - графические ISO импортируют тот же base: `imports = [ ./installation-cd-base.nix ];` в
     https://github.com/NixOS/nixpkgs/blob/8f366cbfcc62871f481e035984e5932e30d8b0ed/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix
   - состав base (iso-image.nix, profiles/all-hardware.nix, profiles/base.nix, profiles/installation-device.nix, isoImage.makeEfiBootable,
     isoImage.makeUsbBootable, swapDevices/fileSystems через mkImageMediaOverride): СТАРАЯ версия файла, spectrum-os.org archive:
     https://spectrum-os.org/git/nixpkgs/tree/nixos/modules/installer/cd-dvd/installation-cd-base.nix?h=archive
     (содержимое на пиннутой ревизии 2026 года мог измениться: не проверено)

3. NetworkManager и wpa_supplicant:
   - графические ISO: `networking.networkmanager.enable = true; networking.wireless.enable = mkForce false;` (PR #42610)
     https://github.com/NixOS/nixpkgs/pull/42610/files ; позже `lib.mkImageMediaOverride false`
     https://code.ornl.gov/nix/nixpkgs/-/commit/ace5ad92a24db91b3a56242b37ad873bac24d0ab
   - 25.11: NM включается уже в installation-cd-base.nix, блок убран из graphical-base (коммит «nixos/installer: ship the minimal ISO with networkmanager»)
     https://code.fizz.buzz/talexander/nixpkgs/commit/75fff53d96b2d2fa26be1dcb76c03b7823c9816f.diff
   => `networking.networkmanager.enable = true;` + `networking.wireless.enable = lib.mkForce false;` корректны и до, и после этого изменения.

4. `nixpkgs.hostPlatform` в модуле (без аргумента `system`):
   - в собственном flake.nix nixpkgs: тест `nixosSystemAcceptsLib` с `nixpkgs.hostPlatform = "x86_64-linux";`, `system` задаётся модульно
     https://github.com/NixOS/nixpkgs/blob/master/flake.nix
   - https://flake.parts/options/flake-parts.html («system is not needed ... or set nixpkgs.hostPlatform in a module»)

5. Нового flake input НЕ добавлялось (nixos-generators не использован): любой новый input изменил бы flake.lock, что запрещено.

````
