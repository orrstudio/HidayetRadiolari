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
        warn "Установлен Python $current_python_version, требуется $required_python_version"
        # Продолжаем выполнение, чтобы дать возможность установить нужную версию
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
    if [ -n "$VIRTUAL_ENV" ] && [ ! -d "$VIRTUAL_ENV" ]; then
        error "Виртуальное окружение не существует"
        exit 1
    fi
    
    if [ -n "$VIRTUAL_ENV" ] && [ ! -x "$VIRTUAL_ENV/bin/pip" ]; then
        error "pip не найден в виртуальном окружении"
        exit 1
    fi
    
    if [ -n "$VIRTUAL_ENV" ]; then
        "$VIRTUAL_ENV/bin/pip" install buildozer || error "Не удалось установить buildozer"
        
        if ! "$VIRTUAL_ENV/bin/pip" list | grep -q buildozer; then
            error "buildozer не установлен"
            exit 1
        fi
        
        success "buildozer установлен"
    fi
    
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

# Функция для определения имени проекта
get_project_name() {
    local project_dir="$1"
    local project_name
    
    # Извлекаем базовое имя директории
    project_name=$(basename "$project_dir")
    
    # Заменяем все небуквенные символы на подчеркивание
    project_name=$(echo "$project_name" | sed 's/[^a-zA-Z0-9]/_/g')
    
    # Преобразуем в нижний регистр
    project_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]')
    
    # Если имя пустое, используем дефолтное
    if [ -z "$project_name" ]; then
        project_name="android_project"
    fi
    
    echo "$project_name"
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
    
    # Настраиваем gradle.properties внутри проекта
    local gradle_props_dir="$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}"
    
    # Проверяем и создаем директорию, если она не существует
    [ ! -d "$gradle_props_dir" ] && {
        mkdir -p "$gradle_props_dir" || \
            error "Не удалось создать директорию для gradle.properties"
    }
    
    echo "org.gradle.java.home=/usr/lib/jvm/java-17-openjdk" > "$gradle_props_dir/gradle.properties" || \
        error "Не удалось создать файл gradle.properties"
    
    # Настраиваем local.properties внутри проекта
    local_props="$PROJECT_ROOT/local.properties"
    mkdir -p $(dirname "$local_props")
    
    {
        echo "sdk.dir=.buildozer/android/platform/android-sdk"
        echo "ndk.dir=.buildozer/android/platform/android-ndk-r25b"
        echo "java.home=/usr/lib/jvm/java-17-openjdk"
    } > "$local_props" || error "Не удалось создать файл local.properties"
    
    # Экспортируем JAVA_HOME для текущей сессии
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
    success "Пути Java настроены"
}

# Функция для установки зависимостей buildozer
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
    info "Создание и настройка виртуального окружения..."
    
    # Определяем путь к виртуальному окружению
    export VENV_DIR="$PROJECT_ROOT/venv"
    export VIRTUAL_ENV="$VENV_DIR"
    
    # Создаем директорию для виртуального окружения, если она не существует
    mkdir -p "$VENV_DIR"
    
    # Проверяем, существует ли уже виртуальное окружение
    if [ ! -d "$VENV_DIR/bin" ]; then
        info "Создаем новое виртуальное окружение..."
        python3 -m venv "$VENV_DIR" || {
            error "Не удалось создать виртуальное окружение"
            return 1
        }
    else
        info "Виртуальное окружение уже существует"
    fi
    
    # Активируем виртуальное окружение
    source "$VENV_DIR/bin/activate" || {
        error "Не удалось активировать виртуальное окружение"
        return 1
    }
    
    # Обновляем pip в виртуальном окружении
    pip install --upgrade pip setuptools wheel || {
        warn "Не удалось обновить pip. Продолжаем с текущей версией."
    }
    
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
    info "Настройка Gradle..."
    
    # Проверяем наличие GRADLE_HOME
    if [ -z "$GRADLE_HOME" ]; then
        export GRADLE_HOME="$PROJECT_ROOT/.buildozer/android/platform/gradle"
        info "GRADLE_HOME установлен в $GRADLE_HOME"
    fi

    export PATH="$GRADLE_HOME/bin:$PATH"
    
    # Определяем имя проекта
    PROJECT_NAME=$(get_project_name "$PROJECT_ROOT")
    
    # Создаем gradle.properties внутри проекта если его нет
    local project_gradle_props="$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}/gradle.properties"
    local gradlew_path="$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}/gradlew"
    local gradle_dir="$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}"
    
    # Проверяем и создаем директории, если они не существуют
    [ ! -d "$gradle_dir" ] && {
        mkdir -p "$gradle_dir" || error "Не удалось создать директорию Gradle"
    }
    
    # Проверяем и создаем gradle.properties
    if [ ! -f "$project_gradle_props" ]; then
        echo "org.gradle.java.home=/usr/lib/jvm/java-17-openjdk" > "$project_gradle_props" || error "Не удалось создать файл gradle.properties"
    fi
    
    # Проверяем наличие gradlew
    if [ -f "$gradlew_path" ]; then
        # Делаем gradlew исполняемым
        chmod +x "$gradlew_path" || error "Не удалось сделать gradlew исполняемым"
    fi
    
    info "Настраиваем Gradle для работы с Java 11..."
    
    # Путь к gradle.properties
    local gradle_props="$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}/gradle.properties"
    
    # Создаем директорию если её нет
    mkdir -p "$(dirname "$gradle_props")"
    
    # Устанавливаем Android SDK и переменные
    export ANDROID_HOME="$PROJECT_ROOT/.buildozer/android/platform/android-sdk"
    export ANDROID_NDK_HOME="$PROJECT_ROOT/.buildozer/android/platform/android-ndk-r25b"
    
    success "Gradle настроен"
}

# Настройка Gradle для работы с Java 11
setup_gradle_java() {
    info "Настройка Gradle для работы с Java 11..."
    
    # Путь к gradle.properties
    local gradle_props="$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}/gradle.properties"
    
    # Создаем директорию если её нет
    mkdir -p "$(dirname "$gradle_props")"
    
    # Добавляем настройки Java 11
    cat >> "$gradle_props" << EOF
org.gradle.java.home=/usr/lib/jvm/java-11-openjdk
EOF
    
    # Создаем settings.gradle если его нет
    local settings_gradle="$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}/settings.gradle"
    if [ ! -f "$settings_gradle" ]; then
        echo "rootProject.name = '${PROJECT_NAME}'" > "$settings_gradle"
    fi
    
    # Даем права на выполнение gradlew
    chmod +x "$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}/gradlew"
    
    success "Настройка Gradle завершена"
}

# Очистка сборки
clean_build() {
    info "Очищаем предыдущую сборку..."
    
    # Очищаем директорию сборки
    if [ -d "$PROJECT_ROOT/.buildozer" ]; then
        rm -rf "$PROJECT_ROOT/.buildozer/*" || error "Не удалось очистить директорию .buildozer"
    fi
    
    # Очищаем временные файлы Python
    find "$PROJECT_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$PROJECT_ROOT" -type f -name "*.pyc" -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -type f -name "*.pyo" -delete 2>/dev/null || true
    
    success "Сборка очищена"
}

# Настройка переменных окружения Android
setup_android_env() {
    info "Настройка переменных окружения Android..."
    
    # Устанавливаем ANDROID_HOME
    export ANDROID_HOME="$PROJECT_ROOT/.buildozer/android/platform/android-sdk"
    
    # Устанавливаем ANDROID_NDK_HOME
    export ANDROID_NDK_HOME="$PROJECT_ROOT/.buildozer/android/platform/android-ndk-r25b"
    
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
    
    local gradle_dir="$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists/${PROJECT_NAME}"
    
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
    )
    
    # Путь к директории с зависимостями
    local deps_dir="$PROJECT_ROOT/.buildozer/system_deps"
    
    # Проверяем наличие директории
    mkdir -p "$deps_dir" || error "Не удалось создать директорию $deps_dir"
    
    # Проверяем наличие пакетов
    for dep in "${system_deps[@]}"; do
        if [ -f "$deps_dir/$dep.tar.xz" ]; then
            info "Устанавливаем $dep..."
            tar -xvf "$deps_dir/$dep.tar.xz" -C "$deps_dir" || error "Не удалось распаковать $dep"
        else
            error "Отсутствует пакет $dep в $deps_dir"
            return 1
        fi
    done
    
    success "Системные зависимости установлены вручную"
}

# Загрузка системных зависимостей
download_system_deps() {
    info "Загружаем системные зависимости..."
    
    # Создаем директорию для загрузки и установки
    local deps_dir="$PROJECT_ROOT/.buildozer/system_deps"
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
        
        # Проверка существования файла
        if [ -f "$deps_dir/$dep_name.tar.xz" ]; then
            echo "✅ $dep_name уже существует, пропускаем загрузку"
            continue
        fi
        
        # Проверка доступности ссылки с использованием wget с отключенной проверкой SSL
        if ! wget --no-check-certificate --spider "$dep_link" 2>/dev/null; then
            echo "❌ Ошибка: Не удалось получить доступ к $dep_link"
            continue
        fi
        
        # Определяем расширение из ссылки
        file_ext=$(echo "$dep_link" | grep -oP '\.tar\.\K(gz|xz)')
        if ! wget --no-check-certificate -O "$deps_dir/$dep_name.tar.$file_ext" "$dep_link"; then
            echo "❌ Ошибка: Не удалось загрузить $dep_name"
            continue
        fi
        
        # Распаковка файла
        if [[ "$file_ext" == "gz" ]]; then
            if ! tar -xzf "$deps_dir/$dep_name.tar.gz" -C "$deps_dir"; then
                echo "❌ Ошибка: Не удалось распаковать $dep_name.tar.gz"
                continue
            fi
        elif [[ "$file_ext" == "xz" ]]; then
            if ! tar -xJf "$deps_dir/$dep_name.tar.xz" -C "$deps_dir"; then
                echo "❌ Ошибка: Не удалось распаковать $dep_name.tar.xz"
                continue
            fi
        else
            echo "❌ Неизвестный формат архива для $dep_name"
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
    export PYTHON_LOCAL_INSTALL="$PROJECT_ROOT/.local/python3.11.7"
    
    # Создаем директорию для загрузки и установки
    local python_download_dir="$PROJECT_ROOT/.local/share/python_downloads"
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
    
    # Добавляем путь к локальной версии Python в начало PATH
    export PATH="$PYTHON_LOCAL_INSTALL/bin:$PATH"
    
    # Используем локальную версию Python для всех операций
    alias python3="$PYTHON_LOCAL_INSTALL/bin/python3"
    alias pip3="$PYTHON_LOCAL_INSTALL/bin/pip3"
    
    # Проверяем, что версия изменилась
    "$PYTHON_LOCAL_INSTALL/bin/python3" --version
    
    success "Python 3.11.7 успешно установлен в $PYTHON_LOCAL_INSTALL"
    
    # Возвращаемся в исходную директорию
    cd "$OLDPWD"
}

# Универсальная функция для проверки и активации виртуального окружения
ensure_venv_activated() {
    # Проверяем, существует ли путь виртуального окружения
    if [ ! -d "$VENV_DIR" ]; then
        # Если окружение не существует, пытаемся его создать
        setup_venv || {
            error "Не удалось создать виртуальное окружение"
            return 1
        }
    fi
    
    # Проверяем, активировано ли виртуальное окружение
    if [ -z "$VIRTUAL_ENV" ] || [[ "$PATH" != *"$VENV_DIR/bin"* ]]; then
        info "Активация виртуального окружения: $VENV_DIR"
        source "$VENV_DIR/bin/activate"
        if [ $? -ne 0 ]; then
            error "Не удалось активировать виртуальное окружение в $VENV_DIR"
            return 1
        fi
    fi
    
    # Проверяем наличие pip во виртуальном окружении
    if [ ! -x "$VENV_DIR/bin/pip" ]; then
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
    # Определение корневой директории проекта
    export PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
    
    # Определение локальных путей для всех инструментов и зависимостей
    LOCAL_TOOLS_DIR="$PROJECT_ROOT/.local/tools"
    BUILDOZER_LOCAL_DIR="$PROJECT_ROOT/.buildozer/local"

    # Создание базовых директорий
    mkdir -p "$LOCAL_TOOLS_DIR"
    mkdir -p "$BUILDOZER_LOCAL_DIR"
    
    # Пути для Python и виртуального окружения
    PYTHON_DOWNLOAD_DIR="$BUILDOZER_LOCAL_DIR/python_downloads"
    PYTHON_LOCAL_INSTALL="$LOCAL_TOOLS_DIR/python"
    VENV_DIR="$BUILDOZER_LOCAL_DIR/venv"

    # Создание директорий для Python
    mkdir -p "$PYTHON_DOWNLOAD_DIR"
    mkdir -p "$PYTHON_LOCAL_INSTALL"
    mkdir -p "$VENV_DIR"
    mkdir -p "$PROJECT_ROOT/.buildozer/local/python"
    mkdir -p "$PROJECT_ROOT/.buildozer/local/venv"
    
    # Директории для зависимостей и сборки
    SYSTEM_DEPS_DIR="$PROJECT_ROOT/.buildozer/system_deps"
    mkdir -p "$SYSTEM_DEPS_DIR"
    DEPS_DIR="$BUILDOZER_LOCAL_DIR/deps"
    BUILDOZER_DIR="$BUILDOZER_LOCAL_DIR/buildozer"

    mkdir -p "$DEPS_DIR"
    mkdir -p "$BUILDOZER_DIR"
    
    # Директории для Java, Android SDK и NDK
    JAVA_DIR="$LOCAL_TOOLS_DIR/java"
    ANDROID_SDK_DIR="$LOCAL_TOOLS_DIR/android-sdk"
    ANDROID_NDK_DIR="$LOCAL_TOOLS_DIR/android-ndk"
    GRADLE_HOME="$BUILDOZER_LOCAL_DIR/gradle"

    mkdir -p "$JAVA_DIR"
    mkdir -p "$ANDROID_SDK_DIR"
    mkdir -p "$ANDROID_NDK_DIR"
    mkdir -p "$GRADLE_HOME"
    
    # Устанавливаем пути для buildozer и Android внутри проекта
    export BUILDOZER_HOME="$BUILDOZER_LOCAL_DIR"
    export ANDROID_HOME="$ANDROID_SDK_DIR"
    export GRADLE_HOME="$GRADLE_HOME"
    export PROJECT_ROOT="$PROJECT_ROOT"

    # Глобальные пути для конфигурационных файлов
    GRADLE_PROPERTIES="$PROJECT_ROOT/.buildozer/android/platform/gradle/gradle.properties"
    LOCAL_PROPERTIES="$PROJECT_ROOT/local.properties"  # local.properties должен быть в корне проекта
    VENV_DIR="$PROJECT_ROOT/.buildozer/local/venv"
    PYTHON_DIR="$PROJECT_ROOT/.buildozer/local/python"

    # Создаем директории для конфигурационных файлов
    mkdir -p "$(dirname "$GRADLE_PROPERTIES")"
    mkdir -p "$(dirname "$LOCAL_PROPERTIES")"

    # Функция для обновления конфигурационных файлов
    update_config_files() {
        info "Обновление конфигурационных файлов..."
        
        # Создаем директории, если они не существуют
        mkdir -p "$PROJECT_ROOT/.buildozer/android/platform/build-arm64-v8a/dists"
        
        # Обновляем local.properties
        {
            echo "sdk.dir=$ANDROID_SDK_DIR"
            echo "ndk.dir=$ANDROID_NDK_DIR"
            echo "java.home=$JAVA_DIR"
        } > "$LOCAL_PROPERTIES" || error "Не удалось создать файл local.properties"
        
        # Обновляем gradle.properties
        {
            echo "org.gradle.java.home=$JAVA_DIR"
        } > "$GRADLE_PROPERTIES" || error "Не удалось создать файл gradle.properties"
        
        success "Конфигурационные файлы обновлены"
    }
    
    # Обновляем пути к файлам конфигурации
    {
        echo "sdk.dir=$ANDROID_SDK_DIR"
        echo "ndk.dir=$ANDROID_NDK_DIR"
        echo "java.home=$JAVA_DIR"
    } > "$LOCAL_PROPERTIES"
    
    # Обновление gradle.properties
    {
        echo "org.gradle.java.home=$JAVA_DIR"
    } > "$GRADLE_PROPERTIES"

    # Функция для создания всех необходимых директорий
    create_project_directories() {
        info "Создание структуры директорий проекта..."
        
        # Базовые директории для локальных инструментов и зависимостей
        mkdir -p "$LOCAL_TOOLS_DIR"
        mkdir -p "$BUILDOZER_LOCAL_DIR"
        mkdir -p "$DEPS_DIR"
        
        # Директории для Buildozer и сборки
        mkdir -p "$PROJECT_ROOT/.buildozer/android/platform/build-tools"
        mkdir -p "$PROJECT_ROOT/.buildozer/android/platform/gradle"
        mkdir -p "$PROJECT_ROOT/.buildozer/android/platform/local_props"
        
        # Директории для Java, Android SDK и NDK
        mkdir -p "$JAVA_DIR"
        mkdir -p "$ANDROID_SDK_DIR"
        mkdir -p "$ANDROID_NDK_DIR"
        mkdir -p "$GRADLE_HOME"
        
        # Директории для Python и виртуального окружения
        mkdir -p "$PYTHON_DOWNLOAD_DIR"
        mkdir -p "$PYTHON_LOCAL_INSTALL"
        mkdir -p "$VENV_DIR"
        mkdir -p "$PROJECT_ROOT/.buildozer/local/python"
        mkdir -p "$PROJECT_ROOT/.buildozer/local/venv"
        
        success "Структура директорий создана"
    }
    
    # Создание структуры директорий
    create_project_directories
    
    # Обновление конфигурационных файлов
    update_config_files
    
    # Проверка требований
    check_requirements
    
    # Загрузка и установка Python 3.11.7
    download_python_3_11_7 || error "Не удалось установить Python 3.11.7"
    
    # Настройка переменных окружения Android
    setup_android_env
    
    # Настройка Java
    setup_java
    
    # Настройка Gradle
    setup_gradle
    
    # Настройка виртуального окружения
    setup_venv || error "Не удалось настроить виртуальное окружение"
    
    # Установка Kivy
    setup_kivy
    
    # Проверка наличия файла buildozer.spec
    check_buildozer_spec
    
    # Проверка наличия Java
    check_java
    
    # Очистка сборки
    clean_build
    
    # Загрузка системных зависимостей
    download_system_deps
    
    # Ручная установка системных зависимостей
    manual_system_deps
    
    # Отладка сборки Gradle
    debug_gradle
    
    # Локализация зависимостей
   
    success "Настройка окружения завершена успешно"
    info "Теперь вы можете запустить сборку командой: buildozer android debug"
}

# Настройка локальных путей для Android инструментов
setup_local_android_tools() {
    info "Настройка локальных инструментов Android..."
    
    # Создание директорий, если они не существуют
    mkdir -p "$LOCAL_TOOLS_DIR" "$ANDROID_SDK_DIR" "$ANDROID_NDK_DIR"
    
    # Получение последних версий SDK и NDK
    local SDK_URL=$(curl -s https://developer.android.com/studio | grep -oP 'https://dl.google.com/android/repository/commandlinetools-linux-\d+_latest.zip')
    local NDK_URL=$(curl -s https://developer.android.com/ndk/downloads | grep -oP 'https://dl.google.com/android/repository/android-ndk-r\d+[a-z]+-linux.zip')
    
    # Загрузка Android SDK
    wget "${SDK_URL:-https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip}" -O "$LOCAL_TOOLS_DIR/sdk-tools.zip" || {
        error "Не удалось загрузить Android SDK"
        return 1
    }
    
    # Загрузка Android NDK
    wget "${NDK_URL:-https://dl.google.com/android/repository/android-ndk-r23b-linux.zip}" -O "$LOCAL_TOOLS_DIR/ndk.zip" || {
        error "Не удалось загрузить Android NDK"
        return 1
    }
    
    # Распаковка SDK с проверкой
    if [ -z "$(ls -A "$ANDROID_SDK_DIR")" ]; then
        unzip "$LOCAL_TOOLS_DIR/sdk-tools.zip" -d "$ANDROID_SDK_DIR" || {
            error "Не удалось распаковать Android SDK"
            return 1
        }
    else
        warn "Директория Android SDK уже содержит файлы. Пропуск распаковки."
    fi
    
    # Распаковка NDK с проверкой
    if [ -z "$(ls -A "$ANDROID_NDK_DIR")" ]; then
        unzip "$LOCAL_TOOLS_DIR/ndk.zip" -d "$ANDROID_NDK_DIR" --strip-components=1 || {
            error "Не удалось распаковать Android NDK"
            return 1
        }
    else
        warn "Директория Android NDK уже содержит файлы. Пропуск распаковки."
    fi
    
    # Очистка архивов
    rm -f "$LOCAL_TOOLS_DIR/sdk-tools.zip" "$LOCAL_TOOLS_DIR/ndk.zip"
    
    success "Локальные инструменты Android настроены"
}

# Функция для полной локализации зависимостей
localize_dependencies() {
    # Создание директории для локальных инструментов
    # mkdir -p "$LOCAL_TOOLS_DIR"
    
    # Загрузка Java
    download_local_java || {
        error "Не удалось локализовать Java"
        return 1
    }
    
    # Настройка Android инструментов
    setup_local_android_tools || {
        error "Не удалось локализовать Android инструменты"
        return 1
    }
    
    success "Зависимости полностью локализованы в $LOCAL_TOOLS_DIR"
}

# Запуск основного процесса
main
