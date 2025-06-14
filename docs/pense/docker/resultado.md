# Documentação de Instalação do Docker

Este guia apresenta os passos para instalar o Docker em diferentes sistemas operacionais, garantindo que qualquer máquina de desenvolvimento (Windows, macOS ou Linux) esteja pronta para usar Dev Containers no VSCode ou Cursor.

## Índice

1. [Requisitos Gerais](#requisitos-gerais)
2. [Windows 10/11](#windows-1011)
3. [macOS (Catalina ou superior)](#macos-catalina-ou-superior)
4. [Ubuntu (20.04+ / 22.04+)](#ubuntu-2004-2204)
5. [Debian (10+)](#debian-10)
6. [Fedora (37+)](#fedora-37)
7. [CentOS (8+)](#centos-8)
8. [Verificação da Instalação](#verificação-da-instalação)
9. [Referências](#referências)

## Requisitos Gerais

- Conexão com a internet.
- Acesso com privilégios de administrador/root.
- Espaço em disco mínimo de 2 GB.

## Windows 10/11

1. Acesse o site oficial do Docker Desktop: https://www.docker.com/products/docker-desktop
2. Clique em **Download for Windows (Windows 10/11)**.
3. Execute o instalador baixado (`Docker Desktop Installer.exe`).
4. Siga o assistente de instalação:
   - Marque a opção **Use WSL 2 instead of Hyper-V**, caso use WSL.
   - Concorde com os termos de licença.
5. Finalize e reinicie o computador, se solicitado.
6. Após o boot, abra o **Docker Desktop** para concluir a configuração.

## macOS (Catalina ou superior)

1. Acesse https://www.docker.com/products/docker-desktop.
2. Clique em **Download for Mac (Apple / Intel chip)** conforme seu processador.
3. Abra o arquivo `.dmg` baixado e arraste o ícone do Docker para a pasta Aplicativos.
4. Execute o **Docker** via Launchpad ou Finder.
5. Aceite as permissões solicitadas e aguarde a inicialização.

## Ubuntu (20.04+ / 22.04+)

```bash
# 1. Atualizar índices de pacotes
sudo apt update

# 2. Instalar dependências\ sudo apt install \
ca-certificates \
curl \
gnupg \
lsb-release -y

# 3. Adicionar repositório oficial Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" |
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Instalar Docker Engine e CLI
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

## Debian (10+)

```bash
# 1. Atualizar índices de pacotes\ n sudo apt update

# 2. Instalar dependências
sudo apt install \
ca-certificates \
curl \
gnupg \
lsb-release -y

# 3. Adicionar chave e repositório Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg |
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" |
tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Instalar Docker
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

## Fedora (37+)

```bash
# 1. Atualizar sistema
sudo dnf -y update

# 2. Configurar repositório Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
--add-repo \
https://download.docker.com/linux/fedora/docker-ce.repo

# 3. Instalar Docker Engine
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

## CentOS (8+)

```bash
# 1. Remover versões antigas\ nsudo dnf remove docker \

# 2. Instalar repositório Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
--add-repo \
https://download.docker.com/linux/centos/docker-ce.repo

# 3. Instalar Docker
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

## Verificação da Instalação

Após a instalação, verifique o funcionamento do Docker:

```bash
docker --version
docker run hello-world
```

Se ambos os comandos retornarem com sucesso, o Docker está corretamente instalado.

## Referências

Documentação oficial Docker: https://docs.docker.com/engine/install/

Guia de Dev Containers VSCode: https://code.visualstudio.com/docs/remote/containers
