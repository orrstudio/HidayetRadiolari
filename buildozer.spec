[app]
title = HidayetRadiolari
package.name = hidayetradiolari
package.domain = org.orrstudio
source.dir = .
source.include_exts = py,png,jpg,kv,atlas,txt
source.include_patterns = radios-list.txt,assets/*
source.exclude_patterns = **/*unittest*.py,**/*test*.py,**/googletest/**/*.py,**/*release_docs.py,**/lldb/**/*.py,**/clang/*.py,**/share/clang/*.py
version = 1.0
requirements = python3==3.11.7,kivy==2.3.0,kivymd==1.2.0,requests==2.32.3,pyjnius==1.6.1,Cython==3.0.11
orientation = portrait
fullscreen = 1
android.permissions = INTERNET,WRITE_EXTERNAL_STORAGE

# Android настройки
android.api = 34
android.minapi = 21
android.ndk = 25b
android.ndk_path = ./.buildozer/android/platform/android-ndk-r25b
android.accept_sdk_license = True
android.accept_license = True
android.archs = arm64-v8a
android.sdk = 34
android.sdk_path = ./.buildozer/android/platform/android-sdk
android.sdk_build_tools_version = 34.0.0

# URL для загрузки компонентов
android.python_source_dir = ./.buildozer/android/platform/build-arm64-v8a/packages/python3/Python-3.11.7
android.sdk_download_url = https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
android.ndk_download_url = https://dl.google.com/android/repository/android-ndk-r25b-linux.zip
android.ant_path = ./.buildozer/android/platform/tools/apache-ant-1.10.14/bin/ant

# Java и Gradle настройки
android.gradle_dependencies = com.google.android.exoplayer:exoplayer:2.19.1
android.enable_androidx = True
android.gradle_version = 8.1.1
android.build_tools_version = 34.0.0
android.java_version = 11

# p4a настройки
p4a.branch = master
p4a.source_dir = ./.buildozer/android/platform/python-for-android

[buildozer]
# Добавим отладочную информацию
log_level = 2
warn_on_root = 1
