import os
import sys
import traceback
import logging
import platform
import importlib.util
import ctypes
import kivy
kivy.require('2.3.0')

# Получение корректного пути для логов на Android
def get_android_log_path():
    try:
        from jnius import autoclass
        
        # Получаем контекст приложения
        PythonActivity = autoclass('org.kivy.android.PythonActivity')
        context = PythonActivity.mActivity.getApplicationContext()
        
        # Получаем директории
        files_dir = context.getFilesDir().getAbsolutePath()
        external_dir = context.getExternalFilesDir(None).getAbsolutePath() if context.getExternalFilesDir(None) else None
        download_dir = '/storage/emulated/0/Download'
        
        # Диагностическая информация
        print(f"PYTHON_DIRS: files_dir={files_dir}, external_dir={external_dir}, download_dir={download_dir}")
        
        # Пробуем разные пути
        paths_to_try = [
            os.path.join(files_dir, 'app_debug.log'),
            os.path.join(external_dir, 'app_debug.log') if external_dir else None,
            os.path.join(download_dir, 'app_debug.log')
        ]
        
        for log_path in paths_to_try:
            if log_path:
                try:
                    with open(log_path, 'a') as f:
                        f.write(f"Log path test: {log_path}\n")
                    print(f"PYTHON_LOG_PATH: Successfully wrote to {log_path}")
                    return log_path
                except Exception as e:
                    print(f"PYTHON_LOG_ERROR: Cannot write to {log_path}: {e}")
        
        # Крайний случай
        return 'app_debug.log'
    except Exception as e:
        print(f"PYTHON_GLOBAL_ERROR: {e}")
        return 'app_debug.log'

# Настройка логирования с явной обработкой ошибок
try:
    log_file_path = get_android_log_path()
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        filename=log_file_path,
        filemode='w'
    )
    logger = logging.getLogger(__name__)
    logger.debug(f"Лог-файл успешно создан: {log_file_path}")
    print(f"PYTHON_LOG: Логирование инициализировано в {log_file_path}")
except Exception as e:
    print(f"PYTHON_CRITICAL: ОШИБКА ЛОГИРОВАНИЯ: {e}")
    print(f"PYTHON_TRACEBACK: {traceback.format_exc()}")
    # Fallback на stdout
    logging.basicConfig(level=logging.DEBUG)
    logger = logging.getLogger(__name__)
    logger.error(f"Не удалось создать лог-файл: {e}")

# Глобальный обработчик вывода
def write_log(message):
    try:
        log_path = get_android_log_path()
        
        # Запись в файл
        with open(log_path, 'a') as log_file:
            log_file.write(f"{message}\n")
        
        # Вывод в stdout
        print(message, flush=True)
        
        # Вывод в stderr
        print(message, file=sys.stderr, flush=True)
    except Exception as e:
        # Крайний случай - вывод прямо в stderr
        print(f"LOGGING ERROR: {e}", file=sys.stderr, flush=True)

# Перенаправление stdout и stderr
class LoggerWriter:
    def write(self, message):
        write_log(message)
    
    def flush(self):
        pass

sys.stdout = LoggerWriter()
sys.stderr = LoggerWriter()

# Начальная диагностика
write_log("PYTHON_START: Инициализация приложения")
write_log(f"PYTHON_PATH: {sys.path}")
write_log(f"PYTHON_VERSION: {sys.version}")
write_log(f"LOG_FILE_PATH: {get_android_log_path()}")

# Дополнительная диагностика
logger.debug(f"Текущая директория: {os.getcwd()}")
logger.debug(f"Абсолютный путь скрипта: {os.path.abspath(__file__)}")
logger.debug(f"Доступные права: {oct(os.stat('.').st_mode)}")

print("PYTHON_LOG: Основная инициализация завершена")

# Логирование пути к лог-файлу при старте
logger.debug(f"Лог-файл создан по пути: {log_file_path}")

# Глобальный обработчик исключений с максимально подробной информацией
def global_exception_handler(exctype, value, tb):
    error_message = f"""
КРИТИЧЕСКАЯ ОШИБКА:
Тип: {exctype.__name__}
Значение: {value}
Платформа: {platform.platform()}
Версия Python: {sys.version}
Путь Python: {sys.path}

Полная трассировка:
{''.join(traceback.format_exception(exctype, value, tb))}
"""
    logger.critical(error_message)
    print(error_message)  # Дублируем в консоль

sys.excepthook = global_exception_handler

# Расширенная диагностика библиотек
def diagnose_libraries():
    logger.debug("Диагностика библиотек:")
    
    # Список библиотек для проверки
    libraries_to_check = [
        'pyjnius', 'kivy', 'kivymd', 'jnius', 
        'requests', 'ctypes', 'platform'
    ]
    
    for lib_name in libraries_to_check:
        try:
            lib = importlib.import_module(lib_name)
            logger.debug(f"Библиотека {lib_name} успешно импортирована. Версия: {getattr(lib, '__version__', 'Неизвестна')}")
        except Exception as e:
            logger.warning(f"Не удалось импортировать {lib_name}: {e}")

# Проверка окружения
def check_environment():
    logger.debug(f"Текущий путь: {os.getcwd()}")
    logger.debug(f"Путь Python: {sys.path}")
    logger.debug(f"Версия Python: {sys.version}")
    logger.debug(f"Исполняемый файл Python: {sys.executable}")
    logger.debug(f"Платформа: {platform.platform()}")
    logger.debug(f"Система: {platform.system()}")

# Вызов диагностических функций
diagnose_libraries()
check_environment()

# Расширенное логирование с полной трассировкой
def log_full_exception(e):
    logger.error(f"Полная трассировка ошибки: {e}")
    logger.error(traceback.format_exc())

# Функция для загрузки библиотек Python с расширенной диагностикой
def load_python_libraries():
    try:
        logger.debug(f"Текущий путь выполнения: {os.getcwd()}")
        logger.debug(f"Путь Python: {sys.path}")
        logger.debug(f"Версия Python: {sys.version}")
        logger.debug(f"Исполняемый файл Python: {sys.executable}")
    except Exception as e:
        logger.error(f"Ошибка при получении системной информации: {e}")

    python_lib_versions = ['python3.9']
    
    for version in python_lib_versions:
        try:
            lib_name = f'libpython{version}.so'
            logger.debug(f"Попытка загрузить библиотеку: {lib_name}")
            
            standard_paths = [
                f'/usr/lib/{lib_name}',
                f'/usr/local/lib/{lib_name}',
                f'/lib/{lib_name}',
                f'/data/app/~~bRLV9MKQ8sbzrAW6KPQRIQ==/org.orrstudio.hidayetradiolari-IX1o-2tT_vE1QYJZPoH6rQ==/lib/arm64/{lib_name}'
            ]
            
            for path in standard_paths:
                logger.debug(f"Проверка пути: {path}")
                if os.path.exists(path):
                    try:
                        logger.debug(f"Попытка загрузки библиотеки: {path}")
                        lib = ctypes.CDLL(path, mode=ctypes.RTLD_GLOBAL)
                        logger.debug(f"Успешно загружена библиотека: {path}")
                        return True
                    except Exception as e:
                        log_full_exception(e)
        
        except Exception as e:
            log_full_exception(e)
    
    logger.error("Не удалось загрузить библиотеку Python")
    return False

# Расширенная диагностика перед загрузкой библиотек
load_python_libraries()

# Отладочная информация о системе и Python
logger.debug(f"Python Version: {sys.version}")
logger.debug(f"Python Executable: {sys.executable}")
logger.debug(f"Python Path: {sys.path}")
logger.debug(f"Platform: {platform.platform()}")
logger.debug(f"System: {platform.system()}")

# Добавление путей к библиотекам Python
python_lib_paths = [
    '/usr/lib/libpython3.9.so',
    '/usr/lib/libpython3.5m.so',
    '/usr/lib/libpython3.6m.so',
    '/usr/lib/libpython3.7m.so',
    '/usr/lib/libpython3.8.so',
    '/usr/lib/libpython3.10.so',
    '/usr/lib/libpython3.11.so'
]

for lib_path in python_lib_paths:
    if os.path.exists(lib_path):
        try:
            os.environ['LD_LIBRARY_PATH'] = os.path.dirname(lib_path)
            logger.debug(f"Добавлен путь к библиотеке: {lib_path}")
        except Exception as e:
            logger.warning(f"Не удалось добавить путь {lib_path}: {e}")

# Проверка доступных библиотек
try:
    def check_library(lib_name):
        spec = importlib.util.find_spec(lib_name)
        if spec is not None:
            logger.debug(f"Library {lib_name} found at: {spec.origin}")
        else:
            logger.warning(f"Library {lib_name} not found")

    libraries_to_check = [
        'kivy', 'kivymd', 'jnius', 'plyer', 
        'requests', 'Cython', 'webbrowser'
    ]
    
    for lib in libraries_to_check:
        check_library(lib)
except Exception as e:
    logger.error(f"Error checking libraries: {e}")

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
import webbrowser

class WebViewApp(App):
    def build(self):
        try:
            logger.debug("Начало построения интерфейса")
            
            # Создание корневого макета
            layout = BoxLayout(orientation='vertical')
            
            # Добавление WebView
            try:
                from jnius import autoclass
                WebView = autoclass('android.webkit.WebView')
                WebViewClient = autoclass('android.webkit.WebViewClient')
                
                logger.debug("Импорт WebView успешен")
            except Exception as e:
                logger.error(f"Ошибка импорта WebView: {e}")
                log_full_exception(e)
                return Label(text=f'Ошибка импорта WebView: {e}')
            
            try:
                webview = WebView(self.get_running_app())
                webview.getSettings().setJavaScriptEnabled(True)
                
                logger.debug("WebView создан")
            except Exception as e:
                logger.error(f"Ошибка создания WebView: {e}")
                log_full_exception(e)
                return Label(text=f'Ошибка создания WebView: {e}')
            
            # Кнопка открытия URL
            btn = Button(text='Открыть URL', on_press=self.open_url)
            
            # Добавление элементов в макет
            layout.add_widget(webview)
            layout.add_widget(btn)
            
            logger.debug("Интерфейс построен успешно")
            return layout
        
        except Exception as e:
            logger.error(f"Критическая ошибка в build(): {e}")
            log_full_exception(e)
            return Label(text=f'Критическая ошибка: {e}')

    def open_url(self, instance):
        try:
            url = 'https://hidayetradiolari.com'
            logger.debug(f"Попытка открыть URL: {url}")
            
            # Проверка доступности библиотек
            try:
                import jnius
                logger.debug(f"Версия pyjnius: {jnius.__version__}")
            except ImportError as e:
                logger.error(f"Не удалось импортировать pyjnius: {e}")
                return
            
            from jnius import autoclass
            PythonActivity = autoclass('org.kivy.android.PythonActivity')
            Intent = autoclass('android.content.Intent')
            Uri = autoclass('android.net.Uri')
            
            intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            current_activity = PythonActivity.mActivity
            current_activity.startActivity(intent)
            
            logger.debug("URL открыт успешно")
        
        except Exception as e:
            logger.error(f"Ошибка открытия URL: {e}")
            log_full_exception(e)

def main():
    try:
        logger.debug("Запуск приложения WebViewApp")
        WebViewApp().run()
    except Exception as e:
        logger.critical(f"Критическая ошибка приложения: {e}")
        logger.critical(traceback.format_exc())
        sys.exit(1)

if __name__ == '__main__':
    main()