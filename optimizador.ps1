#--------------------------------------------------------------------------------#
#               HERRAMIENTA AVANZADA DE OPTIMIZACIÓN - PowerShell v4.0           #
#     Script modular con telemetría, UI mejorada, logs y cálculo de espacio.     #
#--------------------------------------------------------------------------------#

$LogPath = "$PSScriptRoot\optimizador_log.txt"

# --- FUNCIÓN DE REGISTRO (LOGS) ---
function Write-Log {
    param([string]$Message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $Message" | Out-File -FilePath $LogPath -Append -ErrorAction SilentlyContinue
}

# --- FUNCIÓN DE INTERFAZ: DIBUJAR ENCABEZADOS ---
function Draw-Header {
    param([string]$Title)
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White -BackgroundColor DarkCyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# --- FUNCIÓN 0: VERIFICAR PERMISOS DE ADMINISTRADOR ---
function Check-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Draw-Header "ERROR DE PRIVILEGIOS"
        Write-Host "⚠️ PERMISOS INSUFICIENTES." -ForegroundColor Red
        Write-Host "Este script requiere ser ejecutado como Administrador." -ForegroundColor Yellow
        Write-Host "Haz clic derecho en el archivo -> 'Ejecutar con PowerShell' -> 'Ejecutar como Administrador'." -ForegroundColor Yellow
        Read-Host "`nPresiona Enter para salir..."
        exit
    }
    Write-Log "Inicio de sesión de optimización (Administrador verificado)."
}

#================================================================================#
#                            BLOQUE DE TAREAS DE LIMPIEZA                        #
#================================================================================#

function Clean-SystemFolders {
    param([string[]]$FoldersToClean, [string]$TaskName)
    Write-Host "--- Ejecutando: $TaskName ---" -ForegroundColor Cyan
    $totalFreed = 0

    foreach ($folder in $FoldersToClean) {
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($folder)
        if (Test-Path $expandedPath) {
            Write-Host "Analizando: $expandedPath"
            
            # Calcular espacio antes de borrar
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
            foreach ($p in $paths) {
                Remove-Item -Path "$($p.FullName)\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
            Write-Host "✔️ Caché de $($browser.Key) limpiada." -ForegroundColor Green
            Write-Log "Caché de $($browser.Key) limpiada."
        } else {
            Write-Host "ℹ️ $($browser.Key) no encontrado o ya está limpio." -ForegroundColor DarkGray
        }
    }
}

function Clean-WindowsUpdateCache {
    Write-Host "--- Limpiando Caché Profunda de Windows Update... ---" -ForegroundColor Cyan
    Write-Progress -Activity "Mantenimiento de Windows" -Status "Deteniendo servicios de actualización..." -PercentComplete 20
    
    $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
    foreach ($srv in $services) { Stop-Service -Name $srv -Force -ErrorAction SilentlyContinue }
    
    $paths = @("$env:windir\SoftwareDistribution\Download", "$env:windir\System32\catroot2")
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "Limpiando $path..."
            Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Write-Progress -Activity "Mantenimiento de Windows" -Status "Reiniciando servicios..." -PercentComplete 80
    foreach ($srv in $services) { Start-Service -Name $srv -ErrorAction SilentlyContinue }
    
    Write-Progress -Activity "Mantenimiento de Windows" -Status "Completado" -PercentComplete 100
    Write-Host "✔️ Caché de Windows Update eliminada correctamente." -ForegroundColor Green
    Write-Log "Caché de Windows Update limpiada."
}

function Empty-RecycleBin {
    Write-Host "--- Vaciando Papelera de Reciclaje... ---" -ForegroundColor Cyan
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Host "✔️ Papelera vaciada." -ForegroundColor Green
        Write-Log "Papelera de reciclaje vaciada."
    } catch {
        Write-Host "❌ No se pudo vaciar la Papelera o ya está vacía." -ForegroundColor Yellow
    }
}

#================================================================================#
#                 NUEVAS FUNCIONES: PRIVACIDAD Y RENDIMIENTO                     #
#================================================================================#

function Disable-Telemetry {
    Write-Host "--- Desactivando Telemetría de Windows... ---" -ForegroundColor Cyan
    try {
        Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name "dmwappushservice" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "✔️ Servicios de rastreo y telemetría desactivados." -ForegroundColor Green
        Write-Log "Telemetría (DiagTrack y dmwappushservice) desactivada."
    } catch {
        Write-Host "⚠️ Error al modificar servicios de telemetría." -ForegroundColor Red
    }
}

function Optimize-GamingMode {
    Write-Host "--- Optimizando Red y Sistema para Juegos (Baja Latencia)... ---" -ForegroundColor Cyan
    try {
        # Desactivar limitación de red
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295 -ErrorAction SilentlyContinue
        # Priorizar respuesta del sistema
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -ErrorAction SilentlyContinue
        Write-Host "✔️ Parámetros del registro ajustados para baja latencia." -ForegroundColor Green
        Write-Log "Modo Juego activado (NetworkThrottlingIndex y SystemResponsiveness)."
    } catch {
        Write-Host "❌ Error al modificar el registro." -ForegroundColor Red
    }
}

function Remove-Bloatware {
    Write-Host "--- Eliminando Bloatware Seguro (Apps Preinstaladas)... ---" -ForegroundColor Cyan
    $apps = @("*bing*", "*zune*", "*solitaire*")
    foreach ($app in $apps) {
        Write-Host "Eliminando $app..." -ForegroundColor Gray
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
    Write-Host "✔️ Bloatware básico eliminado." -ForegroundColor Green
    Write-Log "Bloatware eliminado: $apps"
}

#================================================================================#
#                       REPARACIÓN Y UTILIDADES ESTÁNDAR                         #
#================================================================================#

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

function Set-HighPerformancePowerPlan {
    $guid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    powercfg /setactive $guid
    Write-Host "✔️ Plan de energía 'Alto Rendimiento' establecido." -ForegroundColor Green
    Write-Log "Plan de energía cambiado a Alto Rendimiento."
}

function Create-SystemRestorePoint {
    Write-Host "--- Creando Punto de Restauración... ---" -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Optimizador Jaccstudios" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "✔️ Punto de Restauración creado con éxito." -ForegroundColor Green
        Write-Log "Punto de restauración creado."
    } catch {
        Write-Host "❌ Error: Es posible que la restauración del sistema esté desactivada o se haya creado uno recientemente." -ForegroundColor Red
    }
}

function Show-SystemInfo {
    Write-Host "--- Información General ---" -ForegroundColor Cyan
    Get-ComputerInfo | Select-Object OsName, CsProcessors | Format-List
    Write-Host "--- Uso de Espacio en Disco ---" -ForegroundColor Cyan
    Get-PSDrive -PSProvider FileSystem | Format-Table Name, @{Name="Usado (GB)"; Expression={[math]::Round($_.Used / 1GB, 2)}}, @{Name="Libre (GB)"; Expression={[math]::Round($_.Free / 1GB, 2)}} -AutoSize
}

#================================================================================#
#                                SISTEMA DE MENÚS                                #
#================================================================================#

function Pause-And-Continue {
    Write-Host "`n"
    Read-Host "Presiona Enter para continuar..."
}

Check-Administrator

do {
    Draw-Header "MENÚ PRINCIPAL - OPTIMIZADOR"
    Write-Host "[1] Limpieza de Basura y Caché"
    Write-Host "[2] Reparación del Sistema (SFC/DISM)"
    Write-Host "[3] Rendimiento y Privacidad (NUEVO)"
    Write-Host "[4] Utilidades y Seguridad"
    Write-Host "[5] Información del Sistema"
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "[Q] Salir" -ForegroundColor Red
    Write-Host ""
    
    $mainChoice = Read-Host "Selecciona una opción"
    $mainChoice = $mainChoice.ToUpper()

    switch ($mainChoice) {
        '1' { 
            do {
                Draw-Header "MENÚ DE LIMPIEZA"
                Write-Host "[1] Limpiar Temporales del Sistema"
                Write-Host "[2] Limpiar Caché de Todos los Navegadores"
                Write-Host "[3] Limpieza Profunda de Windows Update"
                Write-Host "[4] Vaciar Papelera de Reciclaje"
                Write-Host "[A] EJECUTAR TODA LA LIMPIEZA" -ForegroundColor Cyan
                Write-Host "[B] Volver al Menú Principal" -ForegroundColor Red
                
                $choice = (Read-Host "`nOpción").ToUpper()
                Write-Host ""
                switch ($choice) {
                    '1' { Clean-SystemFolders -FoldersToClean @("%temp%", "C:\Windows\Temp", "C:\Windows\Prefetch") -TaskName "Archivos Temporales y Prefetch" }
                    '2' { Clean-BrowserCache }
                    '3' { Clean-WindowsUpdateCache }
                    '4' { Empty-RecycleBin }
                    'A' {
                        Clean-SystemFolders -FoldersToClean @("%temp%", "C:\Windows\Temp", "C:\Windows\Prefetch") -TaskName "Temporales y Prefetch"
                        Clean-BrowserCache
                        Clean-WindowsUpdateCache
                        Empty-RecycleBin
                    }
                }
                if ($choice -ne 'B') { Pause-And-Continue }
            } while ($choice -ne 'B')
        }
        '2' { 
            do {
                Draw-Header "REPARACIÓN DEL SISTEMA"
                Write-Host "[1] Ejecutar SFC (Reparar Archivos Corruptos)"
                Write-Host "[2] Ejecutar DISM (Reparar Imagen Base)"
                Write-Host "[B] Volver" -ForegroundColor Red
                
                $choice = (Read-Host "`nOpción").ToUpper()
                Write-Host ""
                switch ($choice) { '1' { Run-SFC }; '2' { Run-DISM } }
                if ($choice -ne 'B') { Pause-And-Continue }
            } while ($choice -ne 'B')
        }
        '3' { 
            do {
                Draw-Header "RENDIMIENTO Y PRIVACIDAD"
                Write-Host "[1] Activar Plan de Energía 'Alto Rendimiento'"
                Write-Host "[2] Desactivar Telemetría y Rastreo de Windows"
                Write-Host "[3] Modo Juego: Optimizar Latencia de Red"
                Write-Host "[4] Eliminar Bloatware Básico"
                Write-Host "[B] Volver" -ForegroundColor Red
                
                $choice = (Read-Host "`nOpción").ToUpper()
                Write-Host ""
                switch ($choice) { 
                    '1' { Set-HighPerformancePowerPlan }
                    '2' { Disable-Telemetry }
                    '3' { Optimize-GamingMode }
                    '4' { Remove-Bloatware }
                }
                if ($choice -ne 'B') { Pause-And-Continue }
            } while ($choice -ne 'B')
        }
        '4' {
             do {
                Draw-Header "UTILIDADES Y SEGURIDAD"
                Write-Host "[1] Crear Punto de Restauración"
                Write-Host "[2] Limpiar Caché DNS y Reiniciar Winsock"
                Write-Host "[B] Volver" -ForegroundColor Red
                
                $choice = (Read-Host "`nOpción").ToUpper()
                Write-Host ""
                switch ($choice) { 
                    '1' { Create-SystemRestorePoint }
                    '2' { 
                        ipconfig /flushdns
                        netsh winsock reset
                        Write-Host "✔️ Red reiniciada. Se recomienda reiniciar el equipo." -ForegroundColor Green
                    }
                }
                if ($choice -ne 'B') { Pause-And-Continue }
            } while ($choice -ne 'B')
        }
        '5' {
            Draw-Header "INFORMACIÓN DEL SISTEMA"
            Show-SystemInfo
            Pause-And-Continue
        }
        'Q' { 
            Write-Host "`nSaliendo del optimizador... ¡Hasta pronto!" -ForegroundColor Cyan 
            Write-Log "Cierre de la herramienta."
        }
    }
} while ($mainChoice -ne 'Q')
