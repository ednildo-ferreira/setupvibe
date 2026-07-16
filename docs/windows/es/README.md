# Edición Windows de SetupVibe (Beta)

> Configuración de utilidades nativas de Windows — v0.41.6

La Edición Windows (Beta) configura un conjunto enfocado de utilidades nativas de Windows, con WinGet como fuente principal y Chocolatey para los paquetes que no están disponibles mediante WinGet.

## Requisitos

- Windows 11 versión 22H2 (build 22621) o posterior
- Una edición de escritorio de Windows de 64 bits; Windows 10 y Windows Server no son compatibles
- Windows PowerShell 5.1 o posterior
- Una cuenta de administrador
- Acceso a Internet

## Qué Instala

- Pregunta si se debe desactivar el Control de cuentas de usuario (UAC), usando `Yes` como opción predeterminada, y establece la directiva global `EnableLUA` en `0` cuando se acepta
- Cliente OpenSSH
- WinGet mediante el proceso oficial de reparación `Microsoft.WinGet.Client` cuando no está disponible
- Chocolatey mediante su script oficial de arranque cuando no está disponible
- Sistema base de WSL sin una distribución Linux, con WSL 2 como valor predeterminado
- Red reflejada de WSL con acceso por VPN/LAN, túnel DNS, integración con el proxy de Windows, entrada permitida en el firewall de Hyper-V, recuperación automática de memoria y discos virtuales dispersos
- Git, 7-Zip, Wget, FFmpeg, ImageMagick y GitHub CLI
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf y jq
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy y RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font y JetBrains Mono Nerd Font

El instalador es idempotente: detecta y omite los paquetes WinGet instalados, mientras Chocolatey garantiza la presencia de sus paquetes. Los errores se registran por paquete para que las demás instalaciones puedan continuar. Se guarda un registro completo en `C:\ProgramData\SetupVibe\Logs`.

Starship y zoxide se inicializan en los perfiles de Windows PowerShell y PowerShell 7.

Este script es exclusivo para utilidades nativas de Windows y el sistema base de WSL. No instala una distribución Linux, lenguajes de programación, frameworks, administradores de runtimes ni herramientas CLI de IA. Después de instalar una distribución por separado, use `desktop.sh` dentro de ella para configurar un entorno de desarrollo completo.

Si `%USERPROFILE%\.wslconfig` ya existe, SetupVibe crea una copia de seguridad antes de aplicar los valores predeterminados de desarrollo. `-Uninstall` restaura la copia de seguridad y los estados anteriores de las características y el firewall de WSL.

Docker Desktop se excluye intencionalmente. SetupVibe prepara WSL 2, pero no instala Docker ni una distribución Linux.

**Advertencia sobre la red de WSL:** SetupVibe permite el tráfico entrante a WSL en todos los puertos mediante el firewall de Hyper-V para que los servicios futuros sean accesibles desde la red local y las VPN compatibles. Restrinja esta directiva con reglas específicas del firewall de Hyper-V en redes no confiables. Un servicio Linux futuro debe escuchar en `0.0.0.0` o en la interfaz de red adecuada para aceptar conexiones remotas.

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

1. Valida Windows 11 22H2 o posterior y la arquitectura de 64 bits.
2. Solicita privilegios de administrador mediante UAC.
3. Espera los procesos concurrentes de mantenimiento e instalación, rechaza reinicios pendientes, inicia los servicios necesarios, comprueba la directiva WSUS y valida el almacén de componentes de Windows.
4. Pregunta si se debe desactivar UAC, usando `Yes` como opción predeterminada, y establece la directiva global del registro `EnableLUA` en `0` cuando se acepta.
5. Instala el Cliente OpenSSH cuando sea necesario.
6. Copia los scripts auxiliares de Windows de SetupVibe a `%USERPROFILE%\.setupvibe\bin` y agrega ese directorio al `PATH` del usuario.
7. Instala el sistema base de WSL sin una distribución Linux y establece WSL 2 como valor predeterminado.
8. Aplica a WSL red reflejada, acceso por VPN/LAN, DNS, proxy, firewall, recuperación de memoria y discos VHD dispersos.
9. Instala WinGet y Chocolatey cuando sea necesario.
10. Instala cada utilidad de Windows de forma independiente y continúa después de errores aislados.
11. Configura Starship y zoxide para Windows PowerShell y PowerShell 7.
12. Muestra un resumen final y la ubicación del registro completo.

El proceso puede tardar porque los administradores de paquetes descargan e instalan cada utilidad por separado.

## Después De La Instalación

1. Reinicie Windows cuando se solicite. Si eligió desactivar UAC, permanece activo hasta que finalice este reinicio.
2. Abra Windows Terminal o PowerShell 7 para cargar el nuevo `PATH`, Starship y zoxide.
3. Complete las autenticaciones iniciales requeridas por GitHub CLI o Tailscale.

Los scripts auxiliares de SetupVibe se almacenan en `%USERPROFILE%\.setupvibe\bin`. El núcleo `ssh_copy_id.ps1` y su lanzador mínimo `ssh_copy_id.cmd` pueden iniciarse como `ssh_copy_id` desde cualquier sesión nueva de PowerShell, Windows Terminal o Símbolo del sistema.

Verifique los componentes principales en una terminal nueva:

```powershell
winget --version
choco --version
git --version
rg --version
fzf --version
pwsh --version
Get-Command ssh_copy_id
wsl --status
wsl --list --verbose
Get-Content $HOME\.wslconfig
Get-NetFirewallHyperVVMSetting -PolicyStore ActiveStore -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}'
Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA
```

`wsl --list --verbose` debe indicar que no hay distribuciones instaladas, salvo que el equipo ya tuviera alguna. La salida del firewall debe mostrar `DefaultInboundAction` como `Allow`. El último comando debe devolver `0` después del reinicio si respondió `Yes` a la pregunta sobre UAC. Responder `No` conserva la directiva existente y no reactiva UAC si ya estaba desactivado.

## Nueva Ejecución Y Registros

El instalador está diseñado para ejecutarse nuevamente. Los scripts auxiliares de SetupVibe se actualizan, los paquetes WinGet existentes se omiten y Chocolatey garantiza la presencia de sus utilidades administradas.

Los registros completos de la transcripción y los registros dedicados de DISM se almacenan en:

```text
C:\ProgramData\SetupVibe\Logs
```

Si un paquete falla, revise el resumen final y el registro, resuelva el problema informado y ejecute nuevamente el mismo comando.

## Seguridad De Windows Servicing

Antes de instalar o eliminar componentes, SetupVibe espera hasta 20 minutos los procesos activos de `DISM`, `dismhost`, `TiWorker`, Windows Installer, WinGet y Chocolatey. También rechaza reinicios pendientes de Component Based Servicing o Windows Update, inicia `TrustedInstaller` y, durante la instalación, inicia `wuauserv` y `bits`, y después ejecuta `DISM /Online /Cleanup-Image /CheckHealth`.

SetupVibe nunca finaliza por la fuerza los procesos de mantenimiento de Windows. Si se agota la espera, muestra los nombres y PID y se detiene antes de realizar cambios. Reinicie Windows y vuelva a ejecutar el instalador. Esto protege el almacén de componentes frente a operaciones parciales de paquetes o características opcionales.

En equipos administrados por WSUS, las características bajo demanda como OpenSSH aún pueden fallar cuando el origen corporativo no proporciona contenido opcional. El error de OpenSSH indica su archivo dedicado `dism-OpenSSH-Client-*.log`.

## Opciones

Reinicie Windows automáticamente después de una instalación completamente exitosa cuando el sistema indique que se necesita un reinicio:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Restart
```

Sin `-Restart`, el instalador nunca reinicia Windows automáticamente.

Cambie el tiempo máximo de espera de los procesos concurrentes de mantenimiento e instalación, cuyo valor predeterminado es 20 minutos:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -InstallerWaitMinutes 45
```

`-InstallerWaitMinutes` acepta valores de `1` a `120` y no finaliza ningún proceso cuando vence el límite.

### Desinstalación

Elimine todas las utilidades y configuraciones administradas por la Edición Windows desde un clon local:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1 -Uninstall
```

O ejecute el desinstalador desde la rama `windows`:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Uninstall
```

El modo de desinstalación elimina el Cliente OpenSSH, los archivos administrados por SetupVibe de `%USERPROFILE%\.setupvibe\bin` y su entrada del `PATH` del usuario, restaura los estados anteriores de las características opcionales y el firewall de WSL, elimina la configuración de WSL aplicada por SetupVibe, elimina todas las utilidades WinGet y Chocolatey administradas por SetupVibe y elimina el bloque de perfil de Starship y zoxide y la configuración generada de Starship. También elimina runtimes de lenguajes, herramientas de frameworks, rutas de administradores de runtimes y paquetes npm instalados por versiones Beta anteriores de Windows y, a continuación, vuelve a activar UAC. Las distribuciones Linux existentes no se eliminan. WinGet, Chocolatey, los registros y los archivos no relacionados dentro de `%USERPROFILE%\.setupvibe` se conservan.

**Advertencia de desinstalación:** la versión Beta actual no registra si el Cliente OpenSSH o un paquete administrado ya existía antes de SetupVibe. Por lo tanto, `-Uninstall` elimina el Cliente OpenSSH y todos los paquetes de sus listas administradas, incluidos los componentes que puedan haber sido instalados por separado antes de SetupVibe.

Combine `-Uninstall` con `-Restart` para reiniciar automáticamente cuando Windows indique que se requiere un reinicio.

## Reactivación De UAC

Para restaurar el comportamiento de seguridad predeterminado de Windows, ejecute el siguiente comando en una sesión de PowerShell con privilegios de administrador y reinicie Windows:

```powershell
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -PropertyType DWord -Value 1 -Force
```

## Alcance Y Limitaciones

- Windows 10, Windows Server, las compilaciones de Windows 11 anteriores a 22621 y las ediciones de 32 bits se rechazan durante las comprobaciones iniciales.
- Cuando se acepta, la desactivación de UAC afecta a todo el equipo y reduce la seguridad de Windows. Una directiva de dominio o de administración del dispositivo puede restaurar la configuración después de que el script la cambie.
- WSL se instala y configura para WSL 2, red reflejada por VPN/LAN y optimizaciones comunes de desarrollo, pero no se instala ninguna distribución Linux.
- No se instalan lenguajes de programación, frameworks, administradores de runtimes ni herramientas CLI de IA.
- Docker Desktop y un motor Docker local no se instalan.
