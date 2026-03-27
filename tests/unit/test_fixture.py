"""
Testes unitários para o módulo de fixtures DMX512.
"""

import pytest
from unittest.mock import Mock, patch

from controller_dmx512.core.fixture import Fixture, FixtureType
from controller_dmx512.core.channel import Channel, ChannelType


class TestFixture:
    """Testes para a classe Fixture."""

    def test_fixture_creation(self):
        """Testa a criação de um fixture básico."""
        channels = [
            Channel(1, "Dimmer", ChannelType.DIMMER),
            Channel(2, "Red", ChannelType.RED),
            Channel(3, "Green", ChannelType.GREEN),
        ]
        fixture = Fixture("PAR Can 1", FixtureType.PAR_CAN, 1, channels)
        assert fixture.name == "PAR Can 1"
        assert fixture.fixture_type == FixtureType.PAR_CAN
        assert fixture.start_address == 1
        assert len(fixture.channels) == 3

    def test_fixture_with_custom_channels(self):
        """Testa a criação de um fixture com canais personalizados."""
        channels = [
            Channel(10, "Dimmer", ChannelType.DIMMER),
            Channel(11, "Red", ChannelType.RED),
            Channel(12, "Green", ChannelType.GREEN),
            Channel(13, "Blue", ChannelType.BLUE),
        ]
        fixture = Fixture("LED Strip", FixtureType.LED_STRIP, 10, channels)
        assert fixture.name == "LED Strip"
        assert fixture.start_address == 10
        assert len(fixture.channels) == 4

    def test_get_channel_by_number(self):
        """Testa obter canal por número."""
        channels = [
            Channel(1, "Dimmer", ChannelType.DIMMER),
            Channel(2, "Red", ChannelType.RED),
        ]
        fixture = Fixture("PAR Can", FixtureType.PAR_CAN, 1, channels)
        dimmer_channel = fixture.get_channel(1)
        assert dimmer_channel is not None
        assert dimmer_channel.name == "Dimmer"

    def test_get_channel_by_number_not_found(self):
        """Testa obter canal por número inexistente."""
        channels = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture = Fixture("PAR Can", FixtureType.PAR_CAN, 1, channels)
        channel = fixture.get_channel(99)
        assert channel is None

    def test_set_channel_value(self):
        """Testa definir valor de um canal."""
        channels = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture = Fixture("PAR Can", FixtureType.PAR_CAN, 1, channels)
        success = fixture.set_channel_value(1, 128)
        assert success is True
        assert channels[0].current_value == 128

    def test_set_channel_value_invalid(self):
        """Testa definir valor inválido em um canal."""
        channels = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture = Fixture("PAR Can", FixtureType.PAR_CAN, 1, channels)
        success = fixture.set_channel_value(99, 128)
        assert success is False

    def test_reset(self):
        """Testa o reset do fixture."""
        channels = [
            Channel(1, "Dimmer", ChannelType.DIMMER, default_value=10),
            Channel(2, "Red", ChannelType.RED, default_value=20),
        ]
        fixture = Fixture("PAR Can", FixtureType.PAR_CAN, 1, channels)
        fixture.set_channel_value(1, 128)
        fixture.set_channel_value(2, 64)
        fixture.reset_all_channels()
        for channel in fixture.channels:
            assert channel.current_value == channel.default_value

    def test_get_all_values(self):
        """Testa obter valores DMX do fixture."""
        channels = [
            Channel(1, "Dimmer", ChannelType.DIMMER),
            Channel(2, "Red", ChannelType.RED),
            Channel(3, "Green", ChannelType.GREEN),
        ]
        fixture = Fixture("PAR Can", FixtureType.PAR_CAN, 1, channels)
        fixture.set_channel_value(1, 128)
        fixture.set_channel_value(2, 64)
        fixture.set_channel_value(3, 32)
        dmx_data = fixture.get_all_values()
        assert len(dmx_data) == 3
        assert dmx_data[0] == 128  # Dimmer
        assert dmx_data[1] == 64  # Red
        assert dmx_data[2] == 32  # Green

    def test_str_representation(self):
        """Testa a representação string do fixture."""
        channels = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture = Fixture("PAR Can 1", FixtureType.PAR_CAN, 1, channels)
        expected = "Fixture('PAR Can 1', type=par_can, channels=1)"
        assert str(fixture) == expected

    def test_repr_representation(self):
        """Testa a representação repr do fixture."""
        channels = [Channel(1, "Dimmer", ChannelType.DIMMER)]
        fixture = Fixture("PAR Can 1", FixtureType.PAR_CAN, 1, channels)
        expected = "Fixture(name='PAR Can 1', fixture_type=FixtureType.PAR_CAN, start_address=1)"
        assert repr(fixture) == expected


class TestFixtureType:
    """Testes para o enum FixtureType."""

    def test_fixture_type_values(self):
        """Testa se os valores do enum estão corretos."""
        assert FixtureType.PAR_CAN.value == "par_can"
        assert FixtureType.MOVING_HEAD.value == "moving_head"
        assert FixtureType.LED_STRIP.value == "led_strip"
        assert FixtureType.FOG_MACHINE.value == "fog_machine"
        assert FixtureType.LASER.value == "laser"
        assert FixtureType.SCANNER.value == "scanner"
        assert FixtureType.CUSTOM.value == "custom"

    def test_fixture_type_names(self):
        """Testa se os nomes do enum estão corretos."""
        assert FixtureType.PAR_CAN.name == "PAR_CAN"
        assert FixtureType.MOVING_HEAD.name == "MOVING_HEAD"
        assert FixtureType.LED_STRIP.name == "LED_STRIP"
        assert FixtureType.FOG_MACHINE.name == "FOG_MACHINE"
        assert FixtureType.LASER.name == "LASER"
        assert FixtureType.SCANNER.name == "SCANNER"
        assert FixtureType.CUSTOM.name == "CUSTOM"
