"""
Módulo core - Funcionalidades principais do controlador DMX512

Este módulo contém as classes e funções fundamentais para:
- Controle de comunicação DMX512
- Gerenciamento de fixtures e canais
- Protocolo de comunicação RS485
"""

from .channel import Channel
from .dmx_controller import DMXController
from .fixture import Fixture, FixtureType
from .protocol import DMXProtocol
from .rdm import RDMDeviceInfo, RDMUID

__all__ = [
    "DMXController",
    "Fixture",
    "FixtureType",
    "Channel",
    "DMXProtocol",
    "RDMUID",
    "RDMDeviceInfo",
]
