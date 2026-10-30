#!/usr/bin/env bash
# ============================================================
#  Cookie Hunter — публикация проекта на GitHub одной командой
#
#  Что делает:
#    1) Создаёт красивые файлы репозитория: README.md, .gitignore,
#       LICENSE (MIT), requirements.txt (старые сохраняет как *.old-...)
#    2) Чистит только мусорные кэши (__pycache__ и т.п.),
#       НЕ трогает датасет, venv и ваши файлы
#    3) Создаёт свежую git-историю и коммитит ТОЛЬКО нужное:
#       код, data.yaml, classes.txt, best.pt и лучший результат обучения
#    4) Публикует на GitHub (HTTPS + Personal Access Token)
#
#  Использование:
#     bash push_to_github.sh             # полная публикация
#     bash push_to_github.sh --no-push   # подготовить коммит без push (превью)
#
#  Настройка (при желании отредактируйте ниже):
# ============================================================
set -euo pipefail

REPO_NAME="cookie-hunter"
# Файлы весов, которые попадут в репозиторий (можно дописать свои, напр. "bestvt1.pt"):
MODEL_FILES=("best.pt")

# ---------- Оформление вывода ----------
C_G="\033[1;32m"; C_Y="\033[1;33m"; C_R="\033[1;31m"; C_B="\033[1;36m"; C_0="\033[0m"
info() { echo -e "${C_B}▸${C_0} $*"; }
ok()   { echo -e "${C_G}✔${C_0} $*"; }
warn() { echo -e "${C_Y}!${C_0} $*"; }
die()  { echo -e "${C_R}✘ $*${C_0}"; exit 1; }

NO_PUSH=0
if [ "${1:-}" = "--no-push" ]; then NO_PUSH=1; fi

# ---------- 0. Проверки ----------
command -v git >/dev/null 2>&1 || die "git не установлен. Установите его и запустите снова."
[ -f app.py ] || die "Запустите скрипт из папки проекта (рядом с app.py)."

echo -e "${C_B}"
cat <<'BANNER'
  ____ ___  _  _ _____ _     _____  _    ____  _   _ _   _
 / ___/ _ \| \| |_   _| |   | _ \ \/ /  |  _ \/_\ \ \ / / |
| (_| (_) | .` | | | | |__ |   / >  <   | | / _ \ \ V /| |__
 \___\___/|_|\_| |_| |____|_|_\/_/\_\  |_|_\_/ \_\ \_/ |____|
        YOLOv8 cookie detector  ->  GitHub
BANNER
echo -e "${C_0}"

# ---------- 1. Вопросы ----------
read -rp "GitHub username: " GITHUB_USER || GITHUB_USER=""
[ -n "$GITHUB_USER" ] || die "Нужен GitHub username."
read -rp "Имя автора для LICENSE [${GITHUB_USER}]: " AUTHOR || AUTHOR=""
AUTHOR="${AUTHOR:-$GITHUB_USER}"
YEAR="$(date +%Y)"

# ---------- 2. Бэкапы существующих файлов ----------
TS="$(date +%Y%m%d-%H%M%S)"
backup() {
  if [ -f "$1" ]; then
    mv "$1" "$1.old-$TS"
    warn "Существующий $1 сохранён как $1.old-$TS"
  fi
}
backup README.md
backup .gitignore
backup LICENSE
backup requirements.txt

# ---------- 3. Генерация файлов репозитория ----------
info "Создаю .gitignore, requirements.txt, LICENSE, README.md ..."

cat > .gitignore <<'EOF_GI'
# ========== Python environments ==========
.venv/
.venv-*/
venv/
env/

# ========== Python caches ==========
__pycache__/
*.py[cod]
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/
.ipynb_checkpoints/

# ========== Datasets (kept locally, never published) ==========
images/
labels/
screenshots/
screenshots_augmented/
logs/
*.cache

# ========== IDE / OS ==========
.vscode/
.idea/
.DS_Store

# ========== Backup copies made by push_to_github.sh ==========
*.old-*

# ========== Model weights: publish ONLY best.pt ==========
*.pt
*.ptmx
!best.pt

# ========== Training runs: keep only the best result ==========
runs/**
!runs/**/
!runs/**/weights/best.pt
EOF_GI

cat > requirements.txt <<'EOF_REQ'
# Object detection
ultralytics>=8.0.0

# Computer vision
opencv-python>=4.8.0

# Fast screen capture
mss>=9.0.1

# Arrays
numpy>=1.24.0

# Mouse control
pyautogui>=0.9.54
# Linux X11 note: if pyautogui complains, install python3-tk and scrot
EOF_REQ

cat > LICENSE <<EOF_LIC
MIT License

Copyright (c) ${YEAR} ${AUTHOR}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF_LIC

cat > README.md <<'EOF_README'
<div align="center">

# 🍪 Cookie Hunter

**Real-time screen object detection bot powered by YOLOv8**

Finds 🍪 cookies and ⚡ upgrades on the screen and clicks them automatically.

![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)
![YOLOv8](https://img.shields.io/badge/YOLOv8-Ultralytics-FF6600)
![OpenCV](https://img.shields.io/badge/OpenCV-Computer%20Vision-5C3EE8?logo=opencv&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?logo=linux&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-22c55e)

</div>

## ✨ Features

- 🎯 **Custom YOLOv8 model** trained to detect two classes: `cookie` and `upgrade`
- 🖥️ **Real-time screen capture** with `mss` — fast and lightweight
- 🧠 **Confidence filtering** (default threshold `0.7`) to avoid false clicks
- 🎮 **Priority-based clicking** — the `Game` class decides what to click first
- 🖱️ **Automatic mouse control** via `pyautogui`

## 🧠 How it works

1. `mss` grabs a screenshot of the screen.
2. The `Upgrade` class runs YOLOv8 inference on the frame (`ultralytics`).
3. Detections are filtered by class ID and confidence:

   | Class ID | Name | Description |
   |:---:|:---|:---|
   | `0` | `cookie` | 🍪 the main target |
   | `1` | `upgrade` | ⚡ available upgrade |

4. The center of each detection box is computed and the `Game` class clicks the highest-priority target.

## 🚀 Quick start

```bash
# 1. Clone the repository
git clone https://github.com/__GITHUB_USER__/cookie-hunter.git
cd cookie-hunter

# 2. Create a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run
python app.py
```

> The trained model weights are included in the repository (`best.pt`) — no extra downloads needed.

## 🏋️ Training your own model

The dataset layout is described in `data.yaml` (classes: `cookie`, `upgrade`).

```bash
python train.py
```

After training the best weights are saved to `runs/<train>/weights/best.pt` —
only this best checkpoint is kept in the repository.

## 📁 Project structure

```
cookie-hunter/
├── app.py            # main application: detection + clicking loop
├── train.py          # YOLOv8 training script
├── data.yaml         # dataset configuration (paths + classes)
├── classes.txt       # class names used for labeling
└── best.pt           # trained model weights
```

## ⚙️ Configuration

| Parameter | Default | Description |
|:---|:---:|:---|
| `COOKIE_CLASS_ID` | `0` | class index for cookies |
| `UPGRADE_CLASS_ID` | `1` | class index for upgrades |
| `confidence_threshold` | `0.7` | minimum detection confidence |

## 📸 Demo

<!-- Add a screenshot or GIF of the bot in action:
1. Save the image as docs/demo.png in the repository
2. Remove the HTML comment marks below

<p align="center"><img src="docs/demo.png" alt="Cookie Hunter demo" width="600"></p>
-->

## ⚠️ Disclaimer

This project was created **for educational purposes only** — it demonstrates a
custom YOLOv8 training pipeline and computer-vision automation. Automating games
may violate their terms of service. Use responsibly and at your own risk.

## 📄 License

Released under the [MIT License](LICENSE).
EOF_README

# Подставляем реальные значения вместо заглушек
sed -i "s|__GITHUB_USER__|${GITHUB_USER}|g" README.md
ok "Файлы созданы."

# ---------- 4. Опциональная чистка кэшей ----------
read -rp "Удалить локальный мусор (__pycache__ и кэши)? [y/N]: " ans || ans=""
if [[ "$ans" =~ ^[Yy]$ ]]; then
  find . -type d \( -name '__pycache__' -o -name '.pytest_cache' -o -name '.mypy_cache' \) -prune -exec rm -rf {} + 2>/dev/null || true
  ok "Кэши удалены."
else
  info "Пропускаю чистку (датасет, venv и кэши останутся на диске — в GitHub они всё равно не попадут)."
fi

# ---------- 5. Git: свежая история ----------
if [ -d .git ]; then
  warn "Найден существующий git-репозиторий."
  read -rp "Начать историю заново? (старые коммиты будут удалены, файлы на диске сохранятся) [y/N]: " ans || ans=""
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf .git
    ok "Старая git-история удалена."
  else
    die "Отменено. Настройте репозиторий вручную или разрешите пересоздание истории."
  fi
fi

git init -q
git symbolic-ref HEAD refs/heads/main

# git identity — только если не настроен глобально
if [ -z "$(git config user.email || true)" ]; then
  git config user.name "$AUTHOR"
  git config user.email "${GITHUB_USER}@users.noreply.github.com"
  warn "git-автор настроен локально для этого репозитория: ${AUTHOR} <${GITHUB_USER}@users.noreply.github.com>"
fi

# ---------- 6. Добавляем ТОЛЬКО нужные файлы ----------
info "Добавляю файлы в коммит ..."
git add .gitignore README.md LICENSE requirements.txt app.py train.py data.yaml classes.txt

for m in "${MODEL_FILES[@]}"; do
  if [ -f "$m" ]; then
    git add -f "$m"
    ok "Модель: $m"
  else
    warn "Файл $m не найден — пропускаю (список MODEL_FILES в начале скрипта)."
  fi
done

# Лучший результат обучения из runs/ (в обход .gitignore, файл уже в белом списке)
BEST_FOUND=0
while IFS= read -r f; do
  git add -f "$f"
  ok "Лучший результат обучения: $f"
  BEST_FOUND=1
done < <(find runs -type f -name 'best.pt' -path '*/weights/*' 2>/dev/null || true)
if [ "$BEST_FOUND" = 0 ]; then
  warn "runs/**/weights/best.pt не найден — пропускаю (main-модель best.pt всё равно добавлена)."
fi

# ---------- 7. Показываем и подтверждаем ----------
echo
info "В репозиторий попадут только эти файлы:"
echo -e "${C_B}"
git diff --cached --name-only | sed 's/^/   /'
echo -e "${C_0}"

read -rp "Публикуем? [Y/n]: " ans || ans=""
if [[ "$ans" =~ ^[Nn]$ ]]; then
  die "Отменено. Коммит не создан (файлы репозитория уже созданы — можно посмотреть)."
fi

git commit -qm "Initial commit: Cookie Hunter - YOLOv8 screen cookie detector"
git branch -M main
ok "Коммит создан."

# ---------- 8. Push ----------
REMOTE="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi

if [ "$NO_PUSH" = 1 ]; then
  ok "Режим --no-push: коммит готов локально, push не выполнялся."
  info "Для публикации: git push -u origin main"
  exit 0
fi

info "Репозиторий: ${REMOTE}"
info "GitHub запросит логин и пароль:"
info "  • Username: ${GITHUB_USER}"
info "  • Password: Personal Access Token (НЕ пароль от аккаунта!)"
echo
if ! git push -u origin main; then
  warn "Push не удался. Проверьте:"
  echo "   1) Репозиторий создан на https://github.com/new — имя: ${REPO_NAME}, БЕЗ README и лицензии"
  echo "   2) Токен имеет право repo (classic) или Contents: Read and write (fine-grained)"
  echo "   3) Повторить вручную: git push -u origin main"
  exit 1
fi

echo
ok "Готово! 🍪 Ваш проект: https://github.com/${GITHUB_USER}/${REPO_NAME}"
info "Как обновлять репозиторий в будущем:"
echo "   git add app.py train.py data.yaml classes.txt best.pt"
echo "   git commit -m \"Что изменил\""
echo "   git push"
