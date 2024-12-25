#!/bin/bash

# Скрипт настройки окружения для проекта HidayetRadiolari
# 
# Назначение:
# - Установка Python 3.9.16 из AUR
# - Создание виртуального окружения
# - Установка зависимостей проекта
# - Настройка Java 11 и 17 для Android разработки
# - Подготовка окружения для сборки Android приложения
#
# Требования:
# - Установленный yay (AUR helper)
# - Подключение к интернету
# - Права пользователя для установки пакетов
#
# Версии компонентов:
# - Python: 3.9.16
# - Kivy: 2.3.0
# - KivyMD: 1.2.0
# - Java: 11 (основная), 17 (опционально)
# - Buildozer: 1.5.0

set -e  # Остановить скрипт при первой ошибке

# Функция для безопасной установки пакетов через yay с интерактивным режимом
safe_yay_install() {
    local package="$1"
    echo "Установка пакета $package..."
    yay -S --answerdiff=None --answeredit=Always --answerclean=Always --answerupgrade=Always --answerreplace=Always --answerall=Always "$package"
}

# Пути к Java и Python
JAVA_11="/usr/lib/jvm/java-11-openjdk"
JAVA_17="/usr/lib/jvm/java-17-openjdk"
PYTHON_VERSION="3.9.16"
PYTHON_PATH="/home/orr/.pyenv/versions/3.9.16/bin/python3"
VENV_PATH="./venv"

# Проверка наличия существующего виртуального окружения
check_existing_venv() {
    if [ -d "$VENV_PATH" ]; then
        echo "Обнаружено существующее виртуальное окружение в $VENV_PATH"
        read -p "Хотите удалить существующее виртуальное окружение? (y/n): " confirm
        
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            echo "Удаление существующего виртуального окружения..."
            rm -rf "$VENV_PATH"
        else
            echo "Установка остановлена. Виртуальное окружение не изменено."
            exit 1
        fi
    fi
}

# Проверка наличия yay
if ! command -v yay &> /dev/null; then
    echo "Ошибка: yay не установлен. Установите yay для продолжения."
    exit 1
fi

echo "Начало установки окружения проекта HidayetRadiolari..."

# Проверка существующего виртуального окружения
check_existing_venv

# 2. Подготовка виртуального окружения
echo "2. Подготовка виртуального окружения Python $PYTHON_VERSION..."
# Создание нового виртуального окружения
$PYTHON_PATH -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"

# 3. Установка зависимостей с точными версиями
echo "3. Установка зависимостей проекта..."
pip install --upgrade pip
pip install "kivy==2.3.0" "kivymd==1.2.0" "Cython==3.0.5" "requests==2.32.3" "buildozer==1.5.0" "python-for-android==2023.9.16"

# Проверка версий установленных пакетов
echo "Проверка версий установленных пакетов:"
python --version
pip list | grep -E "kivy|kivymd|Cython|requests|buildozer|python-for-android"

# Деактивация виртуального окружения
deactivate

echo "Окружение Python $PYTHON_VERSION успешно настроено!"
echo "Активируйте окружение командой: source $VENV_PATH/bin/activate"

# Функция установки Java с yay
install_java() {
    local version=$1
    local package=$2
    local path=$3
    
    if [ ! -d "$path" ]; then
        echo "Установка Java $version..."
        safe_yay_install "$package"
    else
        echo "Java $version уже установлена"
    fi
}

# 4. Установка Java 11 (основная версия для Android SDK)
echo "4. Установка Java 11 (требуется для Android SDK)..."
install_java "11" "jdk11-openjdk" "$JAVA_11"

# Проверка установки Java 11
echo "Проверка установки Java 11..."
JAVA11_PATH="$JAVA_11/bin/java"
if [ ! -f "$JAVA11_PATH" ]; then
    echo "Ошибка: Java 11 не установлена. Она необходима для работы Android SDK."
    exit 1
fi
$JAVA11_PATH -version

# 5. Установка Java 17 (опционально, для новых версий Gradle)
echo "5. Установка Java 17 (опционально, для новых версий Gradle)..."
install_java "17" "jdk17-openjdk" "$JAVA_17"

# 6. Настройка Gradle (будет установлен через buildozer)
echo "6. Настройка конфигурации Gradle..."
GRADLE_DIR="./.gradle"
GRADLE_PROPS="$GRADLE_DIR/gradle.properties"

mkdir -p "$GRADLE_DIR"

# Очистка старых настроек Java для Gradle
if [ -f "$GRADLE_PROPS" ]; then
    sed -i '/org.gradle.java.home/d' "$GRADLE_PROPS"
fi

# Настройка Java для Gradle
echo "# Конфигурация Java для Gradle" >> "$GRADLE_PROPS"
echo "# По умолчанию используется Java 11 для совместимости с Android SDK" >> "$GRADLE_PROPS"
echo "org.gradle.java.home=$JAVA_11" >> "$GRADLE_PROPS"
echo "" >> "$GRADLE_PROPS"
echo "# Для использования Java 17 (если требуется новой версией Gradle):" >> "$GRADLE_PROPS"
echo "# 1. Закомментируйте строку выше" >> "$GRADLE_PROPS"
echo "# 2. Раскомментируйте строку ниже" >> "$GRADLE_PROPS"
echo "#org.gradle.java.home=$JAVA_17" >> "$GRADLE_PROPS"

echo "Установка завершена!"
echo ""
echo "Установленные компоненты:"
echo "✓ Виртуальное окружение с установленными пакетами"
echo "✓ Java 11 (основная версия): $JAVA_11"
echo "✓ Java 17 (опционально): $JAVA_17"
echo "✓ Конфигурация Gradle: $GRADLE_PROPS"
echo ""
echo "Следующие шаги:"
echo "1. Запустите buildozer init для создания buildozer.spec"
echo "2. Настройте buildozer.spec под ваш проект"
echo "3. Запустите buildozer для установки Android SDK и NDK"
echo ""
echo "Примечание: Android SDK будет использовать Java 11 (настроено в buildozer.spec)"
echo "Gradle по умолчанию также использует Java 11, но может быть переключен на Java 17"
