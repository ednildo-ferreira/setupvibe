# Edição Windows do SetupVibe (Beta)

> Configuração de utilitários nativos do Windows — v0.41.6

A Edição Windows (Beta) configura um conjunto focado de utilitários nativos do Windows, usando o WinGet como fonte principal e o Chocolatey para pacotes indisponíveis no WinGet.

## Requisitos

- Windows 10 versão 1809 (build 17763) ou posterior, ou Windows 11
- Uma edição desktop de 64 bits do Windows; não há suporte para Windows Server
- Windows PowerShell 5.1 ou posterior
- Uma conta de administrador
- Acesso à internet

## O Que É Instalado

- Pergunta se o Controle de Conta de Usuário (UAC) deve ser desativado, usando `Yes` como padrão, e define a política global `EnableLUA` como `0` quando autorizado
- Cliente OpenSSH
- WinGet pelo fluxo oficial de reparo `Microsoft.WinGet.Client`, quando ausente
- Chocolatey pelo script oficial de bootstrap, quando ausente
- Git, 7-Zip, Wget, FFmpeg, ImageMagick e GitHub CLI
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf e jq
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy e RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font e JetBrains Mono Nerd Font

O instalador é idempotente: pacotes WinGet instalados são detectados e ignorados, enquanto o Chocolatey garante seus pacotes com segurança. Falhas são registradas por pacote para que as demais instalações continuem. Um log completo é salvo em `C:\ProgramData\SetupVibe\Logs`.

Starship e zoxide são inicializados nos perfis do Windows PowerShell e do PowerShell 7.

Este script é exclusivo para utilitários nativos do Windows. Ele não instala linguagens de programação, frameworks, gerenciadores de runtime, ferramentas CLI de IA nem WSL. Use o `desktop.sh` dentro do WSL para configurar um ambiente completo de desenvolvimento.

O Docker Desktop foi excluído intencionalmente porque seus backends usuais dependem do WSL 2 ou Hyper-V.

**Aviso de segurança:** desativar o UAC remove seus benefícios de segurança de todo o computador. [A Microsoft recomenda manter essa política habilitada](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/user-account-control-run-all-administrators-in-admin-approval-mode). O SetupVibe altera a configuração somente quando você responde `Yes`; o Windows precisa ser reiniciado para que ela entre em vigor.

## Instalação Com Um Comando

Este é o equivalente no Windows ao comando `curl -sSL desktop.setupvibe.dev | bash`.

Por enquanto, as URLs do instalador Windows apontam para a branch de desenvolvimento `windows`.

1. Abra o menu Iniciar.
2. Procure por **Windows PowerShell** e abra-o. Executar como administrador é opcional, pois o script solicita elevação pelo UAC automaticamente.
3. Revise o [`desktop.ps1`](../../../desktop.ps1) do repositório antes de executar código remoto.
4. Cole o comando abaixo e pressione `Enter`:

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 | iex
   ```

5. Aceite a solicitação do UAC do Windows.
6. Responda `Yes` ou `No` quando o script perguntar se deve desativar o UAC. Pressionar `Enter` seleciona o padrão, `Yes`.
7. Mantenha as janelas do PowerShell abertas até a exibição do resumo.
8. Reinicie o Windows quando solicitado para aplicar a política do UAC e eventuais alterações pendentes dos pacotes.

O comando baixa o `desktop.ps1` do repositório oficial do SetupVibe e o executa na sessão atual do PowerShell. Quando a elevação é necessária, o instalador baixa uma cópia temporária e continua em uma sessão de administrador.

## Instalação Local

Para baixar o script antes de executá-lo:

```powershell
$scriptPath = Join-Path $HOME 'Downloads\desktop.ps1'
Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 -OutFile $scriptPath
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
```

A partir de um clone existente deste repositório:

```powershell
Set-Location C:\caminho\para\setupvibe
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1
```

## O Que Esperar

Durante a execução, o instalador:

1. Valida a edição, o build e a arquitetura de 64 bits do Windows.
2. Solicita privilégios de administrador pelo UAC.
3. Pergunta se deve desativar o UAC, usando `Yes` como padrão, e define a política global de registro `EnableLUA` como `0` quando autorizado.
4. Instala o Cliente OpenSSH, WinGet e Chocolatey quando necessário.
5. Instala cada utilitário do Windows de forma independente e continua após falhas isoladas.
6. Configura Starship e zoxide no Windows PowerShell e no PowerShell 7.
7. Exibe um resumo final e o local do log completo.

O processo pode demorar porque os gerenciadores de pacotes baixam e instalam cada utilitário separadamente.

## Depois da Instalação

1. Reinicie o Windows quando solicitado. Se você optou por desativar o UAC, ele permanece ativo até a conclusão dessa reinicialização.
2. Abra o Windows Terminal ou PowerShell 7 para carregar o novo `PATH`, Starship e zoxide.
3. Conclua as autenticações iniciais exigidas pelo GitHub CLI ou Tailscale.

Verifique os principais componentes em um novo terminal:

```powershell
winget --version
choco --version
git --version
rg --version
fzf --version
pwsh --version
Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA
```

O último comando deve retornar `0` depois da reinicialização caso você tenha respondido `Yes` à pergunta sobre o UAC. Responder `No` preserva a política existente e não reativa o UAC caso ele já estivesse desativado.

## Nova Execução e Logs

O instalador foi desenvolvido para ser executado novamente. Pacotes WinGet já presentes são ignorados, enquanto o Chocolatey garante que seus utilitários gerenciados permaneçam instalados.

Os logs completos são armazenados em:

```text
C:\ProgramData\SetupVibe\Logs
```

Se um pacote falhar, revise o resumo final e o log, resolva o problema informado e execute o mesmo comando novamente.

## Opções

Reinicie o Windows automaticamente depois de uma instalação totalmente bem-sucedida quando o sistema informar que uma reinicialização é necessária:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Restart
```

Sem `-Restart`, o instalador nunca reinicia o Windows automaticamente.

### Desinstalação

Remova todos os utilitários e configurações gerenciados pela Edição Windows a partir de um clone local:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1 -Uninstall
```

Ou execute o desinstalador pela branch `windows`:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Uninstall
```

O modo de desinstalação remove o Cliente OpenSSH, todos os utilitários WinGet e Chocolatey gerenciados pelo SetupVibe, o bloco de perfil do Starship e zoxide e a configuração gerada do Starship. Ele também remove runtimes de linguagens, ferramentas de frameworks, caminhos de gerenciadores de runtime e pacotes npm instalados por versões Beta anteriores do Windows e, em seguida, reativa o UAC. WinGet, Chocolatey e os logs são preservados.

**Aviso sobre a desinstalação:** a versão Beta atual não registra se o Cliente OpenSSH ou um pacote gerenciado já existia antes do SetupVibe. Portanto, `-Uninstall` remove o Cliente OpenSSH e todos os pacotes de suas listas gerenciadas, inclusive componentes que possam ter sido instalados separadamente antes do SetupVibe.

Combine `-Uninstall` com `-Restart` para reiniciar automaticamente quando o Windows informar que uma reinicialização é necessária.

## Reativando o UAC

Para restaurar o comportamento de segurança padrão do Windows, execute o comando abaixo em uma sessão administrativa do PowerShell e reinicie o Windows:

```powershell
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -PropertyType DWord -Value 1 -Force
```

## Escopo e Limitações

- Windows Server e versões de 32 bits do Windows são recusados durante as verificações iniciais.
- Quando autorizada, a desativação do UAC afeta todo o computador e reduz a segurança do Windows. Uma política de domínio ou de gerenciamento do dispositivo pode restaurar a configuração depois que o script a alterar.
- O WSL não é instalado nem configurado. Execute o `desktop.sh` dentro de uma distribuição WSL existente para configurar o ambiente Linux.
- Linguagens de programação, frameworks, gerenciadores de runtime e ferramentas CLI de IA não são instalados.
- O Docker Desktop e um mecanismo Docker local não são instalados.
