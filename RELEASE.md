# Release Guide

## Як зробити реліз

```bash
git add .
git commit -m "feat: your change"
git push origin main

git tag v1.2.3
git push origin v1.2.3   # <-- це тригерить білд
```

Слідкувати за білдом:
```bash
gh run watch --repo ognistyi/goplatform
```

## Версіонування

`vMAJOR.MINOR.PATCH` ([semver](https://semver.org))

- `PATCH` — bug fix
- `MINOR` — нова фіча, зворотня сумісність збережена
- `MAJOR` — breaking changes

## Що відбувається після пушу тегу

GitHub запускає свіжу Ubuntu VM на Azure:

```
VM старт (порожня)
  ├── git clone репо
  ├── встановлює Go 1.21
  └── GoReleaser:
        ├── go build × 5 платформ
        ├── генерує checksums.txt
        └── gh release create → публікує артефакти
VM знищується
```

Результат: https://github.com/ognistyi/goplatform/releases

## Встановлення нової версії

**macOS / Linux:**
```sh
curl -fsSL https://raw.githubusercontent.com/ognistyi/goplatform/main/install.sh | sh
```

**Windows** (PowerShell):
```powershell
irm https://raw.githubusercontent.com/ognistyi/goplatform/main/install.ps1 | iex
```
