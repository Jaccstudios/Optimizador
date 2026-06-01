#--------------------------------------------------------------------------------#
#               HERRAMIENTA AVANZADA DE OPTIMIZACIÓN - INTERACTIVA               #
#     Ejecución Fileless (En memoria) | Navegación por teclado (TUI)             #
#--------------------------------------------------------------------------------#

# --- 1. CONFIGURACIÓN PARA EJECUCIÓN EN MEMORIA ---
$LogPath = "$env:TEMP\optimizador_log.txt"

function Write-Log {
    param([string]$Message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $Message" | Out-File -FilePath $LogPath -Append -ErrorAction SilentlyContinue
}

function Check-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Clear-Host
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host "  ERROR: PERMISOS INSUFICIENTES" -ForegroundColor White -BackgroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host "`nAl usar la ejecución en memoria (irm | iex), tu terminal debe tener privilegios de Administrador." -ForegroundColor Yellow
        Write-Host "Asegúrate de haber abierto PowerShell como Administrador o de iniciar sesión SSH con una cuenta elevada." -ForegroundColor Yellow
        exit
    }
    Write-Log "Inicio de sesión de optimización (Administrador verificado)."
}

# --- 2. MOTOR DE INTERFAZ GRÁFICA DE TERMINAL (TUI) ---
function Show-InteractiveMenu {
    param(
        [string]$Title,
        [string[]]$Options
    )
    $selected = 0
    [Console]::CursorVisible = $false

    while ($true) {
        Clear-Host
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  $Title" -ForegroundColor White -BackgroundColor DarkCyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $selected) {
                Write-Host "  > $($Options[$i]) " -BackgroundColor DarkCyan -ForegroundColor White
            } else {
                Write-Host "    $($Options[$i]) " -ForegroundColor Gray
            }
        }
        
        Write-Host "`n------------------------------------------------------------" -ForegroundColor DarkCyan
        Write-Host " Usa las flechas [Arriba/Abajo] y presiona [Enter]" -ForegroundColor DarkGray

        $key = [Console]::ReadKey($true).Key

        if ($key -eq 'UpArrow') { $selected = [Math]::Max(0, $selected - 1) }
        elseif ($key -eq 'DownArrow') { $selected = [Math]::Min($Options.Count - 1, $selected + 1) }
        elseif ($key -eq 'Enter') { 
            [Console]::CursorVisible = $true 
            Clear-Host
            return $selected 
        }
    }
}

function Pause-And-Continue {
    Write-Host "`nPresiona cualquier tecla para volver al menú..." -ForegroundColor DarkGray
    $null = [Console]::ReadKey($true)
}

# --- 3. MÓDULOS DE TAREAS (LIMPIEZA, REPARACIÓN, RENDIMIENTO) ---

# Limpieza
function Clean-SystemFolders {
    param([string[]]$FoldersToClean, [string]$TaskName)
    Write-Host "--- Ejecutando: $TaskName ---" -ForegroundColor Cyan
    $totalFreed = 0

    foreach ($folder in $FoldersToClean) {
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($folder)
        if (Test-Path $expandedPath) {
            Write-Host "Analizando: $expandedPath"
            $sizeBefore = (Get-ChildItem -Path $expandedPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path "$expandedPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            if ($sizeBefore -gt 0) { $totalFreed += $sizeBefore }
        }
    }
    $mbFreed = [math]::Round($totalFreed / 1MB, 2)
    Write-Host "✔️ Tarea completada. Espacio liberado: $mbFreed MB" -ForegroundColor Green
    Write-Log "$TaskName completado. Liberados $mbFreed MB."
}

function Clean-BrowserCache {
    Write-Host "--- Limpiando Caché de Navegadores (Multi-perfil)... ---" -ForegroundColor Cyan
    $browserPaths = @{
        "Google Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Cache"
        "Microsoft Edge" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\Cache"
        "Brave" = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\*\Cache"
    }
    
    foreach ($browser in $browserPaths.GetEnumerator()) {
        Write-Host "Buscando perfiles de $($browser.Key)..." -ForegroundColor Gray
        $paths = Get-Item -Path $browser.Value -ErrorAction SilentlyContinue
        
        if ($paths) {
            foreach ($p in $paths) { Remove-Item -Path "$($p.FullName)\*" -Recurse -Force -ErrorAction SilentlyContinue }
            Write-Host "✔️ Caché de $($browser.Key) limpiada." -ForegroundColor Green
            Write-Log "Caché de $($browser.Key) limpiada."
        }
    }
}

function Clean-WindowsUpdateCache {
    Write-Host "--- Limpiando Caché Profunda de Windows Update... ---" -ForegroundColor Cyan
    $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
    foreach ($srv in $services) { Stop-Service -Name $srv -Force -ErrorAction SilentlyContinue }
    
    $paths = @("$env:windir\SoftwareDistribution\Download", "$env:windir\System32\catroot2")
    foreach ($path in $paths) {
        if (Test-Path $path) { Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    
    foreach ($srv in $services) { Start-Service -Name $srv -ErrorAction SilentlyContinue }
    Write-Host "✔️ Caché de Windows Update eliminada correctamente." -ForegroundColor Green
    Write-Log "Caché de Windows Update limpiada."
}

function Empty-RecycleBin {
    Write-Host "--- Vaciando Papelera de Reciclaje... ---" -ForegroundColor Cyan
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Host "✔️ Papelera vaciada." -ForegroundColor Green
        Write-Log "Papelera vaciada."
    } catch { Write-Host "ℹ️ La Papelera ya estaba vacía." -ForegroundColor Gray }
}

# Reparación
function Run-SFC {
    Write-Host "--- Ejecutando Comprobador de Archivos (SFC)... ---" -ForegroundColor Cyan
    Write-Host "⏳ Esto puede tardar varios minutos..." -ForegroundColor Yellow
    sfc.exe /scannow
    Write-Log "Ejecutado sfc /scannow."
}

function Run-DISM {
    Write-Host "--- Ejecutando Reparación de Imagen (DISM)... ---" -ForegroundColor Cyan
    Write-Host "⏳ Requiere internet y paciencia..." -ForegroundColor Yellow
    Dism.exe /Online /Cleanup-Image /RestoreHealth
    Write-Log "Ejecutado DISM RestoreHealth."
}

# Rendimiento y Privacidad
function Disable-Telemetry {
    Write-Host "--- Desactivando Telemetría de Windows... ---" -ForegroundColor Cyan
    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name "dmwappushservice" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "✔️ Servicios de rastreo y telemetría desactivados." -ForegroundColor Green
    Write-Log "Telemetría desactivada."
}

function Optimize-GamingMode {
    Write-Host "--- Optimizando Red y Sistema para Juegos (Baja Latencia)... ---" -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -ErrorAction SilentlyContinue
    Write-Host "✔️ Parámetros del registro ajustados para baja latencia." -ForegroundColor Green
    Write-Log "Modo Juego activado."
}

function Remove-Bloatware {
    Write-Host "--- Eliminando Bloatware Seguro... ---" -ForegroundColor Cyan
    $apps = @("*bing*", "*zune*", "*solitaire*")
    foreach ($app in $apps) { Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue }
    Write-Host "✔️ Bloatware básico eliminado." -ForegroundColor Green
    Write-Log "Bloatware eliminado."
}

# Utilidades e Info
function Create-SystemRestorePoint {
    Write-Host "--- Creando Punto de Restauración... ---" -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Optimizador Jaccstudios" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "✔️ Punto de Restauración creado con éxito." -ForegroundColor Green
        Write-Log "Punto de restauración creado."
    } catch { Write-Host "❌ Error: Restauración desactivada o creada recientemente." -ForegroundColor Red }
}

function Show-SystemInfo {
    Write-Host "--- Información General ---" -ForegroundColor Cyan
    Get-ComputerInfo | Select-Object OsName, CsProcessors | Format-List
    Write-Host "--- Uso de Espacio en Disco ---" -ForegroundColor Cyan
    Get-PSDrive -PSProvider FileSystem | Format-Table Name, @{Name="Usado (GB)"; Expression={[math]::Round($_.Used / 1GB, 2)}}, @{Name="Libre (GB)"; Expression={[math]::Round($_.Free / 1GB, 2)}} -AutoSize
}

# --- 4. FLUJO PRINCIPAL Y NAVEGACIÓN ---

Check-Administrator

$mainOptions = @(
    "Limpieza de Basura y Caché",
    "Reparación del Sistema (SFC/DISM)",
    "Rendimiento y Privacidad (Bloatware/Telemetría)",
    "Utilidades y Seguridad de Red",
    "Información del Sistema",
    "Salir"
)

do {
    $mainChoice = Show-InteractiveMenu -Title "MENÚ PRINCIPAL - OPTIMIZADOR JACCSTUDIOS" -Options $mainOptions

    switch ($mainChoice) {
        0 { # Limpieza
            $cleanOpts = @("Temporales del Sistema", "Caché de Navegadores", "Windows Update", "Vaciar Papelera", "Ejecutar TODO", "Volver")
            do {
                $cChoice = Show-InteractiveMenu -Title "MENÚ DE LIMPIEZA" -Options $cleanOpts
                switch ($cChoice) {
                    0 { Clean-SystemFolders -FoldersToClean @("%temp%", "C:\Windows\Temp", "C:\Windows\Prefetch") -TaskName "Temporales y Prefetch"; Pause-And-Continue }
                    1 { Clean-BrowserCache; Pause-And-Continue }
                    2 { Clean-WindowsUpdateCache; Pause-And-Continue }
                    3 { Empty-RecycleBin; Pause-And-Continue }
                    4 { 
                        Clean-SystemFolders -FoldersToClean @("%temp%", "C:\Windows\Temp", "C:\Windows\Prefetch") -TaskName "Temporales"
                        Clean-BrowserCache
                        Clean-WindowsUpdateCache
                        Empty-RecycleBin
                        Pause-And-Continue
                    }
                }
            } while ($cChoice -ne 5)
        }
        1 { # Reparación
            $repOpts = @("Ejecutar SFC (Archivos Corruptos)", "Ejecutar DISM (Imagen Base)", "Volver")
            do {
                $rChoice = Show-InteractiveMenu -Title "REPARACIÓN DEL SISTEMA" -Options $repOpts
                switch ($rChoice) {
                    0 { Run-SFC; Pause-And-Continue }
                    1 { Run-DISM; Pause-And-Continue }
                }
            } while ($rChoice -ne 2)
        }
        2 { # Rendimiento
            $perfOpts = @("Activar Plan 'Alto Rendimiento'", "Desactivar Telemetría", "Modo Juego (Baja Latencia)", "Eliminar Bloatware Básico", "Volver")
            do {
                $pChoice = Show-InteractiveMenu -Title "RENDIMIENTO Y PRIVACIDAD" -Options $perfOpts
                switch ($pChoice) {
                    0 { powercfg /setactive "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"; Write-Host "✔️ Alto rendimiento activado." -ForegroundColor Green; Pause-And-Continue }
                    1 { Disable-Telemetry; Pause-And-Continue }
                    2 { Optimize-GamingMode; Pause-And-Continue }
                    3 { Remove-Bloatware; Pause-And-Continue }
                }
            } while ($pChoice -ne 4)
        }
        3 { # Utilidades
            $utilOpts = @("Crear Punto de Restauración", "Limpiar Caché DNS y Winsock", "Volver")
            do {
                $uChoice = Show-InteractiveMenu -Title "UTILIDADES DE RED Y SEGURIDAD" -Options $utilOpts
                switch ($uChoice) {
                    0 { Create-SystemRestorePoint; Pause-And-Continue }
                    1 { ipconfig /flushdns; netsh winsock reset; Write-Host "✔️ Red reiniciada." -ForegroundColor Green; Pause-And-Continue }
                }
            } while ($uChoice -ne 2)
        }
        4 { Show-SystemInfo; Pause-And-Continue }
        5 { 
            Write-Host "Saliendo del optimizador... ¡Hasta pronto!" -ForegroundColor Cyan
            [Console]::CursorVisible = $true
            exit 
        }
    }
} while ($true)
