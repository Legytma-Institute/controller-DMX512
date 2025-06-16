"""
Interface Gráfica - Módulo para interface gráfica do controlador DMX512

Este módulo contém as classes e widgets para a interface gráfica
do controlador de iluminação.
"""

from .channel_widget import ChannelWidget
from .fixture_widget import FixtureWidget
from .main_window import MainWindow
from .universe_widget import UniverseWidget

__all__ = [
    "MainWindow",
    "FixtureWidget",
    "ChannelWidget",
    "UniverseWidget",
]
