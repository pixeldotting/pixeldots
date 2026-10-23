# CLAUDE.md: pixeldots

Постоянный контекст проекта. Дневника здесь нет: статус по модулям в `PROGRESS.md`, исследование дизайн-системы
в `docs/M3-EXPRESSIVE.md`, сырые выводы команд в `docs/logs/`. Язык общения с владельцем: русский.

## Репозиторий и имена

- GitHub: **github.com/pixeldotting/pixeldots** (`git remote add origin git@github.com:pixeldotting/pixeldots.git`). Каталог чекаута называть `pixeldots` (архивы собираются с `pixeldots/` внутри).
- Flake-вход: `github:pixeldotting/pixeldots`. Выходов `nixosConfigurations` нет, только модули (`nixosModules.default`, `homeManagerModules.default`) и пакеты, так что имя каталога на сборку не влияет.
- Имена `programs.material`, `qs -c material`, namespace `material-*` остаются как есть: это имя шелла, не репозитория.
- В логах `docs/logs/` и `PROGRESS.md` встречается старый путь `material-dots`: это сырой вывод, не править.

## Что это

Material You dotfiles для **NixOS** в духе Caelestia: Hyprland с конфигом на **Lua** (формат 0.55+) и собственный
шелл на **Quickshell** (QML). Цвета из обоев генерирует **matugen**. Бар, лаунчер, уведомления (попапы и центр),
центр управления, дашборд, локскрин и меню сессии, OSD, сайдбар, выбор обоев. Дополнительно: kitty, fish, starship,
GTK/Qt, курсор. Установщик: см. «TODO: УСТАНОВЩИК» (пока не начат).

## Команды

Проверки (работают офлайн, из корня репозитория; именно они прогонялись, см. `docs/logs/`):
```sh
texlua tools/harness.lua config/hypr                 # Lua-конфиг против строгого мока `hl` (мок написан мной, не настоящий Hyprland)
node tools/qmlcheck.js config/quickshell/material    # статическая проверка 64 QML-файлов (типы, импорты); это НЕ qmllint
for f in scripts/*.sh; do bash -n "$f"; done         # синтаксис скриптов
for f in flake.nix nix/*.nix; do nix-instantiate --parse "$f" >/dev/null; done   # только парсинг, не вычисление
```
Сборка и применение (на машине с сетью; **ни разу не выполнялось**, см. НЕ ГОТОВО):
```sh
nix flake lock                       # создаёт flake.lock (его пока нет)
nix flake check                      # вычисление flake
nix build .#material-theme .#material-screenshot
sudo nixos-rebuild switch --flake .#<host>     # или home-manager switch --flake .#<user>
nix fmt                              # nixfmt-rfc-style
```
Подключение из flake пользователя:
```nix
inputs.pixeldots.url = "github:pixeldotting/pixeldots";          # или "path:/home/<user>/pixeldots" для локального чекаута
inputs.pixeldots.inputs.nixpkgs.follows = "nixpkgs";
# в nixosSystem.modules:
pixeldots.nixosModules.default                                  # Hyprland>=0.55, pipewire, NM, bluetooth, upower, polkit, portals
# в home-manager.users.<user>.imports:
pixeldots.homeManagerModules.default
# и:
programs.material.enable = true;
programs.material.repoPath = "/home/<user>/pixeldots";            # необязательно: симлинки вне стора, правки без пересборки
```
Запуск и отладка на живой системе:
```sh
qs -c material                     # запуск шелла (Hyprland делает это сам из autostart.lua)
qs -c material log                 # лог Quickshell, первое место, куда смотреть
qs -c material ipc call <target> <function>     # IPC; на него повешены бинды
hyprctl configerrors               # ошибки Lua-конфига Hyprland
hyprctl reload
material-theme wallpaper <file> | random | mode dark|light|toggle | variant <scheme-name> | apply | init
material-screenshot region|full|window
```
`hyprland --verify-config` на Lua-конфиг не запускалась ни разу; точный флаг для 0.55+ проверить.

## Версии (что зафиксировано, что нет)

- **Hyprland**: нужен >= 0.55 (проверка assert в `nix/nixos.nix` по `programs.hyprland.package.version`). Точная версия не пинится.
- **Quickshell**: `git+https://git.outfoxxed.me/quickshell/quickshell`, **ревизия не зафиксирована**: `flake.lock` отсутствует. Шелл использует новые API (Bluetooth, Pam, UPower, IdleMonitor), так что нужен свежий master.
- **nixpkgs**: канал `nixos-unstable`. **home-manager**: master, `follows` nixpkgs. matugen из nixpkgs, версия неизвестна; шаблоны написаны под v3.
- Исполненное окружение разработки (песочница): Nix 2.34.6, texlua, node 22, git 2.43; **нет** qmllint, lua/lupa, shellcheck, Hyprland, Quickshell.

## Структура репозитория

```
flake.nix                  inputs + outputs (nixosModules.default, homeManagerModules.default, packages, formatter)
nix/{nixos,home,scripts}.nix   системный модуль / модуль home-manager (options.programs.material) / writeShellApplication-обёртки
scripts/*.sh               material-theme (состояние, matugen), material-screenshot
config/hypr/hyprland.lua   точка входа; модули в config/hypr/modules/*.lua (variables, env, monitors, input, look, animations, binds, rules, autostart, colors_fallback)
config/matugen/            config.toml + templates/ (shell.json, hypr.lua, kitty.conf, starship.toml, gtk.css, qt6ct.conf)
config/quickshell/material/  весь шелл, 64 QML-файла
  shell.qml                точка входа
  config/                  Appearance (токены), Colors, Config (~/.config/material/shell.json)
  components/              переиспользуемые виджеты (StyledText, StateLayer, Tile, M3Slider ...)
  services/                синглтоны: Audio, Brightness, Network, Notifs, Hypr, Media, Power, Wallpapers, Weather, ...
  modules/                 Drawers + PanelRegion, bar/, dashboard/, launcher/, notifications/, sidebar/, osd/, session/, wallpaper/, controlcenter/, lock/, Idle, Ipc
wallpapers/aurora.png      стартовые обои (сгенерированы кодом)
tools/                     harness.lua, qmlcheck.js (самодельные проверки)
docs/                      M3-EXPRESSIVE.md, logs/ (сырые выводы)
```
Соглашения:
- Один полноэкранный слой «Drawers» на монитор с маской (Region); внутри все панели, одновременно открыта одна (`Visibilities.active`). Layer namespace всех окон `material-*` (на него завязаны layer_rule).
- Бинды Hyprland вызывают Quickshell IPC, а не наоборот. Простой/блокировка/DPMS идут через `IdleMonitor` в Quickshell; **hypridle не используется**, не добавлять.
- QML: `qs.*` импорты, синглтоны `pragma Singleton`, цвета только из `Colors`, токены только из `Appearance` (магических чисел в компонентах быть не должно).
- Lua: каждый `require`-файл изолирован; общее передавать через возвращаемую таблицу (`modules.variables` отдаёт `V.ipc`, `V.qs`, `V.shell`). Пользовательские правки в необязательном `~/.config/hypr/user.lua` (подключается через `pcall(require)`).
- Цвета: `matugen image` пишет `~/.local/state/material/colors.json` (горячая перезагрузка в шелле), `~/.config/hypr/colors.lua` (gitignored), kitty, starship, GTK css, qt6ct. Состояние темы: `~/.local/state/material/state.json` (wallpaper, mode, variant).
- `.gitignore` содержит `*.log`: поэтому логи в `docs/logs/` называются `.txt`. Не переименовывать обратно.

## Грабли

- **`configType = "lua"` / `mkLuaInline` (home-manager).** Этот проект НЕ использует `wayland.windowManager.hyprland`: `nix/home.nix` линкует всю папку `~/.config/hypr` через `xdg.configFile."hypr"` (рекурсивная копия в стор или симлинк на чекаут при `repoPath`). **Не включать `wayland.windowManager.hyprland` в той же конфигурации**: HM напишет свой `hyprland.lua` (или `hyprland.conf`) в тот же каталог, будет конфликт. Если когда-нибудь переходить на генерацию из HM: опция `configType = "lua"` (по умолчанию значение не выяснено; `"hyprlang"` даёт старый `hyprland.conf`); `settings` превращается в Lua-таблицы, вызовы `bind`/`on`/`define_submap` оборачиваются в `_args`, переменные в `_var`, а сырой Lua, например `hl.dsp.exec_cmd("kitty")` или `mod .. " + T"`, передаётся через `lib.generators.mkLuaInline`; строки внутри `mkLuaInline` экранировать руками; конфиг раздувается (жалоба: ~100 строк → ~500); дополнительные модули через `extraLuaFiles` (+ `autoLoad`, работает только при `configType = "lua"`). Источники: [опция extraLuaFiles](https://mynixos.com/home-manager/option/wayland.windowManager.hyprland.extraLuaFiles), [обсуждение на NixOS Discourse](https://discourse.nixos.org/t/hyprland-inefficiet-lua-config/78217).
- **Где лежит `hyprland.lua` и что он перекрывает.** `~/.config/hypr/hyprland.lua` (в репозитории `config/hypr/hyprland.lua`). По сообщению на Discourse Hyprland читает `hyprland.lua` первым и откатывается на `hyprland.conf`, только если `.lua` нет. То есть наличие `.lua` перекрывает любой старый `hyprland.conf`. Это из форума, страницы вики 0.55 прочитать не удалось (binary data): перепроверить. Если Hyprland стартует без обоих файлов, он создаёт пример `hyprland.lua` вне контроля HM; удалить его перед первой активацией, иначе HM откажется перезаписывать файл. Hyprland Welcome на дефолтном Lua-конфиге ищет `hyprland.conf` (известная проблема, [обсуждение #15410](https://github.com/hyprwm/Hyprland/discussions/15410)).
- `colors.lua` генерируется matugen в `~/.config/hypr/` во время работы. В `look.lua` он подключается через `pcall(require, "colors")` с запасным `colors_fallback.lua`. При `repoPath` файл попадёт в чекаут (в `.gitignore`).
- **Имя «expressive» двусмысленно:** `scheme-expressive` (вариант палитры matugen/MCU) ≠ дизайн-система Material 3 Expressive. Детали в `docs/M3-EXPRESSIVE.md` §3.1.
- Каждый `require`-файл Lua изолирован, глобалов между ними нет.
- Песочница, где писался проект, режет сеть: GitHub (в т.ч. api.github.com) и git.outfoxxed.me дают 403 через прокси, PyPI недоступен. Поэтому `nix flake lock`, `nix build`, `pip install lupa/PySide6` провалились (см. `docs/logs/`). Не пытаться обходить, делать на машине с сетью.
- `hyprctl dispatch '<lua-выражение>'` и `hyprctl eval` используются в `services/Hypr.qml`; их семантику в 0.55 по документации не сверял (см. PROGRESS).

## НЕ ГОТОВО (порядок работ; детали в PROGRESS.md)

1. `flake.lock` нет, `nix flake check`/`nix build`/`nixos-rebuild` ни разу не запускались, `home.nix` и `nixos.nix` только распарсены. Сделать первым: `nix flake lock`, затем вычислить и поправить ошибки опций (особенно `gtk.gtk4.theme = null`).
2. Живой Hyprland >= 0.55 ни разу не запускался: `hyprctl configerrors`, значения `hl.dsp.window.fullscreen`, семантика `hyprctl dispatch/eval` для Lua.
3. Quickshell ни разу не запускался, QML не загружался (только самодельная статика). Прогнать `qs -c material log`, починить непроверенные API (`QsMenuAnchor anchor.item`, `Hyprland.activeToplevel.lastIpcObject`, `DesktopEntry.execute` для Terminal-приложений, Pam/Bluetooth/UPower).
4. Шаблоны matugen (v3-синтаксис, имена переменных, флаги `-m`/`-t`) не рендерились.
5. M3 Expressive не внедрён (пружины, новые радиусы, emphasized-веса): порядок в `docs/M3-EXPRESSIVE.md` §4.
6. `README.md` не написан.
7. Установщик не начат.

## TODO: УСТАНОВЩИК (замысел на будущее, не реализовано)

- **Бутстраппер на `.sh`**: скачивает wayland и зависимости установщика, компилирует его, запускает.
- **Установщик на C++**: на время работы сам становится композитором, запускается под `cage`.
- **Первый экран**: первичный сетап в пиксельном стиле; спрашивает часовой пояс и остальное.
- После ответов ставит приложения и зависимости.
- По завершении выходит из `cage` в готовый Hyprland + Quickshell.

## Правила для следующего агента

- Не заявлять «работает» без запуска; различать «написано», «статически проверено», «запущено» (как в PROGRESS.md).
- Сырые выводы упавших/предупреждающих команд сохранять целиком в `docs/logs/*.txt`, не пересказывать.
- Не рефакторить попутно; один коммит на одну задачу.
