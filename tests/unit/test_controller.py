"""
Testes unitários para o módulo de controlador DMX512.
"""

import pytest
from unittest.mock import Mock, patch

from controller_dmx512.core.dmx_controller import DMXController
from controller_dmx512.core.fixture import Fixture, FixtureType
from controller_dmx512.core.channel import Channel, ChannelType


class TestDMXController:
    """Testes para a classe DMXController."""

    def test_controller_creation(self):
        """Testa a criação de um controlador básico."""
        controller = DMXController()
        assert len(controller.universe) == 512
        assert len(controller.fixtures) == 0

    def test_add_fixture(self):
        """Testa adicionar um fixture ao controlador."""
        controller = DMXController()
        channels = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture = Fixture("PAR Can 1", FixtureType.PAR_CAN, 1, channels)
        success = controller.add_fixture(fixture)
        assert success is True
        assert len(controller.fixtures) == 1
        assert controller.fixtures[0] == fixture

    def test_add_fixture_address_conflict(self):
        """Testa adicionar fixture com conflito de endereço."""
        controller = DMXController()
        channels1 = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        channels2 = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture1 = Fixture("PAR Can 1", FixtureType.PAR_CAN, 1, channels1)
        fixture2 = Fixture("PAR Can 2", FixtureType.PAR_CAN,
                           1, channels2)  # Mesmo endereço
        controller.add_fixture(fixture1)
        success = controller.add_fixture(fixture2)
        assert success is False
        assert len(controller.fixtures) == 1

    def test_remove_fixture(self):
        """Testa remover um fixture do controlador."""
        controller = DMXController()
        channels = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture = Fixture("PAR Can 1", FixtureType.PAR_CAN, 1, channels)
        controller.add_fixture(fixture)
        success = controller.remove_fixture("PAR Can 1")
        assert success is True
        assert len(controller.fixtures) == 0

    def test_remove_fixture_not_found(self):
        """Testa remover fixture inexistente."""
        controller = DMXController()
        success = controller.remove_fixture("Inexistente")
        assert success is False

    def test_get_fixture_by_name(self):
        """Testa obter fixture por nome."""
        controller = DMXController()
        channels = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture = Fixture("PAR Can 1", FixtureType.PAR_CAN, 1, channels)
        controller.add_fixture(fixture)
        found_fixture = controller.get_fixture("PAR Can 1")
        assert found_fixture == fixture

    def test_get_fixture_by_name_not_found(self):
        """Testa obter fixture por nome inexistente."""
        controller = DMXController()
        fixture = controller.get_fixture("Inexistente")
        assert fixture is None

    def test_set_universe_value(self):
        """Testa definir valor de um canal do universo."""
        controller = DMXController()
        success = controller.set_universe_value(1, 128)
        assert success is True
        assert controller.universe[0] == 128  # Índice 0 = canal 1

    def test_set_universe_value_invalid_address(self):
        """Testa definir valor em endereço inválido."""
        controller = DMXController()
        success = controller.set_universe_value(
            0, 128)  # Endereço 0 é inválido
        assert success is False
        success = controller.set_universe_value(513, 128)  # Endereço > 512
        assert success is False

    def test_set_universe_value_invalid_value(self):
        """Testa definir valor inválido."""
        controller = DMXController()
        # O método aceita valores negativos e > 255, mas os limita
        success = controller.set_universe_value(1, -1)  # Valor negativo
        assert success is True  # O método aceita e limita para 0
        assert controller.get_universe_value(1) == 0

        success = controller.set_universe_value(1, 256)  # Valor > 255
        assert success is True  # O método aceita e limita para 255
        assert controller.get_universe_value(1) == 255

    def test_get_universe_value(self):
        """Testa obter valor de um canal do universo."""
        controller = DMXController()
        controller.set_universe_value(1, 128)
        value = controller.get_universe_value(1)
        assert value == 128

    def test_get_universe_value_invalid_address(self):
        """Testa obter valor de endereço inválido."""
        controller = DMXController()
        value = controller.get_universe_value(0)  # Endereço 0 é inválido
        assert value == 0  # O método retorna 0 para endereços inválidos
        value = controller.get_universe_value(513)  # Endereço > 512
        assert value == 0  # O método retorna 0 para endereços inválidos

    def test_blackout(self):
        """Testa o comando blackout."""
        controller = DMXController()
        controller.set_universe_value(1, 128)
        controller.set_universe_value(2, 64)
        controller.set_universe_value(3, 32)
        controller.blackout()
        for i in range(1, 4):
            assert controller.get_universe_value(i) == 0

    def test_full_on(self):
        """Testa o comando full on."""
        controller = DMXController()
        controller.full_on()
        for i in range(1, 513):
            assert controller.get_universe_value(i) == 255

    def test_reset_universe(self):
        """Testa o reset do universo."""
        controller = DMXController()
        controller.set_universe_value(1, 128)
        controller.set_universe_value(2, 64)
        controller.reset_universe()
        for i in range(1, 513):
            assert controller.get_universe_value(i) == 0

    def test_get_universe(self):
        """Testa obter o universo completo."""
        controller = DMXController()
        controller.set_universe_value(1, 128)
        controller.set_universe_value(2, 64)
        universe = controller.get_universe()
        assert len(universe) == 512
        assert universe[0] == 128  # Canal 1
        assert universe[1] == 64   # Canal 2

    @patch('controller_dmx512.core.dmx_controller.DMXProtocol')
    def test_connect_success(self, mock_protocol_class):
        """Testa conexão bem-sucedida."""
        mock_protocol = Mock()
        mock_protocol.is_connected = True
        mock_protocol_class.return_value = mock_protocol

        controller = DMXController()
        success = controller.connect("COM3")

        assert success is True
        mock_protocol_class.assert_called_once()
        mock_protocol.connect.assert_called_once()

    @patch('controller_dmx512.core.dmx_controller.DMXProtocol')
    def test_connect_failure(self, mock_protocol_class):
        """Testa falha na conexão."""
        mock_protocol = Mock()
        mock_protocol.connect.return_value = False
        mock_protocol_class.return_value = mock_protocol

        controller = DMXController()
        success = controller.connect("COM3")

        assert success is False

    @patch('controller_dmx512.core.dmx_controller.DMXProtocol')
    def test_disconnect(self, mock_protocol_class):
        """Testa desconexão."""
        mock_protocol = Mock()
        mock_protocol_class.return_value = mock_protocol

        controller = DMXController()
        controller.protocol = mock_protocol
        controller.disconnect()

        mock_protocol.disconnect.assert_called_once()

    def test_get_status(self):
        """Testa obter status do controlador."""
        controller = DMXController()
        status = controller.get_status()

        assert "connected" in status
        assert "port" in status
        assert "fixture_count" in status
        assert "running" in status
        assert "universe_used" in status
