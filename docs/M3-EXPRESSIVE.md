# Material 3 Expressive: выжимка для этого проекта

Составлено 2026-10-23. Помечено, что проверено по первоисточнику (✔), что взято из вторичного источника или
логического вывода (≈), и что я знаю по памяти, но страницы не открывал (?). Сайт m3.material.io целиком
рендерится JavaScript'ом и через WebFetch отдаёт только пустую оболочку, поэтому его спецификации читались
через исходники реализаций (androidx, material-components-android, material-color-utilities), а не со страниц сайта.

## 1. Откуда взялось

| Факт | Статус | Источник |
|---|---|---|
| **Material You** показан 18 мая 2021 с первой бетой Android 12: «единый язык дизайна», палитра вытягивается из обоев (dynamic color) | ✔ | [Google, Android 12 beta](https://blog.google/products/android/android-12-beta/) |
| **M3 Expressive** анонсирован 13 мая 2025 (Google I/O 2025), заявлен для Android 16 и Wear OS 6, первыми на Pixel | ✔ | [Google, M3 Expressive для Android и Wear OS](https://blog.google/products-and-platforms/platforms/android/material-3-expressive-android-wearos-launch/) |
| Заявленная база: 46 исследований, сотни дизайнов, 18 000+ участников, работа идёт с 2022 | ✔ (заявление Google) | [Google Design, research](https://design.google/library/expressive-material-design-google-research) |
| Состав обновления по версии Google: более яркий цвет, более смелая форма, «более естественная пружинная» анимация, акцентная (emphasized) типографика, отзывчивые компоненты | ✔ | блог Android (ссылка выше) |

Итого: Expressive это **не новая система, а расширение M3** (M3 вышел в 2021 как «Material You»). Палитра
из обоев осталась, добавились токены формы, физика движения, эмфатическая типографика и несколько компонентов.

## 2. Что говорит само исследование (и где маркетинг)

Из [Google Design](https://design.google/library/expressive-material-design-google-research):
- Предпочтение expressive-вариантов во всех возрастных группах, до 87% у 18–24 лет.
- Eye tracking: ключевые элементы находят «до 4 раз быстрее»; кнопка «Отправить» крупнее и заметнее нашлась в 4 раза быстрее.
- Оговорки самой Google, они важны для нас: контекст решает; убирание текстовых подписей ухудшило юзабилити;
  незнакомый паттерн (плейлист без привычного списка) выглядел современнее, но проиграл по юзабилити;
  заметное меньшинство предпочитает спокойный дизайн; цитата: «No amount of expressive design will beat basic functionality».

≈ Вывод: цифры получены на мобильных интерфейсах (тапы, фиксации взгляда на экране телефона). На десктопной
панели с мышью и постоянным набором иконок «в 4 раза быстрее» переносить нельзя. Это обоснование для телефона,
а не для бара Hyprland.

## 3. Чем отличается от обычного M3

### 3.1 Цвет / палитры
- Базовая система ролей M3 (primary/secondary/tertiary + container, 5 уровней surface container, surface dim/bright, fixed-роли) уже была до Expressive. ✔ [Color.md](https://github.com/material-components/material-components-android/blob/master/docs/theming/Color.md). Surface container вместо elevation-оверлеев используется с material-components 1.11.0-alpha02. ✔
- Список вариантов схем (enum `Variant`): MONOCHROME, NEUTRAL, TONAL_SPOT, VIBRANT, EXPRESSIVE, FIDELITY, CONTENT, RAINBOW, FRUIT_SALAD, CMF. ✔ [variant.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/variant.ts)
- **Ловушка имён:** вариант `EXPRESSIVE` (matugen: `scheme-expressive`) это отдельная схема генерации палитры, в её описании сказано «intentionally detached from the source color» (оттенки сознательно отвязаны от исходного цвета). ✔ [scheme_expressive.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/scheme/scheme_expressive.ts). Это не то же самое, что дизайн-система «M3 Expressive». Когда в этом проекте пишут «expressive», нужно уточнять, о чём речь. В какой версии MCU появился вариант, не проверял.
- Реальная «expressive»-правка цвета в спецификации 2025: в `color_spec_2025.ts` для разных вариантов отличаются множители хромы нейтральных поверхностей (например surface_container_highest: TONAL_SPOT ×1.7, EXPRESSIVE ×1.6 или ×2.3 для жёлтых оттенков, VIBRANT ×1.29) и правила выбора тона primary/tertiary с отдельными случаями для жёлтого и голубого оттенков. ✔ [color_spec_2025.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/color_spec_2025.ts). Точные hue-ротации палитр в этих исходниках не нашёл (они в базовом классе), поэтому утверждать, как именно «расходятся» оттенки, не буду.
- По версии Google Design: «более смелое использование цвета», включая вторичный цвет для ключевых действий. ✔ (общая формулировка)
- Поддержка в matugen: типы `-t`: scheme-content, scheme-expressive, scheme-fidelity, scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow, scheme-tonal-spot, по умолчанию tonal-spot. ✔ но это релиз v2.0.0 ([release notes](https://newreleases.io/project/github/InioX/matugen/release/v2.0.0)); актуальность для версии из nixpkgs и использует ли она спецификацию 2025: **не проверено**.

### 3.2 Форма
- Шкала радиусов (✔ [Shape.md](https://github.com/material-components/material-components-android/blob/master/docs/theming/Shape.md)): None 0, ExtraSmall 4, Small 8, Medium 12, Large 16, **LargeIncreased 20**, ExtraLarge 28, **ExtraLargeIncreased 32**, **ExtraExtraLarge 48**, Full 50%. Жирным выделены значения, которых не было в первом M3 (≈ вывод по названиям «Increased»; страница их не помечает как Expressive).
- `MaterialShapes`: библиотека из **35 готовых форм** (Circle, Square, Slanted, Arch, Fan, Arrow, SemiCircle, Oval, Pill, Triangle, Diamond, ClamShell, Pentagon, Gem, Sunny, VerySunny, Cookie4/6/7/9/12Sided, Ghostish, Clover4/8Leaf, Burst, SoftBurst, Boom, SoftBoom, Flower, Puffy, PuffyDiamond, PixelCircle, PixelTriangle, Bun, Heart), помечена `@material3expressive`. ✔ [MaterialShapes.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MaterialShapes.kt)
- Морфинг: `Morph` из `androidx.graphics.shapes` сопоставляет «углы» (features) двух `RoundedPolygon`, разрезает кубические кривые так, чтобы у каждой было ровно одна парная, и линейно интерполирует пары кубиков по `progress`. ✔ [Morph.kt](https://github.com/androidx/androidx/blob/androidx-main/graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/Morph.kt)
- Морф формы кнопки при нажатии/переключении, размеры кнопок XS–XL, круглая и квадратная формы: **не подтвердил** (страница Button.md это не описывает) (?).

### 3.3 Motion (самое существенное отличие)
Раньше: пары «easing + duration» (7 кривых, 16 длительностей от 50 до 1000 мс). Теперь добавлена физика: шесть
пружин = {fast, default, slow} × {spatial, effects}. ✔ [Motion.md](https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md) (нужна версия 1.13.0+).

- **spatial**: двигает/меняет размер/поворачивает; допускает перелёт (damping < 1).
- **effects**: цвет, прозрачность; перелёта нет (damping = 1).
- Скорость выбирается по размеру компонента/пути: переключатель fast, частичный экран default, полный экран slow.

Точные значения из исходников Compose (`StandardMotionTokens.kt` и `ExpressiveMotionTokens.kt`), ✔:

| Пружина | Standard damping / stiffness | **Expressive** damping / stiffness |
|---|---|---|
| fast spatial | 0.9 / 1400 | **0.6 / 800** |
| default spatial | 0.9 / 700 | **0.8 / 380** |
| slow spatial | 0.9 / 300 | **0.8 / 200** |
| fast effects | 1.0 / 3800 | 1.0 / 3800 |
| default effects | 1.0 / 1600 | 1.0 / 1600 |
| slow effects | 1.0 / 800 | 1.0 / 800 |

То есть «expressive» = те же effects-пружины, но spatial-пружины заметно мягче и «пружинистее»
(damping 0.6 против 0.9 у fast). Источники: [StandardMotionTokens](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/StandardMotionTokens.kt), [ExpressiveMotionTokens](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ExpressiveMotionTokens.kt), [MotionScheme.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MotionScheme.kt).

### 3.4 Типографика
- Шкала: 15 ролей (Display/Headline/Title/Body/Label × L/M/S) в двух наборах: baseline и **emphasized**. ✔ [Typography.md](https://github.com/material-components/material-components-android/blob/master/docs/theming/Typography.md)
- Emphasized отличается от baseline только весом (размеры те же): Display/Headline/Title Large и Body ступенькой выше (Regular → Medium), Title Medium/Small и Label (Medium → Bold). ✔ Назначение: иерархия, выбор, действия, редакторские заголовки.
- Variable font (Roboto Flex), оси ROND/wdth/opsz: в доступных мне документах **не упомянуты**, не утверждаю (?).

### 3.5 Компоненты
- ✔ Wavy-индикаторы прогресса (линейный и круговой, determinate и indeterminate; рекомендовано trackThickness 8dp, trackCornerRadius 4dp, circular indicatorSize 52dp), themes `Theme.Material3Expressive.*` с версии material-components `1.14.0` ([ProgressIndicator.md](https://github.com/material-components/material-components-android/blob/master/docs/components/ProgressIndicator.md), [getting-started.md](https://github.com/material-components/material-components-android/blob/master/docs/getting-started.md)). Сам репозиторий помечен как «maintenance mode», рекомендуют Compose.
- ✔ Button groups, split buttons, toggle button groups (только названия на странице Button.md); floating toolbar и крупные кнопки с увеличенными областями нажатия, высококонтрастное «containment» (Google Design).
- ? Loading indicator, FAB menu, expanded navigation rail: знаю по памяти, страницы не открывал.

## 4. Что реально применимо в QML/Quickshell, а что маркетинг

Контекст: в проекте сейчас токены движения это cubic-bezier (`config/quickshell/material/config/Appearance.qml`:
`spatial: [0.38, 1.21, 0.22, 1, 1, 1]` имитирует перелёт кривой, а не физикой), SpringAnimation не используется;
радиусы `xs 8 / sm 12 / md 16 / lg 24 / xl 32 / full`; Tile уже меняет радиус по `checked`.

| Идея M3E | Вердикт | Как в QML |
|---|---|---|
| Spatial/effects-пружины | **Применимо, главное** | `SpringAnimation` (`spring`, `damping`, `mass`, `epsilon`) вместо `NumberAnimation`+bezier. Параметры Compose (damping ratio, stiffness) в `spring`/`damping` QML **напрямую не переносятся**: формулу QML не проверял, значения придётся подбирать на глаз или считать. Effects-пружины (damping 1, без перелёта) спокойно заменяются обычной ease-out кривой, пружина там не нужна. |
| Шкала радиусов с 20/32/48 | **Применимо, тривиально** | добавить токены в `Appearance.rounding` (20, 28, 32, 48). |
| Морф формы при нажатии/выборе | **Применимо в простом виде** | анимировать `Rectangle.radius` (прямоугольник ↔ «таблетка») пружиной. Уже сделано зачатками в Tile. |
| Морф между 35 формами (RoundedPolygon) | **В основном маркетинг для шелла** | возможен через `Shape` + `PathCubic`, интерполируя массивы кубиков в JS, но дорого в реализации; оправдан максимум для 1–2 мест (аватар, индикатор загрузки). |
| Emphasized-типографика | **Применимо, тривиально** | в `StyledText` брать вес Medium/Bold для заголовков и действий; наличие весов Medium/Bold в пакете шрифта Rubik из nixpkgs не проверял. |
| Варианты палитры (`scheme-expressive` и др.) | **Применимо сразу** | `material-theme variant scheme-expressive` уже есть; помнить про ловушку имён (§3.1). |
| Wavy progress / слайдеры | **Применимо, средняя цена** | `Shape` с `PathSvg`/`PathPolyline` или `Canvas`, анимация фазы; красиво в MediaCard и ползунках, но необязательно. |
| Крупные области нажатия, «в 4 раза быстрее» | **Для десктопа маркетинг** | исследование про тачскрин; для мыши и бара не переносится. |
| Floating toolbar, FAB menu, button groups | **Почти не нужно** | мобильные паттерны; наш аналог (плавающий pill-бар) уже есть. |
| Убрать подписи ради чистоты | **Не делать** | сама Google показала ухудшение юзабилити. |

Рекомендуемый порядок внедрения (когда дойдут руки): (1) токены радиусов, (2) пресеты пружин `Appearance.anim.spatial*`/`effects*`
и замена `Anim`/`CAnim`, (3) пружинный морф радиуса в Tile/IconButton/Chip, (4) emphasized-веса, (5) по желанию wavy-слайдер.

## 5. Источники

- Google, Android 12 beta (Material You, 2021): https://blog.google/products/android/android-12-beta/
- Google, M3 Expressive launch (13.05.2025): https://blog.google/products-and-platforms/platforms/android/material-3-expressive-android-wearos-launch/
- Google Design, исследование: https://design.google/library/expressive-material-design-google-research
- Сайт спецификации (нужен JS, не читается инструментом): https://m3.material.io/blog/building-with-m3-expressive
- material-components-android: [Motion](https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md), [Shape](https://github.com/material-components/material-components-android/blob/master/docs/theming/Shape.md), [Typography](https://github.com/material-components/material-components-android/blob/master/docs/theming/Typography.md), [Color](https://github.com/material-components/material-components-android/blob/master/docs/theming/Color.md), [ProgressIndicator](https://github.com/material-components/material-components-android/blob/master/docs/components/ProgressIndicator.md), [getting-started](https://github.com/material-components/material-components-android/blob/master/docs/getting-started.md)
- androidx: [MotionScheme.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MotionScheme.kt), [ExpressiveMotionTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ExpressiveMotionTokens.kt), [StandardMotionTokens.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/StandardMotionTokens.kt), [MaterialShapes.kt](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MaterialShapes.kt), [Morph.kt](https://github.com/androidx/androidx/blob/androidx-main/graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/Morph.kt)
- material-color-utilities: [README](https://github.com/material-foundation/material-color-utilities), [variant.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/variant.ts), [scheme_expressive.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/scheme/scheme_expressive.ts), [color_spec_2025.ts](https://github.com/material-foundation/material-color-utilities/blob/main/typescript/dynamiccolor/color_spec_2025.ts)
- matugen: https://github.com/InioX/matugen , релиз v2.0.0 со списком `-t`: https://newreleases.io/project/github/InioX/matugen/release/v2.0.0
