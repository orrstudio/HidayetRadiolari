# Версии компонентов

## Python 3.9.16

## Kivy 2.3.0
- Последняя стабильная версия
- Полная совместимость с Python 3.9.16

## KivyMD 1.2.0
- Совместимость с Kivy 2.3.0

## Requests 2.32.3
- Полная поддержка Python 3.9.x

## Pyjnius 1.5.0
- Интеграция с Java-API Android
- Стабильная версия для мобильной разработки

## Cython 3.0.5
- Совместимость с Python 3.9

## Python-for-Android 2024.1.21
- Поддержка Python 3.9.x

## Android SDK и NDK

### Android SDK 30 (Android 11)

### Android minSdkVersion 23 (Android 6.0)

### Android NDK r25b

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

# Установка debug-версии
adb -s s88ls4krprwc4dof install bin/hidayetradiolari-1.0-arm64-v8a_armeabi-v7a-debug.apk

# Просмотр всех логов приложения
adb -s s88ls4krprwc4dof logcat | grep "python\|error\|Exception"
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
