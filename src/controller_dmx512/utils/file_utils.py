"""
Utilitários de Arquivo - Funções para manipulação de arquivos de configuração

Este módulo fornece funções para salvar e carregar configurações
de fixtures e outros dados do controlador DMX.
"""

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

import yaml

from ..core.channel import Channel, ChannelType
from ..core.fixture import Fixture, FixtureType

logger = logging.getLogger(__name__)


def save_fixture_config(
    fixtures: List[Fixture], filepath: str, format: str = "json"
) -> bool:
    """
    Salva configuração de fixtures em arquivo

    Args:
        fixtures: Lista de fixtures para salvar
        filepath: Caminho do arquivo
        format: Formato do arquivo ("json" ou "yaml")

    Returns:
        True se salvo com sucesso
    """
    try:
        # Converte fixtures para dicionário
        fixtures_data = []
        for fixture in fixtures:
            fixture_data = {
                "name": fixture.name,
                "type": fixture.fixture_type.value,
                "start_address": fixture.start_address,
                "is_active": fixture.is_active,
                "channels": [],
            }

            for channel in fixture.channels:
                channel_data = {
                    "number": channel.number,
                    "name": channel.name,
                    "type": channel.channel_type.value,
                    "min_value": channel.min_value,
                    "max_value": channel.max_value,
                    "default_value": channel.default_value,
                    "is_active": channel.is_active,
                }
                fixture_data["channels"].append(channel_data)

            fixtures_data.append(fixture_data)

        # Salva no formato especificado
        if format.lower() == "json":
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(fixtures_data, f, indent=2, ensure_ascii=False)
        elif format.lower() == "yaml":
            with open(filepath, "w", encoding="utf-8") as f:
                yaml.dump(
                    fixtures_data, f, default_flow_style=False, allow_unicode=True
                )
        else:
            raise ValueError(f"Formato não suportado: {format}")

        logger.info(f"Configuração salva em {filepath}")
        return True

    except Exception as e:
        logger.error(f"Erro ao salvar configuração: {e}")
        return False


def load_fixture_config(filepath: str) -> List[Fixture]:
    """
    Carrega configuração de fixtures de arquivo

    Args:
        filepath: Caminho do arquivo

    Returns:
        Lista de fixtures carregados
    """
    try:
        # Determina formato pelo extensão
        file_path = Path(filepath)
        if file_path.suffix.lower() in [".yaml", ".yml"]:
            format = "yaml"
        else:
            format = "json"

        # Carrega dados
        if format == "json":
            with open(filepath, "r", encoding="utf-8") as f:
                fixtures_data = json.load(f)
        else:  # yaml
            with open(filepath, "r", encoding="utf-8") as f:
                fixtures_data = yaml.safe_load(f)

        # Converte dados para fixtures
        fixtures = []
        for fixture_data in fixtures_data:
            # Cria fixture
            fixture_type = FixtureType(fixture_data["type"])
            fixture = Fixture(
                name=fixture_data["name"],
                fixture_type=fixture_type,
                start_address=fixture_data["start_address"],
            )
            fixture.is_active = fixture_data.get("is_active", True)

            # Adiciona canais
            for channel_data in fixture_data["channels"]:
                channel_type = ChannelType(channel_data["type"])
                channel = Channel(
                    number=channel_data["number"],
                    name=channel_data["name"],
                    channel_type=channel_type,
                    min_value=channel_data["min_value"],
                    max_value=channel_data["max_value"],
                    default_value=channel_data["default_value"],
                )
                channel.is_active = channel_data.get("is_active", True)
                fixture.add_channel(channel)

            fixtures.append(fixture)

        logger.info(f"Configuração carregada de {filepath}: {len(fixtures)} fixtures")
        return fixtures

    except Exception as e:
        logger.error(f"Erro ao carregar configuração: {e}")
        return []


def save_universe_state(universe: List[int], filepath: str) -> bool:
    """
    Salva estado do universo DMX

    Args:
        universe: Lista com 512 valores do universo
        filepath: Caminho do arquivo

    Returns:
        True se salvo com sucesso
    """
    try:
        # Filtra apenas canais ativos
        active_channels = {}
        for i, value in enumerate(universe):
            if value > 0:
                active_channels[i + 1] = value

        data = {
            "universe": active_channels,
            "total_channels": len(universe),
            "active_channels": len(active_channels),
        }

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

        logger.info(f"Estado do universo salvo em {filepath}")
        return True

    except Exception as e:
        logger.error(f"Erro ao salvar estado do universo: {e}")
        return False


def load_universe_state(filepath: str) -> List[int]:
    """
    Carrega estado do universo DMX

    Args:
        filepath: Caminho do arquivo

    Returns:
        Lista com 512 valores do universo
    """
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Cria universo vazio
        universe = [0] * 512

        # Restaura valores ativos
        for channel, value in data["universe"].items():
            channel_num = int(channel)
            if 1 <= channel_num <= 512:
                universe[channel_num - 1] = value

        logger.info(f"Estado do universo carregado de {filepath}")
        return universe

    except Exception as e:
        logger.error(f"Erro ao carregar estado do universo: {e}")
        return [0] * 512


def export_fixture_library(fixtures: List[Fixture], filepath: str) -> bool:
    """
    Exporta biblioteca de fixtures para arquivo

    Args:
        fixtures: Lista de fixtures
        filepath: Caminho do arquivo

    Returns:
        True se exportado com sucesso
    """
    try:
        library = {"version": "1.0", "fixtures": []}

        for fixture in fixtures:
            fixture_info = {
                "name": fixture.name,
                "type": fixture.fixture_type.value,
                "manufacturer": "Generic",  # Pode ser expandido
                "channels": [],
            }

            for channel in fixture.channels:
                channel_info = {
                    "name": channel.name,
                    "type": channel.channel_type.value,
                    "address": channel.number,
                    "range": [channel.min_value, channel.max_value],
                }
                fixture_info["channels"].append(channel_info)

            library["fixtures"].append(fixture_info)

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(library, f, indent=2, ensure_ascii=False)

        logger.info(f"Biblioteca de fixtures exportada para {filepath}")
        return True

    except Exception as e:
        logger.error(f"Erro ao exportar biblioteca: {e}")
        return False


def create_backup_config(controller_data: Dict[str, Any], filepath: str) -> bool:
    """
    Cria backup completo da configuração

    Args:
        controller_data: Dados do controlador
        filepath: Caminho do arquivo

    Returns:
        True se backup criado com sucesso
    """
    try:
        backup = {
            "version": "1.0",
            "timestamp": None,  # Será preenchido pelo caller
            "controller": controller_data,
        }

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(backup, f, indent=2, ensure_ascii=False)

        logger.info(f"Backup criado em {filepath}")
        return True

    except Exception as e:
        logger.error(f"Erro ao criar backup: {e}")
        return False
