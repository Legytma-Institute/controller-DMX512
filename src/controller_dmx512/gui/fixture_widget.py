"""
Widget de Fixture - Controles para um fixture individual

Este módulo implementa o widget FixtureWidget que fornece
controles para um fixture específico.
"""

import tkinter as tk
from tkinter import ttk
from typing import Any, Dict

from ..core.dmx_controller import DMXController
from ..core.fixture import Fixture
from .channel_widget import ChannelWidget


class FixtureWidget(ttk.Frame):
    """
    Widget para controle de um fixture individual

    Fornece controles para todos os canais de um fixture
    com sliders, entradas numéricas e informações.
    """

    def __init__(self, parent, fixture: Fixture, controller: DMXController):
        """
        Inicializa o widget de fixture

        Args:
            parent: Widget pai
            fixture: Fixture a ser controlado
            controller: Controlador DMX
        """
        super().__init__(parent)
        self.fixture = fixture
        self.controller = controller
        self.channel_widgets: Dict[int, ChannelWidget] = {}

        self.create_widgets()

    def create_widgets(self):
        """Cria os widgets do fixture"""
        # Cabeçalho do fixture
        header_frame = ttk.Frame(self)
        header_frame.pack(fill=tk.X, pady=(0, 10))

        # Nome e tipo
        info_frame = ttk.Frame(header_frame)
        info_frame.pack(side=tk.LEFT, fill=tk.X, expand=True)

        ttk.Label(
            info_frame, text=f"Fixture: {self.fixture.name}", font=("Arial", 12, "bold")
        ).pack(anchor=tk.W)
        ttk.Label(
            info_frame,
            text=f"Tipo: {self.fixture.fixture_type.value}",
            font=("Arial", 10),
        ).pack(anchor=tk.W)
        ttk.Label(
            info_frame,
            text=f"Endereço: {self.fixture.start_address}-{self.fixture.get_end_address()}",
            font=("Arial", 10),
        ).pack(anchor=tk.W)

        # Botões de controle
        buttons_frame = ttk.Frame(header_frame)
        buttons_frame.pack(side=tk.RIGHT, padx=(10, 0))

        ttk.Button(buttons_frame, text="Reset", command=self.reset_fixture).pack(
            side=tk.TOP, pady=(0, 5)
        )
        ttk.Button(buttons_frame, text="Blackout", command=self.blackout_fixture).pack(
            side=tk.TOP
        )

        # Frame para canais com scroll
        channels_frame = ttk.Frame(self)
        channels_frame.pack(fill=tk.BOTH, expand=True)

        # Canvas e scrollbar para canais
        canvas = tk.Canvas(channels_frame)
        scrollbar = ttk.Scrollbar(
            channels_frame, orient=tk.VERTICAL, command=canvas.yview
        )
        self.scrollable_frame = ttk.Frame(canvas)

        self.scrollable_frame.bind(
            "<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Cria widgets para cada canal
        self.create_channel_widgets()

    def create_channel_widgets(self):
        """Cria widgets para cada canal do fixture"""
        for i, channel in enumerate(self.fixture.channels):
            # Frame para o canal
            channel_frame = ttk.LabelFrame(
                self.scrollable_frame, text=f"Canal {channel.number}: {channel.name}"
            )
            channel_frame.pack(fill=tk.X, padx=5, pady=2)

            # Widget do canal
            channel_widget = ChannelWidget(channel_frame, channel, self.controller)
            channel_widget.pack(fill=tk.X, padx=5, pady=5)

            # Armazena referência
            self.channel_widgets[channel.number] = channel_widget

    def reset_fixture(self):
        """Reseta o fixture para valores padrão"""
        self.fixture.reset_all_channels()
        self.update_display()

    def blackout_fixture(self):
        """Executa blackout no fixture"""
        for channel in self.fixture.channels:
            channel.set_value(0)
        self.update_display()

    def update_display(self):
        """Atualiza exibição de todos os canais"""
        for widget in self.channel_widgets.values():
            widget.update_display()
