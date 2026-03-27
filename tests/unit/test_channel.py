"""
Testes unitários para o módulo de canais DMX512.
"""

import pytest
from unittest.mock import Mock, patch

from controller_dmx512.core.channel import Channel, ChannelType


class TestChannel:
    """Testes para a classe Channel."""

    def test_channel_creation(self):
        """Testa a criação de um canal básico."""
        channel = Channel(1, "Dimmer", ChannelType.DIMMER)
        assert channel.number == 1
        assert channel.name == "Dimmer"
        assert channel.channel_type == ChannelType.DIMMER
        assert channel.current_value == 0
        assert channel.min_value == 0
        assert channel.max_value == 255

    def test_channel_with_custom_range(self):
        """Testa a criação de um canal com range personalizado."""
        channel = Channel(2, "Pan", ChannelType.PAN, min_value=0, max_value=255)
        assert channel.number == 2
        assert channel.min_value == 0
        assert channel.max_value == 255

    def test_set_value_within_range(self):
        """Testa definir valor dentro do range permitido."""
        channel = Channel(1, "Dimmer", ChannelType.DIMMER)
        channel.set_value(128)
        assert channel.current_value == 128

    def test_set_value_outside_range(self):
        """Testa definir valor fora do range permitido."""
        channel = Channel(1, "Dimmer", ChannelType.DIMMER)
        # Valor muito alto
        result_high = channel.set_value(300)
        assert result_high is False
        assert channel.current_value == 0
        # Valor muito baixo
        result_low = channel.set_value(-10)
        assert result_low is False
        assert channel.current_value == 0

    def test_set_value_with_custom_range(self):
        """Testa definir valor com range personalizado."""
        channel = Channel(1, "Pan", ChannelType.PAN, min_value=0, max_value=255)
        channel.set_value(128)
        assert channel.current_value == 128
        # Valor fora do range
        result = channel.set_value(300)
        assert result is False
        assert channel.current_value == 128

    def test_reset(self):
        """Testa o reset do canal."""
        channel = Channel(1, "Dimmer", ChannelType.DIMMER, default_value=10)
        channel.set_value(128)
        channel.reset()
        assert channel.current_value == 10

    def test_str_representation(self):
        """Testa a representação string do canal."""
        channel = Channel(1, "Dimmer", ChannelType.DIMMER)
        channel.set_value(128)
        expected = "Channel(1: Dimmer, value=128)"
        assert str(channel) == expected

    def test_repr_representation(self):
        """Testa a representação repr do canal."""
        channel = Channel(1, "Dimmer", ChannelType.DIMMER)
        expected = "Channel(number=1, name='Dimmer', value=0)"
        assert repr(channel) == expected


class TestChannelType:
    """Testes para o enum ChannelType."""

    def test_channel_type_values(self):
        """Testa se os valores do enum estão corretos."""
        assert ChannelType.DIMMER.value == "dimmer"
        assert ChannelType.RED.value == "red"
        assert ChannelType.GREEN.value == "green"
        assert ChannelType.BLUE.value == "blue"
        assert ChannelType.WHITE.value == "white"
        assert ChannelType.PAN.value == "pan"
        assert ChannelType.TILT.value == "tilt"
        assert ChannelType.SHUTTER.value == "shutter"
        assert ChannelType.GOBO.value == "gobo"
        assert ChannelType.COLOR_WHEEL.value == "color_wheel"

    def test_channel_type_names(self):
        """Testa se os nomes do enum estão corretos."""
        assert ChannelType.DIMMER.name == "DIMMER"
        assert ChannelType.RED.name == "RED"
        assert ChannelType.GREEN.name == "GREEN"
        assert ChannelType.BLUE.name == "BLUE"
        assert ChannelType.WHITE.name == "WHITE"
        assert ChannelType.PAN.name == "PAN"
        assert ChannelType.TILT.name == "TILT"
        assert ChannelType.SHUTTER.name == "SHUTTER"
        assert ChannelType.GOBO.name == "GOBO"
        assert ChannelType.COLOR_WHEEL.name == "COLOR_WHEEL"
