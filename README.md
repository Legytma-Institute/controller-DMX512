pre# Controlador DMX512

Um controlador completo para equipamentos que suportam o protocolo DMX512 escrito em Python, projetado para controle de iluminação profissional via porta RS485.

## 🎯 Sobre o Projeto

Este projeto implementa um sistema completo de controle de iluminação DMX512, incluindo:

- **Protocolo DMX512 completo** com comunicação RS485
- **Interface gráfica moderna** para controle intuitivo
- **Suporte a múltiplos tipos de fixtures** (PAR Cans, Moving Heads, LED Strips, etc.)
- **Controle de 512 canais** simultâneos
- **Efeitos e transições** suaves
- **Modo console** para automação
- **Sistema de logging** configurável

## 🏗️ Estrutura do Projeto

```
controller-DMX512/
├── src/controller_dmx512/          # Código fonte principal
│   ├── core/                       # Módulo principal
│   │   ├── protocol.py             # Protocolo DMX512/RS485
│   │   ├── channel.py              # Classe Channel
│   │   ├── fixture.py              # Classe Fixture
│   │   └── dmx_controller.py       # Controlador principal
│   ├── gui/                        # Interface gráfica
│   │   ├── main_window.py          # Janela principal
│   │   ├── fixture_widget.py       # Widget de fixture
│   │   ├── channel_widget.py       # Widget de canal
│   │   └── universe_widget.py      # Widget do universo
│   ├── utils/                      # Utilitários
│   │   ├── color_utils.py          # Manipulação de cores
│   │   └── file_utils.py           # Manipulação de arquivos
│   └── main.py                     # Aplicação principal
├── tests/                          # Testes unitários e integração
│   ├── unit/                       # Testes unitários
│   └── integration/                # Testes de integração
├── examples/                       # Exemplos de uso
├── pyproject.toml                  # Configuração do projeto (PEP 621)
├── requirements.txt                # Dependências de desenvolvimento
└── pytest.ini                      # Configuração do pytest
```

## 🚀 Funcionalidades

### ✨ Principais Recursos

- **Protocolo DMX512 Completo**
  - Implementação fiel do padrão DMX512
  - Comunicação via porta serial RS485
  - Suporte a break e mark after break
  - Transmissão de frames DMX512 completos

- **Sistema de Fixtures**
  - PAR Cans RGB
  - Moving Heads
  - LED Strips
  - Fixtures customizados
  - Validação de endereços

- **Controle de Canais**
  - 512 canais simultâneos
  - Tipos de canais especializados (dimmer, RGB, pan, tilt, etc.)
  - Efeitos de fade suaves
  - Histórico de valores

- **Interface Gráfica**
  - Controles intuitivos com sliders
  - Visualização do universo DMX
  - Gerenciamento de fixtures
  - Controles individuais por canal

- **Utilitários Avançados**
  - Conversão de cores (RGB, HSV, Kelvin)
  - Importação/exportação de configurações
  - Backup de setups
  - Biblioteca de fixtures

## 📋 Pré-requisitos

- **Python 3.8+** instalado no sistema
- **Adaptador USB-RS485** para comunicação DMX
- **Dispositivos DMX512** (PAR Cans, Moving Heads, etc.)
- **pip** (gerenciador de pacotes Python)

### Dependências do Sistema

- **Windows**: Nenhuma dependência adicional
- **Linux**: `sudo apt-get install python3-tk` (para interface gráfica)
- **macOS**: Nenhuma dependência adicional

## 🛠️ Instalação

### 1. Clone o Repositório

```bash
git clone https://github.com/Legytma-Institute/controller-DMX512.git
cd controller-DMX512
```

### 2. Instale o Projeto

```bash
# Instalar em modo desenvolvimento
pip install -e .

# Ou instalar diretamente
pip install .
```

### 3. Instale as Dependências de Desenvolvimento (opcional)

```bash
# Instalar dependências para desenvolvimento
pip install -r requirements.txt
```

### 4. Verifique a Instalação

```bash
# Teste básico
python examples/basic_usage.py

# Execute os testes
pytest
```

## 🎮 Como Usar

### Interface Gráfica (Recomendado)

```bash
# Executar interface gráfica
python -m controller_dmx512.main

# Com porta específica
python -m controller_dmx512.main --port COM3

# Com fixtures de demonstração
python -m controller_dmx512.main --demo

# Logging detalhado
python -m controller_dmx512.main --log-level DEBUG
```

### Modo Console

```bash
# Executar em modo console
python -m controller_dmx512.main --no-gui

# Com porta específica
python -m controller_dmx512.main --no-gui --port /dev/ttyUSB0
```

### Argumentos de Linha de Comando

```bash
python -m controller_dmx512.main [OPÇÕES]

Opções:
  --port, -p PORT        Porta serial (ex: COM3, /dev/ttyUSB0)
  --baudrate, -b RATE    Taxa de transmissão (padrão: 250000)
  --log-level, -l LEVEL  Nível de logging (DEBUG, INFO, WARNING, ERROR)
  --log-file FILE        Arquivo para salvar logs
  --no-gui               Executar em modo console
  --demo                 Criar fixtures de demonstração
  --version, -v          Mostrar versão
  --help, -h             Mostrar ajuda
```

## 📖 Exemplos de Uso

### Exemplo Básico

```python
from controller_dmx512.core.dmx_controller import DMXController

# Criar controlador
controller = DMXController()

# Conectar ao dispositivo
controller.connect("COM3")

# Criar PAR Can RGB
par_can = controller.create_par_can("PAR Can 1", 1)
controller.add_fixture(par_can)

# Definir cor vermelha
par_can.set_channel_value(1, 255)  # Red
par_can.set_channel_value(2, 0)    # Green
par_can.set_channel_value(3, 0)    # Blue

# Efeito de fade
par_can.fade_all_channels([0, 0, 255], duration_ms=2000)  # Para azul

# Blackout
controller.blackout()
```

### Exemplo com Múltiplos Fixtures

```python
# Criar Moving Head
moving_head = controller.create_moving_head("Moving Head 1", 10)
controller.add_fixture(moving_head)

# Criar LED Strip
led_strip = controller.create_led_strip("LED Strip 1", 20, led_count=3)
controller.add_fixture(led_strip)

# Controle individual
moving_head.set_channel_value(1, 255)  # Dimmer
moving_head.set_channel_value(2, 255)  # Shutter

# Controle de cor
led_strip.set_all_channels([255, 0, 0, 0, 255, 0, 0, 0, 255])  # RGB
```

## 🧪 Testes

### Executar Testes

```bash
# Todos os testes
pytest

# Testes unitários apenas
pytest tests/unit/

# Testes com cobertura
pytest --cov=src/controller_dmx512

# Testes específicos
pytest tests/unit/test_channel.py -v
```

### Tipos de Testes

- **Unitários**: Testes de componentes individuais (`tests/unit/`)
- **Integração**: Testes de comunicação entre módulos (`tests/integration/`)
- **GUI**: Testes da interface gráfica
- **Hardware**: Testes com dispositivos físicos

## 🔧 Configuração de Hardware

### Acesso à porta serial no Dev Container

Este projeto já vem preparado para expor adaptadores RS485/DMX512 no devcontainer (bind de `/dev` e modo privilegiado). Passos rápidos:

- **Devcontainer**: após build, o `.devcontainer/post-create.sh` cria/usa o grupo `dialout`, instala utilitários (`minicom`, `screen`, `setserial`, `udev`) e roda `scripts/setup-serial.sh` (regras udev são opcionais; em container sem udevd o script apenas avisa e segue).
- **Verificar dispositivos**: `ls -la /dev/ttyUSB* /dev/ttyACM* /dev/ttyS*` dentro do container.
- **Testar comunicação**: `minicom -D /dev/ttyUSB0` ou `screen /dev/ttyUSB0 9600`. Em Python: `serial.Serial('/dev/ttyUSB0', 250000, timeout=1)`.

#### Windows (WSL 2 + Docker Desktop)

- Instale/ative WSL 2 e o `usbipd-win`.
- Encaminhe o adaptador sempre que conectar: `usbipd list` → `usbipd bind --busid <id>` (1ª vez) → `usbipd attach --wsl --busid <id>`.
- Script de apoio: `scripts/setup-usbipd.ps1` (PowerShell) automatiza bind/attach.

#### macOS

- Instale driver do adaptador (FTDI/CH34x) se preciso.
- Se necessário, crie um pseudo-device com `socat` e faça bind no `devcontainer.json` (ex.: `${HOME}/ttyDMX` → `/dev/ttyUSB0`).

#### Linux

- Adicione seu usuário a `dialout,plugdev`: `sudo usermod -aG dialout,plugdev $USER` e abra nova sessão (`newgrp dialout`).
- Opcional: regra udev específica por VID/PID para liberar a porta.

### Adaptador USB-RS485

1. **Conecte o adaptador** USB-RS485 ao computador
2. **Identifique a porta** (Windows: COM3, Linux: /dev/ttyUSB0)
3. **Configure o endereço** dos dispositivos DMX
4. **Conecte os dispositivos** à saída RS485

### Dispositivos Suportados

- **PAR Cans RGB**
- **Moving Heads**
- **LED Strips**
- **Scanners**
- **Strobes**
- **Fog Machines**
- **Dispositivos customizados**

## 📚 Documentação

### API Reference

```python
# Controlador Principal
controller = DMXController(port="COM3", baudrate=250000)
controller.connect()
controller.disconnect()

# Fixtures
fixture = controller.create_par_can("PAR Can 1", 1)
controller.add_fixture(fixture)
controller.remove_fixture("PAR Can 1")

# Canais
fixture.set_channel_value(channel_number, value)
fixture.set_all_channels([r, g, b])
fixture.fade_all_channels([r, g, b], duration_ms=1000)

# Operações Globais
controller.blackout()
controller.full_on()
controller.reset_all_fixtures()
```

### Utilitários

```python
from controller_dmx512.utils.color_utils import rgb_to_dmx, hex_to_rgb
from controller_dmx512.utils.file_utils import save_fixture_config

# Conversão de cores
dmx_values = rgb_to_dmx(255, 0, 0)  # Vermelho
rgb_color = hex_to_rgb("#FF0000")   # Vermelho

# Salvar configuração
save_fixture_config(fixtures, "setup.json")
```

## 🐛 Solução de Problemas

### Problemas Comuns

1. **Porta não encontrada**

   ```bash
   # Listar portas disponíveis
   python -c "import serial.tools.list_ports; print([p.device for p in serial.tools.list_ports.comports()])"
   ```

2. **Erro de permissão (Linux)**

   ```bash
   # Adicionar usuário ao grupo dialout
   sudo usermod -a -G dialout $USER
   # Reiniciar sessão
   ```

3. **Interface gráfica não abre**

   ```bash
   # Verificar tkinter
   python -c "import tkinter; tkinter._test()"
   ```

### Logs de Debug

```bash
# Executar com logging detalhado
python -m controller_dmx512.main --log-level DEBUG --log-file debug.log
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📦 Distribuição

O projeto utiliza modernas práticas de empacotamento Python:

- **pyproject.toml**: Configuração do projeto seguindo PEP 621
- **src-layout**: Estrutura de código fonte moderna
- **PEP 517/518**: Build system independente
- **PEP 561**: Suporte a type hints

Para construir o pacote:

```bash
# Instalar build
pip install build

# Construir distribuição
python -m build
```

## 🙏 Agradecimentos

- **Python Serial** para comunicação RS485
- **Tkinter** para interface gráfica
- **Pytest** para framework de testes
- **Comunidade DMX512** por padrões e documentação

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/Legytma-Institute/controller-DMX512/issues)
- **Documentação**: [Wiki do Projeto](https://github.com/Legytma-Institute/controller-DMX512/wiki)
- **Author**: [https://github.com/Windol](https://github.com/Windol)

---

**Desenvolvido com ❤️ para a comunidade de iluminação profissional**
