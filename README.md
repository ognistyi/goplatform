# goplatform

CLI-інструмент, що виводить поточну платформу і архітектуру.

**Актуальна версія:**
```
 >>> Platform: darwin/amd64
     Version:  v0.3.0
```

**Якщо є оновлення:**
```
 >>> Platform: darwin/amd64
     Version:  v0.2.1

Нова версія доступна: v0.2.1 -> v0.3.0
Оновити: curl -fsSL https://raw.githubusercontent.com/ognistyi/goplatform/main/install.sh | sh
```

## Встановлення

**macOS / Linux:**
```sh
curl -fsSL https://raw.githubusercontent.com/ognistyi/goplatform/main/install.sh | sh
```

**Windows** (PowerShell):
```powershell
irm https://raw.githubusercontent.com/ognistyi/goplatform/main/install.ps1 | iex
```
Встановлює в `%LOCALAPPDATA%\Programs\goplatform\` і додає в `PATH`.

---

## Крос-компіляція в Go: як це працює

Go компілює одразу під будь-яку платформу **без жодних додаткових інструментів** — достатньо задати дві змінні середовища перед `go build`:

```bash
GOOS=linux GOARCH=arm64 go build -o goplatform-linux-arm64 .
```

`GOOS` — операційна система (`linux`, `darwin`, `windows`, ...).
`GOARCH` — архітектура (`amd64`, `arm64`, `386`, ...).

Go підтримує 47 комбінацій. Весь toolchain вбудований — зовнішній компілятор не потрібен.

### А в інших мовах?

| Мова       | Крос-компіляція                                                                 |
|------------|---------------------------------------------------------------------------------|
| **Go**     | Вбудована. Дві змінні — і готово.                                               |
| **Rust**   | Є, але складніша: потрібно встановити target (`rustup target add`) + лінкер для кожної платформи. Інструмент `cross` спрощує через Docker. |
| **C/C++**  | Потрібен окремий крос-компілятор (`arm-linux-gnueabihf-gcc` тощо) під кожну мішень. |
| **Node.js**| Не компілюється — потрібен рантайм на машині. `pkg`/`nexe` пакують рантайм всередину, але це не компіляція. |
| **PHP**    | Не застосовується — інтерпретатор.                                              |

Go виграє тут за простотою: немає залежності від системного лінкера, тому білд відтворюваний на будь-якій машині.

---

## GitHub Actions: як влаштовані хуки

GitHub Actions — це event-driven система. Кожен "хук" — це реакція на подію в репозиторії.

```
Подія в репо                   Файл-обробник
─────────────────────────────────────────────────────
push в гілку main          →   (не налаштовано)
відкриття pull request     →   (не налаштовано)
push тегу  v*              →   .github/workflows/release.yml  <-- наш випадок
```

Наш workflow файл:

```yaml
on:
  push:
    tags:
      - 'v*'          # спрацьовує тільки на теги виду v0.1.0, v2.3.1, ...
```

Тобто звичайні коміти та пуші в `main` **нічого не тригерять**. Лише `git push origin vX.Y.Z` запускає pipeline.

### Що відбувається після тригера

```
git push origin v1.0.0
        |
        v
GitHub отримує тег
        |
        v
Знаходить .github/workflows/release.yml
        |
        v
Запускає job на ubuntu-latest runner
        |
        ├── actions/checkout        -- клонує репо
        ├── actions/setup-go        -- встановлює Go (версія з go.mod)
        └── goreleaser-action       -- запускає GoReleaser
                |
                ├── читає .goreleaser.yml
                ├── go build x5  (5 платформ паралельно)
                ├── генерує checksums.txt
                └── gh release create  --  публікує GitHub Release
                        |
                        v
              https://github.com/ognistyi/goplatform/releases/tag/v1.0.0
              з 5 бінарниками + checksums.txt
```

`GITHUB_TOKEN` — автоматично вбудований у кожен workflow, вручну нічого налаштовувати не треба.

---

## Як працює інсталятор

### macOS / Linux — `install.sh`

```
curl -fsSL .../install.sh | sh
        │
        ├── 1. detect_platform()
        │      uname -s  →  linux / darwin
        │      uname -m  →  x86_64 → amd64 / aarch64 → arm64
        │
        ├── 2. fetch_latest_version()
        │      GET api.github.com/repos/ognistyi/goplatform/releases/latest
        │      → tag_name: "v1.2.0"
        │
        ├── 3. install_binary()
        │      strip 'v' → "1.2.0"  (GoReleaser не включає 'v' в ім'я файлу)
        │      filename: goplatform_1.2.0_darwin_amd64
        │      url:      github.com/.../releases/download/v1.2.0/goplatform_1.2.0_darwin_amd64
        │
        │      curl download → /tmp/goplatform
        │      chmod +x
        │      mv → /usr/local/bin/goplatform
        │
        └── 4. запускає /usr/local/bin/goplatform
```

### Windows — `install.ps1`

```
irm .../install.ps1 | iex
        │
        ├── 1. Invoke-RestMethod GitHub API → tag_name
        │
        ├── 2. Invoke-WebRequest → завантажує .exe
        │
        ├── 3. зберігає в %LOCALAPPDATA%\Programs\goplatform\goplatform.exe
        │
        ├── 4. додає цю папку в PATH (user-рівень, без адмін-прав)
        │
        └── 5. запускає goplatform.exe
```

### Як команда стає доступною в терміналі (PATH)

`PATH` — це змінна середовища зі списком директорій, які shell перевіряє коли ти вводиш команду без повного шляху.

```
goplatform
    │
    shell шукає виконуваний файл у кожній директорії з PATH:
    │
    ├── /usr/bin         → немає
    ├── /usr/local/bin   → є! → запускає
    └── ...
```

**macOS / Linux:** `/usr/local/bin` вже є в `PATH` за замовчуванням на будь-якій системі — тому після `mv` туди команда одразу доступна без перезапуску терміналу.

**Windows:** інсталятор додає `%LOCALAPPDATA%\Programs\goplatform` в PATH через реєстр (user-рівень, без прав адміністратора). Зміна PATH набуває чинності в **нових** вікнах терміналу — поточне вікно потрібно перезапустити.

```powershell
# Windows: якщо після встановлення команда не знайдена — просто відкрий новий термінал
# або тимчасово в поточному:
$env:PATH += ";$env:LOCALAPPDATA\Programs\goplatform"
```

---

## Механізм перевірки оновлень

При кожному запуску додаток перевіряє, чи є новіша версія на GitHub.

### Як версія потрапляє в бінарник

Go дозволяє "вшити" значення змінної під час компіляції через `-ldflags`:

```
go build -ldflags "-X main.version=v1.2.3" .
                          ^      ^
                          |      |
                     пакет.змінна  значення
```

GoReleaser робить це автоматично при кожному релізі:

```yaml
# .goreleaser.yml
ldflags:
  - -X main.version={{.Version}}   # підставляє тег, наприклад v0.2.0
```

Локальна збірка без ldflags залишає значення за замовчуванням — `"dev"`.

### Логіка перевірки при запуску

```
goplatform запущено
        |
        v
version == "dev"?  -->  так  -->  пропускаємо перевірку (локальна збірка)
        |
       ні
        |
        v
GET api.github.com/repos/ognistyi/goplatform/releases/latest
        |
        ├── помилка / таймаут 3с  -->  мовчки ігноруємо, не блокуємо вивід
        |
        v
release.TagName != version?
        |
        ├── ні   -->  нічого не виводимо
        |
        └── так  -->  виводимо повідомлення:
                      "Нова версія доступна: v0.1.0 -> v0.2.0"
                      "Оновити: curl ... | sh"
```

Перевірка **синхронна** з таймаутом 3 секунди. Якщо GitHub не відповів — додаток просто завершується без повідомлення про помилку.

---

## Випустити нову версію

```bash
# 1. Закомітити зміни
git add .
git commit -m "feat: your change"
git push origin main

# 2. Поставити тег і запушити -- це тригерить білд
git tag v1.2.3
git push origin v1.2.3

# 3. Слідкувати за білдом (опціонально)
gh run watch --repo ognistyi/goplatform

# 4. Оновити локальну версію після завершення білда
curl -fsSL https://raw.githubusercontent.com/ognistyi/goplatform/main/install.sh | sh
```

---

## Локальна збірка

```bash
# звичайна збірка
CGO_ENABLED=0 go build -o goplatform .
./goplatform
#  >>> Platform: darwin/amd64
#      Version:  dev
```

`CGO_ENABLED=0` — вимикає C-бібліотеки, збірка використовує чистий Go.
Потрібно на macOS через `net/http`: без цього прапора Go підтягує системний DNS-резолвер через CGO,
що на нових версіях macOS дає помилку `missing LC_UUID`.

```bash
# збірка з симуляцією конкретної версії (для тесту нотифікацій)
CGO_ENABLED=0 go build -ldflags "-X main.version=v0.1.0" -o goplatform .
./goplatform
#  >>> Platform: darwin/amd64
#      Version:  v0.1.0
#
#  Нова версія доступна: v0.1.0 -> v0.3.0
#  Оновити: curl -fsSL ...
```

### Крос-компіляція вручну

```bash
CGO_ENABLED=0 GOOS=linux   GOARCH=amd64 go build -o goplatform-linux-amd64 .
CGO_ENABLED=0 GOOS=linux   GOARCH=arm64 go build -o goplatform-linux-arm64 .
CGO_ENABLED=0 GOOS=darwin  GOARCH=arm64 go build -o goplatform-darwin-arm64 .
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o goplatform-windows-amd64.exe .
```
