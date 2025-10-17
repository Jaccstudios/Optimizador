#--------------------------------------------------------------------------------#
#               HERRAMIENTA AVANZADA DE OPTIMIZACIÓN - PowerShell v4.0           #
#            Versión con interfaz de usuario mejorada sin "Enter".             #
#--------------------------------------------------------------------------------#

# --- FUNCIÓN 0: VERIFICAR PERMISOS DE ADMINISTRADOR ---
function Check-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "------------------------------------------------------------" -ForegroundColor Red
        Write-Host "ERROR: PERMISOS INSUFICIENTES." -ForegroundColor Yellow
        Write-Host "Este script requiere ser ejecutado como Administrador." -ForegroundColor Yellow
        Write-Host "Haz clic derecho en el archivo -> 'Ejecutar como Administrador'." -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------" -ForegroundColor Red
        Read-Host "Presiona Enter para salir..."
        exit
    }
}

#================================================================================#
#                           BLOQUE DE FUNCIONES DE TAREAS                        #
#          (Toda la lógica de limpieza, reparación, etc. no cambia)             #
#================================================================================#

# --- Limpieza: Carpetas del Sistema ---
function Clean-SystemFolders {
    param([string[]]$FoldersToClean, [string]$TaskName)
    Write-Host "`n--- Ejecutando: $TaskName ---" -ForegroundColor Cyan
    foreach ($folder in $FoldersToClean) {
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($folder)
        if (Test-Path $expandedPath) {
            Write-Host "Limpiando: $expandedPath"
            Remove-Item -Path "$expandedPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✔️ Limpieza completada." -ForegroundColor Green
        } else {
            Write-Host "⚠️ No se encontró: $expandedPath" -ForegroundColor Yellow
        }
    }
}

# --- Limpieza: Caché de Navegadores ---
function Clean-BrowserCache {
    Write-Host "`n--- Limpiando Caché de Navegadores... ---" -ForegroundColor Cyan
    $browserPaths = @{
        "Google Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        "Microsoft Edge" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        "Mozilla Firefox" = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*.default-release\cache2"
    }
    foreach ($browser in $browserPaths.GetEnumerator()) {
        $path = $browser.Value
        if ($browser.Key -eq "Mozilla Firefox") {
            try { $path = (Get-Item $path).FullName } catch { $path = $null }
        }
        if ($path -and (Test-Path $path)) {
            Write-Host "Limpiando $($browser.Key)..."
            Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✔️ Caché de $($browser.Key) limpiada." -ForegroundColor Green
        } else {
            Write-Host "ℹ️ $($browser.Key) no parece estar instalado." -ForegroundColor Gray
        }
    }
}

# --- Limpieza: Caché de Windows Update ---
function Clean-WindowsUpdateCache {
    Write-Host "`n--- Limpiando Caché de Windows Update... ---" -ForegroundColor Cyan
    Write-Host "Deteniendo servicios..." -ForegroundColor Yellow
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
    $path = "$env:windir\SoftwareDistribution"
    if (Test-Path $path) {
        Write-Host "Eliminando archivos de $path..."
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✔️ Caché eliminada." -ForegroundColor Green
    }
    Write-Host "Reiniciando servicios..." -ForegroundColor Yellow
    Start-Service -Name wuauserv
    Start-Service -Name bits
}

# --- Limpieza: Papelera de Reciclaje ---
function Empty-RecycleBin {
    Write-Host "`n--- Vaciando Papelera de Reciclaje... ---" -ForegroundColor Cyan
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Host "✔️ Papelera vaciada." -ForegroundColor Green
    } catch {
        Write-Host "❌ No se pudo vaciar la Papelera." -ForegroundColor Red
    }
}

# --- Reparación: SFC y DISM ---
function Run-SFC {
    Write-Host "`n--- Ejecutando Comprobador de Archivos (SFC)... ---" -ForegroundColor Cyan
    Write-Host "Esto puede tardar varios minutos..." -ForegroundColor Yellow
    sfc.exe /scannow
    Write-Host "✔️ Proceso SFC finalizado." -ForegroundColor Green
}
function Run-DISM {
    Write-Host "`n--- Ejecutando Reparación de Imagen (DISM)... ---" -ForegroundColor Cyan
    Write-Host "Esto puede tardar bastante tiempo y requiere internet..." -ForegroundColor Yellow
    Dism.exe /Online /Cleanup-Image /RestoreHealth
    Write-Host "✔️ Proceso DISM finalizado." -ForegroundColor Green
}

# --- Red: DNS y Winsock ---
function Flush-DNS {
    Write-Host "`n--- Limpiando Caché DNS... ---" -ForegroundColor Cyan
    ipconfig.exe /flushdns
    Write-Host "✔️ Caché DNS limpiada." -ForegroundColor Green
}
function Reset-Winsock {
    Write-Host "`n--- Reiniciando Catálogo Winsock... ---" -ForegroundColor Cyan
    netsh.exe winsock reset
    Write-Host "✔️ Winsock reiniciado. Se recomienda reiniciar el equipo." -ForegroundColor Green
}

# --- Optimización: Plan de Energía y Unidades ---
function Set-HighPerformancePowerPlan {
    $highPerformanceGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    Write-Host "`n--- Activando plan de energía 'Alto Rendimiento'... ---" -ForegroundColor Cyan
    powercfg /setactive $highPerformanceGuid
    Write-Host "✔️ Plan de energía establecido." -ForegroundColor Green
}
function Optimize-Drives {
    Write-Host "`n--- Optimizando todas las unidades (HDD/SSD)... ---" -ForegroundColor Cyan
    Write-Host "Este proceso puede tardar." -ForegroundColor Yellow
    Optimize-Volume -DriveLetter (Get-Volume).DriveLetter -Verbose
    Write-Host "✔️ Optimización completada." -ForegroundColor Green
}

# --- Utilidades: Punto de Restauración y Apps ---
function Create-SystemRestorePoint {
    Write-Host "`n--- Creando Punto de Restauración... ---" -ForegroundColor Cyan
    Checkpoint-Computer -Description "Punto creado por Herramienta de Optimización" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "✔️ Punto de Restauración creado." -ForegroundColor Green
}
function Reregister-StoreApps {
    Write-Host "`n--- Re-registrando Apps de la Tienda de Windows... ---" -ForegroundColor Cyan
    Write-Host "Este proceso puede tardar y mostrará muchos mensajes..." -ForegroundColor Yellow
    Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -Verbose}
    Write-Host "✔️ Tarea completada." -ForegroundColor Green
}

# --- Información: Sistema, Disco y Memoria ---
function Show-SystemInfo {
    Write-Host "`n--- Información del Sistema ---" -ForegroundColor Cyan
    Get-ComputerInfo | Select-Object OsName, CsProcessors, OsHardwareAbstractionLayer | Format-List
    $mem = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum / 1GB
    Write-Host "Memoria Física Total Instalada: $($mem.ToString('F2')) GB"
}
function Show-DiskSpace {
    Write-Host "`n--- Uso de Espacio en Disco ---" -ForegroundColor Cyan
    Get-PSDrive -PSProvider FileSystem | Format-Table Name, @{Name="Usado (GB)"; Expression={[math]::Round($_.Used / 1GB, 2)}}, @{Name="Libre (GB)"; Expression={[math]::Round($_.Free / 1GB, 2)}} -AutoSize
}
function Show-MemoryInfo {
    Write-Host "`n--- Información de Memoria RAM ---" -ForegroundColor Cyan
    try {
        $maxCapacityKB = (wmic memorychip get capacity | Measure-Object -Sum).Sum / 1024 / 1024
        $slots = (wmic memphysical get memorydevices | Where-Object {$_ -match '\d'}).Count
        Write-Host "Capacidad Máxima de RAM Soportada por la Placa Base: $maxCapacityKB GB"
        Write-Host "Ranuras de Memoria Físicas (Slots): $slots"
    } catch {
        Write-Host "❌ No se pudo obtener la información de memoria vía WMIC." -ForegroundColor Red
    }
}


#================================================================================#
#                         FUNCIONES DEL MENÚ (MODIFICADAS)                       #
#================================================================================#

function Show-Menu { param([string]$Title, [scriptblock]$Content)
    Clear-Host
    Write-Host "==================== $Title ====================" -ForegroundColor Green
    & $Content
    Write-Host "Selecciona una opción..." -ForegroundColor Yellow
    # Captura una sola tecla, sin mostrarla en pantalla.
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    return $key
}

function Pause-And-Continue {
    Write-Host "`nPresiona cualquier tecla para continuar..." -ForegroundColor Gray
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}


#================================================================================#
#                             INICIO DEL SCRIPT                                  #
#================================================================================#

Check-Administrator

do {
    $mainChoice = Show-Menu -Title "MENÚ PRINCIPAL" -Content {
        Write-Host "[1] Menú de Limpieza"
        Write-Host "[2] Menú de Reparación del Sistema"
        Write-Host "[3] Menú de Optimización y Rendimiento"
        Write-Host "[4] Menú de Utilidades y Seguridad"
        Write-Host "[5] Menú de Información del Sistema"
        Write-Host "[6] Menú de Utilidades de Red"
        Write-Host "------------------------------------------------------------"
        Write-Host "[Q] Salir del programa" -ForegroundColor Red
    }

    switch ($mainChoice) {
        '1' { # Menú de Limpieza
            do {
                $choice = Show-Menu -Title "MENÚ DE LIMPIEZA" -Content {
                    Write-Host "[1] Limpiar Archivos Temporales (Temp, %Temp%)"
                    Write-Host "[2] Limpiar Carpeta Prefetch"
                    Write-Host "[3] Limpiar Caché de Navegadores"
                    Write-Host "[4] Limpiar Caché de Windows Update"
                    Write-Host "[5] Vaciar Papelera de Reciclaje"
                    Write-Host "[A] EJECUTAR TODAS LAS TAREAS DE LIMPIEZA" -ForegroundColor Cyan
                    Write-Host "[B] Volver al Menú Principal" -ForegroundColor Red
                }
                switch ($choice) {
                    '1' { Clean-SystemFolders -FoldersToClean @("%temp%", "C:\Windows\Temp") -TaskName "Temporales" }
                    '2' { Clean-SystemFolders -FoldersToClean @("C:\Windows\Prefetch") -TaskName "Prefetch" }
                    '3' { Clean-BrowserCache }
                    '4' { Clean-WindowsUpdateCache }
                    '5' { Empty-RecycleBin }
                    'a' {
                        Clean-SystemFolders -FoldersToClean @("%temp%", "C:\Windows\Temp") -TaskName "Temporales"
                        Clean-SystemFolders -FoldersToClean @("C:\Windows\Prefetch") -TaskName "Prefetch"
                        Clean-BrowserCache
                        Clean-WindowsUpdateCache
                        Empty-RecycleBin
                    }
                }
                if ($choice -ne 'b') { Pause-And-Continue }
            } while ($choice -ne 'b')
        }
        '2' { # Menú de Reparación
            do {
                $choice = Show-Menu -Title "REPARACIÓN DEL SISTEMA" -Content {
                    Write-Host "[1] Ejecutar SFC (Comprobador de Archivos)"
                    Write-Host "[2] Ejecutar DISM (Reparar Imagen de Windows)"
                    Write-Host "[B] Volver" -ForegroundColor Red
                }
                switch ($choice) { '1' { Run-SFC } '2' { Run-DISM } }
                if ($choice -ne 'b') { Pause-And-Continue }
            } while ($choice -ne 'b')
        }
        '3' { # Menú de Optimización
            do {
                $choice = Show-Menu -Title "OPTIMIZACIÓN Y RENDIMIENTO" -Content {
                    Write-Host "[1] Activar Plan de Energía 'Alto Rendimiento'"
                    Write-Host "[2] Optimizar Unidades (HDD/SSD)"
                    Write-Host "[B] Volver" -ForegroundColor Red
                }
                switch ($choice) { '1' { Set-HighPerformancePowerPlan } '2' { Optimize-Drives } }
                if ($choice -ne 'b') { Pause-And-Continue }
            } while ($choice -ne 'b')
        }
        '4' { # Menú de Utilidades
             do {
                $choice = Show-Menu -Title "UTILIDADES Y SEGURIDAD" -Content {
                    Write-Host "[1] Crear Punto de Restauración del Sistema"
                    Write-Host "[2] Re-registrar Apps de la Tienda de Windows"
                    Write-Host "[B] Volver" -ForegroundColor Red
                }
                switch ($choice) { '1' { Create-SystemRestorePoint } '2' { Reregister-StoreApps } }
                if ($choice -ne 'b') { Pause-And-Continue }
            } while ($choice -ne 'b')
        }
        '5' { # Menú de Información
             do {
                $choice = Show-Menu -Title "INFORMACIÓN DEL SISTEMA" -Content {
                    Write-Host "[1] Mostrar Información General del PC"
                    Write-Host "[2] Mostrar Uso de Espacio en Disco"
                    Write-Host "[3] Mostrar Información de Memoria RAM (Capacidad y Slots)"
                    Write-Host "[A] MOSTRAR TODO" -ForegroundColor Cyan
                    Write-Host "[B] Volver" -ForegroundColor Red
                }
                switch ($choice) {
                    '1' { Show-SystemInfo }
                    '2' { Show-DiskSpace }
                    '3' { Show-MemoryInfo }
                    'a' { Show-SystemInfo; Show-DiskSpace; Show-MemoryInfo }
                }
                if ($choice -ne 'b') { Pause-And-Continue }
            } while ($choice -ne 'b')
        }
        '6' { # Menú de Red
            do {
                $choice = Show-Menu -Title "UTILIDADES DE RED" -Content {
                    Write-Host "[1] Limpiar Caché DNS"
                    Write-Host "[2] Reiniciar Catálogo Winsock (Requiere reinicio del PC)"
                    Write-Host "[B] Volver" -ForegroundColor Red
                }
                switch ($choice) { '1' { Flush-DNS } '2' { Reset-Winsock } }
                if ($choice -ne 'b') { Pause-And-Continue }
            } while ($choice -ne 'b')
        }
        'q' { Write-Host "Saliendo del programa..." }
        default {
            # No se necesita un mensaje de "opción inválida" porque
            # simplemente no hace nada y vuelve a mostrar el menú.
        }
    }
} while ($mainChoice -ne 'q')
