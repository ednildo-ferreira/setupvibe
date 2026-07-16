# Edição Windows do SetupVibe (Beta)

> Configuração do ambiente de desenvolvimento nativo do Windows — v0.41.6

A Edição Windows (Beta) configura um ambiente completo de desenvolvimento nativo do Windows, usando o WinGet como fonte principal e o Chocolatey para pacotes indisponíveis no WinGet.

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
- PHP 8.4, Composer, Laravel Installer, Ruby 3.3, Bundler e Rails
- Python 3.12, uv, Spec-Kit, Go, Rustup e Cargo
- Node.js LTS, Bun, PNPM, PM2, n8n e as ferramentas de IA configuradas
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf, jq e mise
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy e RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font e JetBrains Mono Nerd Font

O instalador é idempotente: pacotes WinGet instalados são detectados e ignorados, enquanto Chocolatey e os instaladores dos ecossistemas garantem seus pacotes com segurança. Falhas são registradas por pacote para que as demais instalações continuem. Um log completo é salvo em `C:\ProgramData\SetupVibe\Logs`.

O Composer é instalado pelo instalador oficial após a verificação da assinatura SHA-384. Starship e zoxide são inicializados nos perfis do Windows PowerShell e do PowerShell 7.

Este script é exclusivo para ferramentas nativas do Windows. Use o `desktop.sh` dentro do WSL para configurar o ambiente Linux.

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
4. Configura entradas persistentes no `PATH` do usuário.
5. Instala o Cliente OpenSSH, WinGet e Chocolatey quando necessário.
6. Instala cada pacote do Windows de forma independente e continua após falhas isoladas.
7. Instala as ferramentas dos ecossistemas PHP, Ruby, Node.js, Python e Rust.
8. Configura Starship e zoxide no Windows PowerShell e no PowerShell 7.
9. Exibe um resumo final e o local do log completo.

O processo pode demorar, pois Ruby, Rust, Rails, n8n e ferramentas de IA podem baixar ou compilar dependências adicionais.

## Depois da Instalação

1. Reinicie o Windows quando solicitado. Se você optou por desativar o UAC, ele permanece ativo até a conclusão dessa reinicialização.
2. Abra o Windows Terminal ou PowerShell 7 para carregar o novo `PATH`, Starship e zoxide.
3. Conclua as autenticações iniciais exigidas pelo GitHub CLI, Tailscale, Claude Code, Codex ou outros serviços externos.

Verifique os principais componentes em um novo terminal:

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
Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA
```

O último comando deve retornar `0` depois da reinicialização caso você tenha respondido `Yes` à pergunta sobre o UAC. Responder `No` preserva a política existente e não reativa o UAC caso ele já estivesse desativado.

## Nova Execução e Logs

O instalador foi desenvolvido para ser executado novamente. Pacotes WinGet já presentes são ignorados, enquanto os instaladores dos ecossistemas garantem que suas ferramentas permaneçam instaladas.

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

## Reativando o UAC

Para restaurar o comportamento de segurança padrão do Windows, execute o comando abaixo em uma sessão administrativa do PowerShell e reinicie o Windows:

```powershell
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -PropertyType DWord -Value 1 -Force
```

## Escopo e Limitações

- Windows Server e versões de 32 bits do Windows são recusados durante as verificações iniciais.
- Quando autorizada, a desativação do UAC afeta todo o computador e reduz a segurança do Windows. Uma política de domínio ou de gerenciamento do dispositivo pode restaurar a configuração depois que o script a alterar.
- O WSL não é instalado nem configurado. Execute o `desktop.sh` dentro de uma distribuição WSL existente para configurar o ambiente Linux.
- O Docker Desktop e um mecanismo Docker local não são instalados.
