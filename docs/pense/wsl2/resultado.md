A seguir, a documentação em **Markdown** para orientar usuários Windows na instalação e configuração do WSL 2, garantindo um ambiente consistente para uso de Dev Containers no VS Code ou Cursor.

---

## Instalação do WSL 2 no Windows

### 1. Pré-requisitos

1. **Windows 10**, versão 1903 (build 18362) ou superior, ou **Windows 11**.
2. Acesso de **administrador** no sistema.
3. Conexão com a Internet.

---

### 2. Habilitar o Subsistema Linux (WSL)

1. Abra o **PowerShell** como administrador:

   * Clique com o botão direito no menu Iniciar → **Windows PowerShell (Admin)**.

2. Execute o comando para habilitar o recurso WSL e a Plataforma de Máquina Virtual:

   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

3. **Reinicie** o computador para aplicar as alterações.

---

### 3. Definir o WSL 2 como versão padrão

1. Após o reinício, abra o **PowerShell** (não é necessário ser administrador).
2. Defina o WSL 2 como padrão:

   ```powershell
   wsl --set-default-version 2
   ```

---

### 4. Instalar uma distribuição Linux

Você pode escolher sua distribuição preferida (Ubuntu, Debian, Fedora etc.) diretamente da Microsoft Store:

1. Abra a **Microsoft Store**.
2. Busque pela distribuição (ex.: **Ubuntu**).
3. Clique em **Instalar**.
4. Após a instalação, abra o aplicativo da distribuição para concluir a configuração inicial (create user/password).

Caso prefira instalar via linha de comando:

```powershell
wsl --install -d Ubuntu
```

> **Observação:** Se o comando `wsl --install` não for reconhecido, verifique a versão do Windows ou instale via Microsoft Store.

---

### 5. Verificar versão e lista de distribuições

Para listar distribuições e verificar se estão rodando em WSL 2:

```powershell
wsl --list --verbose
```

Saída esperada:

```
  NAME      STATE           VERSION
* Ubuntu    Running         2
  Debian    Stopped         2
```

---

### 6. Atualizar o Kernel do WSL (opcional)

Caso apareça mensagem solicitando atualização do kernel:

1. Acesse [https://aka.ms/wsl2kernel](https://aka.ms/wsl2kernel)
2. Baixe e execute o instalador do kernel Linux.

---

### 7. Configurações adicionais (opcional)

* **Integrar com VS Code**:
  Instale a extensão **Remote – WSL** no VS Code para abrir pastas dentro do Linux diretamente no container.

* **Alocar memória e CPU**:
  Crie (ou edite) o arquivo `%UserProfile%\.wslconfig` com:

  ```ini
  [wsl2]
  memory=4GB
  processors=2
  ```

---

### 8. Teste de funcionamento

No **PowerShell** (ou terminal Linux):

```powershell
wsl uname -r
```

– Deve exibir uma versão de kernel Linux (ex.: `5.x.x-microsoft-standard-WSL2`).

---

**Pronto!** O WSL 2 está instalado e configurado. Agora é possível utilizar Docker em Linux nativo e Dev Containers no VS Code ou Cursor sem dependência de virtualizações adicionais.
