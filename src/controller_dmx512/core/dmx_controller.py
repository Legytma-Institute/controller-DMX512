"""
Controlador DMX512 - Classe principal para gerenciamento de iluminação

Este módulo contém a classe DMXController que é o ponto central
para controle de dispositivos de iluminação via DMX512.
"""

import logging
import threading
import time
from typing import Any, Callable, Dict, List, Optional

from .channel import Channel, ChannelType
from .fixture import Fixture, FixtureType, PredefinedFixtures
from .protocol import DMXBreakLength, DMXProtocol
from .rdm import (
    ALL_DEVICES_UID_INT,
    DiscoveryResult,
    PID_DISC_MUTE,
    PID_DISC_UNIQUE_BRANCH,
    PID_DISC_UN_MUTE,
    RDMCommandClass,
    RDMUID,
    build_rdm_request,
    decode_discovery_response,
    parse_rdm_message,
)

logger = logging.getLogger(__name__)


class DMXController:
    """
    Controlador principal para dispositivos DMX512

    Esta classe gerencia a comunicação com dispositivos de iluminação,
    controla fixtures e canais, e fornece uma interface unificada
    para operações de iluminação.
    """

    def __init__(
        self,
        port: str = None,
        baudrate: int = 250000,
        break_length: DMXBreakLength = DMXBreakLength.STANDARD,
        rs485_direction: str = "none",
        rs485_tx_level: bool = True,
        rdm_controller_uid: str = "7fff:00000001",
    ):
        """
        Inicializa o controlador DMX512

        Args:
            port: Porta serial (se None, será detectada automaticamente)
            baudrate: Taxa de transmissão
            break_length: Duração do break DMX
        """
        self.port = port
        self.baudrate = baudrate
        self.break_length = break_length
        self.rs485_direction = rs485_direction
        self.rs485_tx_level = rs485_tx_level

        self.rdm_controller_uid = RDMUID.from_str(rdm_controller_uid)
        self._rdm_transaction_number = 0

        # Protocolo de comunicação
        self.protocol: Optional[DMXProtocol] = None

        # Gerenciamento de fixtures
        self.fixtures: List[Fixture] = []
        self.fixtures_by_name: Dict[str, Fixture] = {}

        # Universo DMX (512 canais)
        self.universe: List[int] = [0] * 512

        # Thread de atualização
        self.update_thread: Optional[threading.Thread] = None
        self.running = False
        self.update_interval = 0.033  # ~30 FPS

        # Callbacks
        self.on_universe_update: Optional[Callable] = None
        self.on_fixture_update: Optional[Callable] = None

        logger.info("Controlador DMX512 inicializado")

    def connect(self, port: str = None) -> bool:
        """
        Conecta ao dispositivo DMX

        Args:
            port: Porta serial (se None, usa a porta configurada)

        Returns:
            True se conectado com sucesso
        """
        if port:
            self.port = port

        if not self.port:
            # Tenta detectar porta automaticamente
            available_ports = self.get_available_ports()
            if available_ports:
                self.port = available_ports[0]
                logger.info(f"Porta detectada automaticamente: {self.port}")
            else:
                logger.error("Nenhuma porta serial disponível")
                return False

        # Cria e conecta o protocolo
        self.protocol = DMXProtocol(
            self.port,
            self.baudrate,
            self.break_length,
            rs485_direction=self.rs485_direction,
            rs485_tx_level=self.rs485_tx_level,
        )

        if self.protocol.connect():
            self._start_update_thread()
            logger.info(f"Conectado à porta {self.port}")
            return True
        else:
            logger.error(f"Falha ao conectar à porta {self.port}")
            return False

    def disconnect(self):
        """Desconecta do dispositivo DMX"""
        self._stop_update_thread()

        if self.protocol:
            self.protocol.disconnect()
            self.protocol = None

        logger.info("Desconectado do dispositivo DMX")

    def _next_rdm_transaction_number(self) -> int:
        self._rdm_transaction_number = (self._rdm_transaction_number + 1) & 0xFF
        return self._rdm_transaction_number

    def _rdm_send_request(self, packet: bytes, *, timeout_s: float = 0.3) -> Optional[bytes]:
        if not self.protocol or not self.protocol.is_connected:
            return None
        return self.protocol.rdm_transaction(packet, response_timeout_s=timeout_s)

    def _rdm_send_discovery_request(
        self, packet: bytes, *, timeout_s: float = 0.3
    ) -> bytes:
        if not self.protocol or not self.protocol.is_connected:
            return b""
        return self.protocol.rdm_discovery_transaction(packet, response_timeout_s=timeout_s)

    def rdm_discover_devices(
        self,
        *,
        timeout_s: float = 0.3,
        max_devices: int = 256,
    ) -> List[RDMUID]:
        if not self.protocol or not self.protocol.is_connected:
            raise RuntimeError("Controlador não conectado")

        was_running = self.running
        if was_running:
            self._stop_update_thread()

        discovered: List[RDMUID] = []
        try:
            unmute = build_rdm_request(
                dest_uid=RDMUID.all_devices(),
                src_uid=self.rdm_controller_uid,
                transaction_number=self._next_rdm_transaction_number(),
                port_id=1,
                message_count=0,
                sub_device=0,
                command_class=RDMCommandClass.DISCOVERY_COMMAND,
                parameter_id=PID_DISC_UN_MUTE,
                parameter_data=b"",
            )
            self._rdm_send_request(unmute, timeout_s=timeout_s)

            ranges: List[tuple[int, int]] = [(0, ALL_DEVICES_UID_INT)]
            while ranges and len(discovered) < max_devices:
                lower_int, upper_int = ranges.pop()
                lower_uid = RDMUID.from_int(lower_int)
                upper_uid = RDMUID.from_int(upper_int)

                branch = build_rdm_request(
                    dest_uid=RDMUID.all_devices(),
                    src_uid=self.rdm_controller_uid,
                    transaction_number=self._next_rdm_transaction_number(),
                    port_id=1,
                    message_count=0,
                    sub_device=0,
                    command_class=RDMCommandClass.DISCOVERY_COMMAND,
                    parameter_id=PID_DISC_UNIQUE_BRANCH,
                    parameter_data=lower_uid.to_bytes() + upper_uid.to_bytes(),
                )

                raw = self._rdm_send_discovery_request(branch, timeout_s=timeout_s)
                result, uid = decode_discovery_response(raw)
                if result == DiscoveryResult.NO_RESPONSE:
                    continue
                if result == DiscoveryResult.VALID and uid is not None:
                    mute = build_rdm_request(
                        dest_uid=uid,
                        src_uid=self.rdm_controller_uid,
                        transaction_number=self._next_rdm_transaction_number(),
                        port_id=1,
                        message_count=0,
                        sub_device=0,
                        command_class=RDMCommandClass.DISCOVERY_COMMAND,
                        parameter_id=PID_DISC_MUTE,
                        parameter_data=b"",
                    )
                    resp = self._rdm_send_request(mute, timeout_s=timeout_s)
                    if resp is not None:
                        try:
                            parse_rdm_message(resp)
                            discovered.append(uid)
                        except Exception:
                            pass
                    continue

                if lower_int == upper_int:
                    continue

                mid = (lower_int + upper_int) // 2
                ranges.append((lower_int, mid))
                ranges.append((mid + 1, upper_int))

            return discovered

        finally:
            if was_running and self.protocol and self.protocol.is_connected:
                self._start_update_thread()

    def add_fixture(self, fixture: Fixture) -> bool:
        """
        Adiciona um fixture ao controlador

        Args:
            fixture: Fixture a ser adicionado

        Returns:
            True se adicionado com sucesso
        """
        # Verifica conflitos de endereço
        for existing_fixture in self.fixtures:
            if self._fixtures_overlap(existing_fixture, fixture):
                logger.error(
                    f"Conflito de endereço entre fixtures '{existing_fixture.name}' e '{fixture.name}'"
                )
                return False

        self.fixtures.append(fixture)
        self.fixtures_by_name[fixture.name] = fixture

        logger.info(f"Fixture '{fixture.name}' adicionado")
        return True

    def remove_fixture(self, fixture_name: str) -> bool:
        """
        Remove um fixture do controlador

        Args:
            fixture_name: Nome do fixture

        Returns:
            True se removido com sucesso
        """
        fixture = self.fixtures_by_name.get(fixture_name)
        if fixture:
            self.fixtures.remove(fixture)
            del self.fixtures_by_name[fixture_name]
            logger.info(f"Fixture '{fixture_name}' removido")
            return True

        logger.warning(f"Fixture '{fixture_name}' não encontrado")
        return False

    def get_fixture(self, name: str) -> Optional[Fixture]:
        """
        Retorna um fixture pelo nome

        Args:
            name: Nome do fixture

        Returns:
            Fixture encontrado ou None
        """
        return self.fixtures_by_name.get(name)

    def get_all_fixtures(self) -> List[Fixture]:
        """
        Retorna todos os fixtures

        Returns:
            Lista de todos os fixtures
        """
        return self.fixtures.copy()

    def set_fixture_value(
        self, fixture_name: str, channel_index: int, value: int
    ) -> bool:
        """
        Define valor de um canal específico de um fixture

        Args:
            fixture_name: Nome do fixture
            channel_index: Índice do canal no fixture
            value: Valor a ser definido

        Returns:
            True se definido com sucesso
        """
        fixture = self.get_fixture(fixture_name)
        if not fixture:
            return False

        channel = fixture.get_channel_by_index(channel_index)
        if not channel:
            return False

        return channel.set_value(value)

    def set_fixture_all_channels(self, fixture_name: str, values: List[int]) -> bool:
        """
        Define valores para todos os canais de um fixture

        Args:
            fixture_name: Nome do fixture
            values: Lista de valores para os canais

        Returns:
            True se definido com sucesso
        """
        fixture = self.get_fixture(fixture_name)
        if not fixture:
            return False

        return fixture.set_all_channels(values)

    def set_universe_value(self, channel: int, value: int) -> bool:
        """
        Define valor de um canal específico do universo

        Args:
            channel: Número do canal (1-512)
            value: Valor a ser definido

        Returns:
            True se definido com sucesso
        """
        if channel < 1 or channel > 512:
            return False

        self.universe[channel - 1] = max(0, min(255, value))
        return True

    def get_universe_value(self, channel: int) -> int:
        """
        Retorna valor de um canal do universo

        Args:
            channel: Número do canal (1-512)

        Returns:
            Valor do canal
        """
        if channel < 1 or channel > 512:
            return 0

        return self.universe[channel - 1]

    def get_universe(self) -> List[int]:
        """
        Retorna o universo DMX completo

        Returns:
            Lista com 512 valores do universo
        """
        return self.universe.copy()

    def reset_universe(self):
        """Reseta todo o universo DMX para zero"""
        self.universe = [0] * 512
        logger.info("Universo DMX resetado")

    def reset_all_fixtures(self):
        """Reseta todos os fixtures para valores padrão"""
        for fixture in self.fixtures:
            fixture.reset_all_channels()
        logger.info("Todos os fixtures resetados")

    def blackout(self):
        """Executa blackout (todos os canais para zero)"""
        self.reset_universe()
        self.reset_all_fixtures()
        logger.info("Blackout executado")

    def full_on(self):
        """Executa full on (todos os canais para máximo)"""
        self.universe = [255] * 512
        for fixture in self.fixtures:
            for channel in fixture.channels:
                channel.set_value(255)
        logger.info("Full on executado")

    def get_available_ports(self) -> List[str]:
        """
        Retorna portas seriais disponíveis

        Returns:
            Lista de portas disponíveis
        """
        if self.protocol:
            return self.protocol.get_available_ports()

        # Cria protocolo temporário para listar portas
        temp_protocol = DMXProtocol("dummy")
        return temp_protocol.get_available_ports()

    def get_status(self) -> Dict[str, Any]:
        """
        Retorna status do controlador

        Returns:
            Dicionário com informações de status
        """
        return {
            "connected": self.protocol.is_connected if self.protocol else False,
            "port": self.port,
            "fixture_count": len(self.fixtures),
            "running": self.running,
            "universe_used": sum(1 for v in self.universe if v > 0),
        }

    def _fixtures_overlap(self, fixture1: Fixture, fixture2: Fixture) -> bool:
        """Verifica se dois fixtures têm endereços sobrepostos"""
        start1, end1 = fixture1.start_address, fixture1.get_end_address()
        start2, end2 = fixture2.start_address, fixture2.get_end_address()

        return not (end1 < start2 or end2 < start1)

    def _start_update_thread(self):
        """Inicia thread de atualização do universo"""
        if self.running:
            return

        self.running = True
        self.update_thread = threading.Thread(target=self._update_loop, daemon=True)
        self.update_thread.start()
        logger.debug("Thread de atualização iniciada")

    def _stop_update_thread(self):
        """Para thread de atualização"""
        self.running = False
        if self.update_thread:
            self.update_thread.join(timeout=1.0)
            self.update_thread = None
        logger.debug("Thread de atualização parada")

    def _update_loop(self):
        """Loop principal de atualização do universo"""
        while self.running:
            try:
                # Atualiza universo com valores dos fixtures
                self._update_universe_from_fixtures()

                # Envia universo via protocolo
                if self.protocol and self.protocol.is_connected:
                    self.protocol.send_dmx_frame(self.universe)

                # Chama callback se definido
                if self.on_universe_update:
                    self.on_universe_update(self.universe)

                time.sleep(self.update_interval)

            except Exception as e:
                logger.error(f"Erro no loop de atualização: {e}")
                time.sleep(0.1)

    def _update_universe_from_fixtures(self):
        """Atualiza universo com valores dos fixtures"""
        # Limpa universo
        self.universe = [0] * 512

        # Adiciona valores dos fixtures
        for fixture in self.fixtures:
            if not fixture.is_active:
                continue

            for i, channel in enumerate(fixture.channels):
                universe_index = fixture.start_address + i - 1
                if 0 <= universe_index < 512:
                    self.universe[universe_index] = channel.get_value()

    def create_par_can(self, name: str, start_address: int) -> Fixture:
        """Cria um PAR Can RGB"""
        return PredefinedFixtures.create_par_can(name, start_address)

    def create_moving_head(self, name: str, start_address: int) -> Fixture:
        """Cria um Moving Head"""
        return PredefinedFixtures.create_moving_head(name, start_address)

    def create_led_strip(
        self, name: str, start_address: int, led_count: int = 1
    ) -> Fixture:
        """Cria uma LED Strip"""
        return PredefinedFixtures.create_led_strip(name, start_address, led_count)

    def __enter__(self):
        """Context manager entry"""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.disconnect()
