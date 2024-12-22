#!/bin/bash

# Функция для вывода ошибок
error() {
    echo "❌ Ошибка: $1" >&2
    exit 1
}

# Функция для вывода успешных сообщений
success() {
    echo "✅ $1"
}

# Функция для вывода информационных сообщений
info() {
    echo "ℹ️ $1"
}

# Функция для вывода предупреждений
warn() {
    echo "⚠️ $1"
}

# Проверка наличия необходимых инструментов
check_requirements() {
    info "Проверяем наличие необходимых инструментов..."
    
    # Проверка Python
    if ! command -v python3 &> /dev/null; then
        error "Python 3 не установлен"
        exit 1
    fi
    local python_version=$(python3 -V 2>&1 | cut -d' ' -f2)
    success "Python $python_version найден"
    
    # Проверка версии Python
    local required_python_version="3.11.7"
    local current_python_version=$(python3 -V 2>&1 | cut -d' ' -f2)
    
    if [ "$current_python_version" != "$required_python_version" ]; then
        error "Требуется Python $required_python_version, установлен $current_python_version"
        # Здесь можно добавить логику загрузки и установки нужной версии
    fi
    
    # Проверка pip
    if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
        error "pip не установлен"
        exit 1
    fi
    success "pip найден"
    
    # Проверка venv
    if ! python3 -c "import venv" &> /dev/null; then
        error "модуль venv не установлен"
        exit 1
    fi
    success "модуль venv найден"
    
    # Проверка buildozer
    if [ ! -d "$VIRTUAL_ENV" ]; then
        error "Виртуальное окружение не существует"
        exit 1
    fi
    
    if [ ! -x "$VIRTUAL_ENV/bin/pip" ]; then
        error "pip не найден в виртуальном окружении"
        exit 1
    fi
    
    "$VIRTUAL_ENV/bin/pip" install buildozer || error "Не удалось установить buildozer"
    
    if ! "$VIRTUAL_ENV/bin/pip" list | grep -q buildozer; then
        error "buildozer не установлен"
        exit 1
    fi
    
    success "buildozer установлен"
    
    # Проверка git
    if ! command -v git &> /dev/null; then
        error "git не установлен. Установите: sudo pacman -S git"
    fi
    success "git найден"
    
    # Проверяем наличие wget и tar
    if ! command -v wget &> /dev/null; then
        error "Утилита wget не найдена. Невозможно загружать файлы."
        exit 1
    fi
    
    if ! command -v tar &> /dev/null; then
        error "Утилита tar не найдена. Невозможно распаковывать архивы."
        exit 1
    fi
}

# Проверка наличия конкретной версии Java
check_java_version() {
    local required_version=$1
    local java_path=$2
    
    if [ ! -d "$java_path" ]; then
        error "Java $required_version не найдена в $java_path"
    fi
    
    if [ -x "$java_path/bin/java" ]; then
        local version=$("$java_path/bin/java" -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$version" = "$required_version" ]; then
            success "Java $required_version найдена в $java_path"
            return 0
        fi
    fi
    
    error "Неверная версия Java в $java_path"
}

# Проверка наличия обеих версий Java
check_java() {
    info "Проверяем версии Java..."
    local java11_path="/usr/lib/jvm/java-11-openjdk"
    local java17_path="/usr/lib/jvm/java-17-openjdk"
    
    check_java_version "11" "$java11_path"
    check_java_version "17" "$java17_path"
    
    success "Обе версии Java (11 и 17) найдены"
    return 0
}

# Настройка путей Java
setup_java() {
    info "Настраиваем пути Java..."
    
    # Создаем директорию .gradle внутри проекта
    mkdir -p "$PROJECT_ROOT/.gradle" || error "Не удалось создать директорию .gradle"
    
    # Настраиваем gradle.properties внутри проекта
    echo "org.gradle.java.home=/usr/lib/jvm/java-17-openjdk" > "$PROJECT_ROOT/.gradle/gradle.properties" || \
        error "Не удалось создать файл gradle.properties"
    
    # Настраиваем local.properties внутри проекта
    local_props=".buildozer/android/platform/build-arm64-v8a/dists/radiokivy/local.properties"
    mkdir -p $(dirname "$local_props") || error "Не удалось создать директорию для local.properties"
    
    {
        echo "sdk.dir=.buildozer/android/platform/android-sdk"
        echo "ndk.dir=.buildozer/android/platform/android-ndk-r25b"
        echo "java.home=/usr/lib/jvm/java-17-openjdk"
    } > "$local_props" || error "Не удалось создать файл local.properties"
    
    # Экспортируем JAVA_HOME для текущей сессии
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
    success "Пути Java настроены"
}

# Установка зависимостей buildozer
setup_buildozer_deps() {
    # Строгая проверка и активация виртуального окружения
    ensure_venv_activated || {
        error "Не удалось подготовить виртуальное окружение для установки зависимостей"
        return 1
    }
    
    # Обновляем pip с игнорированием ошибок
    safe_pip_command install --upgrade pip setuptools wheel || {
        warn "Не удалось обновить pip. Продолжаем с текущей версией."
    }
    
    info "Путь к виртуальному окружению: $VIRTUAL_ENV"
    
    info "Устанавливаем зависимости из requirements.txt..."
    
    # Чтение требуемых версий из requirements.txt
    local python_version=$(grep "^python==" "$PROJECT_ROOT/requirements.txt" | cut -d'=' -f3)
    local kivy_version=$(grep "^kivy==" "$PROJECT_ROOT/requirements.txt" | cut -d'=' -f3)
    local kivymd_version=$(grep "^kivymd==" "$PROJECT_ROOT/requirements.txt" | cut -d'=' -f3)
    local requests_version=$(grep "^requests==" "$PROJECT_ROOT/requirements.txt" | cut -d'=' -f3)
    local pyjnius_version=$(grep "^pyjnius==" "$PROJECT_ROOT/requirements.txt" | cut -d'=' -f3)
    local cython_version=$(grep "^Cython==" "$PROJECT_ROOT/requirements.txt" | cut -d'=' -f3)
    
    # Массив зависимостей для установки
    local dependencies=(
        "kivy==$kivy_version"
        "kivymd==$kivymd_version"
        "requests==$requests_version"
        "pyjnius==$pyjnius_version"
        "Cython==$cython_version"
        "buildozer"  # Buildozer устанавливаем последней
    )
    
    # Флаг для отслеживания общего статуса установки
    local install_status=0
    
    # Установка зависимостей с проверкой версий
    for dep in "${dependencies[@]}"; do
        info "Проверка и установка: $dep"
        
        # Извлекаем имя пакета и версию
        local package_name=$(echo "$dep" | cut -d'=' -f1)
        local package_version=$(echo "$dep" | cut -d'=' -f3)
        
        # Проверяем текущую установленную версию
        local current_version=$(safe_pip_command show "$package_name" 2>/dev/null | grep Version | cut -d' ' -f2)
        
        if [ -n "$current_version" ]; then
            if [ "$current_version" == "$package_version" ]; then
                success "$package_name уже установлен в версии $package_version"
                continue
            else
                warn "$package_name установлен в версии $current_version. Требуется $package_version"
            fi
        fi
        
        # Установка или обновление пакета
        safe_pip_command install "$dep" || {
            error "Не удалось установить $dep"
            install_status=1
        }
    done
    
    # Проверка установки Buildozer
    if ! safe_pip_command list | grep -q buildozer; then
        safe_pip_command install buildozer || {
            error "Не удалось установить Buildozer"
            return 1
        }
    fi
    
    success "Процесс установки зависимостей завершен"
    return $install_status
}

# Установка локальных зависимостей для buildozer
setup_local_buildozer_deps() {
    # Активируем виртуальное окружение
    source "$VIRTUAL_ENV/bin/activate" || error "Не удалось активировать виртуальное окружение"
    
    # Обновляем pip
    pip install --upgrade pip setuptools wheel
    
    info "Устанавливаем локальные зависимости для buildozer..."
    
    # Список необходимых пакетов
    local packages=(
        "Pillow"
        "docutils"
        "pygments"
        "kivy==2.3.0"
        "Cython==3.0.11"
        "requests==2.32.3"
        "pyjnius==1.6.1"
        "kivymd==1.2.0"
    )
    
    # Попытка установки через pip
    for pkg in "${packages[@]}"; do
        info "Устанавливаем $pkg..."
        pip install "$pkg" || error "Не удалось установить $pkg"
    done
    
    # Проверка и установка системных зависимостей
    if ! pacman -Q glew &> /dev/null; then
        info "Устанавливаем системную зависимость glew..."
        # Установка glew без sudo
        mkdir -p "$HOME/.local/src/glew"
        cd "$HOME/.local/src/glew"
        wget -O glew-2.2.0.tgz https://downloads.sourceforge.net/glew/glew-2.2.0.tgz
        tar -xzf glew-2.2.0.tgz
        cd glew-2.2.0
        make glew.lib.shared
        make install.all GLEW_DEST="$HOME/.local"
        export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
    fi
    
    success "Локальные зависимости buildozer установлены"
}

# Установка Kivy и KivyMD через pip
setup_kivy() {
    # Активируем виртуальное окружение
    source "$VIRTUAL_ENV/bin/activate" || error "Не удалось активировать виртуальное окружение"
    
    # Обновляем pip
    pip install --upgrade pip setuptools wheel
    
    info "Установка Kivy и KivyMD..."
    
    # Проверяем, что мы в правильном виртуальном окружении
    if [[ -z "$VIRTUAL_ENV" ]]; then
        error "Виртуальное окружение не активировано"
        exit 1
    fi
    
    # Установка Kivy и KivyMD через pip
    pip install kivy==2.3.0
    pip install kivymd==1.2.0
    pip install requests==2.32.3
    pip install pyjnius==1.6.1
    pip install Cython==3.0.11
    
    success "Kivy и KivyMD успешно установлены"
}

# Создание и настройка виртуального окружения
setup_venv() {
    info "Создание виртуального окружения..."
    
    # Путь к виртуальному окружению
    local project_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local venv_dir="$project_root/venv"
    
    # Проверяем существование директории для виртуальных окружений
    mkdir -p "$venv_dir"
    
    # Создаем виртуальное окружение
    if [ ! -d "$venv_dir/bin" ]; then
        if ! python3 -m venv "$venv_dir"; then
            error "Не удалось создать виртуальное окружение"
            return 1
        fi
    fi
    
    # Активируем виртуальное окружение
    source "$venv_dir/bin/activate" || error "Не удалось активировать виртуальное окружение"
    
    # Обновляем pip в виртуальном окружении
    pip install --upgrade pip setuptools wheel
    
    success "Виртуальное окружение создано и активировано"
}

# Проверка наличия файла buildozer.spec
check_buildozer_spec() {
    info "Проверяем наличие buildozer.spec..."
    if [ ! -f "buildozer.spec" ]; then
        error "Файл buildozer.spec не найден"
    fi
    success "Файл buildozer.spec найден"
}

# Настройка Gradle
setup_gradle() {
    info "Настраиваем Gradle..."
    
    # Проверяем наличие GRADLE_HOME
    if [ -z "$GRADLE_HOME" ]; then
        export GRADLE_HOME=".buildozer/android/platform/gradle"
        info "GRADLE_HOME установлен в $GRADLE_HOME"
    fi

    export PATH="$GRADLE_HOME/bin:$PATH"
    
    # Создаем gradle.properties в проекте если его нет
    local project_gradle_props=".buildozer/android/platform/build-arm64-v8a/dists/radiokivy/gradle.properties"
    mkdir -p $(dirname "$project_gradle_props")
    
    {
        echo "org.gradle.jvmargs=-Xmx2048m"
        echo "android.useAndroidX=true"
        echo "android.enableJetifier=true"
        echo "org.gradle.configureondemand=true"
        echo "org.gradle.daemon=true"
    } > "$project_gradle_props" || error "Не удалось создать файл gradle.properties"
    
    # Проверяем наличие gradlew
    local gradlew_path=".buildozer/android/platform/build-arm64-v8a/dists/radiokivy/gradlew"
    if [ -f "$gradlew_path" ]; then
        # Делаем gradlew исполняемым
        chmod +x "$gradlew_path" || error "Не удалось сделать gradlew исполняемым"
    fi
    
    success "Gradle настроен"
}

# Настройка Gradle для работы с Java 11
setup_gradle_java() {
    info "Настраиваем Gradle для работы с Java 11..."
    
    # Путь к gradle.properties
    local gradle_props=".buildozer/android/platform/build-arm64-v8a/dists/radiokivy/gradle.properties"
    
    # Создаем директорию если её нет
    mkdir -p "$(dirname "$gradle_props")"
    
    # Добавляем настройки Java 11
    cat >> "$gradle_props" << EOF
org.gradle.java.home=/usr/lib/jvm/java-11-openjdk
EOF
    
    # Создаем settings.gradle если его нет
    local settings_gradle=".buildozer/android/platform/build-arm64-v8a/dists/radiokivy/settings.gradle"
    if [ ! -f "$settings_gradle" ]; then
        echo "rootProject.name = 'radiokivy'" > "$settings_gradle"
    fi
    
    # Даем права на выполнение gradlew
    chmod +x ".buildozer/android/platform/build-arm64-v8a/dists/radiokivy/gradlew"
    
    success "Настройка Gradle завершена"
}

# Очистка сборки
clean_build() {
    info "Очищаем предыдущую сборку..."
    
    # Очищаем директорию сборки
    if [ -d ".buildozer" ]; then
        rm -rf .buildozer/* || error "Не удалось очистить директорию .buildozer"
    fi
    
    # Очищаем временные файлы Python
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete 2>/dev/null || true
    find . -type f -name "*.pyo" -delete 2>/dev/null || true
    
    success "Сборка очищена"
}

# Настройка переменных окружения Android
setup_android_env() {
    info "Настраиваем переменные окружения Android..."
    
    # Устанавливаем ANDROID_HOME
    export ANDROID_HOME=".buildozer/android/platform/android-sdk"
    
    # Устанавливаем ANDROID_NDK_HOME
    export ANDROID_NDK_HOME=".buildozer/android/platform/android-ndk-r25b"
    
    # Добавляем пути в PATH
    export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
    
    # Записываем переменные в .bashrc если их там нет
    local bashrc="$HOME/.bashrc"
    if [ -f "$bashrc" ]; then
        if ! grep -q "ANDROID_HOME=" "$bashrc"; then
            echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >> "$bashrc"
        fi
        if ! grep -q "ANDROID_NDK_HOME=" "$bashrc"; then
            echo "export ANDROID_NDK_HOME=\"$ANDROID_NDK_HOME\"" >> "$bashrc"
        fi
    fi
    
    success "Переменные окружения Android настроены"
}

# Отладка сборки Gradle
debug_gradle() {
    info "Запускаем Gradle с подробным выводом..."
    
    local gradle_dir=".buildozer/android/platform/build-arm64-v8a/dists/radiokivy"
    
    # Проверяем наличие директории
    if [ ! -d "$gradle_dir" ]; then
        warn "Директория Gradle не найдена: $gradle_dir"
        return 0
    fi
    
    # Переходим в директорию с gradle
    cd "$gradle_dir"
    
    # Запускаем gradle с подробным выводом
    ./gradlew clean assembleDebug --info --stacktrace --debug > gradle_debug.log 2>&1
    
    # Проверяем результат
    if [ $? -ne 0 ]; then
        error "Gradle сборка завершилась с ошибкой"
        info "Проверьте лог: $gradle_dir/gradle_debug.log"
        # Показываем последние строки лога с ошибками
        grep -A 10 "FAILURE:" gradle_debug.log || true
        return 1
    fi
    
    success "Gradle сборка успешно завершена"
    cd - > /dev/null
}

# Ручная установка системных зависимостей
manual_system_deps() {
    info "Устанавливаем системные зависимости вручную..."
    
    # Список системных зависимостей
    local system_deps=(
        "sdl2"
        "sdl2_image"
        "sdl2_mixer"
        "sdl2_ttf"
        "gstreamer"
        "gst-plugins-base"
        "gst-plugins-good"
    )
    
    # Путь к директории с зависимостями
    local deps_dir="${HOME}/.buildozer/android/platform/build-tools"
    
    # Проверяем наличие директории
    mkdir -p "$deps_dir" || error "Не удалось создать директорию $deps_dir"
    
    # Проверяем наличие пакетов
    for dep in "${system_deps[@]}"; do
        if [ ! -f "$deps_dir/$dep.tar.gz" ]; then
            error "Отсутствует пакет $dep в $deps_dir"
            return 1
        fi
    done
    
    # Распаковка и установка
    for dep in "${system_deps[@]}"; do
        info "Устанавливаем $dep..."
        tar -xzf "$deps_dir/$dep.tar.gz" -C "$deps_dir" || error "Не удалось распаковать $dep"
    done
    
    success "Системные зависимости установлены вручную"
}

# Загрузка системных зависимостей
download_system_deps() {
    info "Загружаем системные зависимости..."
    
    # Создаем директорию для загрузки и установки
    local deps_dir=".buildozer/android/platform/build-tools"
    mkdir -p "$deps_dir" || error "Не удалось создать директорию для зависимостей"
    
    # Список зависимостей для загрузки
    local deps=(
        "sdl2:https://libsdl.org/release/SDL2-2.28.5.tar.gz"
        "sdl2_image:https://libsdl.org/projects/SDL_image/release/SDL2_image-2.6.3.tar.gz"
        "sdl2_mixer:https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.0/SDL2_mixer-2.6.0.tar.gz"
        "sdl2_ttf:https://libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.20.2.tar.gz"
    )
    
    # Создаем директорию для зависимостей, если она не существует
    mkdir -p "$deps_dir"
    
    # Загрузка и распаковка зависимостей
    for dep_url in "${deps[@]}"; do
        dep_name=$(echo "$dep_url" | cut -d: -f1)
        dep_link=$(echo "$dep_url" | cut -d: -f2-)
        
        echo "Загрузка $dep_name из $dep_link"
        
        # Проверка доступности ссылки с использованием wget с отключенной проверкой SSL
        if ! wget --no-check-certificate --spider "$dep_link" 2>/dev/null; then
            echo "❌ Ошибка: Не удалось получить доступ к $dep_link"
            continue
        fi
        
        # Загрузка файла с подробной информацией с отключенной проверкой SSL
        if ! wget --no-check-certificate -O "$deps_dir/$dep_name.tar.gz" "$dep_link"; then
            echo "❌ Ошибка: Не удалось загрузить $dep_name"
            continue
        fi
        
        # Распаковка файла
        if ! tar -xzf "$deps_dir/$dep_name.tar.gz" -C "$deps_dir"; then
            echo "❌ Ошибка: Не удалось распаковать $dep_name"
            continue
        fi
        
        echo "✅ $dep_name успешно загружен и распакован"
    done
    
    success "Системные зависимости загружены"
}

# Загрузка и установка Python 3.11.7
download_python_3_11_7() {
    # Проверяем, нужна ли установка
    local required_version="3.11.7"
    local current_version=$(python3 --version | awk '{print $2}')
    
    if [ "$current_version" == "$required_version" ]; then
        success "Python $required_version уже установлен"
        return 0
    fi

    info "Начинаем загрузку Python 3.11.7..."
    
    # Путь для локальной установки Python
    export PYTHON_LOCAL_INSTALL="$HOME/.local/python3.11.7"
    
    # Создаем директорию для загрузки и установки
    local python_download_dir="$HOME/.local/share/python_downloads"
    mkdir -p "$python_download_dir"
    mkdir -p "$PYTHON_LOCAL_INSTALL"
    
    # URL для загрузки Python 3.11.7
    local python_url="https://www.python.org/ftp/python/3.11.7/Python-3.11.7.tgz"
    local python_archive="$python_download_dir/Python-3.11.7.tgz"
    
    # Загружаем архив
    if ! wget -O "$python_archive" "$python_url"; then
        error "Не удалось загрузить Python 3.11.7"
        return 1
    fi
    
    # Распаковываем архив
    if ! tar -xzf "$python_archive" -C "$python_download_dir"; then
        error "Не удалось распаковать архив Python 3.11.7"
        return 1
    fi
    
    # Переходим в директорию с исходниками
    cd "$python_download_dir/Python-3.11.7"
    
    # Конфигурируем для локальной установки
    if ! ./configure --prefix="$PYTHON_LOCAL_INSTALL" --enable-optimizations; then
        error "Ошибка конфигурации Python 3.11.7"
        return 1
    fi
    
    # Собираем
    if ! make -j$(nproc); then
        error "Ошибка сборки Python 3.11.7"
        return 1
    fi
    
    # Устанавливаем в локальную директорию
    if ! make install; then
        error "Ошибка установки Python 3.11.7"
        return 1
    fi
    
    # Добавляем путь к локальной версии Python
    export PATH="$PYTHON_LOCAL_INSTALL/bin:$PATH"
    
    # Проверяем установку
    "$PYTHON_LOCAL_INSTALL/bin/python3" --version || {
        error "Не удалось установить Python 3.11.7"
        return 1
    }
    
    success "Python 3.11.7 успешно установлен в $PYTHON_LOCAL_INSTALL"
    
    # Возвращаемся в исходную директорию
    cd "$OLDPWD"
}

# Универсальная функция для проверки и активации виртуального окружения
ensure_venv_activated() {
    # Проверяем, существует ли путь виртуального окружения
    if [ ! -d "$VIRTUAL_ENV" ]; then
        error "Виртуальное окружение не существует в $VIRTUAL_ENV"
        return 1
    }
    
    # Проверяем, активировано ли виртуальное окружение
    if [ -z "$VIRTUAL_ENV" ] || [[ "$PATH" != *"$VIRTUAL_ENV/bin"* ]]; then
        info "Активация виртуального окружения: $VIRTUAL_ENV"
        source "$VIRTUAL_ENV/bin/activate" || {
            error "Не удалось активировать виртуальное окружение в $VIRTUAL_ENV"
            return 1
        }
    fi
    
    # Проверяем наличие pip во виртуальном окружении
    if [ ! -x "$VIRTUAL_ENV/bin/pip" ]; then
        error "pip не найден в виртуальном окружении"
        return 1
    fi
    
    return 0
}

# Функция для безопасного выполнения команд в виртуальном окружении
safe_pip_command() {
    ensure_venv_activated || return 1
    "$VIRTUAL_ENV/bin/pip" "$@"
}

# Основной процесс
main() {
    info "Начинаем настройку окружения..."
    
    # Перехват ошибок
    trap 'error "Произошла ошибка в строке $LINENO"' ERR
    
    # Проверяем доступность wget
    if ! command -v wget &> /dev/null; then
        error "Утилита wget не найдена. Установите wget для загрузки зависимостей."
        exit 1
    fi
    
    # Проверяем доступность tar
    if ! command -v tar &> /dev/null; then
        error "Утилита tar не найдена. Установите tar для распаковки архивов."
        exit 1
    fi
    
    # Проверяем доступность интернета
    if ! wget -q --spider https://www.google.com; then
        error "Нет подключения к интернету. Проверьте сетевое соединение."
        exit 1
    fi
    
    # Создаем локальные директории для виртуального окружения и зависимостей
    local project_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local venv_dir="$project_root/venv"
    local buildozer_dir="$project_root/.buildozer"
    local deps_dir="$buildozer_dir/deps"
    
    # Создаем директории, если они не существуют
    mkdir -p "$venv_dir" "$buildozer_dir" "$deps_dir"
    
    # Устанавливаем пути для buildozer и Android внутри проекта
    export BUILDOZER_HOME="$project_root/.buildozer"
    export ANDROID_HOME="$project_root/.android"
    export GRADLE_HOME="$project_root/.gradle"
    export PROJECT_ROOT="$project_root"

    # Создаем необходимые директории
    mkdir -p "$BUILDOZER_HOME/android/platform/build-tools"
    mkdir -p "$ANDROID_HOME"
    mkdir -p "$GRADLE_HOME"
    
    # Создаем виртуальное окружение в локальной директории
    if [ ! -d "$venv_dir/bin" ]; then
        python3 -m venv "$venv_dir"
    fi
    
    # Активируем виртуальное окружение
    source "$venv_dir/bin/activate"
    
    check_requirements
    
    setup_buildozer_deps
    setup_local_buildozer_deps
    setup_kivy
    check_buildozer_spec
    check_java
    setup_java
    setup_android_env
    setup_gradle
    setup_gradle_java
    clean_build
    download_system_deps
    manual_system_deps
    debug_gradle
    
    # Замена VLC на ExoPlayer
    # В buildozer.spec:
    # - Заменили android.gradle_dependencies = org.videolan.android:libvlc-all:3.6.0
    # на android.gradle_dependencies = com.google.android.exoplayer:exoplayer:2.19.1
    #
    # В main.py:
    # - Для Android заменили VLC на ExoPlayer API
    # - Для десктопа оставили VLC без изменений
    #
    # Добавление файла списка радиостанций в сборку:
    # - В buildozer.spec добавили строку:
    # source.include_patterns = radios-list.txt
    
    success "Настройка окружения завершена успешно"
    info "Теперь вы можете запустить сборку командой: buildozer android debug"
}

# Запуск основного процесса
main
