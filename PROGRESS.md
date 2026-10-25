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
Правило из задачи: «готово» только то, что проверено. Здесь НИ ОДИН этап не ГОТОВ: в песочнице нет nix, qemu, KVM, GitHub и сети.
| Этап | Статус | Что проверено и чем | Чего нет |
|---|---|---|---|
| 1. `nixosConfigurations.iso` (база + рабочий стол, `nix/iso.nix`) | **ВЫЧИСЛЕНИЕ ПОДТВЕРЖДЕНО владельцем только для ПЕРВОЙ версии** (без cage и без пакетов live-сессии) | `nix flake check --no-build` у владельца: `all checks passed` (`iso-stage1-flake-check-owner.txt`) | Версия с cage и новыми пакетами (коммит `a0b2770`) **не вычислялась ни разу**. `nix build` образа и загрузка в QEMU не выполнены. |
| 2. Автозапуск live-сессии (`services.cage`, `pixeldots-live-session`) | **ЗАГЛУШКА: код написан, не вычислен, не загружен** | Баланс скобок (не парсер). Опции `services.cage.*` сверены с документацией (`iso-live-sources.txt`), но не на пине. UI в ISO-режиме прогнан без дисплея. | Вычисление, сборка, лог загрузки из QEMU, работа SDL2 под cage, `sudo -n` из сессии cage, Restart-политика юнита `cage-tty1`. |
| 3. Установка на диск (`installer/disks.sh`, `installer/install-iso.sh`, экраны Disk/Erase в UI) | **ЗАГЛУШКА: логика проверена на поддельных утилитах** | 58 + 12 утверждений с поддельными `parted`/`mkfs`/`mount`/`nixos-install`/`lsblk`; 5 мутантов пойманы; UI-сценарии (`iso-ui-tests.txt`, `iso-backend-tests.txt`) | Ни одного реального диска, `parted`, `mkfs`, `nixos-install`, `nixos-generate-config`. Сгенерированный `flake.nix`/`pixeldots-local.nix` никогда не вычислялся (только прочитан глазами и проверен баланс скобок). Установка в QEMU на виртуальный диск и загрузка с него не выполнены. |
| 4. GitHub Actions (`.github/workflows/iso.yml`) | **ЗАГЛУШКА: ни разу не запускался на GitHub** | YAML парсится, единственный триггер `workflow_dispatch`, `bash -n` всех шагов, шаг подготовки релиза прогнан локально на фальшивых ISO 100 МБ и 2,2 ГБ (`tools/test-iso-release-prep.sh`, `iso-workflow-and-nix-static.txt`) | Реальный запуск: сборка ISO на раннере, достаточность места, `gh release create`, размер настоящего ISO относительно лимита 2 GiB. |

Жёсткие требования из задачи и чем они проверены (без nix; реальная проверка вывода nixos-install не делалась):
- **Пароль только как `hashedPassword`, не в `.nix` и не на экране:** `install-iso.sh` хеширует до генерации файлов и обнуляет открытый пароль; тест ищет пароль во всех сгенерированных файлах, логе и записи вызовов (не найден); фильтр `$6$…` в скрипте и в UI; тест утечки падает на сборке БЕЗ фильтра (мутант). Оговорка: хеш лежит в `/nix/store` системы, это штатное поведение NixOS для `hashedPassword`.
- **Ввод проверяется ДО подстановки в Nix и ДО любых команд:** 23 негативных теста + контроль, что корректный запрос принимается; мутант «стирание до проверки» ловится.
- **Диск только из списка, после подтверждения:** по умолчанию не выбран ни один диск (UI: Space/клик), отдельный экран Erase с моделью, размером и устройством, переключатель всегда выключен и сбрасывается при возврате; бэкенд заново сверяет диск (имя, модель, размер) со списком `disks.sh` и требует `PD_ERASE_CONFIRM = PD_DISK`.
- **Не выдуманные опции:** источники в `iso-live-sources.txt`; НЕ на пинe nixpkgs.

Известные практические риски (не исправлены, решать владельцу):
- **Quickshell собирается из git при установке.** `nix/home.nix` берёт `inputs.quickshell.packages.<system>.default`, бинарный кэш в проекте не настроен, значит `nixos-install` на машине пользователя может часами компилировать Qt-проект. Варианты: Cachix из CI, либо пакет из nixpkgs.
- **Лимит релиза 2 GiB:** ISO с Hyprland и PipeWire может его превысить; workflow тогда режет на части (проверено только на фальшивых файлах).
- **Нужна сеть и ~4 ГБ RAM при установке** (входные flake скачиваются в живой /nix/store, который в RAM). Wi-Fi в мастере нет: для него `Ctrl+Alt+F2`, `nmtui`, назад `Ctrl+Alt+F1`.
- **Только UEFI.** BIOS-режим мастер отклоняет.
- **У установленной системы нет редактируемого чекаута** (`programs.material.repoPath` не задан, конфиг из стора).
- `flake-lock.yml` по cron (понедельник) делает `nix flake update` и коммитит лок: пины, под которые сверялся ISO, сдвинутся сами. Не менялся без решения владельца.

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
| ISO: UI в ISO-режиме (диск, пользователь, стирание, хеш в логе) + регрессия обычного визарда | `installer/pixeldots-installer-headless`, сценарии `tests/iso-*.txt`, `tests/flow|mouse|fail.txt`, контроли (мутант без фильтра падает) | OK; скриншоты 1920x1080 просмотрены | `iso-ui-tests.txt` |
| ISO: `disks.sh` | `tests/disks-test.sh` с поддельными `lsblk`/`findmnt` | 12/12; недоступный для проверки диск не предлагается (fail closed) | `iso-backend-tests.txt` |
| ISO: `install-iso.sh` | `tests/backend-test.sh` с поддельными утилитами, 5 мутантов | 58/58; мутанты пойманы 4/4 по смыслу + 1 после усиления теста | `iso-backend-tests.txt` |
| ISO: релизный шаг workflow | `tools/test-iso-release-prep.sh` (PyYAML, разреженные файлы), контроль «лишний триггер push → тест падает» | 11/11 | `iso-workflow-and-nix-static.txt` |
| ISO: баланс скобок в `flake.nix`, `nix/*.nix` и в сгенерированных файлах | самодельный скрипт (НЕ парсер Nix) | OK | `iso-workflow-and-nix-static.txt` |

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
- ISO целиком, кроме вычисления первой версии у владельца: версия с cage и пакетами live-сессии не вычислялась; сборка образа, загрузка в QEMU, разметка и `nixos-install` на настоящем диске, сгенерированные `flake.nix` и `pixeldots-local.nix` (опции `services.xserver.xkb.*`, `hashedPassword`, `home.activation.pixeldotsLook`, `xdg.configFile."hypr/user.lua"`, `follows`), запуск `.github/workflows/iso.yml`. Подробно в таблице ISO.
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
0. ISO: (а) `nix flake check --no-build` на текущем коммите (вычислит cage-сессию и новые пакеты) и приложить вывод; (б) `nix build .#nixosConfigurations.iso.config.system.build.isoImage` и загрузка в QEMU с UEFI (OVMF) и виртуальным диском >= 30 ГБ: прогнать мастер до конца, перезагрузиться с диска; (в) запустить workflow `iso` вручную на ветке. Решить вопрос с кэшем для Quickshell и с cron в `flake-lock.yml`.
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

### docs/logs/iso-ui-tests.txt

````text
$ make clean && make headless  (g++ -std=c++17 -Wall -Wextra)
g++ -O2 -std=c++17 -Wall -Wextra -Isrc src/app.cpp src/main_headless.cpp -o pixeldots-installer-headless
[make exit=0]

=== regression: the existing (non-ISO) wizard ===

$ tests/flow.txt
quit=1 exit=0 screen=done
[exit=0]

$ tests/mouse.txt
quit=1 exit=0 screen=done
[exit=0]

$ tests/fail.txt (FAKE_FAIL=1)
quit=1 exit=1 screen=failed
[exit=0]

=== ISO mode (PD_ISO=1, fake disks, fake backend, no sudo) ===

$ tests/iso-flow.txt: no default user/disk, explicit disk choice, erase confirmation resets on Back
quit=1 exit=0 screen=done
[exit=0]

$ tests/iso-nodisk.txt FAKE_DISKS=nouefi
quit=0 exit=0 screen=disk
[exit=0]

$ tests/iso-nodisk.txt FAKE_DISKS=none
quit=0 exit=0 screen=disk
[exit=0]

$ tests/iso-leak.txt: backend prints a $6$ hash, it must not reach the on-screen log
quit=1 exit=0 screen=done
[exit=0]

=== controls: the leak test must be able to fail ===

$ assertnolog on text that IS in the log (expect exit 4)
assertnolog failed for 'Installing'
[exit=4]

$ same leak test on a build WITHOUT the redaction (expect exit 4)
assertnolog failed for 'LEAKEDHASH'
[exit=4]

````

### docs/logs/iso-backend-tests.txt

````text
$ bash installer/tests/disks-test.sh   (fake lsblk/findmnt; no real disks)
ok   - offers nvme0n1 with a clean model and exact size
ok   - offers sda, squeezes the double blank in the model
ok   - sanitises a hostile model string (no quote, semicolon or pipe survives)
ok   - hides a disk under 20 GiB (sdb)
ok   - hides the installation medium: iso9660 (sdc)
ok   - hides a mounted disk (sdd)
ok   - hides a disk with active swap (sdg)
ok   - fails closed when lsblk cannot inspect a disk (sdh)
ok   - hides rom, loop and read-only devices
ok   - every line has exactly 5 fields
ok   - not UEFI: one ERR line and no disks
ok   - no disks at all: ERR line

passed: 12  failed: 0
[exit=0]

$ bash installer/tests/backend-test.sh   (fake parted/mkfs/mount/nixos-install; PD_DEV_DIR and PD_MNT point into a temp dir)
== dry run ==
ok   - dry run succeeds
ok   - dry run generated flake.nix and pixeldots-local.nix
ok   - hashedPassword is a sha-512 hash
ok   - the plaintext password is in no generated file, log or call record
ok   - no unreplaced @PLACEHOLDER@ left
ok   - host, user, tz, locale, layout, stateVersion substituted
ok   - apps resolved, unfree enabled because of discord
ok   - flake pins the ISO revision
ok   - dry run runs no tool
== invalid input is rejected BEFORE any command runs ==
ok   - control: the unmodified request is accepted (so the rejections below are not vacuous)
ok   - rejected: PD_HOSTNAME=a;b
ok   - rejected: PD_HOSTNAME=-bad
ok   - rejected: PD_HOSTNAME=has space
ok   - rejected: PD_HOSTNAME=x"y
ok   - rejected: PD_USER=Root
ok   - rejected: PD_USER=root
ok   - rejected: PD_USER=al"ice
ok   - rejected: PD_USER=1abc
ok   - rejected: PD_USER=a b
ok   - rejected: PD_TZ=Europe/Berlin;rm
ok   - rejected: PD_TZ=a b
ok   - rejected: PD_LAYOUT=us;x
ok   - rejected: PD_LAYOUT=US
ok   - rejected: PD_LOCALE=en_US
ok   - rejected: PD_MODE=blue
ok   - rejected: PD_VARIANT=scheme-x;y
ok   - rejected: PD_APPS=nope
ok   - rejected: PD_APPS=firefox,;x
ok   - rejected: PD_AUTOSTART=2
ok   - rejected: PD_DISK=sda;rm
ok   - rejected: PD_DISK=../sda
ok   - rejected: PD_DISK_SIZE=12x
ok   - rejected: PD_DISK_MODEL=ev"il
ok   - rejected: password too short
ok   - rejected: empty password
ok   - rejected: non-ASCII password
ok   - rejected: erase not confirmed (empty)
ok   - rejected: confirmation for another disk
ok   - error messages do not echo the password
== disk re-check ==
ok   - rejected: disk not offered by pixeldots-disks (and for that reason)
ok   - rejected: size changed since the user chose (and for that reason)
ok   - rejected: model changed since the user chose
ok   - rejected: not booted in UEFI mode
== real run with fake tools (sda) ==
ok   - succeeds
ok   - calls happen in the safe order
ok   - partitioning commands target only the chosen disk
ok   - no command mentions another disk
ok   - mkfs on partition 1 (FAT32 ESP) and 2 (ext4)
ok   - GPT, 1 GiB ESP, esp flag
ok   - nixos-install uses --root, --flake path:..#host and --no-root-passwd
ok   - config written into the target, configuration.nix removed
ok   - the hash printed by nixos-install is hidden in the output and the log
ok   - plaintext password nowhere
ok   - progress markers reach 100
== nvme naming ==
ok   - succeeds
ok   - partitions are nvme0n1p1 / nvme0n1p2
ok   - sda is untouched
== install failure ==
ok   - fails with a clear error and does not umount as if finished

passed: 58  failed: 0
[exit=0]

=== mutation checks: break the script on purpose, the tests must fail (results of the run above this log was made from) ===
mutant [no hostname regex]: passed: 54  failed: 4
mutant [no erase confirmation]: passed: 57  failed: 1
mutant [no disk re-check]: passed: 57  failed: 1
mutant [wipe before validation]: passed: 23  failed: 35
mutant [password echoed to the log]: passed: 55  failed: 3
restored original: passed: 58  failed: 0

$ bash -n installer/*.sh installer/tests/*.sh
ok installer/disks.sh
ok installer/install-iso.sh
ok installer/tests/backend-test.sh
ok installer/tests/disks-test.sh
ok installer/tests/fake-apply-iso.sh
ok installer/tests/fake-apply.sh
ok installer/tests/fake-disks.sh


````

### docs/logs/iso-workflow-and-nix-static.txt

````text
$ bash tools/test-iso-release-prep.sh   (runs the "Prepare release files" step on sparse fake ISOs; needs PyYAML)
ok   - small ISO: ok, one ISO + SHA256SUMS, tag exported
ok   - small ISO: notes do not mention splitting
ok   - big ISO: ok, tag generated
ok   - big ISO: split, no unsplit ISO left, every file under 2 GiB
ok   - big ISO: joined parts have the checksum SHA256SUMS lists for the whole ISO
ok   - big ISO: notes explain how to join
ok   - bad tag refused: a b
ok   - bad tag refused: x;rm
ok   - bad tag refused: ../x
ok   - bad tag refused: aaaaaaaaaaaaaaaaaaaa
ok   - no ISO built: refused

passed: 11  failed: 0
[exit=0]

$ yaml load + triggers + bash -n of every run: block
triggers: ['workflow_dispatch']
Free disk space bash -n ok
Build the ISO bash -n ok
Prepare release files bash -n ok
Publish release bash -n ok

$ python3 /tmp/nixbalance.py flake.nix nix/*.nix   (crude delimiter check, NOT a Nix parser)
balanced  flake.nix
balanced  nix/home.nix
balanced  nix/installer.nix
balanced  nix/iso.nix
balanced  nix/nixos.nix
balanced  nix/scripts.nix

$ sha256sum -c flake.lock (hash taken before the ISO work started)
flake.lock: OK
flake.lock identical to 04770e9

````

### docs/logs/iso-live-sources.txt

````text
# Откуда взято каждое решение для live-сессии, установки и релиза (поиск: инструмент web_search, 2026-10-24/25).
# Сеть песочницы закрыта, источники НЕ на пиннутой ревизии nixpkgs (02c087f3fe67): это те ревизии, что вернул поиск.
# Окончательная сверка с пином возможна только настоящим `nix flake check` / `nix build` (см. PROGRESS.md).

1. services.cage (автозапуск сессии вместо логина)
   - опции services.cage.{enable,user,program,extraArguments,environment}: nixos/modules/services/wayland/cage.nix
     https://github.com/NixOS/nixpkgs/blob/release-20.09/nixos/modules/services/wayland/cage.nix  (старая версия модуля)
     https://mynixos.com/nixpkgs/option/services.cage.environment                                   (опция есть в актуальном nixpkgs)
   - юнит называется cage-tty1, конфликтует с getty@tty1, PAM-сервис cage, wantedBy graphical.target (тот же файл).
   - ОТКРЫТО: Restart-политика юнита и точный текст модуля на пине не сверены; сессия-обёртка написана так, чтобы не зависеть от неё.

2. Живой пользователь nixos, sudo без пароля, автологин
   - PR #66338 «installer/no-root»: пользователь nixos, `security.sudo.wheelNeedsPassword = false` в profiles/installation-device.nix
     https://gitea.suzanne.soy/suzanne.soy/nixpkgs/commit/dd49cf711e3139fec2eca26f31c2ffd8b5c5873b
   - получается, что `sudo -n` из сессии cage работает без пароля. Не проверено на живом образе.

3. Установка по руководству NixOS (UEFI)
   - порядок: parted mklabel gpt → mkpart ESP fat32 → set N esp on → mkfs.fat -F 32 -n boot → mkfs.ext4 -L nixos → mount (boot с umask=077)
     → nixos-generate-config --root /mnt → nixos-install. boot.loader.systemd-boot.enable = true; boot.loader.efi.canTouchEfiVariables = true.
     https://github.com/NixOS/nixpkgs/blob/8cfce968b1a3a01d74421496a643caac6f3911ad/nixos/doc/manual/installation/installing.xml
     https://git.pub.solar/b12f/nixpkgs/commit/7fb52b1325a383b7bd83aa2552f6d9d57106d241
   - отличие от руководства: ESP 1 GiB вместо 512 MiB (больше запас под ядра), корень вторым разделом.
   - nixos-install --root DIR --flake URI#NAME --no-root-passwd (флаги --flake, --no-root-passwd):
     https://www.mankier.com/8/nixos-install
     https://github.com/NixOS/nixpkgs/blob/bb8b5735d6f7e06b9ddd27de115b0600c1ffbdb4/nixos/modules/installer/tools/nixos-install.sh
   - раскладка: services.xserver.xkb.{layout,options}, console.useXkbConfig
     https://wiki.nixos.org/wiki/Keyboard_Layout_Customization
     https://git.uninsane.org/colin/nixpkgs/src/commit/60e731d1ceb7343b1d137afe6b09f3f6409d701b/nixos/modules/config/console.nix
   - Home Manager: lib.hm.dag.entryBefore, home.activation, xdg.configFile (используются уже в nix/home.nix проекта, на пине вычисляются).
   - Не из документации, а из своего кода: `inputs.<имя>.follows = "pixeldots/<имя>"` (документированный механизм flake follows);
     имена входов nixpkgs/home-manager взяты из flake.nix проекта.

4. GitHub Releases
   - лимит: каждый файл релиза меньше 2 GiB, до 1000 файлов
     https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
     https://fast.io/resources/github-release-file-size-limit/
   - `gh release create <tag> <files> --target --title --notes-file --prerelease`
     https://cli.github.com/manual/gh_release_create
   - cachix/install-nix-action@v31 и actions/checkout@v4: те же версии, что в существующем .github/workflows/flake-lock.yml.
   - Список каталогов для освобождения места (/usr/share/dotnet, /usr/local/lib/android, /opt/ghc, ...) общеизвестный, НЕ сверен с образом раннера.

````
