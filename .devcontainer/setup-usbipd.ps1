[CmdletBinding()]
param(
    [string]$Distribution = "Ubuntu"
)

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Reabrindo o script com privilégios de administrador..." -ForegroundColor Yellow
    $arguments = @("-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
    if ($Distribution) { $arguments += @("-Distribution", $Distribution) }
    Start-Process powershell -ArgumentList $arguments -Verb RunAs
    exit
}

$script:WingetPath = $null
$script:UsbipdPath = $null
$script:UsbPcapRemoved = $false

function Ensure-UsbipdCommand {
    if ($script:UsbipdPath -and (Test-Path $script:UsbipdPath)) {
        if (-not (Get-Command usbipd -ErrorAction SilentlyContinue)) {
            Set-Alias -Name usbipd -Value $script:UsbipdPath -Scope Script
        }
        return $script:UsbipdPath
    }

    $existing = Get-Command usbipd -ErrorAction SilentlyContinue
    if ($existing) {
        $script:UsbipdPath = $existing.Source
        return $script:UsbipdPath
    }

    $candidates = @()
    if ($env:ProgramFiles) {
        $candidates += Join-Path $env:ProgramFiles "usbipd-win\usbipd.exe"
    }
    $pf86 = ${env:ProgramFiles(x86)}
    if ($pf86) {
        $candidates += Join-Path $pf86 "usbipd-win\usbipd.exe"
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            $script:UsbipdPath = $candidate
            Set-Alias -Name usbipd -Value $candidate -Scope Script
            Write-Host "usbipd encontrado em $candidate" -ForegroundColor Green
            return $script:UsbipdPath
        }
    }

    return $null
}

function Resolve-Distribution {
    param([string]$Distribution)

    if ($Distribution) {
        Write-Host "Usando distribuição informada: $Distribution" -ForegroundColor Cyan
        return $Distribution
    }

    Write-Host "Detectando distribuição WSL padrão..." -ForegroundColor Yellow
    try {
        $names = @()
        $default = $null
        $list = wsl.exe -l
        foreach ($line in $list) {
            $trimmed = $line.Trim()
            if (-not $trimmed -or $trimmed -like "Windows Subsystem*") { continue }

            if ($trimmed -like "*(Default)") {
                $default = ($trimmed -replace " \(Default\)$", "")
            }
            $names += ($trimmed -replace " \(Default\)$", "")
        }

        if ($default) {
            Write-Host "Distribuição padrão detectada: $default" -ForegroundColor Green
            return $default
        }

        if ($names.Count -gt 0) {
            Write-Host "Nenhuma distribuição em execução detectada; usando ${names[0]}" -ForegroundColor Yellow
            return $names[0]
        }
    } catch {
        Write-Host "Falha ao detectar distribuição automaticamente: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "Mantendo valor padrão 'Ubuntu'." -ForegroundColor Yellow
    return "Ubuntu"
}

function Uninstall-UsbPcap {
    if ($script:UsbPcapRemoved) {
        return $true
    }

    Write-Host "Removendo USBPcap automaticamente devido à incompatibilidade..." -ForegroundColor Yellow

    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    $targets = @()
    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            $targets += Get-ChildItem $path | Where-Object {
                ($_.GetValue('DisplayName') -like '*USBPcap*')
            }
        }
    }

    if (-not $targets -or $targets.Count -eq 0) {
        Write-Host "USBPcap não encontrado; prosseguindo." -ForegroundColor DarkYellow
        return $false
    }

    foreach ($entry in $targets) {
        $display = $entry.GetValue('DisplayName')
        $productCode = $entry.PSChildName
        if ($productCode -match '^\{.+\}$') {
            $args = "/x $productCode /quiet /norestart"
            Write-Host "Executando msiexec para remover $display ($productCode)..." -ForegroundColor Yellow
            $proc = Start-Process -FilePath msiexec.exe -ArgumentList $args -PassThru -Wait -NoNewWindow
            if ($proc.ExitCode -eq 0) {
                Write-Host "$display removido." -ForegroundColor Green
                $script:UsbPcapRemoved = $true
            } else {
                Write-Warning "Falha ao remover $display (código $($proc.ExitCode))."
            }
        } else {
            $uninstallString = $entry.GetValue('UninstallString')
            if ($uninstallString) {
                Write-Host "Executando comando de remoção para $display..." -ForegroundColor Yellow
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c $uninstallString /quiet /norestart" -Wait -NoNewWindow
                $script:UsbPcapRemoved = $true
            }
        }
    }

    if ($script:UsbPcapRemoved) {
        Write-Host "USBPcap removido. Desconecte e reconecte o adaptador USB para continuar." -ForegroundColor Green
    }

    return $script:UsbPcapRemoved
}

function Handle-UsbPcapWarning {
    param([string]$Output)

    if ($script:UsbPcapRemoved) {
        return
    }

    if ($Output -match "USB filter 'USBPcap'") {
        $removed = Uninstall-UsbPcap
        if ($removed) {
            Write-Host "Reexecutando usbipd após remover USBPcap..." -ForegroundColor Yellow
        }
    }
}

function Get-UsbipdVersion {
    $cmd = Ensure-UsbipdCommand
    if (-not $cmd) { return $null }

    try {
        & $cmd --version
    } catch {
        return $null
    }
}

function Ensure-Winget {
    $existing = Get-Command winget -ErrorAction SilentlyContinue
    if ($existing) {
        $script:WingetPath = $existing.Source
        Write-Host "winget já instalado." -ForegroundColor Green
        return
    }

    $wingetExe = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\winget.exe"
    if (Test-Path $wingetExe) {
        Set-Alias -Name winget -Value $wingetExe -Scope Script
        $script:WingetPath = $wingetExe
        Write-Host "winget disponível via $wingetExe" -ForegroundColor Green
        return
    }

    Write-Host "winget não encontrado. Instalando App Installer (winget)..." -ForegroundColor Yellow
    $tempPath = Join-Path $env:TEMP "AppInstaller.msixbundle"
    $wingetUri = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    try {
        Invoke-WebRequest -Uri $wingetUri -OutFile $tempPath -UseBasicParsing
    } catch {
        throw "Falha ao baixar App Installer: $($_.Exception.Message)"
    }

    try {
        Add-AppxPackage -Path $tempPath
        Write-Host "winget instalado com sucesso." -ForegroundColor Green
    } catch {
        if ($_.Exception.HResult -eq 0x80073D02) {
            throw "Feche o aplicativo 'App Installer' e execute novamente o script."
        }
        throw "Falha ao instalar App Installer: $($_.Exception.Message)"
    } finally {
        if (Test-Path $tempPath) { Remove-Item $tempPath -Force }
    }

    Start-Sleep -Seconds 3

    $existing = Get-Command winget -ErrorAction SilentlyContinue
    if ($existing) {
        $script:WingetPath = $existing.Source
        return
    }

    $wingetExe = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\winget.exe"
    if (Test-Path $wingetExe) {
        Set-Alias -Name winget -Value $wingetExe -Scope Script
        $script:WingetPath = $wingetExe
        Write-Host "winget disponível via $wingetExe" -ForegroundColor Green
    } else {
        throw "winget instalado, mas ainda não disponível. Feche o PowerShell e execute o script novamente."
    }
}

function Install-UsbipdWin {
    Write-Host "Verificando usbipd-win..."
    $usbipdVersion = Get-UsbipdVersion

    if ($usbipdVersion) {
        Write-Host "usbipd-win já instalado: $usbipdVersion" -ForegroundColor Green
        return
    }

    Write-Host "Instalando usbipd-win via winget..." -ForegroundColor Yellow
    $wingetExe = $script:WingetPath
    if (-not $wingetExe) {
        throw "winget não está acessível nesta sessão."
    }

    $installArgs = @(
        "install",
        "usbipd",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--silent"
    )

    $process = Start-Process -FilePath $wingetExe -ArgumentList $installArgs -NoNewWindow -PassThru -Wait

    Start-Sleep -Seconds 2
    $usbipdVersion = Get-UsbipdVersion

    if ($usbipdVersion) {
        Write-Host "usbipd-win disponível: $usbipdVersion" -ForegroundColor Green
        return
    }

    $alreadyInstalledCodes = @(-1978335189, -1978335212)
    if ($alreadyInstalledCodes -contains $process.ExitCode) {
        Write-Host "usbipd-win já estava instalado nas origens configuradas." -ForegroundColor Yellow
        return
    }

    throw "Não foi possível instalar usbipd-win via winget (código $($process.ExitCode))."
}

function Get-UsbipdDevices {
    $cmd = Ensure-UsbipdCommand
    if (-not $cmd) {
        throw "usbipd não encontrado após a instalação. Reabra o PowerShell e execute novamente."
    }

    $raw = & $cmd list 2>&1
    $text = ($raw | Out-String)
    Handle-UsbPcapWarning -Output $text
    if ($script:UsbPcapRemoved) {
        $raw = & $cmd list 2>&1
    }

    $devices = @()

    foreach ($line in $raw) {
        if ($line -match '^(?<busid>\d+-\d+)\s+(?<vidpid>[0-9A-Fa-f]{4}:[0-9A-Fa-f]{4})\s+(?<device>.+?)(?<state>Attached|Not attached|Disabled|Shared)?\s*$') {
            $devices += [pscustomobject]@{
                BusId = $matches['busid']
                VidPid = $matches['vidpid']
                Device = ($matches['device'].Trim())
                State  = ($matches['state'] -replace '\s+', ' ').Trim()
            }
        }
    }

    return $devices
}

function Prompt-DeviceSelection($devices) {
    if (-not $devices -or $devices.Count -eq 0) {
        throw "Nenhum dispositivo USB compatível encontrado."
    }

    if ($devices.Count -eq 1) {
        Write-Host "Encontrado apenas um dispositivo: $($devices[0].Device) ($($devices[0].BusId))." -ForegroundColor Cyan
        return $devices[0]
    }

    Write-Host "Selecione o dispositivo que deseja compartilhar:" -ForegroundColor Cyan
    $index = 1
    $devices | ForEach-Object {
        Write-Host "[$index] BUSID=$($_.BusId) VID:PID=$($_.VidPid) DEVICE=$($_.Device) STATE=$($_.State)"
        $index++
    }

    while ($true) {
        $choice = Read-Host "Digite o número ou BUSID desejado"
        if ([int]::TryParse($choice, [ref]$null)) {
            $choiceIndex = [int]$choice
            if ($choiceIndex -ge 1 -and $choiceIndex -le $devices.Count) {
                return $devices[$choiceIndex - 1]
            }
        } elseif ($devices.BusId -contains $choice) {
            return ($devices | Where-Object { $_.BusId -eq $choice })
        }
        Write-Host "Entrada inválida. Tente novamente." -ForegroundColor Yellow
    }
}

function Share-UsbDevice {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Device,
        [string]$Distribution
    )

    $cmd = Ensure-UsbipdCommand
    if (-not $cmd) {
        throw "usbipd não encontrado após a instalação. Reabra o PowerShell e execute novamente."
    }

    Write-Host "Preparando dispositivo $($Device.BusId) - $($Device.Device)" -ForegroundColor Cyan

    Write-Host "Garantindo que o dispositivo não esteja anexado em outra sessão..." -ForegroundColor Yellow
    $null = & $cmd detach --busid $Device.BusId 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dispositivo desanexado do WSL/VM anterior." -ForegroundColor DarkGreen
    } else {
        Write-Host "Detach retornou código $LASTEXITCODE (ignorado se já estava livre)." -ForegroundColor DarkYellow
    }

    $null = & $cmd unbind --busid $Device.BusId 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Bind anterior removido." -ForegroundColor DarkGreen
    } else {
        Write-Host "Unbind retornou código $LASTEXITCODE (ignorado se já estava livre)." -ForegroundColor DarkYellow
    }

    Write-Host "Executando usbipd bind..."
    & $cmd bind --busid $Device.BusId | Out-Null

    Write-Host "Verificando se a distribuição WSL '$Distribution' está em execução..." -ForegroundColor Yellow
    $wslStatus = wsl.exe -l --running 2>&1 | Out-String
    if ($wslStatus -notmatch [regex]::Escape($Distribution)) {
        Write-Host "Iniciando distribuição WSL '$Distribution'..." -ForegroundColor Yellow
        wsl.exe -d $Distribution -- echo "WSL iniciado" 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
    Write-Host "Distribuição WSL '$Distribution' em execução." -ForegroundColor Green

    Write-Host "Compartilhando com WSL ($Distribution)..."
    $attachArgs = @("attach", "--busid", $Device.BusId)
    if ($Distribution) {
        $attachArgs += @("--wsl", $Distribution)
    } else {
        $attachArgs += @("--wsl")
    }

    $output = & $cmd @attachArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        $outputText = ($output | Out-String).Trim()
        throw "Falha ao anexar o dispositivo (código $LASTEXITCODE).`nDetalhes: $outputText"
    }

    Write-Host "Dispositivo anexado com sucesso!" -ForegroundColor Green
}

try {
    Ensure-Winget
    Install-UsbipdWin

    $devices = Get-UsbipdDevices
    $selected = Prompt-DeviceSelection -devices $devices
    Share-UsbDevice -Device $selected -Distribution $Distribution

    Write-Host "Agora você pode verificar a porta dentro do WSL com 'ls -l /dev/ttyUSB*'." -ForegroundColor Green
} catch {
    Write-Error $_
    exit 1
}
