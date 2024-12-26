# Команды для ввода в ручную

## Управление виртуальным окружением Python 3.9.16:
```bash
# Создание
python -m venv venv

# Активация
source venv/bin/activate

# Деактивация
deactivate
```

## Установка зависимостей:
```bash
# Обновление pip
python -m pip install --upgrade pip

# Установка всех зависимостей из requirements.txt
pip install -r requirements.txt

# Установка buildozer и Cython (если требуется отдельно)
pip install buildozer==1.5.0 Cython==3.0.5
```

## Очистка проекта
```bash
# Полная очистка buildozer
buildozer android clean

# Очистка кэша Python
python3 -m pip cache purge

# Удаление временных файлов
rm -rf .buildozer/
```

## Сборка Android приложения:

https://www.youtube.com/watch?v=pzsvN3fuBA0

```bash
# Инициализация buildozer (только при первом использовании)
buildozer init

# Очистка сборки
buildozer android clean

# Сборка debug-версии
buildozer -v android debug

# Просмотр логов
buildozer android logcat
```

## Сборка проекта
```bash
# Сборка debug-версии
buildozer android debug

# Просмотр логов
buildozer android logcat
```

## Установка на устройство
```bash
# Список подключенных устройств
adb devices

# Подключение по вайфай
adb tcpip 5555
adb connect 192.168.1.65:5555

# Установка debug-версии
adb -s s88ls4krprwc4dof install bin/debug.apk
adb -s 192.168.1.65:5555 install bin/debug.apk

# Просмотр всех логов приложения
adb -s s88ls4krprwc4dof logcat | grep "python\|error\|Exception"
adb -s 192.168.1.65:5555 logcat | grep "python\|error\|Exception"
```

## Отладка Android приложения:
```bash
# Просмотр логов Python
adb logcat | grep python

# Просмотр ошибок
adb logcat | grep error

# Просмотр всех логов приложения
adb logcat | grep "python\|error\|Exception"

# Установка debug-версии
adb -s s88ls4krprwc4dof install bin/hidayetradiolari-1.0-arm64-v8a_armeabi-v7a-debug.apk
```

## Зависимости системы Arch Linux:
```bash
# Проверка установки buildozer
pacman -Qs buildozer

# Установка системных зависимостей (если требуется)
yay -S python-pip python-virtualenv python-kivy python-setuptools
```
