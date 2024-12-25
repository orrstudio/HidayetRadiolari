[app]
title = HidayetRadiolari
package.name = hidayetradiolari
package.domain = org.orrstudio
version = 1.0
orientation = portrait
android.minSdkVersion = 23
android.api = 30
android.minapi = 23
android.permissions = INTERNET, ACCESS_NETWORK_STATE
android.add_features = android.hardware.touchscreen
android.ndk_path = /home/orr/.buildozer/android/platform/android-ndk-r25b
android.ndk = https://dl.google.com/android/repository/android-ndk-r25b-linux.zip
android.accept_sdk_license = True
android.accept_license = True
android.archs = arm64-v8a, armeabi-v7a
android.sdk_build_tools_version = 30.0.3
source.dir = .
source.include_exts = py,png,jpg,kv,atlas,txt
source.include_patterns = icons/*.png,fonts/*,audio/*,images/*,radios-list.txt,assets/*
source.exclude_patterns = **/*unittest*.py,**/*test*.py
icon.filename = icons/icon.png
icon.prefix = hidayetradiolari_
splash.filename = icons/presplash.png
splash.prefix = hidayetradiolari_
requirements = python3==3.9.16,kivy==2.3.0,kivymd==1.2.0,requests==2.32.3,pyjnius==1.5.0,Cython==3.0.5,python-for-android==2024.1.21,plyer==2.1.0

# Java и Gradle настройки
android.enable_androidx = True
android.java_version = 17
android.java_home = /usr/lib/jvm/java-17-openjdk
android.gradle_version = 8.0
android.gradle_plugin = 8.0
android.gradle_java_home = /usr/lib/jvm/java-17-openjdk

[buildozer]
log_level = 2
warn_on_root = 1

[release]
name = HidayetRadiolari
version = 1.0
android.release_mode = debug
