## Documentação de Instalação do Cursor e Extensões para Docker, Remote e Dev Containers

### 1. Introdução

Este guia descreve, de forma prática, os passos necessários para instalar o editor **Cursor** e as extensões de **Docker**, **Remote Development** e **Dev Containers** nos principais sistemas operacionais: Windows, macOS e Linux.

### 2. Pré-requisitos

* **Docker** já instalado e configurado no sistema. Caso ainda não possua, consulte a [documentação oficial do Docker](https://docs.docker.com/get-docker/).
* Acesso à internet para download dos instaladores.
* Permissões de administrador/sudo no sistema.

---

### 3. Instalação do Cursor

#### 3.1 Windows

1. Acesse o site oficial: [https://www.cursor.so/download](https://www.cursor.so/download).
2. Baixe o instalador `.msi` para Windows.
3. Execute o arquivo baixado e siga o assistente de instalação.
4. Ao finalizar, abra o **Cursor** pelo menu Iniciar.

#### 3.2 macOS

1. Acesse: [https://www.cursor.so/download](https://www.cursor.so/download).
2. Baixe o arquivo `.dmg` para macOS.
3. Monte a imagem de disco e arraste o ícone do **Cursor** para a pasta `Aplicativos`.
4. Abra o **Cursor** via Launchpad ou `Finder > Aplicativos`.

#### 3.3 Linux (Ubuntu/Debian)

1. Baixe o pacote `.deb` em [https://www.cursor.so/download](https://www.cursor.so/download).
2. Instale pelo terminal:

   ```bash
   sudo dpkg -i cursor*.deb
   sudo apt-get install -f       # Corrige dependências, se necessário
   ```
3. Abra o **Cursor** via o menu de aplicativos ou digitando `cursor` no terminal.

---

### 4. Instalação das Extensões

As extensões podem ser instaladas via interface gráfica ou linha de comando, tanto no **Cursor** quanto no **VSCode**.

#### 4.1 Extensões Necessárias

* **Docker**: `ms-azuretools.vscode-docker`
* **Remote Development (Extension Pack)**: `ms-vscode-remote.vscode-remote-extensionpack`
* **Dev Containers** (caso não esteja inclusa no pack): `ms-vscode-remote.remote-containers`
* **Remote WSL**: `ms-vscode-remote.remote-wsl`

#### 4.2 Linha de Comando

##### VSCode

```bash
# Docker
code --install-extension ms-azuretools.vscode-docker
# Remote Development Pack
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
# Dev Containers (opcional)
code --install-extension ms-vscode-remote.remote-containers
# Remote WSL (opcional)
code --install-extension ms-vscode-remote.remote-wsl
```

##### Cursor

O **Cursor** compartilha o mesmo mecanismo de extensão do VSCode:

```bash
# Docker
cursor --install-extension ms-azuretools.vscode-docker
# Remote Development Pack
cursor --install-extension ms-vscode-remote.vscode-remote-extensionpack
# Dev Containers (opcional)
cursor --install-extension ms-vscode-remote.remote-containers
# Remote WSL (opcional)
cursor --install-extension ms-vscode-remote.remote-wsl
```

> *Observação:* Caso o comando `cursor` não esteja disponível, utilize o caminho completo do executável (ex.: `/usr/bin/cursor`).

#### 4.3 Interface Gráfica

1. Abra o **Cursor** ou **VSCode**.
2. Acesse o painel de **Extensões** (ícone de quadrados empilhados ou `Ctrl+Shift+X`).
3. Pesquise pelo nome da extensão (ex.: "Docker").
4. Clique em **Instalar**.

---

### 5. Verificação

1. Após a instalação, abra o **Cursor** ou **VSCode**.
2. Acesse `Extensões` e confirme que as três extensões estão instaladas e habilitadas.
3. No terminal integrado, execute:

   ```bash
   docker version
   ```

   para verificar a comunicação com o Docker.

---

### 6. Conclusão

Com o **Cursor** e as extensões de **Docker**, **Remote Development**, **Dev Containers** e **Remote WSL** instalados, sua equipe iniciará o desenvolvimento em Dev Containers de forma rápida e padronizada, independentemente do sistema operacional.

---

*Este documento foi gerado para apoiar desenvolvedores iniciantes na configuração do ambiente de desenvolvimento.*
