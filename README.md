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


Затем установите Python-библиотеки:
pip install -r requirements.txt
