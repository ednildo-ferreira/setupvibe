# Edición Windows de SetupVibe

> Configuración del entorno de desarrollo nativo de Windows — v0.41.6

La Edición Windows configura un entorno completo de desarrollo nativo de Windows, con WinGet como fuente principal y Chocolatey para los paquetes que no están disponibles mediante WinGet.

## Requisitos

- Windows 10 versión 1809 (build 17763) o posterior, o Windows 11
- Una edición de escritorio de Windows de 64 bits; Windows Server no es compatible
- Windows PowerShell 5.1 o posterior
- Una cuenta de administrador
- Acceso a Internet

## Qué Instala

- Cliente OpenSSH
- WinGet mediante el proceso oficial de reparación `Microsoft.WinGet.Client` cuando no está disponible
- Chocolatey mediante su script oficial de arranque cuando no está disponible
- Git, 7-Zip, Wget, FFmpeg, ImageMagick y GitHub CLI
- PHP 8.4, Composer, Laravel Installer, Ruby 3.3, Bundler y Rails
- Python 3.12, uv, Spec-Kit, Go, Rustup y Cargo
- Node.js LTS, Bun, PNPM, PM2, n8n y las herramientas de IA configuradas
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf, jq y mise
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy y RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font y JetBrains Mono Nerd Font

El instalador es idempotente: detecta y omite los paquetes WinGet instalados, mientras Chocolatey y los instaladores de cada ecosistema garantizan la presencia de sus paquetes. Los errores se registran por paquete para que las demás instalaciones puedan continuar. Se guarda un registro completo en `C:\ProgramData\SetupVibe\Logs`.

Composer se instala desde su instalador oficial después de verificar la firma SHA-384. Starship y zoxide se inicializan en los perfiles de Windows PowerShell y PowerShell 7.

Este script es exclusivo para herramientas nativas de Windows. Use `desktop.sh` dentro de WSL para configurar el entorno Linux.

Docker Desktop se excluye intencionalmente porque sus motores habituales requieren WSL 2 o Hyper-V.

## Instalación Con Un Comando

Este es el equivalente en Windows de `curl -sSL desktop.setupvibe.dev | bash`.

1. Abra el menú Inicio.
2. Busque **Windows PowerShell** y ábralo. Ejecutarlo como administrador es opcional, ya que el script solicita elevación mediante UAC automáticamente.
3. Revise el archivo [`desktop.ps1`](../../../desktop.ps1) del repositorio antes de ejecutar código remoto.
4. Pegue el siguiente comando y presione `Entrar`:

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/promovaweb/setupvibe/main/desktop.ps1 | iex
   ```

5. Acepte la solicitud de UAC de Windows.
6. Mantenga abiertas las ventanas de PowerShell hasta que aparezca el resumen.
7. Reinicie Windows si el resumen lo solicita.

El comando descarga `desktop.ps1` desde el repositorio oficial de SetupVibe y lo ejecuta en la sesión actual de PowerShell. Cuando se necesita elevación, el instalador descarga una copia temporal y continúa en una sesión de administrador.

## Instalación Local

Para descargar el script antes de ejecutarlo:

```powershell
$scriptPath = Join-Path $HOME 'Downloads\desktop.ps1'
Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/promovaweb/setupvibe/main/desktop.ps1 -OutFile $scriptPath
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
```

Desde un clon existente de este repositorio:

```powershell
Set-Location C:\ruta\a\setupvibe
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1
```

## Qué Esperar

Durante la ejecución, el instalador:

1. Valida la edición, la compilación y la arquitectura de 64 bits de Windows.
2. Solicita privilegios de administrador mediante UAC.
3. Configura entradas persistentes en el `PATH` del usuario.
4. Instala el Cliente OpenSSH, WinGet y Chocolatey cuando sea necesario.
5. Instala cada paquete de Windows de forma independiente y continúa después de errores aislados.
6. Instala las herramientas de los ecosistemas PHP, Ruby, Node.js, Python y Rust.
7. Configura Starship y zoxide para Windows PowerShell y PowerShell 7.
8. Muestra un resumen final y la ubicación del registro completo.

El proceso puede tardar, ya que Ruby, Rust, Rails, n8n y las herramientas de IA pueden descargar o compilar dependencias adicionales.

## Después De La Instalación

1. Reinicie Windows cuando se solicite.
2. Abra Windows Terminal o PowerShell 7 para cargar el nuevo `PATH`, Starship y zoxide.
3. Complete las autenticaciones iniciales requeridas por GitHub CLI, Tailscale, Claude Code, Codex u otros servicios externos.

Verifique los componentes principales en una terminal nueva:

```powershell
winget --version
choco --version
git --version
php --version
composer --version
ruby --version
python --version
node --version
rustc --version
pwsh --version
```

## Nueva Ejecución Y Registros

El instalador está diseñado para ejecutarse nuevamente. Los paquetes WinGet existentes se omiten, mientras los instaladores de los ecosistemas garantizan la presencia de sus herramientas.

Los registros completos se almacenan en:

```text
C:\ProgramData\SetupVibe\Logs
```

Si un paquete falla, revise el resumen final y el registro, resuelva el problema informado y ejecute nuevamente el mismo comando.

## Opciones

Reinicie Windows automáticamente después de una instalación completamente exitosa cuando el sistema indique que se necesita un reinicio:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/main/desktop.ps1))) -Restart
```

Sin `-Restart`, el instalador nunca reinicia Windows automáticamente.

## Alcance Y Limitaciones

- Windows Server y las ediciones de 32 bits de Windows se rechazan durante las comprobaciones iniciales.
- WSL no se instala ni configura. Ejecute `desktop.sh` dentro de una distribución WSL existente para configurar el entorno Linux.
- Docker Desktop y un motor Docker local no se instalan.
