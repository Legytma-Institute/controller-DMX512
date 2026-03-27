"""
Protocolo DMX512 - Implementação da comunicação via RS485

Este módulo implementa o protocolo DMX512 para comunicação
com dispositivos de iluminação através de porta serial RS485.
"""

import logging
import time
from enum import Enum
from typing import Any, Dict, List, Optional

import serial

logger = logging.getLogger(__name__)


class DMXProtocolError(Exception):
    """Exceção para erros do protocolo DMX512"""

    pass


class DMXBreakLength(Enum):
    """Duração do break DMX em microssegundos"""

    STANDARD = 88  # Padrão DMX512
    LONG = 176  # Break longo para alguns dispositivos


class DMXProtocol:
    """
    Implementação do protocolo DMX512 para comunicação via RS485

    O protocolo DMX512 consiste em:
    1. Break (88-176 μs de sinal baixo)
    2. Mark After Break (8 μs de sinal alto)
    3. Start Code (1 byte)
    4. Data (até 512 bytes)
    """

    def __init__(
        self,
        port: str,
        baudrate: int = 250000,
        break_length: DMXBreakLength = DMXBreakLength.STANDARD,
        rs485_direction: str = "none",
        rs485_tx_level: bool = True,
    ):
        """
        Inicializa o protocolo DMX512

        Args:
            port: Porta serial (ex: 'COM3', '/dev/ttyUSB0')
            baudrate: Taxa de transmissão (padrão DMX512: 250000)
            break_length: Duração do break em microssegundos
        """
        self.port = port
        self.baudrate = baudrate
        self.break_length = break_length
        self.rs485_direction = rs485_direction
        self.rs485_tx_level = rs485_tx_level
        self.serial_connection: Optional[serial.Serial] = None
        self.is_connected = False

        # Constantes do protocolo DMX512
        self.DMX_UNIVERSE_SIZE = 512
        self.START_CODE = 0x00
        self.MARK_AFTER_BREAK = 8  # μs

        self.RDM_START_CODE = 0xCC

    def connect(self) -> bool:
        """
        Estabelece conexão com a porta serial

        Returns:
            True se conectado com sucesso, False caso contrário
        """
        try:
            self.serial_connection = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_TWO,
                timeout=1.0,
            )

            # Configura a porta para suportar break
            self.serial_connection.break_condition = False

            # Estado inicial: transmissão
            self._set_rs485_mode(tx=True)

            self.is_connected = True
            logger.info(f"Conectado à porta {self.port} com sucesso")
            return True

        except serial.SerialException as e:
            logger.error(f"Erro ao conectar à porta {self.port}: {e}")
            self.is_connected = False
            return False

    def disconnect(self):
        """Fecha a conexão serial"""
        if self.serial_connection and self.serial_connection.is_open:
            self.serial_connection.close()
            self.is_connected = False
            logger.info(f"Desconectado da porta {self.port}")

    def send_dmx_frame(self, data: List[int], start_address: int = 1) -> bool:
        """
        Envia um frame DMX512 completo

        Args:
            data: Lista de valores dos canais (1-512)
            start_address: Endereço inicial (1-512)

        Returns:
            True se enviado com sucesso, False caso contrário
        """
        if not self.is_connected or not self.serial_connection:
            logger.error("Não há conexão serial ativa")
            return False

        if not data:
            logger.warning("Dados vazios para envio")
            return False

        try:
            # Valida endereço inicial
            if start_address < 1 or start_address > self.DMX_UNIVERSE_SIZE:
                raise DMXProtocolError(f"Endereço inicial inválido: {start_address}")

            # Prepara o universo DMX completo
            universe = [0] * self.DMX_UNIVERSE_SIZE
            end_address = min(start_address + len(data) - 1, self.DMX_UNIVERSE_SIZE)

            # Copia os dados para o universo
            for i, value in enumerate(data):
                if start_address + i - 1 < self.DMX_UNIVERSE_SIZE:
                    universe[start_address + i - 1] = max(0, min(255, value))

            # Envia o frame DMX
            return self._transmit_frame(universe)

        except Exception as e:
            logger.error(f"Erro ao enviar frame DMX: {e}")
            return False

    def _set_rs485_mode(self, *, tx: bool) -> None:
        if not self.serial_connection:
            return

        if self.rs485_direction == "none":
            return

        level = self.rs485_tx_level if tx else (not self.rs485_tx_level)

        if self.rs485_direction == "rts":
            self.serial_connection.rts = level
        elif self.rs485_direction == "dtr":
            self.serial_connection.dtr = level
        else:
            raise DMXProtocolError(f"Modo RS485 inválido: {self.rs485_direction}")

    def send_frame(self, start_code: int, payload: bytes) -> None:
        if not self.serial_connection:
            raise DMXProtocolError("Conexão serial não inicializada")

        self._set_rs485_mode(tx=True)

        self.serial_connection.break_condition = True
        time.sleep(self.break_length.value / 1000000.0)

        self.serial_connection.break_condition = False
        time.sleep(self.MARK_AFTER_BREAK / 1000000.0)

        self.serial_connection.write(bytes([start_code & 0xFF]))
        if payload:
            self.serial_connection.write(payload)
        self.serial_connection.flush()

    def _read_exact(self, size: int, timeout_s: float) -> Optional[bytes]:
        if not self.serial_connection:
            return None

        deadline = time.monotonic() + timeout_s
        buf = bytearray()
        old_timeout = self.serial_connection.timeout
        try:
            while len(buf) < size and time.monotonic() < deadline:
                remaining = deadline - time.monotonic()
                self.serial_connection.timeout = max(0.0, remaining)
                chunk = self.serial_connection.read(size - len(buf))
                if chunk:
                    buf += chunk
            if len(buf) != size:
                return None
            return bytes(buf)
        finally:
            self.serial_connection.timeout = old_timeout

    def read_rdm_message(self, timeout_s: float = 0.2) -> Optional[bytes]:
        if not self.serial_connection:
            return None

        deadline = time.monotonic() + timeout_s
        old_timeout = self.serial_connection.timeout
        try:
            while time.monotonic() < deadline:
                remaining = deadline - time.monotonic()
                self.serial_connection.timeout = max(0.0, remaining)
                b = self.serial_connection.read(1)
                if not b:
                    continue
                if b[0] != self.RDM_START_CODE:
                    continue
                rest = self._read_exact(
                    2, timeout_s=max(0.0, deadline - time.monotonic())
                )
                if not rest:
                    return None
                msg_len = rest[1]
                if msg_len < 3:
                    return None
                remaining_len = msg_len - 3
                tail = self._read_exact(
                    remaining_len, timeout_s=max(0.0, deadline - time.monotonic())
                )
                if tail is None:
                    return None
                return b + rest + tail
            return None
        finally:
            self.serial_connection.timeout = old_timeout

    def read_discovery_response(self, timeout_s: float = 0.2) -> bytes:
        if not self.serial_connection:
            return b""

        deadline = time.monotonic() + timeout_s
        buf = bytearray()
        old_timeout = self.serial_connection.timeout
        try:
            self.serial_connection.timeout = 0.0
            while time.monotonic() < deadline:
                waiting = self.serial_connection.in_waiting
                if waiting:
                    chunk = self.serial_connection.read(waiting)
                    if chunk:
                        buf += chunk
                        deadline = time.monotonic() + 0.02
                else:
                    time.sleep(0.001)
            return bytes(buf)
        finally:
            self.serial_connection.timeout = old_timeout

    def rdm_transaction(
        self,
        request_packet: bytes,
        response_timeout_s: float = 0.2,
    ) -> Optional[bytes]:
        if not self.serial_connection:
            return None

        self.serial_connection.reset_input_buffer()
        self.send_frame(request_packet[0], request_packet[1:])

        self._set_rs485_mode(tx=False)
        try:
            return self.read_rdm_message(timeout_s=response_timeout_s)
        finally:
            self._set_rs485_mode(tx=True)

    def rdm_discovery_transaction(
        self,
        request_packet: bytes,
        response_timeout_s: float = 0.2,
    ) -> bytes:
        if not self.serial_connection:
            return b""

        self.serial_connection.reset_input_buffer()
        self.send_frame(request_packet[0], request_packet[1:])

        self._set_rs485_mode(tx=False)
        try:
            return self.read_discovery_response(timeout_s=response_timeout_s)
        finally:
            self._set_rs485_mode(tx=True)

    def _transmit_frame(self, universe: List[int]) -> bool:
        """
        Transmite um frame DMX512 completo

        Args:
            universe: Lista de 512 valores representando o universo DMX

        Returns:
            True se transmitido com sucesso
        """
        try:
            self.send_frame(self.START_CODE, bytes(universe))

            logger.debug("Frame DMX512 transmitido com sucesso")
            return True

        except Exception as e:
            logger.error(f"Erro na transmissão do frame: {e}")
            return False

    def send_single_channel(self, channel: int, value: int) -> bool:
        """
        Envia valor para um único canal

        Args:
            channel: Número do canal (1-512)
            value: Valor do canal (0-255)

        Returns:
            True se enviado com sucesso
        """
        if channel < 1 or channel > self.DMX_UNIVERSE_SIZE:
            logger.error(f"Canal inválido: {channel}")
            return False

        if value < 0 or value > 255:
            logger.error(f"Valor inválido: {value}")
            return False

        # Cria universo com apenas o canal especificado
        universe = [0] * self.DMX_UNIVERSE_SIZE
        universe[channel - 1] = value

        return self._transmit_frame(universe)

    def get_available_ports(self) -> List[str]:
        """
        Retorna lista de portas seriais disponíveis

        Returns:
            Lista de portas disponíveis
        """
        import serial.tools.list_ports

        ports = serial.tools.list_ports.comports()
        return [port.device for port in ports]

    def test_connection(self) -> bool:
        """
        Testa a conexão enviando um frame vazio

        Returns:
            True se a conexão está funcionando
        """
        if not self.is_connected:
            return False

        try:
            universe = [0] * self.DMX_UNIVERSE_SIZE
            return self._transmit_frame(universe)
        except Exception as e:
            logger.error(f"Erro no teste de conexão: {e}")
            return False

    def get_status(self) -> Dict[str, Any]:
        """
        Retorna status da conexão

        Returns:
            Dicionário com informações de status
        """
        return {
            "connected": self.is_connected,
            "port": self.port,
            "baudrate": self.baudrate,
            "break_length": self.break_length.value,
            "serial_open": (
                self.serial_connection.is_open if self.serial_connection else False
            ),
        }
