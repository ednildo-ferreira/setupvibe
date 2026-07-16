# Edición Windows de SetupVibe (Beta)

> Configuración de utilidades nativas de Windows — v0.41.6

La Edición Windows (Beta) configura un conjunto enfocado de utilidades nativas de Windows, con WinGet como fuente principal y Chocolatey para los paquetes que no están disponibles mediante WinGet.

## Requisitos

- Windows 10 versión 1809 (build 17763) o posterior, o Windows 11
- Una edición de escritorio de Windows de 64 bits; Windows Server no es compatible
- Windows PowerShell 5.1 o posterior
- Una cuenta de administrador
- Acceso a Internet

## Qué Instala

- Pregunta si se debe desactivar el Control de cuentas de usuario (UAC), usando `Yes` como opción predeterminada, y establece la directiva global `EnableLUA` en `0` cuando se acepta
- Cliente OpenSSH
- WinGet mediante el proceso oficial de reparación `Microsoft.WinGet.Client` cuando no está disponible
- Chocolatey mediante su script oficial de arranque cuando no está disponible
- Git, 7-Zip, Wget, FFmpeg, ImageMagick y GitHub CLI
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf y jq
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy y RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font y JetBrains Mono Nerd Font

El instalador es idempotente: detecta y omite los paquetes WinGet instalados, mientras Chocolatey garantiza la presencia de sus paquetes. Los errores se registran por paquete para que las demás instalaciones puedan continuar. Se guarda un registro completo en `C:\ProgramData\SetupVibe\Logs`.

Starship y zoxide se inicializan en los perfiles de Windows PowerShell y PowerShell 7.

Este script es exclusivo para utilidades nativas de Windows. No instala lenguajes de programación, frameworks, administradores de runtimes, herramientas CLI de IA ni WSL. Use `desktop.sh` dentro de WSL para configurar un entorno de desarrollo completo.

Docker Desktop se excluye intencionalmente porque sus motores habituales requieren WSL 2 o Hyper-V.

**Advertencia de seguridad:** desactivar UAC elimina sus beneficios de seguridad para todo el equipo. [Microsoft recomienda mantener habilitada esta directiva](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/user-account-control-run-all-administrators-in-admin-approval-mode). SetupVibe cambia esta configuración solo cuando responde `Yes`; Windows debe reiniciarse para que entre en vigor.

## Instalación Con Un Comando

Este es el equivalente en Windows de `curl -sSL desktop.setupvibe.dev | bash`.

Por ahora, las URL del instalador de Windows apuntan a la rama de desarrollo `windows`.

1. Abra el menú Inicio.
2. Busque **Windows PowerShell** y ábralo. Ejecutarlo como administrador es opcional, ya que el script solicita elevación mediante UAC automáticamente.
3. Revise el archivo [`desktop.ps1`](../../../desktop.ps1) del repositorio antes de ejecutar código remoto.
4. Pegue el siguiente comando y presione `Entrar`:

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 | iex
   ```

5. Acepte la solicitud de UAC de Windows.
6. Responda `Yes` o `No` cuando el script pregunte si debe desactivar UAC. Pulsar `Entrar` selecciona la opción predeterminada, `Yes`.
7. Mantenga abiertas las ventanas de PowerShell hasta que aparezca el resumen.
8. Reinicie Windows cuando se solicite para aplicar la directiva de UAC y los cambios de paquetes pendientes.

El comando descarga `desktop.ps1` desde el repositorio oficial de SetupVibe y lo ejecuta en la sesión actual de PowerShell. Cuando se necesita elevación, el instalador descarga una copia temporal y continúa en una sesión de administrador.

## Instalación Local

Para descargar el script antes de ejecutarlo:

```powershell
$scriptPath = Join-Path $HOME 'Downloads\desktop.ps1'
Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 -OutFile $scriptPath
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
3. Pregunta si se debe desactivar UAC, usando `Yes` como opción predeterminada, y establece la directiva global del registro `EnableLUA` en `0` cuando se acepta.
4. Instala el Cliente OpenSSH, WinGet y Chocolatey cuando sea necesario.
5. Instala cada utilidad de Windows de forma independiente y continúa después de errores aislados.
6. Configura Starship y zoxide para Windows PowerShell y PowerShell 7.
7. Muestra un resumen final y la ubicación del registro completo.

El proceso puede tardar porque los administradores de paquetes descargan e instalan cada utilidad por separado.

## Después De La Instalación

1. Reinicie Windows cuando se solicite. Si eligió desactivar UAC, permanece activo hasta que finalice este reinicio.
2. Abra Windows Terminal o PowerShell 7 para cargar el nuevo `PATH`, Starship y zoxide.
3. Complete las autenticaciones iniciales requeridas por GitHub CLI o Tailscale.

Verifique los componentes principales en una terminal nueva:

```powershell
winget --version
choco --version
git --version
rg --version
fzf --version
pwsh --version
Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA
```

El último comando debe devolver `0` después del reinicio si respondió `Yes` a la pregunta sobre UAC. Responder `No` conserva la directiva existente y no reactiva UAC si ya estaba desactivado.

## Nueva Ejecución Y Registros

El instalador está diseñado para ejecutarse nuevamente. Los paquetes WinGet existentes se omiten, mientras Chocolatey garantiza la presencia de sus utilidades administradas.

Los registros completos se almacenan en:

```text
C:\ProgramData\SetupVibe\Logs
```

Si un paquete falla, revise el resumen final y el registro, resuelva el problema informado y ejecute nuevamente el mismo comando.

## Opciones

Reinicie Windows automáticamente después de una instalación completamente exitosa cuando el sistema indique que se necesita un reinicio:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Restart
```

Sin `-Restart`, el instalador nunca reinicia Windows automáticamente.

### Desinstalación

Elimine todas las utilidades y configuraciones administradas por la Edición Windows desde un clon local:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1 -Uninstall
```

O ejecute el desinstalador desde la rama `windows`:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Uninstall
```

El modo de desinstalación elimina el Cliente OpenSSH, todas las utilidades WinGet y Chocolatey administradas por SetupVibe, el bloque de perfil de Starship y zoxide y la configuración generada de Starship. También elimina runtimes de lenguajes, herramientas de frameworks, rutas de administradores de runtimes y paquetes npm instalados por versiones Beta anteriores de Windows y, a continuación, vuelve a activar UAC. WinGet, Chocolatey y los registros se conservan.

**Advertencia de desinstalación:** la versión Beta actual no registra si el Cliente OpenSSH o un paquete administrado ya existía antes de SetupVibe. Por lo tanto, `-Uninstall` elimina el Cliente OpenSSH y todos los paquetes de sus listas administradas, incluidos los componentes que puedan haber sido instalados por separado antes de SetupVibe.

Combine `-Uninstall` con `-Restart` para reiniciar automáticamente cuando Windows indique que se requiere un reinicio.

## Reactivación De UAC

Para restaurar el comportamiento de seguridad predeterminado de Windows, ejecute el siguiente comando en una sesión de PowerShell con privilegios de administrador y reinicie Windows:

```powershell
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -PropertyType DWord -Value 1 -Force
```

## Alcance Y Limitaciones

- Windows Server y las ediciones de 32 bits de Windows se rechazan durante las comprobaciones iniciales.
- Cuando se acepta, la desactivación de UAC afecta a todo el equipo y reduce la seguridad de Windows. Una directiva de dominio o de administración del dispositivo puede restaurar la configuración después de que el script la cambie.
- WSL no se instala ni configura. Ejecute `desktop.sh` dentro de una distribución WSL existente para configurar el entorno Linux.
- No se instalan lenguajes de programación, frameworks, administradores de runtimes ni herramientas CLI de IA.
- Docker Desktop y un motor Docker local no se instalan.
