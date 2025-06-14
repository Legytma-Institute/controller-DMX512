Abaixo segue a documentação em Markdown para instalação do Visual Studio Code (ou Cursor) e dos plugins necessários para Docker, Remote e Dev Containers nos principais sistemas operacionais.

# Instalação do VSCode e Extensões para Docker e Dev Containers

Este guia descreve de forma objetiva a instalação do Visual Studio Code (ou Cursor) e das extensões necessárias para desenvolvimento em Dev Containers, garantindo consistência em qualquer sistema operacional.

---

## 1. Pré-requisitos comuns

- **Conta de usuário** com privilégios de instalação (administrador/root).
- **Conexão com a Internet** para download dos instaladores e extensões.
- **Docker Engine** previamente instalado e em funcionamento.
  - [Guia de instalação do Docker Engine](https://docs.docker.com/get-docker/)

---

## 2. Windows

### 2.1. Instalar o VSCode

1. Acesse:
   https://code.visualstudio.com/
2. Clique em **Download** > **Windows x64 Installer**.
3. Execute o instalador e siga os passos padrão (Next > Accept > Install > Finish).

> **Atalho**: pode usar também o **winget**:
> ```powershell
> winget install --id Microsoft.VisualStudioCode -e
> ```

### 2.2. Instalar extensões

1. Abra o VSCode.
2. Vá em **Extensões** (Ctrl+Shift+X).
3. Pesquise e instale:
   - **Docker**
     - Identificador: `ms-azuretools.vscode-docker`
   - **Dev Containers** (Remote – Containers)
     - Identificador: `ms-vscode-remote.remote-containers`
   - **Remote Development** (pacote opcional)
     - Identificador: `ms-vscode-remote.vscode-remote-extensionpack`
   - **Remote WSL**
     - Identificador: `ms-vscode-remote.remote-wsl`
4. Reinicie o VSCode.

---

## 3. macOS

### 3.1. Instalar o VSCode

1. Acesse:
   https://code.visualstudio.com/
2. Clique em **Download** > **macOS Universal**.
3. Abra o `.zip` baixado e mova o `Visual Studio Code.app` para a pasta **Applications**.

> **Alternativa Homebrew**:
> ```bash
> brew install --cask visual-studio-code
> ```

### 3.2. Instalar extensões

1. Abra o VSCode.
2. Acesse **Extensões** (⌘+Shift+X).
3. Pesquise e instale:
   - **Docker** (`ms-azuretools.vscode-docker`)
   - **Dev Containers** (`ms-vscode-remote.remote-containers`)
   - **Remote Development** (`ms-vscode-remote.vscode-remote-extensionpack`)
   - **Remote WSL** (`ms-vscode-remote.remote-wsl`)
4. Reinicie o VSCode.

---

## 4. Linux

### 4.1. Distribuições Debian/Ubuntu

#### 4.1.1. Instalar o VSCode

```bash
# Importar chave Microsoft
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
rm microsoft.gpg

# Adicionar repositório
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Atualizar e instalar
sudo apt update
sudo apt install code
```

#### 4.1.2. Instalar extensões

```bash
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code --install-extension ms-vscode-remote.remote-wsl
```

### 4.2. Distribuições Fedora/RHEL

#### 4.2.1. Instalar o VSCode

```bash
# Importar chave e repositório
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'cat <<EOF > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF'

# Instalar
sudo dnf check-update
sudo dnf install code
```

#### 4.2.2. Instalar extensões

```bash
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code --install-extension ms-vscode-remote.remote-wsl
```

---

## 5. Validação

1. **Verificar VSCode**

   ```bash
   code --version
   ```
2. **Verificar extensões**

   ```bash
   code --list-extensions | grep -E "docker|remote-containers|remote-extensionpack|remote-wsl"
   ```
3. **Testar Dev Container**

   * Abra a paleta de comandos (Ctrl/Cmd+Shift+P)
   * Escolha **Dev Containers: Open Sample**
   * Selecione o exemplo e aguarde o build do container.

---

> Documentação gerada para iniciantes, com foco em praticidade e agilidade na configuração do ambiente de desenvolvimento em Dev Containers. Qualquer dúvida, retorne para ajustes.
