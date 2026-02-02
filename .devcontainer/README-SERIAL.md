# Configuração de Porta Serial no Dev Container

Este dev container foi configurado para dar acesso às portas seriais, permitindo comunicação com dispositivos DMX512 e outros equipamentos via interface serial.

## Configurações Implementadas

### 1. Mapeamento de Dispositivos

O container mapeia os seguintes dispositivos seriais:

- `/dev/ttyUSB0` - Dispositivos USB seriais
- `/dev/ttyACM0` - Dispositivos Arduino/ACM
- `/dev/ttyS0` a `/dev/ttyS3` - Portas seriais padrão

### 2. Permissões e Grupos

- Criação do grupo `dialout`
- Adição do usuário ao grupo `dialout`
- Configuração de permissões 666 para dispositivos seriais
- Adição da capacidade `SYS_RAWIO`

### 3. Ferramentas Instaladas

- `minicom` - Terminal serial
- `screen` - Multiplexador de terminal
- `setserial` - Configuração de portas seriais
- `udev` - Gerenciamento de dispositivos

## Como Usar

### Verificar Dispositivos Disponíveis

```bash
ls -la /dev/tty*
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
2. Confirme se o dispositivo aparece em `/dev/tty*` no host
3. Reinicie o dev container

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

- O container precisa ser executado com privilégios para acessar dispositivos seriais
- Alguns dispositivos podem requerer configurações específicas de baudrate
- Para dispositivos DMX512, geralmente usa-se 250000 bauds
- Recomenda-se desconectar e reconectar o dispositivo após iniciar o container

## Recursos Adicionais

- [Documentação PySerial](https://pyserial.readthedocs.io/)
- [Especificação DMX512](https://en.wikipedia.org/wiki/DMX512)
- [Configuração UDEV](https://wiki.archlinux.org/title/Udev)
