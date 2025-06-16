"""
Controlador DMX512 - Sistema para controle de iluminação via protocolo DMX512/RS485

Este pacote fornece funcionalidades para:
- Comunicação com dispositivos DMX512 via porta RS485
- Interface gráfica para controle de iluminação
- Gerenciamento de fixtures e canais DMX
- Configuração e monitoramento de dispositivos
"""

__version__ = "0.1.0"
__author__ = "Alex Manoel Ferreira Silva (Windol)"
__email__ = "alex@legytma.com.br"

from .core.channel import Channel

# Imports principais para facilitar o uso
from .core.dmx_controller import DMXController
from .core.fixture import Fixture, FixtureType
from .gui.main_window import MainWindow

__all__ = [
    "DMXController",
    "Fixture",
    "FixtureType",
    "Channel",
    "MainWindow",
]
