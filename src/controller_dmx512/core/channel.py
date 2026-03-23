"""
Canal DMX - Representação de um canal individual do protocolo DMX512

Este módulo define a classe Channel que representa um canal DMX
individual com suas propriedades e funcionalidades.
"""

import logging
from enum import Enum
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


class ChannelType(Enum):
    """Tipos de canais DMX"""

    DIMMER = "dimmer"
    RED = "red"
    GREEN = "green"
    BLUE = "blue"
    WHITE = "white"
    AMBER = "amber"
    UV = "uv"
    PAN = "pan"
    TILT = "tilt"
    GOBO = "gobo"
    COLOR_WHEEL = "color_wheel"
    SHUTTER = "shutter"
    FOCUS = "focus"
    ZOOM = "zoom"
    STROBE = "strobe"
    SPEED = "speed"
    CUSTOM = "custom"


class Channel:
    """
    Representa um canal DMX individual

    Um canal DMX é um byte (0-255) que controla uma função específica
    de um dispositivo de iluminação.
    """

    def __init__(
        self,
        number: int,
        name: str = "",
        channel_type: ChannelType = ChannelType.CUSTOM,
        min_value: int = 0,
        max_value: int = 255,
        default_value: int = 0,
    ):
        """
        Inicializa um canal DMX

        Args:
            number: Número do canal (1-512)
            name: Nome descritivo do canal
            channel_type: Tipo do canal
            min_value: Valor mínimo permitido
            max_value: Valor máximo permitido
            default_value: Valor padrão do canal
        """
        if number < 1 or number > 512:
            raise ValueError("Número do canal deve estar entre 1 e 512")

        if min_value < 0 or max_value > 255 or min_value > max_value:
            raise ValueError("Valores inválidos para min/max")

        if default_value < min_value or default_value > max_value:
            raise ValueError("Valor padrão fora do intervalo permitido")

        self.number = number
        self.name = name or f"Canal {number}"
        self.channel_type = channel_type
        self.min_value = min_value
        self.max_value = max_value
        self.default_value = default_value
        self.current_value = default_value
        self.is_active = True

        # Histórico de valores para efeitos
        self.value_history: list[int] = []
        self.max_history_size = 100

    def set_value(self, value: int) -> bool:
        """
        Define o valor do canal

        Args:
            value: Novo valor (0-255)

        Returns:
            True se o valor foi definido com sucesso
        """
        if not self.is_active:
            logger.warning(f"Canal {self.number} está inativo")
            return False

        # Valida o valor
        if value < self.min_value or value > self.max_value:
            logger.warning(
                f"Valor {value} fora do intervalo [{self.min_value}, {self.max_value}]"
            )
            return False

        # Adiciona ao histórico
        self.value_history.append(self.current_value)
        if len(self.value_history) > self.max_history_size:
            self.value_history.pop(0)

        self.current_value = value
        logger.debug(f"Canal {self.number} definido para {value}")
        return True

    def get_value(self) -> int:
        """
        Retorna o valor atual do canal

        Returns:
            Valor atual do canal
        """
        return self.current_value

    def reset(self):
        """Reseta o canal para o valor padrão"""
        self.set_value(self.default_value)
        self.value_history.clear()
        logger.debug(f"Canal {self.number} resetado para valor padrão")

    def fade_to(self, target_value: int, duration_ms: int = 1000, steps: int = 50):
        """
        Transição suave para um valor específico

        Args:
            target_value: Valor final desejado
            duration_ms: Duração da transição em milissegundos
            steps: Número de passos para a transição
        """
        if not self.is_active:
            return

        import time

        start_value = self.current_value
        step_delay = duration_ms / steps / 1000.0  # Converte para segundos

        for i in range(steps + 1):
            progress = i / steps
            current_value = int(start_value + (target_value - start_value) * progress)
            self.set_value(current_value)
            time.sleep(step_delay)

    def get_percentage(self) -> float:
        """
        Retorna o valor como porcentagem

        Returns:
            Valor como porcentagem (0.0 - 1.0)
        """
        return (self.current_value - self.min_value) / (self.max_value - self.min_value)

    def set_percentage(self, percentage: float) -> bool:
        """
        Define o valor usando porcentagem

        Args:
            percentage: Porcentagem (0.0 - 1.0)

        Returns:
            True se definido com sucesso
        """
        if percentage < 0.0 or percentage > 1.0:
            return False

        value = int(self.min_value + percentage * (self.max_value - self.min_value))
        return self.set_value(value)

    def get_info(self) -> Dict[str, Any]:
        """
        Retorna informações completas do canal

        Returns:
            Dicionário com informações do canal
        """
        return {
            "number": self.number,
            "name": self.name,
            "type": self.channel_type.value,
            "current_value": self.current_value,
            "default_value": self.default_value,
            "min_value": self.min_value,
            "max_value": self.max_value,
            "percentage": self.get_percentage(),
            "is_active": self.is_active,
            "history_size": len(self.value_history),
        }

    def to_dict(self) -> Dict[str, Any]:
        """Serializa o canal para dicionário"""
        return {
            "name": self.name,
            "type": self.channel_type.value,
            "min_value": self.min_value,
            "max_value": self.max_value,
            "default_value": self.default_value,
            "current_value": self.current_value,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any], number: int) -> "Channel":
        """Cria um canal a partir de um dicionário

        Args:
            data: Dicionário com dados do canal
            number: Número (endereço) do canal
        """
        channel_type = ChannelType(data.get("type", "custom"))
        ch = cls(
            number=number,
            name=data.get("name", f"Canal {number}"),
            channel_type=channel_type,
            min_value=data.get("min_value", 0),
            max_value=data.get("max_value", 255),
            default_value=data.get("default_value", 0),
        )
        if "current_value" in data:
            ch.set_value(data["current_value"])
        return ch

    def __str__(self) -> str:
        return f"Channel({self.number}: {self.name}, value={self.current_value})"

    def __repr__(self) -> str:
        return f"Channel(number={self.number}, name='{self.name}', value={self.current_value})"
