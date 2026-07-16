# Edição Windows do SetupVibe

> Configuração do ambiente de desenvolvimento nativo do Windows — v0.41.6

A Edição Windows configura um ambiente completo de desenvolvimento nativo do Windows, usando o WinGet como fonte principal e o Chocolatey para pacotes indisponíveis no WinGet.

## Requisitos

- Windows 10 versão 1809 (build 17763) ou posterior, ou Windows 11
- Uma edição desktop de 64 bits do Windows; não há suporte para Windows Server
- Windows PowerShell 5.1 ou posterior
- Uma conta de administrador
- Acesso à internet

## O Que É Instalado

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

## Instalação Com Um Comando

Este é o equivalente no Windows ao comando `curl -sSL desktop.setupvibe.dev | bash`.

1. Abra o menu Iniciar.
2. Procure por **Windows PowerShell** e abra-o. Executar como administrador é opcional, pois o script solicita elevação pelo UAC automaticamente.
3. Revise o [`desktop.ps1`](../../../desktop.ps1) do repositório antes de executar código remoto.
4. Cole o comando abaixo e pressione `Enter`:

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/promovaweb/setupvibe/main/desktop.ps1 | iex
   ```

5. Aceite a solicitação do UAC do Windows.
6. Mantenha as janelas do PowerShell abertas até a exibição do resumo.
7. Reinicie o Windows se o resumo solicitar.

O comando baixa o `desktop.ps1` do repositório oficial do SetupVibe e o executa na sessão atual do PowerShell. Quando a elevação é necessária, o instalador baixa uma cópia temporária e continua em uma sessão de administrador.

## Instalação Local

Para baixar o script antes de executá-lo:

```powershell
$scriptPath = Join-Path $HOME 'Downloads\desktop.ps1'
Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/promovaweb/setupvibe/main/desktop.ps1 -OutFile $scriptPath
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
3. Configura entradas persistentes no `PATH` do usuário.
4. Instala o Cliente OpenSSH, WinGet e Chocolatey quando necessário.
5. Instala cada pacote do Windows de forma independente e continua após falhas isoladas.
6. Instala as ferramentas dos ecossistemas PHP, Ruby, Node.js, Python e Rust.
7. Configura Starship e zoxide no Windows PowerShell e no PowerShell 7.
8. Exibe um resumo final e o local do log completo.

O processo pode demorar, pois Ruby, Rust, Rails, n8n e ferramentas de IA podem baixar ou compilar dependências adicionais.

## Depois da Instalação

1. Reinicie o Windows quando solicitado.
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
```

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
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/main/desktop.ps1))) -Restart
```

Sem `-Restart`, o instalador nunca reinicia o Windows automaticamente.

## Escopo e Limitações

- Windows Server e versões de 32 bits do Windows são recusados durante as verificações iniciais.
- O WSL não é instalado nem configurado. Execute o `desktop.sh` dentro de uma distribuição WSL existente para configurar o ambiente Linux.
- O Docker Desktop e um mecanismo Docker local não são instalados.
