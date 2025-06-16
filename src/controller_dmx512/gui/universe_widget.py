"""
Widget do Universo - Visualização do universo DMX completo

Este módulo implementa o widget UniverseWidget que mostra
uma visualização gráfica dos 512 canais do universo DMX.
"""

import tkinter as tk
from tkinter import ttk
from typing import List

from ..core.dmx_controller import DMXController


class UniverseWidget(ttk.Frame):
    """
    Widget para visualização do universo DMX

    Mostra uma representação gráfica dos 512 canais
    com valores e cores indicativas.
    """

    def __init__(self, parent, controller: DMXController):
        """
        Inicializa o widget do universo

        Args:
            parent: Widget pai
            controller: Controlador DMX
        """
        super().__init__(parent)
        self.controller = controller
        self.channel_buttons = []

        self.create_widgets()
        self.update_display()

    def create_widgets(self):
        """Cria os widgets do universo"""
        # Cabeçalho
        header_frame = ttk.Frame(self)
        header_frame.pack(fill=tk.X, pady=(0, 10))

        ttk.Label(
            header_frame, text="Universo DMX (512 Canais)", font=("Arial", 12, "bold")
        ).pack(side=tk.LEFT)

        # Botões de controle
        ttk.Button(header_frame, text="Atualizar", command=self.update_display).pack(
            side=tk.RIGHT
        )

        # Frame principal com scroll
        main_frame = ttk.Frame(self)
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Canvas para os canais
        self.canvas = tk.Canvas(main_frame, bg="white")
        scrollbar = ttk.Scrollbar(
            main_frame, orient=tk.VERTICAL, command=self.canvas.yview
        )

        # Frame interno para os canais
        self.channels_frame = ttk.Frame(self.canvas)

        self.canvas.create_window((0, 0), window=self.channels_frame, anchor="nw")
        self.canvas.configure(yscrollcommand=scrollbar.set)

        self.canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Cria botões para os canais
        self.create_channel_buttons()

        # Configura scroll
        self.channels_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")),
        )

    def create_channel_buttons(self):
        """Cria botões para os 512 canais"""
        # Organiza em grade de 32x16 (512 canais)
        rows = 16
        cols = 32

        for i in range(512):
            channel_num = i + 1
            row = i // cols
            col = i % cols

            # Frame para o canal
            channel_frame = ttk.Frame(self.channels_frame)
            channel_frame.grid(row=row, column=col, padx=1, pady=1, sticky="nsew")

            # Botão do canal
            button = tk.Button(
                channel_frame,
                text=str(channel_num),
                width=3,
                height=1,
                font=("Arial", 8),
                command=lambda ch=channel_num: self.on_channel_click(ch),
            )

            button.pack(fill=tk.BOTH, expand=True)
            self.channel_buttons.append(button)

            # Configura grid weights
            self.channels_frame.grid_rowconfigure(row, weight=1)
            self.channels_frame.grid_columnconfigure(col, weight=1)

    def on_channel_click(self, channel_num: int):
        """Callback para clique em um canal"""
        # Diálogo para definir valor do canal
        dialog = tk.Toplevel(self)
        dialog.title(f"Canal {channel_num}")
        dialog.geometry("300x150")
        dialog.transient(self.winfo_toplevel())
        dialog.grab_set()

        # Valor atual
        current_value = self.controller.get_universe_value(channel_num)

        ttk.Label(dialog, text=f"Valor do Canal {channel_num}:").pack(pady=(10, 5))

        # Slider
        value_var = tk.IntVar(value=current_value)
        slider = ttk.Scale(
            dialog, from_=0, to=255, variable=value_var, orient=tk.HORIZONTAL
        )
        slider.pack(fill=tk.X, padx=10, pady=5)

        # Entrada numérica
        entry_var = tk.StringVar(value=str(current_value))
        entry = ttk.Entry(dialog, textvariable=entry_var, width=10)
        entry.pack(pady=5)

        def update_slider(*args):
            try:
                value = int(entry_var.get())
                if 0 <= value <= 255:
                    value_var.set(value)
            except ValueError:
                pass

        def update_entry(*args):
            entry_var.set(str(value_var.get()))

        # Bindings
        value_var.trace("w", update_entry)
        entry_var.trace("w", update_slider)

        def apply_value():
            try:
                value = int(entry_var.get())
                if 0 <= value <= 255:
                    self.controller.set_universe_value(channel_num, value)
                    self.update_display()
                    dialog.destroy()
            except ValueError:
                pass

        # Botões
        buttons_frame = ttk.Frame(dialog)
        buttons_frame.pack(pady=10)

        ttk.Button(buttons_frame, text="Aplicar", command=apply_value).pack(
            side=tk.LEFT, padx=5
        )
        ttk.Button(buttons_frame, text="Cancelar", command=dialog.destroy).pack(
            side=tk.LEFT, padx=5
        )

        entry.focus()

    def update_display(self):
        """Atualiza exibição do universo"""
        universe = self.controller.get_universe()

        for i, button in enumerate(self.channel_buttons):
            channel_num = i + 1
            value = universe[i]

            # Atualiza texto do botão
            button.config(text=f"{channel_num}\n{value}")

            # Atualiza cor baseada no valor
            if value == 0:
                bg_color = "#F0F0F0"  # Cinza claro (off)
                fg_color = "#000000"  # Preto
            elif value < 64:
                bg_color = "#FFE4E1"  # Rosa claro
                fg_color = "#000000"
            elif value < 128:
                bg_color = "#FFD700"  # Dourado
                fg_color = "#000000"
            elif value < 192:
                bg_color = "#FFA500"  # Laranja
                fg_color = "#000000"
            else:
                bg_color = "#90EE90"  # Verde claro
                fg_color = "#000000"

            button.config(bg=bg_color, fg=fg_color)

    def get_channel_info(self, channel_num: int) -> dict:
        """
        Retorna informações de um canal específico

        Args:
            channel_num: Número do canal (1-512)

        Returns:
            Dicionário com informações do canal
        """
        value = self.controller.get_universe_value(channel_num)

        # Verifica se o canal está sendo usado por algum fixture
        fixture_info = None
        for fixture in self.controller.get_all_fixtures():
            if fixture.start_address <= channel_num <= fixture.get_end_address():
                channel_index = channel_num - fixture.start_address
                if 0 <= channel_index < len(fixture.channels):
                    channel = fixture.channels[channel_index]
                    fixture_info = {
                        "fixture_name": fixture.name,
                        "fixture_type": fixture.fixture_type.value,
                        "channel_name": channel.name,
                        "channel_type": channel.channel_type.value,
                    }
                break

        return {
            "channel": channel_num,
            "value": value,
            "percentage": value / 255.0,
            "fixture_info": fixture_info,
        }
