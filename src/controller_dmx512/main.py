#!/usr/bin/env python3
"""
Aplicação Principal - Controlador DMX512

Este módulo contém a função main e configuração inicial
da aplicação de controle de iluminação DMX512.
"""

import argparse
import logging
import os
import sys
from pathlib import Path

import coloredlogs

from controller_dmx512.core.dmx_controller import DMXController
from controller_dmx512.gui.main_window import MainWindow

# Adiciona o diretório src ao path para imports
sys.path.insert(0, str(Path(__file__).parent.parent))


def setup_logging(level: str = "INFO", log_file: str = None):
    """
    Configura o sistema de logging

    Args:
        level: Nível de logging (DEBUG, INFO, WARNING, ERROR)
        log_file: Arquivo de log (se None, usa console)
    """
    # Configura formato do log
    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # Configura nível
    numeric_level = getattr(logging, level.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError(f"Nível de log inválido: {level}")

    # Instala o coloredlogs
    coloredlogs.install(
        level=numeric_level,
        fmt=log_format,
        level_styles={
            "debug": {"color": "green"},
            "info": {"color": "cyan"},
            "warning": {"color": "yellow"},
            "error": {"color": "red"},
            "critical": {"color": "red", "bold": True},
        },
    )

    # Handler para arquivo (se especificado) - não será colorido
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(numeric_level)
        file_handler.setFormatter(logging.Formatter(log_format))
        logging.getLogger().addHandler(file_handler)

    # Configura logging específico para bibliotecas externas
    logging.getLogger("serial").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)


def create_sample_fixtures(controller: DMXController):
    """
    Cria fixtures de exemplo para demonstração

    Args:
        controller: Controlador DMX
    """
    # PAR Can RGB no endereço 1
    par_can = controller.create_par_can("PAR Can 1", 1)
    controller.add_fixture(par_can)

    # Moving Head no endereço 10
    moving_head = controller.create_moving_head("Moving Head 1", 10)
    controller.add_fixture(moving_head)

    # LED Strip no endereço 20
    led_strip = controller.create_led_strip("LED Strip 1", 20, led_count=3)
    controller.add_fixture(led_strip)

    logging.info("Fixtures de exemplo criados")


def main():
    """Função principal da aplicação"""
    # Configura parser de argumentos
    parser = argparse.ArgumentParser(
        description="Controlador DMX512 - Sistema para controle de iluminação via protocolo DMX512/RS485",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos de uso:
  %(prog)s                    # Executa com interface gráfica
  %(prog)s --port COM3        # Conecta à porta específica
  %(prog)s --log-level DEBUG  # Executa com logging detalhado
  %(prog)s --no-gui           # Executa apenas em modo console
        """,
    )

    parser.add_argument(
        "--port",
        "-p",
        type=str,
        help="Porta serial para conexão DMX (ex: COM3, /dev/ttyUSB0)",
    )

    parser.add_argument(
        "--baudrate",
        "-b",
        type=int,
        default=250000,
        help="Taxa de transmissão serial (padrão: 250000)",
    )

    parser.add_argument(
        "--log-level",
        "-l",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="Nível de logging (padrão: INFO)",
    )

    parser.add_argument("--log-file", type=str, help="Arquivo para salvar logs")

    parser.add_argument(
        "--no-gui",
        action="store_true",
        help="Executa em modo console (sem interface gráfica)",
    )

    parser.add_argument(
        "--demo",
        action="store_true",
        help="Cria fixtures de demonstração automaticamente",
    )

    parser.add_argument(
        "--version", "-v", action="version", version="Controlador DMX512 v0.1.0"
    )

    # Parse argumentos
    args = parser.parse_args()

    # Fallback automático para modo console em ambientes sem DISPLAY
    if not args.no_gui and (sys.platform == "win32" or os.environ.get("DISPLAY")):
        pass
    elif not args.no_gui:
        logging.warning("DISPLAY não definido; alternando para modo console (--no-gui)")
        args.no_gui = True

    try:
        # Configura logging
        setup_logging(args.log_level, args.log_file)

        logging.info("Iniciando Controlador DMX512")
        logging.info(f"Argumentos: {args}")

        # Cria controlador
        controller = DMXController(port=args.port, baudrate=args.baudrate)

        if args.no_gui:
            # Modo console
            run_console_mode(controller, args)
        else:
            # Modo GUI
            run_gui_mode(controller, args)

    except KeyboardInterrupt:
        logging.info("Aplicação interrompida pelo usuário")
        sys.exit(0)
    except Exception as e:
        logging.error(f"Erro fatal: {e}")
        sys.exit(1)


def run_console_mode(controller: DMXController, args):
    """
    Executa aplicação em modo console

    Args:
        controller: Controlador DMX
        args: Argumentos da linha de comando
    """
    logging.info("Executando em modo console")

    # Conecta ao dispositivo
    if args.port:
        if controller.connect(args.port):
            logging.info(f"Conectado à porta {args.port}")
        else:
            logging.error(f"Falha ao conectar à porta {args.port}")
            return
    else:
        # Lista portas disponíveis
        ports = controller.get_available_ports()
        if ports:
            logging.info(f"Portas disponíveis: {ports}")
            if controller.connect(ports[0]):
                logging.info(f"Conectado automaticamente à porta {ports[0]}")
            else:
                logging.error("Falha na conexão automática")
                return
        else:
            logging.error("Nenhuma porta serial disponível")
            return

    # Cria fixtures de demonstração se solicitado
    if args.demo:
        create_sample_fixtures(controller)

    try:
        # Loop principal do console
        logging.info("Digite 'help' para ver comandos disponíveis")

        while True:
            try:
                command = input("DMX> ").strip().lower()

                if command == "quit" or command == "exit":
                    break
                elif command == "help":
                    print_console_help()
                elif command == "status":
                    print_status(controller)
                elif command == "fixtures":
                    print_fixtures(controller)
                elif command == "universe":
                    print_universe(controller)
                elif command == "blackout":
                    controller.blackout()
                    logging.info("Blackout executado")
                elif command == "fullon":
                    controller.full_on()
                    logging.info("Full on executado")
                elif command == "reset":
                    controller.reset_all_fixtures()
                    logging.info("Todos os fixtures resetados")
                elif command.startswith("set "):
                    handle_set_command(controller, command)
                else:
                    logging.warning(f"Comando desconhecido: {command}")

            except EOFError:
                break
            except KeyboardInterrupt:
                break

    finally:
        controller.disconnect()
        logging.info("Aplicação finalizada")


def run_gui_mode(controller: DMXController, args):
    """
    Executa aplicação em modo GUI

    Args:
        controller: Controlador DMX
        args: Argumentos da linha de comando
    """
    logging.info("Executando em modo GUI")

    # Cria fixtures de demonstração se solicitado
    if args.demo:
        create_sample_fixtures(controller)

    # Cria e executa janela principal
    window = MainWindow(controller)
    window.run()


def print_console_help():
    """Imprime ajuda dos comandos do console"""
    print("""
Comandos disponíveis:
  help                    - Mostra esta ajuda
  status                  - Mostra status do controlador
  fixtures                - Lista todos os fixtures
  universe                - Mostra valores do universo DMX
  blackout                - Executa blackout (todos os canais para zero)
  fullon                  - Executa full on (todos os canais para máximo)
  reset                   - Reseta todos os fixtures
  set <canal> <valor>     - Define valor de um canal (ex: set 1 255)
  set <fixture> <canal> <valor> - Define valor de canal de fixture (ex: set "PAR Can 1" 0 128)
  quit/exit               - Sai da aplicação
""")


def print_status(controller: DMXController):
    """Imprime status do controlador"""
    status = controller.get_status()
    print(f"""
Status do Controlador:
  Conectado: {status['connected']}
  Porta: {status['port']}
  Fixtures: {status['fixture_count']}
  Executando: {status['running']}
  Canais ativos: {status['universe_used']}/512
""")


def print_fixtures(controller: DMXController):
    """Imprime lista de fixtures"""
    fixtures = controller.get_all_fixtures()
    if not fixtures:
        print("Nenhum fixture configurado")
        return

    print("\nFixtures configurados:")
    for fixture in fixtures:
        info = fixture.get_info()
        print(
            f"  {info['name']} ({info['type']}) - Endereço {info['start_address']}-{info['end_address']} ({info['channel_count']} canais)"
        )


def print_universe(controller: DMXController):
    """Imprime valores do universo DMX"""
    universe = controller.get_universe()
    active_channels = [i + 1 for i, v in enumerate(universe) if v > 0]

    if not active_channels:
        print("Nenhum canal ativo no universo")
        return

    print(f"\nCanais ativos ({len(active_channels)}):")
    for channel in active_channels[:20]:  # Mostra apenas os primeiros 20
        value = universe[channel - 1]
        print(f"  Canal {channel}: {value}")

    if len(active_channels) > 20:
        print(f"  ... e mais {len(active_channels) - 20} canais")


def handle_set_command(controller: DMXController, command: str):
    """
    Processa comando 'set'

    Args:
        controller: Controlador DMX
        command: Comando completo
    """
    parts = command.split()
    if len(parts) == 3:
        # set <canal> <valor>
        try:
            channel = int(parts[1])
            value = int(parts[2])
            if controller.set_universe_value(channel, value):
                logging.info(f"Canal {channel} definido para {value}")
            else:
                logging.error("Falha ao definir valor do canal")
        except ValueError:
            logging.error("Valores inválidos para canal ou valor")
    elif len(parts) == 4:
        # set <fixture> <canal> <valor>
        try:
            fixture_name = parts[1].strip('"')
            channel_index = int(parts[2])
            value = int(parts[3])
            if controller.set_fixture_value(fixture_name, channel_index, value):
                logging.info(
                    f"Fixture '{fixture_name}' canal {channel_index} definido para {value}"
                )
            else:
                logging.error("Falha ao definir valor do canal do fixture")
        except ValueError:
            logging.error("Valores inválidos para canal ou valor")
    else:
        logging.error("Sintaxe inválida para comando 'set'")


if __name__ == "__main__":
    main()
