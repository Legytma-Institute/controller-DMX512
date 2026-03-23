"""
Janela Principal - Interface gráfica principal do controlador DMX512

Este módulo implementa a janela principal da aplicação com
controles para gerenciar fixtures e canais DMX.
"""

import logging
import os
import sys
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk
from typing import Optional

from ..core.dmx_controller import DMXController
from ..core.fixture import Fixture, FixtureType, PredefinedFixtures
from .fixture_widget import FixtureWidget
from .rdm_widget import RDMWidget
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
        self._current_file: Optional[str] = None
        self._displayed_fixture: Optional[str] = None
        self.root = tk.Tk()
        self.setup_window()
        self.create_menu_bar()
        self.create_widgets()
        self.setup_bindings()
        self.update_fixtures_list()

        logger.info("Janela principal inicializada")

    def setup_window(self):
        """Configura a janela principal"""
        self.root.title("Controlador DMX512")
        # Abre em maximizado
        try:
            if sys.platform.startswith("win"):
                self.root.state("zoomed")
            else:
                self.root.attributes("-zoomed", True)
        except tk.TclError:
            self.root.geometry(
                f"{self.root.winfo_screenwidth()}x{self.root.winfo_screenheight()}+0+0"
            )
        # self.root.geometry("1920x1080")
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

        # Notebook com abas (DMX / RDM)
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True, pady=(10, 0))

        # --- Aba DMX ---
        dmx_tab = ttk.Frame(self.notebook)
        self.notebook.add(dmx_tab, text="DMX")

        # Frame de conteúdo principal
        content_frame = ttk.Frame(dmx_tab)
        content_frame.pack(fill=tk.BOTH, expand=True)

        # Painel esquerdo - Lista de fixtures
        self.create_fixtures_panel(content_frame)

        # Painel central - Controles de fixture
        self.create_fixture_controls_panel(content_frame)

        # Painel direito - Universo DMX
        self.create_universe_panel(content_frame)

        # --- Aba RDM ---
        rdm_tab = ttk.Frame(self.notebook)
        self.notebook.add(rdm_tab, text="RDM")

        self.rdm_widget = RDMWidget(rdm_tab, self.controller)
        self.rdm_widget.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Barra de status
        self.create_status_bar(main_frame)

    def create_menu_bar(self):
        """Cria a barra de menus"""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)

        # Menu Arquivo
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Arquivo", menu=file_menu)
        file_menu.add_command(label="Novo", command=self.file_new, accelerator="Ctrl+N")
        file_menu.add_command(label="Abrir...", command=self.file_open, accelerator="Ctrl+O")
        file_menu.add_separator()
        file_menu.add_command(label="Salvar", command=self.file_save, accelerator="Ctrl+S")
        file_menu.add_command(label="Salvar Como...", command=self.file_save_as, accelerator="Ctrl+Shift+S")
        file_menu.add_separator()
        file_menu.add_command(label="Sair", command=self.on_closing)

        # Menu Fixture
        fixture_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Fixture", menu=fixture_menu)
        fixture_menu.add_command(label="Adicionar Fixture...", command=self.add_from_config)
        fixture_menu.add_command(label="Clonar Selecionada", command=self.clone_fixture)
        fixture_menu.add_separator()
        fixture_menu.add_command(label="Exportar como Template...", command=self.export_fixture_as_template)

        # Atalhos de teclado
        self.root.bind("<Control-n>", lambda e: self.file_new())
        self.root.bind("<Control-o>", lambda e: self.file_open())
        self.root.bind("<Control-s>", lambda e: self.file_save())
        self.root.bind("<Control-Shift-S>", lambda e: self.file_save_as())

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
        ttk.Button(toolbar, text="Adicionar Fixture", command=self.add_from_config).pack(
            side=tk.LEFT, padx=(0, 5)
        )
        ttk.Button(toolbar, text="Clonar", command=self.clone_fixture).pack(
            side=tk.LEFT, padx=(0, 5)
        )

        # Separador
        ttk.Separator(toolbar, orient=tk.VERTICAL).pack(
            side=tk.LEFT, fill=tk.Y, padx=10
        )

        # Porta serial
        ttk.Label(toolbar, text="Porta:").pack(side=tk.LEFT, padx=(0, 5))
        self.port_var = tk.StringVar()
        self.port_combo = ttk.Combobox(
            toolbar, textvariable=self.port_var, width=15)
        self.port_combo.pack(side=tk.LEFT, padx=(0, 5))

        # Atualiza lista de portas
        self.update_port_list()

    def create_fixtures_panel(self, parent):
        """Cria o painel de lista de fixtures"""
        # Frame do painel
        fixtures_frame = ttk.LabelFrame(parent, text="Fixtures")
        fixtures_frame.pack(side=tk.LEFT, fill=tk.BOTH,
                            expand=False, padx=(0, 5))

        # Lista de fixtures
        list_frame = ttk.Frame(fixtures_frame)
        list_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Scrollbar
        scrollbar = ttk.Scrollbar(list_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Listbox
        self.fixtures_listbox = tk.Listbox(
            list_frame, yscrollcommand=scrollbar.set)
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
        self.fixture_widgets_frame.pack(
            fill=tk.BOTH, expand=True, padx=5, pady=5)

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
        # Ajusta o tamanho do frame para 1/2 da largura da janela
        # universe_frame.pack_propagate(False)
        universe_frame.configure(width=800)
        universe_frame.pack(side=tk.RIGHT, fill=tk.BOTH,
                            expand=False, padx=(5, 0))

        # Widget do universo
        self.universe_widget = UniverseWidget(universe_frame, self.controller)
        self.universe_widget.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

    def create_status_bar(self, parent):
        """Cria a barra de status"""
        self.status_bar = ttk.Frame(parent)
        self.status_bar.pack(fill=tk.X, pady=(10, 0))

        # Status de conexão
        self.connection_status = ttk.Label(
            self.status_bar, text="Desconectado")
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

    # ------------------------------------------------------------------
    # Operações de arquivo
    # ------------------------------------------------------------------

    def _update_title(self):
        """Atualiza o título da janela com o nome do arquivo atual"""
        base = "Controlador DMX512"
        if self._current_file:
            self.root.title(f"{base} — {os.path.basename(self._current_file)}")
        else:
            self.root.title(base)

    def file_new(self):
        """Novo projeto — limpa todas as fixtures"""
        if self.controller.fixtures:
            if not messagebox.askyesno("Novo", "Descartar fixtures atuais e criar novo projeto?"):
                return
        self.controller.clear_all_fixtures()
        self._current_file = None
        self._update_title()
        self.update_fixtures_list()
        self.clear_fixture_controls()

    def file_open(self):
        """Abre uma coleção de fixtures de um arquivo JSON"""
        filepath = filedialog.askopenfilename(
            title="Abrir Coleção de Fixtures",
            filetypes=[("Coleção DMX", "*.dmxcol"), ("JSON", "*.json"), ("Todos", "*.*")],
        )
        if not filepath:
            return
        try:
            self.controller.load_fixture_collection(filepath)
            self._current_file = filepath
            self._update_title()
            self.update_fixtures_list()
            self.clear_fixture_controls()
            messagebox.showinfo("Sucesso", f"{len(self.controller.fixtures)} fixture(s) carregada(s)")
        except Exception as e:
            messagebox.showerror("Erro", f"Falha ao abrir arquivo:\n{e}")

    def file_save(self):
        """Salva a coleção atual no arquivo corrente (ou chama Salvar Como)"""
        if self._current_file:
            try:
                self.controller.save_fixture_collection(self._current_file)
            except Exception as e:
                messagebox.showerror("Erro", f"Falha ao salvar:\n{e}")
        else:
            self.file_save_as()

    def file_save_as(self):
        """Salva a coleção atual em um novo arquivo"""
        filepath = filedialog.asksaveasfilename(
            title="Salvar Coleção de Fixtures",
            defaultextension=".dmxcol",
            filetypes=[("Coleção DMX", "*.dmxcol"), ("JSON", "*.json"), ("Todos", "*.*")],
        )
        if not filepath:
            return
        try:
            self.controller.save_fixture_collection(filepath)
            self._current_file = filepath
            self._update_title()
            messagebox.showinfo("Sucesso", "Coleção salva com sucesso")
        except Exception as e:
            messagebox.showerror("Erro", f"Falha ao salvar:\n{e}")

    # ------------------------------------------------------------------
    # Adicionar fixture de arquivo de configuração (template)
    # ------------------------------------------------------------------

    def _get_fixtures_dir(self) -> str:
        """Retorna o caminho da pasta de templates de fixtures"""
        # Tenta encontrar a pasta fixtures/ relativa ao projeto
        here = Path(__file__).resolve()
        # Sobe até encontrar a pasta fixtures/ (projeto raiz)
        for parent in here.parents:
            candidate = parent / "fixtures"
            if candidate.is_dir():
                return str(candidate)
        return ""

    def add_from_config(self):
        """Adiciona uma fixture a partir de um arquivo de configuração"""
        initial_dir = self._get_fixtures_dir()
        filepath = filedialog.askopenfilename(
            title="Selecionar Template de Fixture",
            initialdir=initial_dir or None,
            filetypes=[("Config Fixture", "*.dmxfix"), ("JSON", "*.json"), ("Todos", "*.*")],
        )
        if not filepath:
            return

        try:
            import json as _json
            with open(filepath, "r", encoding="utf-8") as f:
                cfg = _json.load(f)
        except Exception as e:
            messagebox.showerror("Erro", f"Falha ao ler configuração:\n{e}")
            return

        # Mostra diálogo com dados pré-preenchidos
        dialog = tk.Toplevel(self.root)
        dialog.title("Adicionar Fixture de Configuração")
        dialog.geometry("350x280")
        dialog.transient(self.root)
        dialog.grab_set()

        # Info do template (somente leitura)
        info_frame = ttk.LabelFrame(dialog, text="Configuração")
        info_frame.pack(fill=tk.X, padx=10, pady=(10, 5))

        cfg_name = cfg.get("name", "Desconhecido")
        cfg_manufacturer = cfg.get("manufacturer", "-")
        cfg_brand = cfg.get("brand", "-")
        cfg_model = cfg.get("model", "-")
        cfg_channels = len(cfg.get("channels", []))

        ttk.Label(info_frame, text=f"Fixture: {cfg_name}").pack(anchor=tk.W, padx=5)
        ttk.Label(info_frame, text=f"Fabricante: {cfg_manufacturer} | Marca: {cfg_brand}").pack(anchor=tk.W, padx=5)
        ttk.Label(info_frame, text=f"Modelo: {cfg_model} | Canais: {cfg_channels}").pack(anchor=tk.W, padx=5, pady=(0, 5))

        # Nome
        ttk.Label(dialog, text="Nome da fixture:").pack(pady=(5, 2))
        name_var = tk.StringVar(value=cfg_name)
        name_entry = ttk.Entry(dialog, textvariable=name_var)
        name_entry.pack(padx=10, fill=tk.X)

        # Endereço
        ttk.Label(dialog, text="Endereço inicial:").pack(pady=(5, 2))
        next_addr = self._get_next_available_address()
        addr_var = tk.StringVar(value=str(next_addr))
        ttk.Entry(dialog, textvariable=addr_var).pack(padx=10, fill=tk.X)

        def do_add():
            name = name_var.get().strip()
            if not name:
                messagebox.showerror("Erro", "Nome é obrigatório")
                return
            try:
                address = int(addr_var.get())
                if not (1 <= address <= 512):
                    raise ValueError()
            except ValueError:
                messagebox.showerror("Erro", "Endereço deve ser entre 1 e 512")
                return

            try:
                fixture = Fixture.from_config(filepath, name, address)
                if self.controller.add_fixture(fixture):
                    self.update_fixtures_list()
                    dialog.destroy()
                    messagebox.showinfo("Sucesso", f"Fixture '{name}' adicionada")
                else:
                    messagebox.showerror("Erro", "Falha ao adicionar fixture")
            except Exception as ex:
                messagebox.showerror("Erro", f"Falha ao criar fixture:\n{ex}")

        btns = ttk.Frame(dialog)
        btns.pack(pady=10)
        ttk.Button(btns, text="Adicionar", command=do_add).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btns, text="Cancelar", command=dialog.destroy).pack(side=tk.LEFT)
        name_entry.focus()

    # ------------------------------------------------------------------
    # Clonar fixture
    # ------------------------------------------------------------------

    def clone_fixture(self):
        """Clona a fixture selecionada com novo nome e próximo endereço"""
        selection = self.fixtures_listbox.curselection()
        if not selection:
            messagebox.showwarning("Aviso", "Selecione uma fixture para clonar")
            return

        fixture_name = self.fixtures_listbox.get(selection[0])
        fixture = self.controller.get_fixture(fixture_name)
        if not fixture:
            return

        next_addr = self._get_next_available_address()

        dialog = tk.Toplevel(self.root)
        dialog.title("Clonar Fixture")
        dialog.geometry("300x200")
        dialog.transient(self.root)
        dialog.grab_set()

        ttk.Label(dialog, text=f"Clonando: {fixture.name}").pack(pady=(10, 5))

        ttk.Label(dialog, text="Novo nome:").pack(pady=(5, 2))
        name_var = tk.StringVar(value=f"{fixture.name} (cópia)")
        name_entry = ttk.Entry(dialog, textvariable=name_var)
        name_entry.pack(padx=10, fill=tk.X)

        ttk.Label(dialog, text="Endereço inicial:").pack(pady=(5, 2))
        addr_var = tk.StringVar(value=str(next_addr))
        ttk.Entry(dialog, textvariable=addr_var).pack(padx=10, fill=tk.X)

        def do_clone():
            new_name = name_var.get().strip()
            if not new_name:
                messagebox.showerror("Erro", "Nome é obrigatório")
                return
            try:
                address = int(addr_var.get())
                if not (1 <= address <= 512):
                    raise ValueError()
            except ValueError:
                messagebox.showerror("Erro", "Endereço deve ser entre 1 e 512")
                return

            cloned = fixture.clone(new_name, address)
            if self.controller.add_fixture(cloned):
                self.update_fixtures_list()
                dialog.destroy()
                messagebox.showinfo("Sucesso", f"Fixture '{new_name}' clonada")
            else:
                messagebox.showerror("Erro", "Falha ao clonar fixture")

        btns = ttk.Frame(dialog)
        btns.pack(pady=10)
        ttk.Button(btns, text="Clonar", command=do_clone).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btns, text="Cancelar", command=dialog.destroy).pack(side=tk.LEFT)
        name_entry.select_range(0, tk.END)
        name_entry.focus()

    # ------------------------------------------------------------------
    # Exportar fixture como template
    # ------------------------------------------------------------------

    def export_fixture_as_template(self):
        """Exporta a fixture selecionada como arquivo de configuração (.dmxfix)"""
        selection = self.fixtures_listbox.curselection()
        if not selection:
            messagebox.showwarning("Aviso", "Selecione uma fixture para exportar")
            return

        fixture_name = self.fixtures_listbox.get(selection[0])
        fixture = self.controller.get_fixture(fixture_name)
        if not fixture:
            return

        # Diálogo para preencher metadados antes de salvar
        dialog = tk.Toplevel(self.root)
        dialog.title("Exportar Fixture como Template")
        dialog.geometry("350x300")
        dialog.transient(self.root)
        dialog.grab_set()

        ttk.Label(dialog, text=f"Fixture: {fixture.name}", font=("Arial", 10, "bold")).pack(
            pady=(10, 5)
        )
        ttk.Label(dialog, text=f"Canais: {fixture.get_channel_count()}").pack()

        # Metadados editáveis
        metadata = getattr(fixture, "config_metadata", {})

        ttk.Label(dialog, text="Nome do template:").pack(pady=(10, 2))
        tpl_name_var = tk.StringVar(value=metadata.get("fixture_name", fixture.name))
        ttk.Entry(dialog, textvariable=tpl_name_var).pack(padx=10, fill=tk.X)

        ttk.Label(dialog, text="Fabricante:").pack(pady=(5, 2))
        mfr_var = tk.StringVar(value=metadata.get("manufacturer", ""))
        ttk.Entry(dialog, textvariable=mfr_var).pack(padx=10, fill=tk.X)

        ttk.Label(dialog, text="Marca / Modelo:").pack(pady=(5, 2))
        model_frame = ttk.Frame(dialog)
        model_frame.pack(padx=10, fill=tk.X)
        brand_var = tk.StringVar(value=metadata.get("brand", ""))
        model_var = tk.StringVar(value=metadata.get("model", ""))
        ttk.Entry(model_frame, textvariable=brand_var, width=18).pack(side=tk.LEFT, expand=True, fill=tk.X)
        ttk.Label(model_frame, text=" / ").pack(side=tk.LEFT)
        ttk.Entry(model_frame, textvariable=model_var, width=18).pack(side=tk.LEFT, expand=True, fill=tk.X)

        def do_export():
            filepath = filedialog.asksaveasfilename(
                title="Salvar Template de Fixture",
                defaultextension=".dmxfix",
                filetypes=[("Config Fixture", "*.dmxfix"), ("JSON", "*.json"), ("Todos", "*.*")],
                parent=dialog,
            )
            if not filepath:
                return
            # Atualiza metadados temporariamente para exportação
            fixture.config_metadata = {
                "fixture_name": tpl_name_var.get().strip() or fixture.name,
                "manufacturer": mfr_var.get().strip(),
                "brand": brand_var.get().strip(),
                "model": model_var.get().strip(),
            }
            try:
                fixture.save_config(filepath)
                dialog.destroy()
                messagebox.showinfo("Sucesso", f"Template salvo em:\n{filepath}")
            except Exception as ex:
                messagebox.showerror("Erro", f"Falha ao exportar:\n{ex}")

        btns = ttk.Frame(dialog)
        btns.pack(pady=10)
        ttk.Button(btns, text="Exportar", command=do_export).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btns, text="Cancelar", command=dialog.destroy).pack(side=tk.LEFT)

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

    def _get_next_available_address(self) -> int:
        """Calcula o próximo endereço DMX disponível após todas as fixtures existentes"""
        if not self.controller.fixtures:
            return 1
        max_end = max(f.get_end_address() for f in self.controller.fixtures)
        next_addr = max_end + 1
        return min(next_addr, 512)

    def remove_fixture(self):
        """Remove fixture selecionado"""
        selection = self.fixtures_listbox.curselection()
        if not selection:
            messagebox.showwarning(
                "Aviso", "Selecione um fixture para remover")
            return

        fixture_name = self.fixtures_listbox.get(selection[0])
        if messagebox.askyesno("Confirmar", f"Remover fixture '{fixture_name}'?"):
            if self.controller.remove_fixture(fixture_name):
                self.update_fixtures_list()
                self.clear_fixture_controls()
                messagebox.showinfo(
                    "Sucesso", f"Fixture '{fixture_name}' removido")
            else:
                messagebox.showerror("Erro", "Falha ao remover fixture")

    def rename_fixture(self):
        """Renomeia fixture selecionado"""
        selection = self.fixtures_listbox.curselection()
        if not selection:
            messagebox.showwarning(
                "Aviso", "Selecione um fixture para renomear")
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
            messagebox.showinfo(
                "Sucesso", f"Fixture renomeado para '{new_name}'")

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
        # Não limpar controles quando o listbox perde o foco

    def show_fixture_controls(self, fixture_name: str):
        """Mostra controles para um fixture específico"""
        # Evita reconstruir se já está exibindo o mesmo fixture
        if self._displayed_fixture == fixture_name and fixture_name in self.fixture_widgets:
            return

        fixture = self.controller.get_fixture(fixture_name)
        if not fixture:
            return

        # Limpa controles existentes
        self.clear_fixture_controls()

        # Oculta label inicial
        self.no_fixture_label.pack_forget()

        # Cria widget de fixture
        fixture_widget = FixtureWidget(
            self.fixture_widgets_frame, fixture, self.controller
        )
        fixture_widget.pack(fill=tk.BOTH, expand=True)

        # Armazena referência
        self.fixture_widgets[fixture_name] = fixture_widget
        self._displayed_fixture = fixture_name

    def clear_fixture_controls(self):
        """Limpa controles de fixture"""
        # Remove widgets existentes
        for widget in self.fixture_widgets.values():
            widget.destroy()
        self.fixture_widgets.clear()
        self._displayed_fixture = None

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

        self.universe_widget.update_display()

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
