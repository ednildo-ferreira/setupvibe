# SSH Copy ID para Windows 11 (Beta)

Este utilitário copia a chave SSH do usuário atual do Windows 11 para um servidor remoto e, após a cópia, abre automaticamente uma sessão SSH no servidor.

O script também verifica se o OpenSSH Client está disponível. Quando necessário, solicita autorização do Controle de Conta de Usuário do Windows e instala o recurso automaticamente.

## O que o script faz

Ao ser executado, o `ssh_copy_id.bat` realiza estas ações:

1. Verifica se o OpenSSH Client está instalado no Windows 11.
2. Instala o OpenSSH Client após confirmação do Controle de Conta de Usuário, caso esteja ausente.
3. Procura uma chave SSH válida no diretório `%USERPROFILE%\.ssh`.
4. Exibe o nome da chave encontrada.
5. Reconstrói a chave pública quando encontra uma chave privada padrão sem o arquivo `.pub` correspondente.
6. Cria uma chave Ed25519 sem senha quando nenhuma chave SSH é encontrada.
7. Solicita o servidor no formato `usuario@endereco`.
8. Copia a chave pública para o arquivo `~/.ssh/authorized_keys` do servidor sem duplicar uma chave já instalada.
9. Abre uma sessão SSH no servidor após a cópia.

## Requisitos

- Windows 11.
- Conexão com a internet caso o OpenSSH Client precise ser instalado.
- Usuário e senha de uma conta SSH no servidor remoto.
- Servidor remoto configurado para aceitar conexão SSH e autenticação por senha na primeira conexão.
- Permissão para gravar no diretório pessoal da conta remota.

## Opção 1 — Usar pelo Prompt de Comando

### Passo 1 — Abrir o terminal

Pressione `Win + R`, digite `cmd` e pressione `Enter`.

Não é necessário abrir o Prompt de Comando como administrador. Se o OpenSSH Client precisar ser instalado, o próprio script exibirá a solicitação de elevação do Windows.

### Passo 2 — Entrar no diretório do script

Use `cd` com o caminho onde o repositório SetupVibe foi salvo. Por exemplo:

```batch
cd /d "%USERPROFILE%\Downloads\setupvibe\utils\windows\ssh_copy_id"
```

Se o repositório estiver em outro local, substitua o caminho pelo diretório correto.

### Passo 3 — Executar o script

Execute:

```batch
ssh_copy_id.bat
```

### Passo 4 — Autorizar a instalação do OpenSSH

Se o cliente SSH ainda não estiver instalado, o Windows exibirá uma solicitação do Controle de Conta de Usuário. Clique em **Sim** e aguarde a instalação.

Quando o OpenSSH já estiver instalado, esta etapa será ignorada automaticamente.

### Passo 5 — Conferir ou criar a chave SSH

Se uma chave válida existir, o script mostrará seu nome:

```text
Chave SSH encontrada: id_ed25519.pub
```

Se nenhuma chave existir, o script informará isso e criará `%USERPROFILE%\.ssh\id_ed25519` sem senha.

### Passo 6 — Informar o servidor remoto

Quando solicitado, digite o usuário SSH, o caractere `@` e o endereço IP ou nome do servidor:

```text
Informe o servidor remoto no formato usuario@endereco: deploy@192.0.2.10
```

Outros exemplos válidos:

```text
root@servidor.exemplo.com
ubuntu@203.0.113.20
```

### Passo 7 — Confirmar o servidor e informar a senha

Na primeira conexão, o comando SSH poderá perguntar se o servidor é confiável:

```text
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Confira a impressão digital do servidor com o administrador e digite `yes` para continuar.

Em seguida, o próprio comando `ssh` solicitará a senha da conta remota. A senha não aparecerá na tela enquanto for digitada. Pressione `Enter` ao terminar.

### Passo 8 — Usar a sessão SSH

Após a chave ser copiada com sucesso, o script abre automaticamente uma nova conexão com o servidor. Essa conexão normalmente não solicitará a senha novamente.

Para encerrar a sessão e voltar ao terminal do Windows, execute:

```bash
exit
```

## Opção 2 — Usar pelo PowerShell

Abra o PowerShell ou o Windows Terminal e entre no diretório do script:

```powershell
Set-Location "$env:USERPROFILE\Downloads\setupvibe\utils\windows\ssh_copy_id"
```

Execute o arquivo usando o prefixo `.\`:

```powershell
.\ssh_copy_id.bat
```

Depois disso, siga as mesmas instruções exibidas nas etapas do Prompt de Comando.

## Baixar somente o script pelo PowerShell

Caso não queira clonar todo o repositório, execute os comandos abaixo no PowerShell:

```powershell
$destino = "$env:USERPROFILE\Downloads\ssh_copy_id"
New-Item -ItemType Directory -Force -Path $destino | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/promovaweb/setupvibe/windows/utils/windows/ssh_copy_id/ssh_copy_id.bat" -OutFile "$destino\ssh_copy_id.bat"
Set-Location $destino
.\ssh_copy_id.bat
```

## Chaves reconhecidas

O script procura primeiro estas chaves públicas padrão:

- `id_ed25519.pub`
- `id_ecdsa.pub`
- `id_rsa.pub`

Também pode usar outro arquivo `.pub` válido encontrado em `%USERPROFILE%\.ssh`. Arquivos de certificado terminados em `-cert.pub` são ignorados.

Se apenas a chave privada padrão existir, o script tentará reconstruir o arquivo público usando `ssh-keygen -y`.

## Solução de problemas

### O OpenSSH Client não pôde ser instalado

Confirme que o Windows possui acesso à internet e que sua conta pode autorizar operações administrativas. Em seguida, abra o Prompt de Comando como administrador e execute novamente o script.

Em computadores corporativos, a instalação de recursos opcionais pode estar bloqueada por políticas da organização. Nesse caso, solicite a instalação do OpenSSH Client ao administrador do equipamento.

### A conexão foi recusada

Confirme estes dados:

- O endereço do servidor está correto.
- O serviço SSH está ativo no servidor.
- A porta SSH está liberada no firewall.
- A conta informada existe no servidor.

O script usa a porta SSH padrão `22`.

### A senha foi recusada

Verifique se a senha pertence ao usuário informado e se o servidor permite autenticação por senha. Alguns servidores aceitam somente chaves previamente autorizadas ou bloqueiam acesso direto do usuário `root`.

### A chave foi copiada, mas a conexão final falhou

A chave já estará instalada no servidor. Tente a conexão manual para visualizar a mensagem completa:

```batch
ssh usuario@endereco
```

### A chave privada pede uma senha durante a reconstrução

Isso acontece quando a chave privada existente possui uma passphrase. Informe a passphrase correta para permitir que `ssh-keygen` reconstrua o arquivo público.

## Segurança

A chave criada pelo script não possui passphrase, conforme o fluxo automatizado do utilitário. Proteja sua conta do Windows e não compartilhe o arquivo da chave privada, como `%USERPROFILE%\.ssh\id_ed25519`.

Somente o arquivo público terminado em `.pub` deve ser copiado ou compartilhado.
