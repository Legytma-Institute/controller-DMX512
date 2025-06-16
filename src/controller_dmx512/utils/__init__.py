"""
Utilitários - Funções auxiliares para o controlador DMX512

Este módulo contém funções utilitárias para o projeto.
"""

from .color_utils import dmx_to_rgb, hex_to_rgb, rgb_to_dmx
from .file_utils import load_fixture_config, save_fixture_config

__all__ = [
    "rgb_to_dmx",
    "dmx_to_rgb",
    "hex_to_rgb",
    "save_fixture_config",
    "load_fixture_config",
]
