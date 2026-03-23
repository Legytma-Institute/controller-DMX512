"""
Widget de Fixture - Controles para um fixture individual

Este módulo implementa o widget FixtureWidget que fornece
controles para um fixture específico.
"""

import tkinter as tk
from tkinter import messagebox, ttk
from typing import Any, Dict

from ..core.channel import Channel, ChannelType
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
        self.channel_frames: dict[int, ttk.LabelFrame] = {}
        self.channel_name_labels: dict[int, tk.Label] = {}
        for i, channel in enumerate(self.fixture.channels):
            self._create_single_channel_widget(i, channel)

        # Botão para adicionar canal no final da lista
        self._add_btn_frame = ttk.Frame(self.scrollable_frame)
        self._add_btn_frame.pack(fill=tk.X, padx=5, pady=(5, 10))
        ttk.Button(
            self._add_btn_frame, text="+ Adicionar Canal", command=self._add_channel_dialog,
        ).pack(anchor=tk.W)

    def _create_single_channel_widget(self, index: int, channel):
        """Cria o widget de um canal individual"""
        channel_frame = ttk.LabelFrame(self.scrollable_frame)
        channel_frame.pack(fill=tk.X, padx=5, pady=2)

        # Barra de título: lápis | nome | × remover
        title_bar = ttk.Frame(channel_frame)
        title_bar.pack(fill=tk.X, padx=5, pady=(2, 0))

        pencil_btn = tk.Label(
            title_bar, text="\u270E", font=("Arial", 11), cursor="hand2",
        )
        pencil_btn.pack(side=tk.LEFT)
        pencil_btn.bind(
            "<Button-1>",
            lambda e, ch=channel: self._rename_channel(ch),
        )

        name_lbl = tk.Label(
            title_bar,
            text=f"Canal {channel.number}: {channel.name}",
            font=("Arial", 10, "bold"),
        )
        name_lbl.pack(side=tk.LEFT, padx=(4, 0))

        # Botão remover (×)
        remove_btn = tk.Label(
            title_bar, text="\u00D7", font=("Arial", 13, "bold"),
            cursor="hand2", fg="red",
        )
        remove_btn.pack(side=tk.RIGHT)
        remove_btn.bind(
            "<Button-1>",
            lambda e, idx=index: self._remove_channel(idx),
        )

        # Widget do canal
        channel_widget = ChannelWidget(channel_frame, channel, self.controller)
        channel_widget.pack(fill=tk.X, padx=5, pady=5)

        # Armazena referências
        self.channel_widgets[channel.number] = channel_widget
        self.channel_frames[channel.number] = channel_frame
        self.channel_name_labels[channel.number] = name_lbl

    def _rebuild_channels(self):
        """Reconstrói todos os widgets de canais"""
        # Destrói widgets antigos
        for frm in self.channel_frames.values():
            frm.destroy()
        if hasattr(self, "_add_btn_frame") and self._add_btn_frame.winfo_exists():
            self._add_btn_frame.destroy()
        self.channel_widgets.clear()
        self.channel_frames.clear()
        self.channel_name_labels.clear()

        # Recria
        self.create_channel_widgets()

    # ------------------------------------------------------------------
    # Adicionar / Remover canais
    # ------------------------------------------------------------------

    def _add_channel_dialog(self):
        """Diálogo para adicionar um novo canal"""
        top = self.winfo_toplevel()
        dialog = tk.Toplevel(top)
        dialog.title("Adicionar Canal")
        dialog.geometry("300x170")
        dialog.resizable(False, False)
        dialog.transient(top)

        next_num = self.fixture.start_address + len(self.fixture.channels)

        ttk.Label(dialog, text=f"Endereço: {next_num}").pack(pady=(10, 5))

        ttk.Label(dialog, text="Nome:").pack(pady=(0, 2))
        name_var = tk.StringVar(value=f"Canal {len(self.fixture.channels) + 1}")
        name_entry = ttk.Entry(dialog, textvariable=name_var, width=25)
        name_entry.pack()

        ttk.Label(dialog, text="Tipo:").pack(pady=(5, 2))
        types = [ct.value for ct in ChannelType]
        type_var = tk.StringVar(value="dimmer")
        type_combo = ttk.Combobox(dialog, textvariable=type_var, values=types, state="readonly", width=22)
        type_combo.pack()

        def do_add(event=None):
            ch_name = name_var.get().strip()
            if not ch_name:
                return
            ch = Channel(next_num, ch_name, ChannelType(type_var.get()))
            self.fixture.add_channel(ch)
            dialog.destroy()
            self._rebuild_channels()

        btns = ttk.Frame(dialog)
        btns.pack(pady=8)
        ttk.Button(btns, text="Adicionar", width=10, command=do_add).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btns, text="Cancelar", width=10, command=dialog.destroy).pack(side=tk.LEFT)
        name_entry.select_range(0, tk.END)
        name_entry.focus_set()
        name_entry.bind("<Return>", do_add)

    def _remove_channel(self, index: int):
        """Remove um canal pelo índice"""
        if len(self.fixture.channels) <= 1:
            messagebox.showwarning("Aviso", "A fixture deve ter pelo menos 1 canal")
            return
        ch = self.fixture.channels[index]
        if messagebox.askyesno("Remover Canal", f"Remover canal '{ch.name}'?"):
            self.fixture.remove_channel_by_index(index)
            self._rebuild_channels()

    # ------------------------------------------------------------------
    # Controles gerais
    # ------------------------------------------------------------------

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

    # ------------------------------------------------------------------
    # Renomear canal
    # ------------------------------------------------------------------

    def _rename_channel(self, channel):
        """Diálogo para renomear um canal"""
        top = self.winfo_toplevel()
        dialog = tk.Toplevel(top)
        dialog.title(f"Renomear Canal {channel.number}")
        dialog.geometry("300x130")
        dialog.resizable(False, False)
        dialog.transient(top)

        ttk.Label(dialog, text="Novo nome:").pack(pady=(15, 5))
        name_var = tk.StringVar(value=channel.name)
        entry = ttk.Entry(dialog, textvariable=name_var, width=30)
        entry.pack(padx=20)

        def apply_rename(event=None):
            new_name = name_var.get().strip()
            if not new_name:
                return
            channel.name = new_name
            lbl = self.channel_name_labels.get(channel.number)
            if lbl and lbl.winfo_exists():
                lbl.config(text=f"Canal {channel.number}: {new_name}")
            try:
                dialog.destroy()
            except tk.TclError:
                pass

        btns = ttk.Frame(dialog)
        btns.pack(pady=10)
        ttk.Button(btns, text="OK", width=8, command=apply_rename).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btns, text="Cancelar", width=8, command=dialog.destroy).pack(side=tk.LEFT)

        entry.select_range(0, tk.END)
        entry.focus_set()
        entry.bind("<Return>", apply_rename)
