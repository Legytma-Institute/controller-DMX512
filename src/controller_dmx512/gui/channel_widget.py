"""
Widget de Canal - Controles para um canal DMX individual

Este módulo implementa o widget ChannelWidget que fornece
controles para um canal específico.
"""

import tkinter as tk
from tkinter import ttk

from ..core.channel import Channel
from ..core.dmx_controller import DMXController


class ChannelWidget(ttk.Frame):
    """
    Widget para controle de um canal DMX individual

    Fornece slider, entrada numérica e informações do canal.
    """

    def __init__(self, parent, channel: Channel, controller: DMXController):
        """
        Inicializa o widget de canal

        Args:
            parent: Widget pai
            channel: Canal a ser controlado
            controller: Controlador DMX
        """
        super().__init__(parent)
        self.channel = channel
        self.controller = controller
        self.updating = False  # Flag para evitar loops de atualização

        self.create_widgets()
        self.update_display()

    def create_widgets(self):
        """Cria os widgets do canal"""
        # Frame principal
        main_frame = ttk.Frame(self)
        main_frame.pack(fill=tk.X, expand=True)

        # Informações do canal
        info_frame = ttk.Frame(main_frame)
        info_frame.pack(side=tk.LEFT, fill=tk.Y, padx=(0, 10))

        ttk.Label(
            info_frame,
            text=f"Tipo: {self.channel.channel_type.value}",
            font=("Arial", 9),
        ).pack(anchor=tk.W)
        ttk.Label(
            info_frame,
            text=f"Range: {self.channel.min_value}-{self.channel.max_value}",
            font=("Arial", 9),
        ).pack(anchor=tk.W)

        # Controles
        controls_frame = ttk.Frame(main_frame)
        controls_frame.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

        # Slider
        slider_frame = ttk.Frame(controls_frame)
        slider_frame.pack(fill=tk.X, pady=(0, 5))

        ttk.Label(slider_frame, text="Valor:").pack(side=tk.LEFT)

        self.slider = ttk.Scale(
            slider_frame,
            from_=self.channel.min_value,
            to=self.channel.max_value,
            orient=tk.HORIZONTAL,
            command=self.on_slider_change,
        )
        self.slider.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(5, 0))

        # Entrada numérica
        entry_frame = ttk.Frame(controls_frame)
        entry_frame.pack(fill=tk.X)

        ttk.Label(entry_frame, text="Valor:").pack(side=tk.LEFT)

        self.value_var = tk.StringVar()
        self.value_entry = ttk.Entry(entry_frame, textvariable=self.value_var, width=8)
        self.value_entry.pack(side=tk.LEFT, padx=(5, 0))

        # Botão de aplicação
        ttk.Button(entry_frame, text="Aplicar", command=self.on_entry_apply).pack(
            side=tk.LEFT, padx=(5, 0)
        )

        # Botão de reset
        ttk.Button(entry_frame, text="Reset", command=self.reset_channel).pack(
            side=tk.LEFT, padx=(5, 0)
        )

        # Bindings
        self.value_entry.bind("<Return>", lambda e: self.on_entry_apply())
        self.value_entry.bind("<FocusOut>", lambda e: self.on_entry_apply())

    def on_slider_change(self, value):
        """Callback para mudança no slider"""
        if self.updating:
            return

        try:
            int_value = int(float(value))
            self.channel.set_value(int_value)
            self.update_display()
        except ValueError:
            pass

    def on_entry_apply(self):
        """Aplica valor da entrada numérica"""
        if self.updating:
            return

        try:
            value = int(self.value_var.get())
            if self.channel.set_value(value):
                self.update_display()
        except ValueError:
            # Restaura valor anterior se entrada inválida
            self.update_display()

    def reset_channel(self):
        """Reseta o canal para valor padrão"""
        self.channel.reset()
        self.update_display()

    def update_display(self):
        """Atualiza exibição do canal"""
        self.updating = True

        # Atualiza slider
        self.slider.set(self.channel.get_value())

        # Atualiza entrada
        self.value_var.set(str(self.channel.get_value()))

        # Atualiza cor de fundo baseada no valor
        percentage = self.channel.get_percentage()
        if percentage > 0.8:
            bg_color = "#90EE90"  # Verde claro
        elif percentage > 0.5:
            bg_color = "#FFD700"  # Dourado
        elif percentage > 0.2:
            bg_color = "#FFA500"  # Laranja
        else:
            bg_color = "#F0F0F0"  # Cinza claro

        self.configure(style="Channel.TFrame")
        style = ttk.Style()
        style.configure("Channel.TFrame", background=bg_color)

        self.updating = False
