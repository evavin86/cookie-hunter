Автоматический кликер для "печеньки" на основе нейросети YOLOv8. Проект делает скриншоты экрана, распознаёт печеньку, кнопки прокачки и бонусы, а затем автоматически кликает по ним.

Установка библиотек
Откройте терминал в папке проекта и выполните:

Вариант 1 — установить всё сразу (рекомендуется)
pip install -r requirements.txt

Вариант 2 — установить по одной
pip install ultralytics
pip install opencv-python
pip install numpy
pip install pillow
pip install pyautogui
pip install mss

Linux
Проект поддерживает Linux (X11, не Wayland). Скрипты автоматически определяют ОС и переключаются на mss для скриншотов.

Первоначальная настройка на Linux
Установите системные пакеты для pyautogui (нужен для управления мышью, на X11):

# Ubuntu / Debian
sudo apt update && sudo apt install -y python3-xlib scrot

# Fedora
sudo dnf install python3-xlib scrot

# Arch Linux
sudo pacman -S python-xlib scrot

Затем установите Python-библиотеки:
pip install -r requirements.txt
