import kivy
kivy.require('2.3.0')

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
import webbrowser
import platform
import sys
import traceback
import logging

# Настройка логирования
logging.basicConfig(
    level=logging.DEBUG, 
    format='%(asctime)s - %(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)

class WebViewApp(App):
    def build(self):
        # Отладочная информация о системе
        logger.debug(f"Python Version: {sys.version}")
        logger.debug(f"Platform: {platform.platform()}")
        logger.debug(f"System: {platform.system()}")
        
        try:
            # Попытка импорта дополнительных модулей
            import jnius
            logger.debug(f"Pyjnius Version: {jnius.__version__}")
        except ImportError:
            logger.warning("Pyjnius не установлен")
        
        layout = BoxLayout(orientation='vertical')
        
        label = Label(text='Hidayet Radiolari', font_size='20sp')
        layout.add_widget(label)
        
        button = Button(
            text='Открыть YouTube', 
            on_press=self.open_url
        )
        layout.add_widget(button)
        
        return layout
    
    def open_url(self, instance):
        url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        
        try:
            if platform.system() == 'Android':
                try:
                    from jnius import autoclass
                    logger.debug("Попытка открыть URL через Android Intent")
                    PythonActivity = autoclass('org.kivy.android.PythonActivity')
                    Intent = autoclass('android.content.Intent')
                    Uri = autoclass('android.net.Uri')
                    
                    intent = Intent(Intent.ACTION_VIEW)
                    intent.setData(Uri.parse(url))
                    current_activity = PythonActivity.mActivity
                    current_activity.startActivity(intent)
                    logger.debug("URL успешно открыт через Android Intent")
                except ImportError:
                    logger.warning("Не удалось импортировать pyjnius. Используем альтернативный метод.")
                    import webbrowser
                    webbrowser.open(url)
            elif platform.system() == 'Darwin':  # macOS
                import subprocess
                subprocess.call(['open', url])
            elif platform.system() == 'Windows':
                import os
                os.startfile(url)
            else:  # Linux
                webbrowser.open(url)
        except Exception as e:
            logger.error(f"Ошибка открытия URL: {e}")
            logger.error(traceback.format_exc())

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