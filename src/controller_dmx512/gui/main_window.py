"""
Janela Principal - Interface gráfica principal do controlador DMX512

Este módulo implementa a janela principal da aplicação com
controles para gerenciar fixtures e canais DMX.
"""

import logging
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from typing import Optional

from ..core.dmx_controller import DMXController
from ..core.fixture import Fixture, FixtureType, PredefinedFixtures
from .fixture_widget import FixtureWidget
from .universe_widget import UniverseWidget

logger = logging.getLogger(__name__)


class MainWindow:
    """
    Janela principal da aplicação

    Fornece interface gráfica para controle de dispositivos DMX512
    com gerenciamento de fixtures, canais e universo DMX.
    """

    def __init__(self, controller: DMXController = None):
        """
        Inicializa a janela principal

        Args:
            controller: Instância do controlador DMX (se None, cria uma nova)
        """
        self.controller = controller or DMXController()
        self.root = tk.Tk()
        self.setup_window()
        self.create_widgets()
        self.setup_bindings()

        logger.info("Janela principal inicializada")

    def setup_window(self):
        """Configura a janela principal"""
        self.root.title("Controlador DMX512")
        self.root.geometry("1200x800")
        self.root.minsize(800, 600)

        # Configura ícone (se disponível)
        try:
            self.root.iconbitmap("icon.ico")
        except:
            pass

        # Configura estilo
        style = ttk.Style()
        style.theme_use("clam")

    def create_widgets(self):
        """Cria os widgets da interface"""
        # Frame principal
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Barra de ferramentas superior
        self.create_toolbar(main_frame)

        # Frame de conteúdo principal
        content_frame = ttk.Frame(main_frame)
        content_frame.pack(fill=tk.BOTH, expand=True, pady=(10, 0))

        # Painel esquerdo - Lista de fixtures
        self.create_fixtures_panel(content_frame)

        # Painel central - Controles de fixture
        self.create_fixture_controls_panel(content_frame)

        # Painel direito - Universo DMX
        self.create_universe_panel(content_frame)

        # Barra de status
        self.create_status_bar(main_frame)

    def create_toolbar(self, parent):
        """Cria a barra de ferramentas"""
        toolbar = ttk.Frame(parent)
        toolbar.pack(fill=tk.X, pady=(0, 10))

        # Botões de conexão
        ttk.Button(toolbar, text="Conectar", command=self.connect_dmx).pack(
            side=tk.LEFT, padx=(0, 5)
        )
        ttk.Button(toolbar, text="Desconectar", command=self.disconnect_dmx).pack(
            side=tk.LEFT, padx=(0, 5)
        )

        # Separador
        ttk.Separator(toolbar, orient=tk.VERTICAL).pack(
            side=tk.LEFT, fill=tk.Y, padx=10
        )

        # Botões de controle
        ttk.Button(toolbar, text="Blackout", command=self.blackout).pack(
            side=tk.LEFT, padx=(0, 5)
        )
        ttk.Button(toolbar, text="Full On", command=self.full_on).pack(
            side=tk.LEFT, padx=(0, 5)
        )
        ttk.Button(toolbar, text="Reset", command=self.reset_all).pack(
            side=tk.LEFT, padx=(0, 5)
        )

        # Separador
        ttk.Separator(toolbar, orient=tk.VERTICAL).pack(
            side=tk.LEFT, fill=tk.Y, padx=10
        )

        # Botões de fixture
        ttk.Button(toolbar, text="Adicionar PAR Can", command=self.add_par_can).pack(
            side=tk.LEFT, padx=(0, 5)
        )
        ttk.Button(
            toolbar, text="Adicionar Moving Head", command=self.add_moving_head
        ).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(
            toolbar, text="Adicionar LED Strip", command=self.add_led_strip
        ).pack(side=tk.LEFT, padx=(0, 5))

        # Separador
        ttk.Separator(toolbar, orient=tk.VERTICAL).pack(
            side=tk.LEFT, fill=tk.Y, padx=10
        )

        # Porta serial
        ttk.Label(toolbar, text="Porta:").pack(side=tk.LEFT, padx=(0, 5))
        self.port_var = tk.StringVar()
        self.port_combo = ttk.Combobox(toolbar, textvariable=self.port_var, width=15)
        self.port_combo.pack(side=tk.LEFT, padx=(0, 5))

        # Atualiza lista de portas
        self.update_port_list()

    def create_fixtures_panel(self, parent):
        """Cria o painel de lista de fixtures"""
        # Frame do painel
        fixtures_frame = ttk.LabelFrame(parent, text="Fixtures")
        fixtures_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=False, padx=(0, 5))

        # Lista de fixtures
        list_frame = ttk.Frame(fixtures_frame)
        list_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Scrollbar
        scrollbar = ttk.Scrollbar(list_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Listbox
        self.fixtures_listbox = tk.Listbox(list_frame, yscrollcommand=scrollbar.set)
        self.fixtures_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.config(command=self.fixtures_listbox.yview)

        # Botões de controle de fixtures
        buttons_frame = ttk.Frame(fixtures_frame)
        buttons_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Button(buttons_frame, text="Remover", command=self.remove_fixture).pack(
            side=tk.LEFT, padx=(0, 5)
        )
        ttk.Button(buttons_frame, text="Renomear", command=self.rename_fixture).pack(
            side=tk.LEFT
        )

    def create_fixture_controls_panel(self, parent):
        """Cria o painel de controles de fixture"""
        # Frame do painel
        controls_frame = ttk.LabelFrame(parent, text="Controles de Fixture")
        controls_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5)

        # Frame para widgets de fixture
        self.fixture_widgets_frame = ttk.Frame(controls_frame)
        self.fixture_widgets_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Label inicial
        self.no_fixture_label = ttk.Label(
            self.fixture_widgets_frame,
            text="Selecione um fixture para ver os controles",
            font=("Arial", 12),
        )
        self.no_fixture_label.pack(expand=True)

        # Dicionário para widgets de fixture
        self.fixture_widgets = {}

    def create_universe_panel(self, parent):
        """Cria o painel do universo DMX"""
        # Frame do painel
        universe_frame = ttk.LabelFrame(parent, text="Universo DMX")
        universe_frame.pack(side=tk.RIGHT, fill=tk.BOTH, expand=False, padx=(5, 0))

        # Widget do universo
        self.universe_widget = UniverseWidget(universe_frame, self.controller)
        self.universe_widget.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

    def create_status_bar(self, parent):
        """Cria a barra de status"""
        self.status_bar = ttk.Frame(parent)
        self.status_bar.pack(fill=tk.X, pady=(10, 0))

        # Status de conexão
        self.connection_status = ttk.Label(self.status_bar, text="Desconectado")
        self.connection_status.pack(side=tk.LEFT)

        # Status do universo
        self.universe_status = ttk.Label(
            self.status_bar, text="Universo: 0/512 canais ativos"
        )
        self.universe_status.pack(side=tk.RIGHT)

    def setup_bindings(self):
        """Configura eventos e bindings"""
        # Binding para seleção de fixture
        self.fixtures_listbox.bind("<<ListboxSelect>>", self.on_fixture_select)

        # Binding para fechamento da janela
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)

        # Atualização periódica do status
        self.update_status()

    def update_port_list(self):
        """Atualiza lista de portas disponíveis"""
        ports = self.controller.get_available_ports()
        self.port_combo["values"] = ports
        if ports:
            self.port_combo.set(ports[0])

    def connect_dmx(self):
        """Conecta ao dispositivo DMX"""
        port = self.port_var.get()
        if not port:
            messagebox.showerror("Erro", "Selecione uma porta serial")
            return

        if self.controller.connect(port):
            self.connection_status.config(text=f"Conectado: {port}")
            messagebox.showinfo("Sucesso", f"Conectado à porta {port}")
        else:
            messagebox.showerror("Erro", f"Falha ao conectar à porta {port}")

    def disconnect_dmx(self):
        """Desconecta do dispositivo DMX"""
        self.controller.disconnect()
        self.connection_status.config(text="Desconectado")
        messagebox.showinfo("Info", "Desconectado do dispositivo DMX")

    def blackout(self):
        """Executa blackout"""
        self.controller.blackout()
        self.update_fixture_widgets()
        self.universe_widget.update_display()

    def full_on(self):
        """Executa full on"""
        self.controller.full_on()
        self.update_fixture_widgets()
        self.universe_widget.update_display()

    def reset_all(self):
        """Reseta todos os fixtures"""
        self.controller.reset_all_fixtures()
        self.update_fixture_widgets()
        self.universe_widget.update_display()

    def add_par_can(self):
        """Adiciona um PAR Can"""
        self._add_fixture_dialog("PAR Can", FixtureType.PAR_CAN)

    def add_moving_head(self):
        """Adiciona um Moving Head"""
        self._add_fixture_dialog("Moving Head", FixtureType.MOVING_HEAD)

    def add_led_strip(self):
        """Adiciona uma LED Strip"""
        self._add_fixture_dialog("LED Strip", FixtureType.LED_STRIP)

    def _add_fixture_dialog(self, fixture_type_name: str, fixture_type: FixtureType):
        """Diálogo para adicionar fixture"""
        dialog = tk.Toplevel(self.root)
        dialog.title(f"Adicionar {fixture_type_name}")
        dialog.geometry("300x150")
        dialog.transient(self.root)
        dialog.grab_set()

        # Nome do fixture
        ttk.Label(dialog, text="Nome:").pack(pady=(10, 5))
        name_var = tk.StringVar()
        name_entry = ttk.Entry(dialog, textvariable=name_var)
        name_entry.pack(pady=(0, 10))

        # Endereço inicial
        ttk.Label(dialog, text="Endereço inicial:").pack(pady=(0, 5))
        address_var = tk.StringVar(value="1")
        address_entry = ttk.Entry(dialog, textvariable=address_var)
        address_entry.pack(pady=(0, 10))

        def add_fixture():
            name = name_var.get().strip()
            if not name:
                messagebox.showerror("Erro", "Nome é obrigatório")
                return

            try:
                address = int(address_var.get())
                if address < 1 or address > 512:
                    raise ValueError()
            except ValueError:
                messagebox.showerror("Erro", "Endereço deve ser entre 1 e 512")
                return

            # Cria o fixture
            if fixture_type == FixtureType.PAR_CAN:
                fixture = self.controller.create_par_can(name, address)
            elif fixture_type == FixtureType.MOVING_HEAD:
                fixture = self.controller.create_moving_head(name, address)
            elif fixture_type == FixtureType.LED_STRIP:
                fixture = self.controller.create_led_strip(name, address)
            else:
                fixture = Fixture(name, fixture_type, address)

            # Adiciona ao controlador
            if self.controller.add_fixture(fixture):
                self.update_fixtures_list()
                dialog.destroy()
                messagebox.showinfo(
                    "Sucesso", f"{fixture_type_name} '{name}' adicionado"
                )
            else:
                messagebox.showerror("Erro", "Falha ao adicionar fixture")

        # Botões
        buttons_frame = ttk.Frame(dialog)
        buttons_frame.pack(pady=10)

        ttk.Button(buttons_frame, text="Adicionar", command=add_fixture).pack(
            side=tk.LEFT, padx=(0, 5)
        )
        ttk.Button(buttons_frame, text="Cancelar", command=dialog.destroy).pack(
            side=tk.LEFT
        )

        # Foco no nome
        name_entry.focus()

    def remove_fixture(self):
        """Remove fixture selecionado"""
        selection = self.fixtures_listbox.curselection()
        if not selection:
            messagebox.showwarning("Aviso", "Selecione um fixture para remover")
            return

        fixture_name = self.fixtures_listbox.get(selection[0])
        if messagebox.askyesno("Confirmar", f"Remover fixture '{fixture_name}'?"):
            if self.controller.remove_fixture(fixture_name):
                self.update_fixtures_list()
                self.clear_fixture_controls()
                messagebox.showinfo("Sucesso", f"Fixture '{fixture_name}' removido")
            else:
                messagebox.showerror("Erro", "Falha ao remover fixture")

    def rename_fixture(self):
        """Renomeia fixture selecionado"""
        selection = self.fixtures_listbox.curselection()
        if not selection:
            messagebox.showwarning("Aviso", "Selecione um fixture para renomear")
            return

        old_name = self.fixtures_listbox.get(selection[0])
        fixture = self.controller.get_fixture(old_name)
        if not fixture:
            return

        # Diálogo de renomeação
        dialog = tk.Toplevel(self.root)
        dialog.title("Renomear Fixture")
        dialog.geometry("300x100")
        dialog.transient(self.root)
        dialog.grab_set()

        ttk.Label(dialog, text="Novo nome:").pack(pady=(10, 5))
        name_var = tk.StringVar(value=old_name)
        name_entry = ttk.Entry(dialog, textvariable=name_var)
        name_entry.pack(pady=(0, 10))

        def rename():
            new_name = name_var.get().strip()
            if not new_name:
                messagebox.showerror("Erro", "Nome é obrigatório")
                return

            if new_name in self.controller.fixtures_by_name and new_name != old_name:
                messagebox.showerror("Erro", "Nome já existe")
                return

            fixture.name = new_name
            self.controller.fixtures_by_name[new_name] = fixture
            if new_name != old_name:
                del self.controller.fixtures_by_name[old_name]

            self.update_fixtures_list()
            dialog.destroy()
            messagebox.showinfo("Sucesso", f"Fixture renomeado para '{new_name}'")

        buttons_frame = ttk.Frame(dialog)
        buttons_frame.pack(pady=10)

        ttk.Button(buttons_frame, text="Renomear", command=rename).pack(
            side=tk.LEFT, padx=(0, 5)
        )
        ttk.Button(buttons_frame, text="Cancelar", command=dialog.destroy).pack(
            side=tk.LEFT
        )

        name_entry.focus()

    def update_fixtures_list(self):
        """Atualiza lista de fixtures"""
        self.fixtures_listbox.delete(0, tk.END)
        for fixture in self.controller.get_all_fixtures():
            self.fixtures_listbox.insert(tk.END, fixture.name)

    def on_fixture_select(self, event):
        """Callback para seleção de fixture"""
        selection = self.fixtures_listbox.curselection()
        if selection:
            fixture_name = self.fixtures_listbox.get(selection[0])
            self.show_fixture_controls(fixture_name)
        else:
            self.clear_fixture_controls()

    def show_fixture_controls(self, fixture_name: str):
        """Mostra controles para um fixture específico"""
        fixture = self.controller.get_fixture(fixture_name)
        if not fixture:
            return

        # Limpa controles existentes
        self.clear_fixture_controls()

        # Cria widget de fixture
        fixture_widget = FixtureWidget(
            self.fixture_widgets_frame, fixture, self.controller
        )
        fixture_widget.pack(fill=tk.BOTH, expand=True)

        # Armazena referência
        self.fixture_widgets[fixture_name] = fixture_widget

    def clear_fixture_controls(self):
        """Limpa controles de fixture"""
        # Remove widgets existentes
        for widget in self.fixture_widgets.values():
            widget.destroy()
        self.fixture_widgets.clear()

        # Mostra label inicial
        self.no_fixture_label.pack(expand=True)

    def update_fixture_widgets(self):
        """Atualiza todos os widgets de fixture"""
        for widget in self.fixture_widgets.values():
            widget.update_display()

    def update_status(self):
        """Atualiza barra de status"""
        status = self.controller.get_status()

        # Status de conexão
        if status["connected"]:
            self.connection_status.config(text=f"Conectado: {status['port']}")
        else:
            self.connection_status.config(text="Desconectado")

        # Status do universo
        self.universe_status.config(
            text=f"Universo: {status['universe_used']}/512 canais ativos"
        )

        # Agenda próxima atualização
        self.root.after(1000, self.update_status)

    def on_closing(self):
        """Callback para fechamento da janela"""
        if messagebox.askokcancel("Sair", "Deseja sair da aplicação?"):
            self.controller.disconnect()
            self.root.destroy()

    def run(self):
        """Executa a aplicação"""
        self.root.mainloop()
