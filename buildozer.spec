[app]
title = HidayetRadiolari
package.name = hidayetradiolari
package.domain = org.orrstudio
version = 1.0
orientation = portrait
android.sdk = 28 # Или более новая версия
android.minSdkVersion = 21
android.permissions = INTERNET, ACCESS_NETWORK_STATE
android.add_features = android.hardware.touchscreen
android.ndk = 21 # Или более новая версия
source.dir = .
source.include_exts = py,png,jpg,kv,atlas
#icon.filename = icon.png # Замените на имя вашего файла иконки
#icon.prefix = myvideoapp_
#splash.filename = splash.png # Замените на имя вашего файла заставки
#splash.prefix = myvideoapp_
requirements = python3,kivy,ffpyplayer,ffpyplayer_codecs

[buildozer]
log_level = 2
app_dir = .

[release]
name = HidayetRadiolari
version = 1.0
android.release_mode = debug 
"""
Когда установлено значение debug, это означает, 
что приложение будет собрано в отладочном режиме. 
В отладочном режиме: 
- Включаются дополнительные отладочные символы, 
- Отключена оптимизация, 
- Включены расширенные логи и возможности отладки, 
- Размер приложения обычно больше, 
- Производительность ниже, чем в релизной версии. 
Это полезно при разработке и тестировании приложения, 
так как позволяет легче находить и диагностировать 
ошибки. 
Когда вы будете готовы выпустить финальную версию 
приложения, вам нужно будет изменить это значение 
на 'release', чтобы получить оптимизированную версию 
приложения.
"""