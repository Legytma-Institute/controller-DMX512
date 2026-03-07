# Configuração de Porta Serial no Dev Container

Este Dev Container foi preparado para expor os adaptadores RS485/DMX512 conectados ao host, independentemente do sistema operacional. Use este guia como referência rápida para liberar o dispositivo serial e validá-lo dentro do container.

## Visão geral da configuração

- `.devcontainer/devcontainer.json` monta `/dev` inteiro, adiciona `SYS_RAWIO` e executa o script `.devcontainer/setup-serial.sh` após o build.
- O script cria/adiciona o grupo `dialout`, instala utilitários (`minicom`, `screen`, `setserial`, `udev`) e mostra os dispositivos `ttyS*` detectados.
- Por padrão, expomos:
  - `/dev/ttyUSB0` – adaptadores USB/RS485
  - `/dev/ttyACM0` – dispositivos ACM/Arduino
  - `/dev/ttyS0` a `/dev/ttyS3` – portas seriais nativas

## Passo a passo por sistema operacional

### 1. Windows 10/11 (WSL 2 + Docker Desktop)

1. Instale/ative o WSL 2 com uma distro Ubuntu (`wsl --install -d Ubuntu`).
2. Instale o `usbipd-win` para encaminhar o adaptador USB para o WSL:
   ```powershell
   winget install --id turtle.Usbipd
   ```
3. Sempre que conectar o adaptador RS485:
   ```powershell
   usbipd list                       # encontre o BUSID (ex.: 1-5)
   usbipd bind --busid 1-5           # apenas na primeira vez
   usbipd attach --wsl --busid 1-5   # disponibiliza no Ubuntu/WSL
   ```
4. No Ubuntu (WSL), confirme a porta (`ls -l /dev/ttyUSB*`).
5. Abra o projeto via VSCode/Cursor → _Dev Containers: Reopen in Container_; o bind `/dev:/dev` fará com que `/dev/ttyUSB0` apareça no container.
6. Se o dispositivo sumir após reiniciar, repita o `usbipd attach`.

### 2. macOS (Intel ou Apple Silicon)

1. Instale drivers do adaptador (FTDI/CH34x etc.) se necessário.
2. Conceda acesso a USB/Disco completo para o terminal/VSCode em **Configurações → Privacidade e Segurança**.
3. Identifique o device (`ls /dev/tty.usbserial*` ou `/dev/cu.usbmodem*`).
4. Use `socat` para criar um pseudo-dispositivo acessível ao Docker Desktop:
   ```bash
   socat -d -d pty,link=$HOME/ttyDMX raw,echo=0 file:/dev/tty.usbserial-0001,raw,echo=0
   ```
5. (Opcional) Adicione ao `devcontainer.json` um bind dedicado:
   ```jsonc
   "runArgs": [
     "--privileged",
     "-v", "/dev:/dev",
     "-v", "${env:HOME}/ttyDMX:/dev/ttyUSB0"
   ]
   ```
6. Reabra o Dev Container e teste `/dev/ttyUSB0` normalmente.

### 3. Linux (Ubuntu/Debian/Fedora/Arch)

1. Garanta que seu usuário pertence aos grupos necessários:
   ```bash
   sudo usermod -aG dialout,plugdev $USER
   newgrp dialout
   ```
2. Opcional: regra udev para liberar o dispositivo automaticamente (ajuste VID/PID conforme `lsusb`):
   ```bash
   sudo tee /etc/udev/rules.d/70-usb-serial.rules <<'EOF'
   SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout"
   EOF
   sudo udevadm control --reload-rules && sudo udevadm trigger
   ```
3. Conecte o adaptador e confirme `/dev/ttyUSB0` ou `/dev/ttyACM0` antes de abrir o Dev Container.

> Para todas as plataformas, desconectar e reconectar o adaptador após subir o container resolve a maioria dos casos de _Device or resource busy_.

## Como Usar

### Verificar dispositivos disponíveis no host

```bash
# Linux/macOS
ls -la /dev/ttyUSB* /dev/ttyACM* /dev/ttyS*

# Windows (PowerShell, rodar fora do WSL)
Get-CimInstance Win32_SerialPort | Select-Object Name,DeviceID
```

### Verificar dispositivos dentro do Dev Container

```bash
ls -la /dev/ttyUSB* /dev/ttyACM* /dev/ttyS*
```

### Testar Comunicação Serial

```bash
# Usando minicom
minicom -D /dev/ttyUSB0

# Usando screen
screen /dev/ttyUSB0 9600
```

### No Python

```python
import serial

# Exemplo de conexão
ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1)
ser.write(b'Hello DMX512\n')
response = ser.readline()
ser.close()
```

## Solução de Problemas

### Dispositivo não encontrado

1. Verifique se o dispositivo está conectado ao host
2. Confirme se o dispositivo aparece em `/dev/ttyUSB*`, `/dev/ttyACM*` ou `/dev/ttyS*` no host
3. Reinicie o dev container
4. (Windows) Execute novamente `usbipd attach --wsl --busid <id>`
5. (macOS) Garanta que o `socat` ainda está em execução

### Erro de Permissão

```bash
# Adicionar usuário ao grupo dialout manualmente
sudo usermod -a -G dialout $USER
newgrp dialout
```

### Dispositivo não acessível

```bash
# Verificar permissões
ls -la /dev/ttyUSB0

# Ajustar permissões se necessário
sudo chmod 666 /dev/ttyUSB0
```

## Notas Importantes

- O container precisa ser executado com privilégios e bind de `/dev` (já configurado em `devcontainer.json`).
- Adaptadores diferentes podem expor nomes distintos (ex.: `/dev/ttyUSB1`, `/dev/ttyS4`).
- Para DMX512, utilize **250000 bauds**, 8N2.
- Desconectar/reconectar o dispositivo após subir o container evita travamentos do driver.
- Em Windows/macOS, o acesso depende de serviços externos (`usbipd`, `socat`). Certifique-se de mantê-los ativos.

## Recursos Adicionais

- [Documentação PySerial](https://pyserial.readthedocs.io/)
- [Especificação DMX512](https://en.wikipedia.org/wiki/DMX512)
- [Configuração UDEV](https://wiki.archlinux.org/title/Udev)
