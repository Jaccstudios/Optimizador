# PSP-Util (PowerShell Optimization & Repair Tool) v4.0

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg?style=for-the-badge&logo=powershell)

Una suite de optimización, limpieza y reparación todo-en-uno para Windows, creada en PowerShell puro con una interfaz de menú interactiva.

Inspirado en la funcionalidad de herramientas como [Massgrave.dev](https://massgrave.dev/), este script busca centralizar las tareas comunes de mantenimiento y optimización en una única utilidad de consola que es potente, portátil y fácil de usar.

## 🖼️ Interfaz de Usuario

La herramienta utiliza una interfaz de menú limpia y rápida, que se controla con una sola tecla (sin necesidad de presionar "Enter"), lo que permite una navegación y ejecución de tareas muy fluida.

```

## \==================== MENÚ PRINCIPAL ==================== [1] Menú de Limpieza [2] Menú de Reparación del Sistema [3] Menú de Optimización y Rendimiento [4] Menú de Utilidades y Seguridad [5] Menú de Información del Sistema [6] Menú de Utilidades de Red

[Q] Salir del programa
Selecciona una opción...

````
*(Captura de pantalla del menú principal)*

---

## 🚀 Funcionalidades Detalladas

La herramienta se divide en seis módulos principales para una fácil navegación.

### 🧹 1. Menú de Limpieza
* **[1] Limpiar Archivos Temporales:** Elimina el contenido de `C:\Windows\Temp` y `%temp%`.
* **[2] Limpiar Carpeta Prefetch:** Vacía `C:\Windows\Prefetch` (puede ralentizar el primer inicio de apps).
* **[3] Limpiar Caché de Navegadores:** Borra la caché de Chrome, Edge y Firefox.
* **[4] Limpiar Caché de Windows Update:** Elimina archivos de instalación de actualizaciones descargados (`SoftwareDistribution`).
* **[5] Vaciar Papelera de Reciclaje:** Vacía la papelera del usuario actual.
* **[A] Ejecutar Todas las Tareas:** Realiza todas las acciones de limpieza anteriores en secuencia.

### 🛠️ 2. Menú de Reparación del Sistema
* **[1] Ejecutar SFC (Comprobador de Archivos):** Ejecuta `sfc /scannow` para encontrar y reparar archivos corruptos del sistema.
* **[2] Ejecutar DISM (Reparar Imagen de Windows):** Ejecuta `Dism /Online /Cleanup-Image /RestoreHealth` para reparar la imagen de componentes de Windows.

### ⚡ 3. Menú de Optimización y Rendimiento
* **[1] Activar Plan de Energía 'Alto Rendimiento':** Cambia el plan de energía activo para priorizar el rendimiento.
* **[2] Optimizar Unidades (HDD/SSD):** Ejecuta la herramienta de optimización de Windows (`Optimize-Volume`), que aplica `TRIM` a los SSD y desfragmenta los HDD.

### 🛡️ 4. Menú de Utilidades y Seguridad
* **[1] Crear Punto de Restauración:** Crea un punto de restauración del sistema, esencial antes de realizar cambios importantes.
* **[2] Re-registrar Apps de la Tienda de Windows:** Vuelve a registrar todas las aplicaciones UWP (Store, Calculadora, Fotos, etc.) para solucionar problemas de apertura.

### ℹ️ 5. Menú de Información del Sistema
* **[1] Mostrar Información General del PC:** Muestra el SO, procesador y memoria RAM instalada.
* **[2] Mostrar Uso de Espacio en Disco:** Presenta una tabla con el espacio usado y libre de todas las unidades.
* **[3] Mostrar Información de Memoria RAM:** Muestra la **capacidad máxima de RAM** soportada por la placa base y el **número de ranuras (slots)** físicas.
* **[A] Mostrar Todo:** Ejecuta los tres informes anteriores.

### 🌐 6. Menú de Utilidades de Red
* **[1] Limpiar Caché DNS:** Ejecuta `ipconfig /flushdns` para solucionar problemas de resolución de nombres.
* **[2] Reiniciar Catálogo Winsock:** Ejecuta `netsh winsock reset` para corregir problemas de conectividad (requiere reinicio).

---

## 📋 Requisitos Previos

* **Sistema Operativo:** Windows 10 o Windows 11.
* **Permisos:** **¡Permisos de Administrador!** El script no funcionará sin ellos. Cuenta con una verificación al inicio para asegurar esto.

---

## 🚀 Cómo Empezar

Existen varias formas de ejecutar este script, desde la más simple hasta la más profesional.

### Método 1: Ejecución Rápida desde la Web (Para Probar)
Este método descarga el script y lo ejecuta directamente en la memoria. Es la forma más rápida de usarlo.

*Reemplaza la URL con la URL "Raw" de tu script en GitHub/GitLab:*
```powershell
# Abre una ventana de PowerShell (puede ser como usuario normal)
irm [https://raw.githubusercontent.com/TU_USUARIO/TU_REPOSITORIO/main/Optimizador.ps1](https://raw.githubusercontent.com/TU_USUARIO/TU_REPOSITORIO/main/Optimizador.ps1) | iex
````

### Método 2: Ejecución Local (Uso Frecuente)

1.  Guarda el código completo en un archivo con la extensión `.ps1` (ej. `Optimizador.ps1`).
2.  Haz **clic derecho** sobre el archivo.
3.  Selecciona **"Ejecutar con PowerShell"**.
4.  Acepta la ventana de permisos de Administrador (UAC).

### Método 3: Lanzador `.bat` (El más Cómodo)

1.  Guarda el script como `Optimizador.ps1`.
2.  En la **misma carpeta**, crea un nuevo archivo llamado `Ejecutar.bat`.
3.  Abre `Ejecutar.bat` con el Bloc de notas y pega el siguiente código:
    ```cmd
    @echo off
    :: Lanza el script de PowerShell con permisos elevados y saltando la política de ejecución
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Optimizador.ps1"
    pause
    ```
4.  Guarda el archivo `.bat`. Ahora, solo necesitas hacer **clic derecho en `Ejecutar.bat` \> "Ejecutar como administrador"**.

### Método 4: Compilar a `.exe` (Nivel Avanzado/Distribución)

Puedes convertir el script en un archivo `.exe` independiente que solicite automáticamente los permisos de administrador.

1.  Abre PowerShell **como Administrador**.
2.  Instala el módulo `Ps2Exe`:
    ```powershell
    Install-Module -Name Ps2Exe
    ```
3.  Navega a la carpeta de tu script:
    ```powershell
    cd "C:\Ruta\A\Tu\Script"
    ```
4.  Ejecuta el compilador:
    ```powershell
    ps2exe -inputFile '.\Optimizador.ps1' -outputFile '.\Optimizador.exe' -requireAdministrator
    ```
5.  Ahora puedes distribuir y ejecutar `Optimizador.exe` como cualquier otro programa.

-----

## ⚠️ ¡Importante\! Advertencia de Uso

Esta es una herramienta poderosa que realiza cambios significativos en la configuración y los archivos del sistema. El autor ha hecho todo lo posible por asegurar que los comandos sean seguros y efectivos, pero **el uso de este script es bajo tu propio riesgo**.

**Se recomienda encarecidamente crear un Punto de Restauración del Sistema** (Opción 4-1 en el menú) antes de ejecutar tareas de reparación o limpieza extensivas. El autor no se hace responsable por cualquier pérdida de datos o daño al sistema.

## 📄 Licencia

Este proyecto se distribuye bajo la **Licencia MIT**. Eres libre de usar, modificar y distribuir el código.

```
```
