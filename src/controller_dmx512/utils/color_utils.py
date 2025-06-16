"""
Utilitários de Cor - Funções para manipulação de cores em DMX

Este módulo fornece funções para conversão entre diferentes
formatos de cor e valores DMX.
"""

import colorsys
from typing import List, Tuple


def rgb_to_dmx(r: int, g: int, b: int) -> List[int]:
    """
    Converte valores RGB (0-255) para valores DMX

    Args:
        r: Componente vermelho (0-255)
        g: Componente verde (0-255)
        b: Componente azul (0-255)

    Returns:
        Lista com valores DMX [R, G, B]
    """
    return [max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b))]


def dmx_to_rgb(dmx_values: List[int]) -> Tuple[int, int, int]:
    """
    Converte valores DMX para RGB

    Args:
        dmx_values: Lista com valores DMX [R, G, B]

    Returns:
        Tupla com valores RGB (R, G, B)
    """
    if len(dmx_values) < 3:
        return (0, 0, 0)

    return (dmx_values[0], dmx_values[1], dmx_values[2])


def hex_to_rgb(hex_color: str) -> Tuple[int, int, int]:
    """
    Converte cor hexadecimal para RGB

    Args:
        hex_color: Cor em formato hexadecimal (ex: "#FF0000" ou "FF0000")

    Returns:
        Tupla com valores RGB (R, G, B)
    """
    # Remove # se presente
    hex_color = hex_color.lstrip("#")

    if len(hex_color) != 6:
        raise ValueError("Cor hexadecimal deve ter 6 caracteres")

    try:
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)
        return (r, g, b)
    except ValueError:
        raise ValueError("Cor hexadecimal inválida")


def rgb_to_hex(r: int, g: int, b: int) -> str:
    """
    Converte valores RGB para hexadecimal

    Args:
        r: Componente vermelho (0-255)
        g: Componente verde (0-255)
        b: Componente azul (0-255)

    Returns:
        Cor em formato hexadecimal (#RRGGBB)
    """
    return f"#{r:02x}{g:02x}{b:02x}"


def hsv_to_rgb(h: float, s: float, v: float) -> Tuple[int, int, int]:
    """
    Converte valores HSV para RGB

    Args:
        h: Matiz (0.0-1.0)
        s: Saturação (0.0-1.0)
        v: Valor (0.0-1.0)

    Returns:
        Tupla com valores RGB (R, G, B)
    """
    rgb = colorsys.hsv_to_rgb(h, s, v)
    return tuple(int(c * 255) for c in rgb)


def rgb_to_hsv(r: int, g: int, b: int) -> Tuple[float, float, float]:
    """
    Converte valores RGB para HSV

    Args:
        r: Componente vermelho (0-255)
        g: Componente verde (0-255)
        b: Componente azul (0-255)

    Returns:
        Tupla com valores HSV (H, S, V)
    """
    rgb_normalized = (r / 255.0, g / 255.0, b / 255.0)
    return colorsys.rgb_to_hsv(*rgb_normalized)


def kelvin_to_rgb(kelvin: int) -> Tuple[int, int, int]:
    """
    Converte temperatura de cor (Kelvin) para RGB

    Args:
        kelvin: Temperatura em Kelvin (1000-12000)

    Returns:
        Tupla com valores RGB (R, G, B)
    """
    # Limita o range
    kelvin = max(1000, min(12000, kelvin))

    # Algoritmo simplificado para conversão Kelvin -> RGB
    if kelvin <= 6600:
        # Cores quentes (amarelo/laranja)
        temp = kelvin / 100
        if temp <= 66:
            red = 255
            green = max(0, min(255, 99.4708025861 * (temp - 60) - 161.1195681661))
        else:
            red = max(0, min(255, 329.698727446 * ((temp - 60) ** -0.1332047592)))
            green = max(0, min(255, 288.1221695283 * ((temp - 60) ** -0.0755148492)))
        blue = 255 if temp >= 66 else 0
    else:
        # Cores frias (azul)
        temp = (kelvin - 6600) / 100
        red = max(0, min(255, 255 - 255 * (temp / 54)))
        green = max(0, min(255, 255 - 255 * (temp / 54)))
        blue = 255

    return (int(red), int(green), int(blue))


def create_color_wheel(steps: int = 360) -> List[Tuple[int, int, int]]:
    """
    Cria uma roda de cores

    Args:
        steps: Número de passos na roda de cores

    Returns:
        Lista de cores RGB
    """
    colors = []
    for i in range(steps):
        hue = i / steps
        rgb = hsv_to_rgb(hue, 1.0, 1.0)
        colors.append(rgb)
    return colors


def interpolate_colors(
    color1: Tuple[int, int, int], color2: Tuple[int, int, int], steps: int
) -> List[Tuple[int, int, int]]:
    """
    Interpola entre duas cores

    Args:
        color1: Primeira cor RGB
        color2: Segunda cor RGB
        steps: Número de passos de interpolação

    Returns:
        Lista de cores interpoladas
    """
    colors = []
    for i in range(steps):
        factor = i / (steps - 1) if steps > 1 else 0
        r = int(color1[0] + (color2[0] - color1[0]) * factor)
        g = int(color1[1] + (color2[1] - color1[1]) * factor)
        b = int(color1[2] + (color2[2] - color1[2]) * factor)
        colors.append((r, g, b))
    return colors
