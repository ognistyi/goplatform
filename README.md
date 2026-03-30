# goplatform

CLI-інструмент, що виводить поточну платформу і архітектуру.

```
 >>> Platform: darwin/amd64
```

## Встановлення

```sh
curl -fsSL https://raw.githubusercontent.com/ognistyi/goplatform/main/install.sh | sh
```

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

`install.sh` — звичайний POSIX shell-скрипт. Логіка:

```
curl -fsSL .../install.sh | sh
        |
        v
1. detect_platform()
   uname -s  -->  linux / darwin / windows
   uname -m  -->  x86_64 -> amd64 / aarch64 -> arm64

        |
        v
2. fetch_latest_version()
   GET api.github.com/repos/ognistyi/goplatform/releases/latest
   --> tag_name: "v1.2.0"

        |
        v
3. install_binary()
   strip 'v'  -->  "1.2.0"   (GoReleaser не включає 'v' в ім'я файлу)

   filename:  goplatform_1.2.0_darwin_amd64
   url:       github.com/.../releases/download/v1.2.0/goplatform_1.2.0_darwin_amd64

   curl download --> /tmp/goplatform
   chmod +x
   mv /usr/local/bin/goplatform   (sudo якщо немає прав)

        |
        v
4. /usr/local/bin/goplatform   -- запускає встановлений бінарник
```

Чому `v` стрипається: GoReleaser використовує повний тег (`v1.2.0`) в URL, але **без `v`** в імені файлу. Це поведінка за замовчуванням GoReleaser — в скрипті це враховано явно.

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
go build -o goplatform .
./goplatform
```

Крос-компіляція вручну:

```bash
GOOS=linux GOARCH=arm64 go build -o goplatform-linux-arm64 .
```
