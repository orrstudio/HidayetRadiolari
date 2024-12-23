#!/bin/bash

# Явное определение директории для зависимостей
export deps_dir=".buildozer/system_deps"

# Проверка и создание директории, если она не существует
if [ ! -d "$deps_dir" ]; then
    mkdir -p "$deps_dir"
    echo "Создана директория: $deps_dir"
fi

# Функция проверки и установки пакетов
check_and_install_packages() {
    local packages=("base-devel" "git" "meson" "ninja" "cmake" "wget" "tar" "xz")
    local missing_packages=()

    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            missing_packages+=("$pkg")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "Следующие пакеты отсутствуют: ${missing_packages[*]}"
        read -p "Хотите установить недостающие пакеты? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            sudo pacman -S --noconfirm "${missing_packages[@]}"
        else
            echo "Установка пакетов отменена. Некоторые функции могут работать некорректно."
        fi
    fi
}

# Вызываем проверку пакетов
check_and_install_packages

# Переход в директорию зависимостей
cd "$deps_dir"

# Список репозиториев плагинов
PLUGINS=(
    "https://github.com/GStreamer/gst-plugins-base.git"
    "https://github.com/GStreamer/gst-plugins-good.git"
    "https://github.com/GStreamer/gst-plugins-bad.git"
    "https://github.com/GStreamer/gst-plugins-ugly.git"
)

# Функция сборки плагинов
build_plugin() {
    local repo_url=$1
    local plugin_name=$(basename $repo_url .git)
    
    git clone $repo_url
    cd $plugin_name
    
    # Переключение на версию 1.22.5
    git checkout 1.22.5
    
    # Настройка сборки
    meson setup builddir \
        -Dprefix="$deps_dir/$plugin_name" \
        -Dbuildtype=release \
        -Ddefault_library=shared
    
    # Сборка
    ninja -C builddir
    
    # Установка
    sudo ninja -C builddir install
    
    # Создание архива
    tar -czvf "$deps_dir/${plugin_name}_1.22.5.tar.gz" builddir
    
    cd ..
}

# Функция загрузки SDL библиотек
download_sdl_libraries() {
    local sdl_libraries=(
        "https://libsdl.org/release/SDL2-2.28.5.tar.gz"
        "https://libsdl.org/projects/SDL_image/release/SDL2_image-2.6.3.tar.gz"
        "https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.0/SDL2_mixer-2.6.0.tar.gz"
        "https://libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.20.2.tar.gz"
    )
    
    mkdir -p "$deps_dir"
    
    for url in "${sdl_libraries[@]}"; do
        wget "$url" -P "$deps_dir"
    done
}

# Функция установки SDL библиотек
install_sdl_libraries() {
    local sdl_libraries=(
        "SDL2-2.28.5"
        "SDL2_image-2.6.3"
        "SDL2_mixer-2.6.0"
        "SDL2_ttf-2.20.2"
    )
    
    for lib in "${sdl_libraries[@]}"; do
        local tar_file="${lib}.tar.gz"
        local extracted_dir="${lib}"
        
        tar -xzf "$deps_dir/$tar_file" -C "$deps_dir"
        cd "$deps_dir/$extracted_dir"
        
        # Настройка с локальным префиксом
        ./configure --prefix="$deps_dir"
        make
        make install
        
        cd ..
    done
}

# Вызываем функцию загрузки SDL библиотек перед установкой
download_sdl_libraries

# Вызываем функцию установки SDL библиотек перед сборкой плагинов
install_sdl_libraries

# Сборка каждого плагина
for plugin in "${PLUGINS[@]}"; do
    build_plugin $plugin
done

# Загрузка GStreamer для Android
GSTREAMER_URL="https://gstreamer.freedesktop.org/data/pkg/android/1.22.5/gstreamer-1.0-android-universal-1.22.5.tar.xz"
GSTREAMER_FILE="gstreamer-1.0-android-universal-1.22.5.tar.xz"

# Скачивание архива
wget "$GSTREAMER_URL" -O "$deps_dir/$GSTREAMER_FILE"

# Распаковка архива
tar -xvf "$deps_dir/$GSTREAMER_FILE" -C "$deps_dir"

# Создание архива GStreamer
tar -czvf "$deps_dir/gstreamer_1.22.5_android.tar.gz" "$deps_dir/gstreamer-1.0-android-universal-1.22.5"

echo "Сборка плагинов и GStreamer 1.22.5 завершена в $deps_dir!"
