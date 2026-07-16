@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Utilitario Windows 11 para copiar a chave SSH para um servidor remoto.

if not defined USERPROFILE (
    echo ERRO: Nao foi possivel localizar o perfil do usuario atual.
    exit /b 1
)

where ssh >nul 2>&1
if errorlevel 1 (
    call :install_openssh_client
    if errorlevel 1 exit /b 1
    set "PATH=%PATH%;%SystemRoot%\System32\OpenSSH"
    where ssh >nul 2>&1
    if errorlevel 1 (
        echo ERRO: O OpenSSH Client foi instalado, mas o comando ssh ainda nao esta disponivel.
        echo Feche este terminal, abra um novo e execute o arquivo novamente.
        exit /b 1
    )
)

where ssh-keygen >nul 2>&1
if errorlevel 1 (
    echo ERRO: O comando ssh-keygen nao foi encontrado.
    echo Instale o recurso OpenSSH Client do Windows 11 e tente novamente.
    exit /b 1
)

set "SSH_DIR=%USERPROFILE%\.ssh"
set "PUBLIC_KEY="

if not exist "%SSH_DIR%" (
    mkdir "%SSH_DIR%" >nul 2>&1
    if errorlevel 1 (
        echo ERRO: Nao foi possivel criar o diretorio "%SSH_DIR%".
        exit /b 1
    )
)

call :find_public_key
if not defined PUBLIC_KEY (
    call :recover_public_key
    if errorlevel 1 exit /b 1
)

if defined PUBLIC_KEY (
    for %%F in ("%PUBLIC_KEY%") do echo Chave SSH encontrada: %%~nxF
) else (
    call :create_new_key
    if errorlevel 1 exit /b 1
)

ssh-keygen -l -f "%PUBLIC_KEY%" >nul 2>&1
if errorlevel 1 (
    echo ERRO: A chave publica "%PUBLIC_KEY%" nao e valida.
    exit /b 1
)

echo.
set "REMOTE="
set /p "REMOTE=Informe o servidor remoto no formato usuario@endereco: "
if not defined REMOTE (
    echo ERRO: O endereco remoto nao pode ficar vazio.
    exit /b 1
)
setlocal EnableDelayedExpansion

echo.
echo Copiando a chave para !REMOTE!...
echo A senha do servidor sera solicitada pelo comando ssh.
type "!PUBLIC_KEY!" | ssh "!REMOTE!" "umask 077; mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && cat > ~/.ssh/.setupvibe_key.tmp && (grep -qxFf ~/.ssh/.setupvibe_key.tmp ~/.ssh/authorized_keys || cat ~/.ssh/.setupvibe_key.tmp >> ~/.ssh/authorized_keys); status=$?; rm -f ~/.ssh/.setupvibe_key.tmp; exit $status"
if errorlevel 1 (
    echo.
    echo ERRO: Nao foi possivel copiar a chave SSH para !REMOTE!.
    exit /b 1
)

echo.
echo Chave copiada com sucesso para !REMOTE!.
echo Conectando ao servidor...
ssh "!REMOTE!"
if errorlevel 1 (
    echo.
    echo ERRO: A chave foi copiada, mas a conexao com !REMOTE! falhou.
    exit /b 1
)

exit /b 0

:install_openssh_client
where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo ERRO: O OpenSSH Client nao esta instalado e o PowerShell nao foi encontrado.
    exit /b 1
)

echo O OpenSSH Client do Windows 11 nao esta instalado.
echo Confirme a solicitacao do Controle de Conta de Usuario para instala-lo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$process = Start-Process -FilePath dism.exe -Verb RunAs -Wait -PassThru -ArgumentList '/Online','/Add-Capability','/CapabilityName:OpenSSH.Client~~~~0.0.1.0'; if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) { exit 0 }; exit 1"
if errorlevel 1 (
    echo ERRO: Nao foi possivel instalar o OpenSSH Client do Windows 11.
    echo Execute este arquivo como administrador e tente novamente.
    exit /b 1
)
echo OpenSSH Client instalado com sucesso.
exit /b 0

:find_public_key
for %%K in (id_ed25519.pub id_ecdsa.pub id_rsa.pub) do (
    if not defined PUBLIC_KEY if exist "%SSH_DIR%\%%K" call :consider_public_key "%SSH_DIR%\%%K"
)
for /f "delims=" %%K in ('dir /b /a-d /o:n "%SSH_DIR%\*.pub" 2^>nul') do (
    if not defined PUBLIC_KEY call :consider_public_key "%SSH_DIR%\%%K"
)
exit /b 0

:consider_public_key
set "KEY_NAME=%~nx1"
if /i "%KEY_NAME:~-9%"=="-cert.pub" exit /b 0
ssh-keygen -l -f "%~1" >nul 2>&1
if not errorlevel 1 set "PUBLIC_KEY=%~1"
exit /b 0

:recover_public_key
if exist "%SSH_DIR%\id_ed25519" (
    call :rebuild_public_key "%SSH_DIR%\id_ed25519"
    exit /b
)
if exist "%SSH_DIR%\id_ecdsa" (
    call :rebuild_public_key "%SSH_DIR%\id_ecdsa"
    exit /b
)
if exist "%SSH_DIR%\id_rsa" (
    call :rebuild_public_key "%SSH_DIR%\id_rsa"
    exit /b
)
exit /b 0

:rebuild_public_key
for %%F in ("%~1") do echo A chave privada %%~nxF existe, mas a chave publica esta ausente.
echo Tentando reconstruir a chave publica...
ssh-keygen -y -f "%~1" > "%~1.pub"
if errorlevel 1 (
    del "%~1.pub" >nul 2>&1
    echo ERRO: Nao foi possivel reconstruir a chave publica.
    exit /b 1
)
set "PUBLIC_KEY=%~1.pub"
exit /b 0

:create_new_key
echo Nenhuma chave SSH foi encontrada para o usuario atual.
echo Criando uma nova chave Ed25519 sem senha com os valores padrao...

ssh-keygen -q -t ed25519 -f "%SSH_DIR%\id_ed25519" -N ""
if errorlevel 1 (
    echo ERRO: Nao foi possivel criar a nova chave SSH.
    exit /b 1
)
set "PUBLIC_KEY=%SSH_DIR%\id_ed25519.pub"
if not exist "%SSH_DIR%\id_ed25519.pub" (
    echo ERRO: A chave publica nao foi criada em "%SSH_DIR%\id_ed25519.pub".
    exit /b 1
)
echo Nova chave SSH criada: id_ed25519.pub
exit /b 0
