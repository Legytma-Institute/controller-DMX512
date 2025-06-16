#!/usr/bin/env python3
"""
Exemplo Básico - Uso básico do controlador DMX512

Este exemplo demonstra como usar o controlador DMX512
para controlar dispositivos de iluminação.
"""

import sys
import time
from pathlib import Path

from controller_dmx512.core.channel import Channel, ChannelType
from controller_dmx512.core.dmx_controller import DMXController
from controller_dmx512.core.fixture import Fixture, FixtureType, PredefinedFixtures

# Adiciona o diretório src ao path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))


def main():
    """Exemplo básico de uso"""
    print("=== Exemplo Básico - Controlador DMX512 ===\n")

    # Cria controlador
    controller = DMXController()

    print("1. Criando fixtures de exemplo...")

    # Cria um PAR Can RGB
    par_can = controller.create_par_can("PAR Can 1", 1)
    controller.add_fixture(par_can)
    print(f"   - PAR Can criado: {par_can.name} (endereço {par_can.start_address})")

    # Cria um Moving Head
    moving_head = controller.create_moving_head("Moving Head 1", 10)
    controller.add_fixture(moving_head)
    print(
        f"   - Moving Head criado: {moving_head.name} (endereço {moving_head.start_address})"
    )

    # Cria uma LED Strip
    led_strip = controller.create_led_strip("LED Strip 1", 20, led_count=2)
    controller.add_fixture(led_strip)
    print(
        f"   - LED Strip criada: {led_strip.name} (endereço {led_strip.start_address})"
    )

    print("\n2. Listando fixtures criados:")
    for fixture in controller.get_all_fixtures():
        print(f"   - {fixture.name}: {fixture.get_channel_count()} canais")

    print("\n3. Demonstração de controle (sem conexão física):")

    # Demonstra controle do PAR Can
    print("\n   Controlando PAR Can:")
    par_can = controller.get_fixture("PAR Can 1")
    if par_can:
        # Vermelho
        par_can.set_channel_value(1, 255)  # Red
        par_can.set_channel_value(2, 0)  # Green
        par_can.set_channel_value(3, 0)  # Blue
        print("     - Cor vermelha aplicada")

        # Verde
        par_can.set_channel_value(1, 0)  # Red
        par_can.set_channel_value(2, 255)  # Green
        par_can.set_channel_value(3, 0)  # Blue
        print("     - Cor verde aplicada")

        # Azul
        par_can.set_channel_value(1, 0)  # Red
        par_can.set_channel_value(2, 0)  # Green
        par_can.set_channel_value(3, 255)  # Blue
        print("     - Cor azul aplicada")

        # Branco
        par_can.set_channel_value(1, 255)  # Red
        par_can.set_channel_value(2, 255)  # Green
        par_can.set_channel_value(3, 255)  # Blue
        print("     - Cor branca aplicada")

    # Demonstra controle do Moving Head
    print("\n   Controlando Moving Head:")
    moving_head = controller.get_fixture("Moving Head 1")
    if moving_head:
        # Liga dimmer
        moving_head.set_channel_value(1, 255)  # Dimmer
        print("     - Dimmer ligado")

        # Abre shutter
        moving_head.set_channel_value(2, 255)  # Shutter
        print("     - Shutter aberto")

        # Cor branca
        moving_head.set_channel_value(3, 0)  # Red
        moving_head.set_channel_value(4, 0)  # Green
        moving_head.set_channel_value(5, 0)  # Blue
        moving_head.set_channel_value(6, 255)  # White
        print("     - Cor branca aplicada")

    # Demonstra controle da LED Strip
    print("\n   Controlando LED Strip:")
    led_strip = controller.get_fixture("LED Strip 1")
    if led_strip:
        # Primeira LED: vermelho
        led_strip.set_channel_value(1, 255)  # Red LED 1
        led_strip.set_channel_value(2, 0)  # Green LED 1
        led_strip.set_channel_value(3, 0)  # Blue LED 1
        print("     - LED 1: vermelho")

        # Segunda LED: azul
        led_strip.set_channel_value(4, 0)  # Red LED 2
        led_strip.set_channel_value(5, 0)  # Green LED 2
        led_strip.set_channel_value(6, 255)  # Blue LED 2
        print("     - LED 2: azul")

    print("\n4. Status do universo:")
    universe = controller.get_universe()
    active_channels = [i + 1 for i, v in enumerate(universe) if v > 0]
    print(f"   - Canais ativos: {len(active_channels)}")
    print(f"   - Primeiros 10 canais ativos: {active_channels[:10]}")

    print("\n5. Demonstração de efeitos:")

    # Efeito de fade no PAR Can
    print("\n   Efeito fade no PAR Can:")
    par_can = controller.get_fixture("PAR Can 1")
    if par_can:
        # Fade de vermelho para azul
        print("     - Fade de vermelho para azul...")
        par_can.fade_all_channels([0, 0, 255], duration_ms=2000)

    print("\n6. Operações de controle:")

    # Blackout
    print("   - Executando blackout...")
    controller.blackout()

    # Full on
    print("   - Executando full on...")
    controller.full_on()

    # Reset
    print("   - Resetando todos os fixtures...")
    controller.reset_all_fixtures()

    print("\n=== Exemplo concluído ===")
    print("\nPara conectar a um dispositivo físico:")
    print("1. Conecte um adaptador USB-RS485")
    print("2. Execute: python -m controller_dmx512.main --port COM3")
    print("3. Use a interface gráfica ou modo console")


if __name__ == "__main__":
    main()
