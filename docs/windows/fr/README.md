# Édition Windows de SetupVibe (Beta)

> Configuration des utilitaires Windows natifs — v0.41.6

L'Édition Windows (Beta) configure un ensemble ciblé d'utilitaires Windows natifs, avec WinGet comme source principale et Chocolatey pour les paquets indisponibles via WinGet.

## Prérequis

- Windows 11 version 22H2 (build 22621) ou ultérieure
- Une édition de bureau Windows 64 bits ; Windows 10 et Windows Server ne sont pas pris en charge
- Windows PowerShell 5.1 ou ultérieur
- Un compte administrateur
- Un accès à Internet

## Éléments Installés

- Client OpenSSH
- WinGet via le processus officiel de réparation `Microsoft.WinGet.Client` s'il est absent
- Chocolatey via son script d'amorçage officiel s'il est absent
- Système WSL de base sans distribution Linux, avec WSL 2 par défaut
- Réseau WSL en mode miroir avec accès VPN/LAN, tunneling DNS, intégration du proxy Windows, trafic entrant autorisé dans le pare-feu Hyper-V, récupération automatique de la mémoire et disques virtuels épars
- Git, 7-Zip, Wget, FFmpeg, ImageMagick et GitHub CLI
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf et jq
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy et RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font et JetBrains Mono Nerd Font

Le programme d'installation est idempotent : les paquets WinGet installés sont détectés et ignorés, tandis que Chocolatey garantit la présence de ses paquets. Les échecs sont enregistrés par paquet afin que les autres installations puissent continuer. Un journal complet est enregistré dans `C:\ProgramData\SetupVibe\Logs`.

Starship et zoxide sont initialisés dans les profils Windows PowerShell et PowerShell 7.

Ce script est exclusivement destiné aux utilitaires Windows natifs et au système WSL de base. Il n'installe aucune distribution Linux, aucun langage de programmation, framework, gestionnaire de runtime ou outil CLI d'IA. Après avoir installé une distribution séparément, utilisez `desktop.sh` dans celle-ci pour configurer un environnement de développement complet.

Si `%USERPROFILE%\.wslconfig` existe déjà, SetupVibe le sauvegarde avant d'appliquer les paramètres de développement par défaut. `-Uninstall` restaure cette sauvegarde ainsi que les états précédents des fonctionnalités et du pare-feu WSL.

Docker Desktop est volontairement exclu. SetupVibe prépare WSL 2, mais n'installe ni Docker ni distribution Linux.

**Avertissement sur le réseau WSL :** SetupVibe autorise le trafic entrant vers WSL sur tous les ports via le pare-feu Hyper-V afin que les futurs services soient accessibles depuis le réseau local et les VPN compatibles. Limitez cette stratégie avec des règles de pare-feu Hyper-V spécifiques sur les réseaux non fiables. Un futur service Linux doit écouter sur `0.0.0.0` ou sur l'interface réseau appropriée pour accepter les connexions distantes.

## Installation En Une Commande

Il s'agit de l'équivalent Windows de `curl -sSL desktop.setupvibe.dev | bash`.

Pour le moment, les URL du programme d'installation Windows ciblent la branche de développement `windows`.

1. Ouvrez le menu Démarrer.
2. Recherchez **Windows PowerShell** et ouvrez-le. Le démarrage en tant qu'administrateur est facultatif, car le script demande automatiquement une élévation via l'UAC.
3. Examinez le fichier [`desktop.ps1`](../../../desktop.ps1) du dépôt avant d'exécuter du code distant.
4. Collez la commande suivante et appuyez sur `Entrée` :

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 | iex
   ```

5. Acceptez la demande UAC de Windows.
6. Gardez les fenêtres PowerShell ouvertes jusqu'à l'affichage du résumé.
7. Redémarrez Windows si cela est demandé pour appliquer les modifications de composants ou de paquets en attente.

La commande télécharge `desktop.ps1` depuis le dépôt officiel de SetupVibe et l'exécute dans la session PowerShell actuelle. Lorsqu'une élévation est nécessaire, le programme télécharge une copie temporaire et continue dans une session administrateur.

## Installation Locale

Pour télécharger le script avant de l'exécuter :

```powershell
$scriptPath = Join-Path $HOME 'Downloads\desktop.ps1'
Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 -OutFile $scriptPath
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
```

Depuis un clone existant de ce dépôt :

```powershell
Set-Location C:\chemin\vers\setupvibe
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1
```

## Déroulement

Pendant l'exécution, le programme :

1. Valide Windows 11 22H2 ou ultérieur et l'architecture 64 bits.
2. Demande les privilèges administrateur via l'UAC.
3. Attend les processus concurrents de maintenance et d'installation, refuse les redémarrages en attente, démarre les services requis, vérifie la stratégie WSUS et valide le magasin de composants Windows.
4. Installe le client OpenSSH si nécessaire.
5. Copie les scripts auxiliaires Windows de SetupVibe dans `%USERPROFILE%\.setupvibe\bin` et ajoute ce répertoire au `PATH` de l'utilisateur.
6. Installe le système WSL de base sans distribution Linux et définit WSL 2 par défaut.
7. Applique à WSL le réseau en mode miroir, l'accès VPN/LAN, le DNS, le proxy, le pare-feu, la récupération de mémoire et les disques VHD épars.
8. Installe WinGet et Chocolatey si nécessaire.
9. Installe chaque utilitaire Windows indépendamment et continue après les échecs isolés.
10. Configure Starship et zoxide pour Windows PowerShell et PowerShell 7.
11. Affiche un résumé final et l'emplacement du journal complet.

Le processus peut prendre du temps, car les gestionnaires de paquets téléchargent et installent chaque utilitaire séparément.

## Après L'installation

1. Redémarrez Windows lorsque cela est demandé pour terminer les modifications de composants ou de paquets en attente.
2. Ouvrez Windows Terminal ou PowerShell 7 pour charger le nouveau `PATH`, Starship et zoxide.
3. Effectuez les authentifications initiales requises par GitHub CLI ou Tailscale.

Les scripts auxiliaires SetupVibe sont stockés dans `%USERPROFILE%\.setupvibe\bin`. Le noyau `ssh_copy_id.ps1` et son lanceur minimal `ssh_copy_id.cmd` peuvent être lancés avec `ssh_copy_id` depuis toute nouvelle session PowerShell, Windows Terminal ou Invite de commandes.

Vérifiez les principaux composants dans un nouveau terminal :

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
```

`wsl --list --verbose` doit indiquer qu'aucune distribution n'est installée, sauf si la machine en possédait déjà une. La sortie du pare-feu doit afficher `DefaultInboundAction` avec la valeur `Allow`.

## Nouvelle Exécution Et Journaux

Le programme est conçu pour être réexécuté. Les scripts auxiliaires SetupVibe sont actualisés, les paquets WinGet déjà présents sont ignorés et Chocolatey garantit la présence de ses utilitaires gérés.

Les journaux complets de transcription et les journaux DISM dédiés sont enregistrés dans :

```text
C:\ProgramData\SetupVibe\Logs
```

Si un paquet échoue, consultez le résumé final et le journal, corrigez le problème signalé, puis exécutez à nouveau la même commande.

## Sécurité De Windows Servicing

Avant d'installer ou de supprimer des composants, SetupVibe attend jusqu'à 20 minutes les processus actifs `DISM`, `dismhost`, `TiWorker`, Windows Installer, WinGet et Chocolatey. Il refuse également les redémarrages en attente de Component Based Servicing ou Windows Update, démarre `TrustedInstaller` et, pendant l'installation, démarre `wuauserv` et `bits`, puis exécute `DISM /Online /Cleanup-Image /CheckHealth`.

SetupVibe ne termine jamais de force les processus de maintenance Windows. Si l'attente expire, il affiche les noms et PID et s'arrête avant toute modification. Redémarrez Windows et relancez le programme. Cela protège le magasin de composants contre les opérations partielles de paquets ou de fonctionnalités facultatives.

Sur les ordinateurs gérés par WSUS, les fonctionnalités à la demande telles qu'OpenSSH peuvent encore échouer lorsque la source d'entreprise ne fournit pas le contenu facultatif. L'erreur OpenSSH indique son fichier dédié `dism-OpenSSH-Client-*.log`.

## Options

Redémarrez automatiquement Windows après une installation entièrement réussie lorsque le système indique qu'un redémarrage est nécessaire :

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Restart
```

Sans `-Restart`, le programme ne redémarre jamais Windows automatiquement.

Modifiez le délai maximal d'attente des processus concurrents de maintenance et d'installation, dont la valeur par défaut est de 20 minutes :

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -InstallerWaitMinutes 45
```

`-InstallerWaitMinutes` accepte les valeurs de `1` à `120` et ne termine aucun processus lorsque le délai expire.

### Désinstallation

Supprimez tous les utilitaires et toutes les configurations gérés par l'Édition Windows depuis un clone local :

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1 -Uninstall
```

Ou exécutez le programme de désinstallation depuis la branche `windows` :

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Uninstall
```

Le mode de désinstallation supprime le client OpenSSH, les fichiers gérés par SetupVibe dans `%USERPROFILE%\.setupvibe\bin` et leur entrée dans le `PATH` utilisateur, restaure les états précédents des fonctionnalités facultatives et du pare-feu WSL, supprime la configuration WSL appliquée par SetupVibe, supprime tous les utilitaires WinGet et Chocolatey gérés par SetupVibe et supprime le bloc de profil Starship et zoxide ainsi que la configuration Starship générée. Il supprime également les runtimes de langages, les outils de frameworks, les chemins des gestionnaires de runtimes et les paquets npm installés par les versions Beta Windows précédentes. Les distributions Linux existantes ne sont pas supprimées. WinGet, Chocolatey, les journaux et les fichiers sans rapport dans `%USERPROFILE%\.setupvibe` sont conservés.

**Avertissement de désinstallation :** la version Beta actuelle ne détermine pas si le client OpenSSH ou un paquet géré existait avant SetupVibe. Par conséquent, `-Uninstall` supprime le client OpenSSH et tous les paquets de ses listes gérées, y compris les composants qui ont pu être installés séparément avant SetupVibe.

Associez `-Uninstall` à `-Restart` pour redémarrer automatiquement lorsque Windows indique qu'un redémarrage est nécessaire.

## Portée Et Limites

- Windows 10, Windows Server, les builds de Windows 11 antérieures à 22621 et les éditions 32 bits sont refusés lors des contrôles initiaux.
- WSL est installé et configuré pour WSL 2, le réseau en mode miroir via VPN/LAN et les optimisations de développement courantes, mais aucune distribution Linux n'est installée.
- Aucun langage de programmation, framework, gestionnaire de runtime ou outil CLI d'IA n'est installé.
- Docker Desktop et un moteur Docker local ne sont pas installés.
