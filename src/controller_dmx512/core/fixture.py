"""
Fixture - Representação de um dispositivo de iluminação DMX

Este módulo define as classes Fixture e FixtureType que representam
dispositivos de iluminação e seus tipos.
"""

import json
import logging
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

from .channel import Channel, ChannelType

logger = logging.getLogger(__name__)


class FixtureType(Enum):
    """Tipos de fixtures de iluminação"""

    PAR_CAN = "par_can"
    FLOOD_LIGHT = "flood_light"
    SPOT_LIGHT = "spot_light"
    WASH_LIGHT = "wash_light"
    BEAM_LIGHT = "beam_light"
    MOVING_HEAD = "moving_head"
    SCANNER = "scanner"
    STROBE = "strobe"
    LASER = "laser"
    LED_PANEL = "led_panel"
    LED_STRIP = "led_strip"
    FOG_MACHINE = "fog_machine"
    CUSTOM = "custom"


class Fixture:
    """
    Representa um dispositivo de iluminação (fixture)

    Um fixture é composto por um ou mais canais DMX que controlam
    diferentes funções do dispositivo.
    """

    def __init__(
        self,
        name: str,
        fixture_type: FixtureType,
        start_address: int,
        channels: List[Channel] = None,
    ):
        """
        Inicializa um fixture

        Args:
            name: Nome do fixture
            fixture_type: Tipo do fixture
            start_address: Endereço DMX inicial (1-512)
            channels: Lista de canais do fixture
        """
        if start_address < 1 or start_address > 512:
            raise ValueError("Endereço inicial deve estar entre 1 e 512")

        self.name = name
        self.fixture_type = fixture_type
        self.start_address = start_address
        self.channels: List[Channel] = channels or []
        self.is_active = True

        # Valida endereços dos canais
        self._validate_channel_addresses()

        logger.info(f"Fixture '{name}' criado com {len(self.channels)} canais")

    def _validate_channel_addresses(self):
        """Valida se os endereços dos canais estão corretos"""
        if not self.channels:
            return

        expected_address = self.start_address
        for channel in self.channels:
            if channel.number != expected_address:
                logger.warning(
                    f"Canal {channel.number} não está no endereço esperado {expected_address}"
                )
            expected_address += 1

    def add_channel(self, channel: Channel):
        """
        Adiciona um canal ao fixture

        Args:
            channel: Canal a ser adicionado
        """
        # Verifica se o endereço está disponível
        expected_address = self.start_address + len(self.channels)
        if channel.number != expected_address:
            logger.warning(
                f"Canal {channel.number} adicionado em endereço inesperado {expected_address}"
            )

        self.channels.append(channel)
        logger.debug(f"Canal {channel.number} adicionado ao fixture '{self.name}'")

    def remove_channel_by_index(self, index: int) -> bool:
        """Remove um canal pelo índice e reajusta endereços dos canais seguintes"""
        if 0 <= index < len(self.channels):
            removed = self.channels.pop(index)
            # Reajusta endereços dos canais restantes
            for i, ch in enumerate(self.channels):
                ch.number = self.start_address + i
            logger.debug(f"Canal '{removed.name}' removido do fixture '{self.name}'")
            return True
        return False

    def get_channel(self, channel_number: int) -> Optional[Channel]:
        """
        Retorna um canal específico

        Args:
            channel_number: Número do canal

        Returns:
            Canal encontrado ou None
        """
        for channel in self.channels:
            if channel.number == channel_number:
                return channel
        return None

    def get_channel_by_index(self, index: int) -> Optional[Channel]:
        """
        Retorna um canal pelo índice na lista

        Args:
            index: Índice do canal

        Returns:
            Canal encontrado ou None
        """
        if 0 <= index < len(self.channels):
            return self.channels[index]
        return None

    def set_channel_value(self, channel_number: int, value: int) -> bool:
        """
        Define o valor de um canal específico

        Args:
            channel_number: Número do canal
            value: Valor a ser definido

        Returns:
            True se definido com sucesso
        """
        channel = self.get_channel(channel_number)
        if channel:
            return channel.set_value(value)
        return False

    def set_all_channels(self, values: List[int]) -> bool:
        """
        Define valores para todos os canais

        Args:
            values: Lista de valores para os canais

        Returns:
            True se todos os valores foram definidos
        """
        if len(values) != len(self.channels):
            logger.error(
                f"Número de valores ({len(values)}) não corresponde ao número de canais ({len(self.channels)})"
            )
            return False

        success = True
        for channel, value in zip(self.channels, values):
            if not channel.set_value(value):
                success = False

        return success

    def get_all_values(self) -> List[int]:
        """
        Retorna valores de todos os canais

        Returns:
            Lista com valores de todos os canais
        """
        return [channel.get_value() for channel in self.channels]

    def reset_all_channels(self):
        """Reseta todos os canais para seus valores padrão"""
        for channel in self.channels:
            channel.reset()
        logger.debug(f"Todos os canais do fixture '{self.name}' foram resetados")

    def fade_all_channels(self, target_values: List[int], duration_ms: int = 1000):
        """
        Transição suave para todos os canais

        Args:
            target_values: Lista de valores finais
            duration_ms: Duração da transição em milissegundos
        """
        if len(target_values) != len(self.channels):
            logger.error("Número de valores não corresponde ao número de canais")
            return

        import threading
        import time

        def fade_channel(channel, target_value):
            channel.fade_to(target_value, duration_ms)

        # Cria threads para cada canal
        threads = []
        for channel, target_value in zip(self.channels, target_values):
            thread = threading.Thread(target=fade_channel, args=(channel, target_value))
            threads.append(thread)
            thread.start()

        # Aguarda todas as threads terminarem
        for thread in threads:
            thread.join()

    def get_end_address(self) -> int:
        """
        Retorna o endereço final do fixture

        Returns:
            Endereço do último canal
        """
        if not self.channels:
            return self.start_address
        return self.start_address + len(self.channels) - 1

    def get_channel_count(self) -> int:
        """
        Retorna o número de canais

        Returns:
            Número de canais do fixture
        """
        return len(self.channels)

    def get_info(self) -> Dict[str, Any]:
        """
        Retorna informações completas do fixture

        Returns:
            Dicionário com informações do fixture
        """
        return {
            "name": self.name,
            "type": self.fixture_type.value,
            "start_address": self.start_address,
            "end_address": self.get_end_address(),
            "channel_count": self.get_channel_count(),
            "is_active": self.is_active,
            "channels": [channel.get_info() for channel in self.channels],
        }

    def to_config(self) -> Dict[str, Any]:
        """Exporta o fixture como template de configuração (.dmxfix)"""
        metadata = getattr(self, "config_metadata", {})
        return {
            "name": metadata.get("fixture_name", self.name),
            "manufacturer": metadata.get("manufacturer", ""),
            "brand": metadata.get("brand", ""),
            "model": metadata.get("model", ""),
            "type": self.fixture_type.value,
            "channels": [
                {"name": ch.name, "type": ch.channel_type.value}
                for ch in self.channels
            ],
        }

    def save_config(self, filepath: Union[str, Path]) -> None:
        """Salva o fixture como arquivo de configuração (template .dmxfix)"""
        path = Path(filepath)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(self.to_config(), f, indent=2, ensure_ascii=False)

    def to_dict(self) -> Dict[str, Any]:
        """Serializa o fixture para dicionário (usado para salvar coleção)"""
        return {
            "name": self.name,
            "type": self.fixture_type.value,
            "start_address": self.start_address,
            "is_active": self.is_active,
            "channels": [ch.to_dict() for ch in self.channels],
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Fixture":
        """Cria um fixture a partir de um dicionário serializado"""
        fixture_type = FixtureType(data.get("type", "custom"))
        start_address = data["start_address"]
        channels: List[Channel] = []
        for i, ch_data in enumerate(data.get("channels", [])):
            channels.append(Channel.from_dict(ch_data, start_address + i))
        fixture = cls(
            name=data["name"],
            fixture_type=fixture_type,
            start_address=start_address,
            channels=channels,
        )
        fixture.is_active = data.get("is_active", True)
        return fixture

    @classmethod
    def from_config(cls, config_path: Union[str, Path], name: str, start_address: int) -> "Fixture":
        """Cria um fixture a partir de um arquivo de configuração (template)

        Args:
            config_path: Caminho para o arquivo JSON de configuração
            name: Nome para o fixture
            start_address: Endereço DMX inicial
        """
        path = Path(config_path)
        with open(path, "r", encoding="utf-8") as f:
            cfg = json.load(f)

        fixture_type_str = cfg.get("type", "custom")
        try:
            fixture_type = FixtureType(fixture_type_str)
        except ValueError:
            fixture_type = FixtureType.CUSTOM

        channels: List[Channel] = []
        for i, ch_cfg in enumerate(cfg.get("channels", [])):
            ch = Channel(
                number=start_address + i,
                name=ch_cfg.get("name", f"Canal {i + 1}"),
                channel_type=ChannelType(ch_cfg.get("type", "custom")),
                min_value=ch_cfg.get("min_value", 0),
                max_value=ch_cfg.get("max_value", 255),
                default_value=ch_cfg.get("default_value", 0),
            )
            channels.append(ch)

        fixture = cls(
            name=name,
            fixture_type=fixture_type,
            start_address=start_address,
            channels=channels,
        )
        fixture.config_metadata = {
            "fixture_name": cfg.get("name", ""),
            "manufacturer": cfg.get("manufacturer", ""),
            "brand": cfg.get("brand", ""),
            "model": cfg.get("model", ""),
        }
        return fixture

    def clone(self, new_name: str, new_start_address: int) -> "Fixture":
        """Clona o fixture com novo nome e endereço"""
        channels: List[Channel] = []
        for i, ch in enumerate(self.channels):
            new_ch = Channel(
                number=new_start_address + i,
                name=ch.name,
                channel_type=ch.channel_type,
                min_value=ch.min_value,
                max_value=ch.max_value,
                default_value=ch.default_value,
            )
            channels.append(new_ch)
        return Fixture(
            name=new_name,
            fixture_type=self.fixture_type,
            start_address=new_start_address,
            channels=channels,
        )

    def __str__(self) -> str:
        return f"Fixture('{self.name}', type={self.fixture_type.value}, channels={len(self.channels)})"

    def __repr__(self) -> str:
        return f"Fixture(name='{self.name}', fixture_type={self.fixture_type}, start_address={self.start_address})"


# Fixtures pré-definidos para facilitar o uso
class PredefinedFixtures:
    """Fixtures pré-definidos comuns"""

    @staticmethod
    def create_par_can(name: str, start_address: int) -> Fixture:
        """Cria um PAR Can RGB básico"""
        fixture = Fixture(name, FixtureType.PAR_CAN, start_address)

        # Canal 1: Red
        fixture.add_channel(Channel(start_address, "Red", ChannelType.RED))
        # Canal 2: Green
        fixture.add_channel(Channel(start_address + 1, "Green", ChannelType.GREEN))
        # Canal 3: Blue
        fixture.add_channel(Channel(start_address + 2, "Blue", ChannelType.BLUE))

        return fixture

    @staticmethod
    def create_moving_head(name: str, start_address: int) -> Fixture:
        """Cria um Moving Head básico"""
        fixture = Fixture(name, FixtureType.MOVING_HEAD, start_address)

        # Canais típicos de um moving head
        fixture.add_channel(Channel(start_address, "Dimmer", ChannelType.DIMMER))
        fixture.add_channel(Channel(start_address + 1, "Shutter", ChannelType.SHUTTER))
        fixture.add_channel(Channel(start_address + 2, "Red", ChannelType.RED))
        fixture.add_channel(Channel(start_address + 3, "Green", ChannelType.GREEN))
        fixture.add_channel(Channel(start_address + 4, "Blue", ChannelType.BLUE))
        fixture.add_channel(Channel(start_address + 5, "White", ChannelType.WHITE))
        fixture.add_channel(Channel(start_address + 6, "Pan Fine", ChannelType.PAN))
        fixture.add_channel(Channel(start_address + 7, "Pan Coarse", ChannelType.PAN))
        fixture.add_channel(Channel(start_address + 8, "Tilt Fine", ChannelType.TILT))
        fixture.add_channel(Channel(start_address + 9, "Tilt Coarse", ChannelType.TILT))

        return fixture

    @staticmethod
    def create_led_strip(name: str, start_address: int, led_count: int = 1) -> Fixture:
        """Cria uma LED Strip RGB"""
        fixture = Fixture(name, FixtureType.LED_STRIP, start_address)

        for i in range(led_count):
            base_addr = start_address + (i * 3)
            fixture.add_channel(Channel(base_addr, f"Red {i+1}", ChannelType.RED))
            fixture.add_channel(
                Channel(base_addr + 1, f"Green {i+1}", ChannelType.GREEN)
            )
            fixture.add_channel(Channel(base_addr + 2, f"Blue {i+1}", ChannelType.BLUE))

        return fixture

    @staticmethod
    def create_generic(name: str, start_address: int, channel_count: int = 16) -> Fixture:
        """Cria uma fixture genérica com N canais (padrão 16) para testes"""
        fixture = Fixture(name, FixtureType.CUSTOM, start_address)

        for i in range(channel_count):
            fixture.add_channel(
                Channel(start_address + i, f"Canal {i + 1}", ChannelType.DIMMER)
            )

        return fixture
