"""
Painel RDM - Widget para gerenciamento de dispositivos RDM

Este módulo implementa o painel de controle RDM na interface gráfica,
permitindo discovery, visualização de propriedades e comandos RDM.
"""

import logging
import threading
import tkinter as tk
from tkinter import messagebox, ttk
from typing import List, Optional

from ..core.dmx_controller import DMXController
from ..core.rdm import RDMDeviceInfo, RDMUID

logger = logging.getLogger(__name__)


class RDMWidget(ttk.Frame):
    """
    Widget para gerenciamento de dispositivos RDM

    Fornece interface para discovery, visualização de propriedades
    e controle de dispositivos RDM na linha DMX512.
    """

    def __init__(self, parent: tk.Widget, controller: DMXController):
        super().__init__(parent)
        self.controller = controller
        self._discovered_devices: List[RDMDeviceInfo] = []
        self._selected_uid: Optional[str] = None
        self._discovery_running = False

        self._create_widgets()

    def _create_widgets(self):
        """Cria os widgets do painel RDM"""

        # --- Toolbar ---
        toolbar = ttk.Frame(self)
        toolbar.pack(fill=tk.X, pady=(0, 5))

        self._btn_discover = ttk.Button(
            toolbar, text="Discover", command=self._on_discover
        )
        self._btn_discover.pack(side=tk.LEFT, padx=(0, 5))

        self._btn_refresh = ttk.Button(
            toolbar, text="Atualizar Info", command=self._on_refresh_info
        )
        self._btn_refresh.pack(side=tk.LEFT, padx=(0, 5))

        self._lbl_status = ttk.Label(toolbar, text="")
        self._lbl_status.pack(side=tk.LEFT, padx=(10, 0))

        # --- Device list (Treeview) ---
        list_frame = ttk.Frame(self)
        list_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 5))

        columns = ("uid", "label", "manufacturer", "model", "address", "footprint")
        self._tree = ttk.Treeview(
            list_frame, columns=columns, show="headings", height=8
        )
        self._tree.heading("uid", text="UID")
        self._tree.heading("label", text="Nome")
        self._tree.heading("manufacturer", text="Fabricante")
        self._tree.heading("model", text="Modelo")
        self._tree.heading("address", text="Endereço")
        self._tree.heading("footprint", text="Canais")

        self._tree.column("uid", width=120, minwidth=100)
        self._tree.column("label", width=120, minwidth=80)
        self._tree.column("manufacturer", width=120, minwidth=80)
        self._tree.column("model", width=120, minwidth=80)
        self._tree.column("address", width=70, minwidth=50)
        self._tree.column("footprint", width=60, minwidth=40)

        scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self._tree.yview)
        self._tree.configure(yscrollcommand=scrollbar.set)

        self._tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self._tree.bind("<<TreeviewSelect>>", self._on_device_select)

        # --- Device detail / actions ---
        detail_frame = ttk.LabelFrame(self, text="Dispositivo Selecionado")
        detail_frame.pack(fill=tk.X, pady=(0, 5))

        # Info grid
        info_grid = ttk.Frame(detail_frame)
        info_grid.pack(fill=tk.X, padx=5, pady=5)

        row = 0
        ttk.Label(info_grid, text="UID:").grid(row=row, column=0, sticky=tk.W, padx=(0, 5))
        self._lbl_uid = ttk.Label(info_grid, text="-")
        self._lbl_uid.grid(row=row, column=1, sticky=tk.W)

        row += 1
        ttk.Label(info_grid, text="Fabricante:").grid(row=row, column=0, sticky=tk.W, padx=(0, 5))
        self._lbl_manufacturer = ttk.Label(info_grid, text="-")
        self._lbl_manufacturer.grid(row=row, column=1, sticky=tk.W)

        row += 1
        ttk.Label(info_grid, text="Modelo:").grid(row=row, column=0, sticky=tk.W, padx=(0, 5))
        self._lbl_model = ttk.Label(info_grid, text="-")
        self._lbl_model.grid(row=row, column=1, sticky=tk.W)

        row += 1
        ttk.Label(info_grid, text="Firmware:").grid(row=row, column=0, sticky=tk.W, padx=(0, 5))
        self._lbl_firmware = ttk.Label(info_grid, text="-")
        self._lbl_firmware.grid(row=row, column=1, sticky=tk.W)

        row += 1
        ttk.Label(info_grid, text="Personalidade:").grid(row=row, column=0, sticky=tk.W, padx=(0, 5))
        self._lbl_personality = ttk.Label(info_grid, text="-")
        self._lbl_personality.grid(row=row, column=1, sticky=tk.W)

        row += 1
        ttk.Label(info_grid, text="Sensores:").grid(row=row, column=0, sticky=tk.W, padx=(0, 5))
        self._lbl_sensors = ttk.Label(info_grid, text="-")
        self._lbl_sensors.grid(row=row, column=1, sticky=tk.W)

        # Actions
        actions_frame = ttk.Frame(detail_frame)
        actions_frame.pack(fill=tk.X, padx=5, pady=(0, 5))

        self._btn_identify_on = ttk.Button(
            actions_frame, text="Identify ON", command=lambda: self._on_identify(True)
        )
        self._btn_identify_on.pack(side=tk.LEFT, padx=(0, 5))

        self._btn_identify_off = ttk.Button(
            actions_frame, text="Identify OFF", command=lambda: self._on_identify(False)
        )
        self._btn_identify_off.pack(side=tk.LEFT, padx=(0, 5))

        ttk.Separator(actions_frame, orient=tk.VERTICAL).pack(
            side=tk.LEFT, fill=tk.Y, padx=10
        )

        ttk.Label(actions_frame, text="Endereço DMX:").pack(side=tk.LEFT, padx=(0, 5))
        self._var_address = tk.StringVar()
        self._entry_address = ttk.Entry(
            actions_frame, textvariable=self._var_address, width=6
        )
        self._entry_address.pack(side=tk.LEFT, padx=(0, 5))

        self._btn_set_address = ttk.Button(
            actions_frame, text="Definir", command=self._on_set_address
        )
        self._btn_set_address.pack(side=tk.LEFT, padx=(0, 5))

        ttk.Separator(actions_frame, orient=tk.VERTICAL).pack(
            side=tk.LEFT, fill=tk.Y, padx=10
        )

        ttk.Label(actions_frame, text="Nome:").pack(side=tk.LEFT, padx=(0, 5))
        self._var_label = tk.StringVar()
        self._entry_label = ttk.Entry(
            actions_frame, textvariable=self._var_label, width=20
        )
        self._entry_label.pack(side=tk.LEFT, padx=(0, 5))

        self._btn_set_label = ttk.Button(
            actions_frame, text="Renomear", command=self._on_set_label
        )
        self._btn_set_label.pack(side=tk.LEFT, padx=(0, 5))

        # Disable actions initially
        self._set_actions_enabled(False)

    # ------------------------------------------------------------------
    # Actions
    # ------------------------------------------------------------------

    def _on_discover(self):
        if self._discovery_running:
            return
        if not self.controller.protocol or not self.controller.protocol.is_connected:
            messagebox.showwarning("Aviso", "Conecte ao dispositivo DMX antes de executar discovery.")
            return

        self._discovery_running = True
        self._btn_discover.config(state=tk.DISABLED)
        self._lbl_status.config(text="Executando discovery...")

        def _run():
            try:
                devices = self.controller.rdm_discover_and_populate()
                self._discovered_devices = devices
                self.after(0, self._populate_tree)
            except Exception as e:
                logger.error("Erro no RDM discovery: %s", e)
                self.after(0, lambda: messagebox.showerror("Erro", f"Falha no discovery: {e}"))
            finally:
                self._discovery_running = False
                self.after(0, lambda: self._btn_discover.config(state=tk.NORMAL))

        threading.Thread(target=_run, daemon=True).start()

    def _populate_tree(self):
        self._tree.delete(*self._tree.get_children())
        for dev in self._discovered_devices:
            self._tree.insert(
                "",
                tk.END,
                iid=str(dev.uid),
                values=(
                    str(dev.uid),
                    dev.device_label or "-",
                    dev.manufacturer_label or "-",
                    dev.device_model_description or "-",
                    dev.dmx_start_address,
                    dev.dmx_footprint,
                ),
            )
        count = len(self._discovered_devices)
        self._lbl_status.config(text=f"{count} dispositivo(s) encontrado(s)")

    def _on_device_select(self, _event=None):
        selection = self._tree.selection()
        if not selection:
            self._selected_uid = None
            self._set_actions_enabled(False)
            self._clear_detail()
            return

        uid_str = selection[0]
        self._selected_uid = uid_str
        info = self.controller.rdm_devices.get(uid_str)
        if info:
            self._show_detail(info)
        self._set_actions_enabled(True)

    def _on_refresh_info(self):
        if not self._selected_uid:
            return
        if not self.controller.protocol or not self.controller.protocol.is_connected:
            return

        try:
            uid = RDMUID.from_str(self._selected_uid)
        except ValueError:
            return

        def _run():
            info = self.controller.rdm_get_full_device_info(uid)
            if info:
                self.after(0, lambda: self._show_detail(info))
                self.after(0, self._populate_tree)

        threading.Thread(target=_run, daemon=True).start()

    def _on_identify(self, on: bool):
        if not self._selected_uid:
            return
        try:
            uid = RDMUID.from_str(self._selected_uid)
        except ValueError:
            return

        def _run():
            self.controller.rdm_identify(uid, on=on)

        threading.Thread(target=_run, daemon=True).start()

    def _on_set_address(self):
        if not self._selected_uid:
            return
        try:
            uid = RDMUID.from_str(self._selected_uid)
            address = int(self._var_address.get())
            if not (1 <= address <= 512):
                raise ValueError()
        except ValueError:
            messagebox.showerror("Erro", "Endereço deve ser entre 1 e 512")
            return

        def _run():
            ok = self.controller.rdm_set_dmx_address(uid, address)
            if ok:
                self.after(0, lambda: self._lbl_status.config(text=f"Endereço alterado para {address}"))
                info = self.controller.rdm_get_full_device_info(uid)
                if info:
                    self.after(0, lambda: self._show_detail(info))
                    self.after(0, self._populate_tree)
            else:
                self.after(0, lambda: messagebox.showerror("Erro", "Falha ao alterar endereço"))

        threading.Thread(target=_run, daemon=True).start()

    def _on_set_label(self):
        if not self._selected_uid:
            return
        try:
            uid = RDMUID.from_str(self._selected_uid)
        except ValueError:
            return
        label = self._var_label.get().strip()
        if not label:
            messagebox.showerror("Erro", "Nome não pode ser vazio")
            return

        def _run():
            ok = self.controller.rdm_set_device_label(uid, label)
            if ok:
                self.after(0, lambda: self._lbl_status.config(text=f"Nome alterado para '{label}'"))
                info = self.controller.rdm_get_full_device_info(uid)
                if info:
                    self.after(0, lambda: self._show_detail(info))
                    self.after(0, self._populate_tree)
            else:
                self.after(0, lambda: messagebox.showerror("Erro", "Falha ao renomear dispositivo"))

        threading.Thread(target=_run, daemon=True).start()

    # ------------------------------------------------------------------
    # Detail helpers
    # ------------------------------------------------------------------

    def _show_detail(self, info: RDMDeviceInfo):
        self._lbl_uid.config(text=str(info.uid))
        self._lbl_manufacturer.config(text=info.manufacturer_label or "-")
        self._lbl_model.config(text=info.device_model_description or "-")
        self._lbl_firmware.config(text=info.software_version_label or "-")

        personality_text = f"{info.current_personality}/{info.personality_count}"
        if info.personalities.get(info.current_personality):
            p = info.personalities[info.current_personality]
            personality_text += f" - {p.description} ({p.dmx_footprint}ch)"
        self._lbl_personality.config(text=personality_text)

        self._lbl_sensors.config(text=str(info.sensor_count))
        self._var_address.set(str(info.dmx_start_address))
        self._var_label.set(info.device_label)

    def _clear_detail(self):
        self._lbl_uid.config(text="-")
        self._lbl_manufacturer.config(text="-")
        self._lbl_model.config(text="-")
        self._lbl_firmware.config(text="-")
        self._lbl_personality.config(text="-")
        self._lbl_sensors.config(text="-")
        self._var_address.set("")
        self._var_label.set("")

    def _set_actions_enabled(self, enabled: bool):
        state = tk.NORMAL if enabled else tk.DISABLED
        self._btn_identify_on.config(state=state)
        self._btn_identify_off.config(state=state)
        self._btn_set_address.config(state=state)
        self._btn_set_label.config(state=state)
        self._entry_address.config(state=state)
        self._entry_label.config(state=state)
        self._btn_refresh.config(state=state)
