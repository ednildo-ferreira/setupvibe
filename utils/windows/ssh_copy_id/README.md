# SSH Copy ID para Windows 11 (Beta)

> Utilitário PowerShell para copiar uma chave SSH pública do Windows para um servidor remoto.

O código-fonte do núcleo fica em `ssh_copy_id.ps1`. Durante a instalação, ele recebe o nome `ssh_copy_id_core.ps1`, evitando que o PowerShell escolha o núcleo no lugar do lançador seguro `ssh_copy_id.cmd` quando o comando é executado sem extensão.

## Instalação pelo SetupVibe

O `desktop.ps1` instala os dois arquivos em `%USERPROFILE%\.setupvibe\bin` e adiciona esse diretório ao `PATH` do usuário:

```text
%USERPROFILE%\.setupvibe\bin\ssh_copy_id_core.ps1
%USERPROFILE%\.setupvibe\bin\ssh_copy_id.cmd
```

Depois de abrir um novo terminal, execute o utilitário de qualquer diretório:

```powershell
ssh_copy_id
```

Uma nova execução do SetupVibe atualiza os arquivos. O parâmetro `-Uninstall` remove somente os arquivos registrados como gerenciados e a entrada correspondente do `PATH`, preservando outros arquivos que o usuário possa manter em `%USERPROFILE%\.setupvibe`.

## Por Que PowerShell

O PowerShell oferece tratamento nativo de parâmetros, caminhos, processos, códigos de saída, elevação pelo UAC e erros terminantes. Isso torna a implementação mais segura e testável que uma rotina extensa em Batch.

O lançador `.cmd` não contém lógica SSH. Ele procura primeiro o PowerShell 7 (`pwsh.exe`), usa o Windows PowerShell (`powershell.exe`) como alternativa e chama `ssh_copy_id_core.ps1` com `-ExecutionPolicy Bypass` apenas para esse processo. Em uma instalação manual, também aceita o nome original `ssh_copy_id.ps1`.

## O Que O Utilitário Faz

1. Verifica a disponibilidade de `ssh.exe` e `ssh-keygen.exe`.
2. Interrompe com uma orientação clara para executar o SetupVibe quando o OpenSSH assinado não está disponível.
3. Procura uma chave pública válida em `%USERPROFILE%\.ssh`.
4. Reconstrói a chave pública quando encontra uma chave privada padrão sem o arquivo `.pub` correspondente.
5. Cria uma chave Ed25519 sem senha quando nenhuma chave válida é encontrada.
6. Valida o destino no formato `usuario@endereco` e a porta TCP.
7. Copia a chave para `~/.ssh/authorized_keys` sem duplicar uma chave já instalada.
8. Abre uma sessão SSH, a menos que `-NoConnect` seja informado.

## Uso

### Modo Interativo

Solicite o destino durante a execução:

```powershell
ssh_copy_id
```

### Destino Informado Na Linha De Comando

```powershell
ssh_copy_id deploy@192.0.2.10
```

### Porta SSH Personalizada

```powershell
ssh_copy_id deploy@192.0.2.10 -Port 2222
```

### Copiar Sem Abrir Uma Sessão

```powershell
ssh_copy_id deploy@192.0.2.10 -NoConnect
```

### Executar O Núcleo Diretamente

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\ssh_copy_id.ps1 deploy@192.0.2.10 -Port 22
```

### Executar Pelo Prompt De Comando

```batch
ssh_copy_id deploy@192.0.2.10 -NoConnect
```

## Parâmetros

| Parâmetro | Padrão | Descrição |
| --- | --- | --- |
| `Remote` | Interativo | Destino no formato `usuario@endereco`; também pode ser o primeiro argumento posicional. |
| `-Port` | `22` | Porta TCP do serviço SSH, entre `1` e `65535`. |
| `-NoConnect` | Desativado | Copia a chave sem abrir a sessão SSH interativa ao final. |

## Requisitos Do Servidor Remoto

- Serviço SSH acessível pela porta escolhida.
- Autenticação por senha permitida na primeira conexão ou outro método já disponível.
- Permissão para gravar no diretório pessoal da conta remota.
- Ambiente compatível com os comandos POSIX `umask`, `mkdir`, `touch`, `chmod`, `cat`, `grep` e `rm`.

O fluxo atual destina-se a servidores Linux, macOS e outros ambientes SSH compatíveis com esses comandos. Ele não instala a chave em um servidor OpenSSH nativo do Windows.

## Chaves Reconhecidas

O utilitário procura primeiro estas chaves públicas:

- `id_ed25519.pub`
- `id_ecdsa.pub`
- `id_rsa.pub`

Em seguida, considera outros arquivos `.pub` válidos em `%USERPROFILE%\.ssh`, ignorando certificados terminados em `-cert.pub`. A validade é verificada com `ssh-keygen -l`.

Quando encontra apenas `id_ed25519`, `id_ecdsa` ou `id_rsa`, tenta reconstruir o arquivo público com `ssh-keygen -y`. Uma chave privada protegida solicitará sua passphrase durante essa operação.

## Instalação Manual

Baixe o núcleo e o lançador da branch `windows`:

```powershell
$destino = "$env:USERPROFILE\Downloads\ssh_copy_id"
New-Item -ItemType Directory -Force -Path $destino | Out-Null
$base = 'https://raw.githubusercontent.com/promovaweb/setupvibe/windows/utils/windows/ssh_copy_id'
Invoke-WebRequest -Uri "$base/ssh_copy_id.ps1" -OutFile "$destino\ssh_copy_id.ps1"
Invoke-WebRequest -Uri "$base/ssh_copy_id.cmd" -OutFile "$destino\ssh_copy_id.cmd"
Set-Location $destino
.\ssh_copy_id.cmd
```

## Solução De Problemas

### OpenSSH Não Está Disponível

Execute o instalador principal do SetupVibe. O helper não usa Recursos sob Demanda, DISM nem Windows Update: o SetupVibe baixa o MSI x64 oficial do Microsoft Win32-OpenSSH, valida sua assinatura Authenticode e instala Cliente e Servidor.

### Conexão Recusada

Confirme o endereço, a porta, o serviço SSH, o firewall e a existência da conta informada.

### Senha Recusada

Verifique se a senha pertence ao usuário informado e se o servidor permite autenticação por senha. Alguns servidores aceitam somente chaves já autorizadas ou bloqueiam acesso direto do usuário `root`.

### Cópia Concluída, Mas A Conexão Final Falhou

A chave já pode estar instalada. Teste a conexão manualmente:

```powershell
ssh -p 22 usuario@endereco
```

## Segurança

A chave criada automaticamente não possui passphrase. Proteja a conta do Windows e nunca compartilhe a chave privada, como `%USERPROFILE%\.ssh\id_ed25519`.

Somente o arquivo público terminado em `.pub` deve ser copiado ou compartilhado. Na primeira conexão, confira a impressão digital apresentada pelo servidor antes de confirmar a confiança no host.
