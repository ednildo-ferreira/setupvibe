# Édition Windows de SetupVibe (Beta)

> Configuration des utilitaires Windows natifs — v0.41.6

L'Édition Windows (Beta) configure des utilitaires Windows natifs, Python et Node.js, avec WinGet comme source principale et Chocolatey pour les paquets indisponibles via WinGet.

## Prérequis

- Windows 11 version 22H2 (build 22621) ou ultérieure
- Une édition de bureau Windows x64 (AMD64) ; Windows 32 bits, Windows sur ARM, Windows 10 et Windows Server ne sont pas pris en charge
- Windows PowerShell 5.1 ou ultérieur
- Un compte administrateur
- Un accès à Internet

## Éléments Installés

- Derniers client et serveur Microsoft Win32-OpenSSH officiels via le MSI Win64 x64 signé
- WinGet via le processus officiel de réparation `Microsoft.WinGet.Client` s'il est absent
- Chocolatey via son script d'amorçage officiel s'il est absent
- Python 3.14 directement via l'installateur officiel de `python.org` et Node.js LTS directement via le MSI officiel de `nodejs.org`, avec `python`, `pip`, `node`, `npm` et `npx` dans le `PATH` de la machine pour Claude et Codex
- Système WSL de base sans distribution Linux, avec WSL 2 par défaut
- Réseau WSL en mode miroir avec accès VPN/LAN, tunneling DNS, intégration du proxy Windows, trafic entrant autorisé dans le pare-feu Hyper-V, récupération automatique de la mémoire et disques virtuels épars
- Git, 7-Zip, Wget, FFmpeg, ImageMagick et GitHub CLI (`gh`)
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf et jq
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy et RustScan
- PowerShell 7, Windows Terminal, FiraCode Nerd Font et JetBrains Mono Nerd Font

Le programme d'installation est idempotent : les paquets WinGet installés sont détectés et ignorés, Chocolatey garantit la présence de ses paquets et les installateurs officiels de Python et Node.js sont réappliqués en toute sécurité. Les échecs sont enregistrés par paquet afin que les autres installations puissent continuer. Un journal complet est enregistré dans `C:\ProgramData\SetupVibe\Logs`.

Les profils d'origine de Windows PowerShell et PowerShell 7, ainsi que leurs stratégies d'exécution persistantes, sont conservés. Starship et ZSH ne sont pas installés ; zoxide reste disponible uniquement comme utilitaire CLI, sans initialisation automatique.

Python et Node.js sont les seuls runtimes de programmation installés par ce script. Il n'installe aucune distribution Linux, aucun framework, gestionnaire de runtime, outil CLI d'IA ou autre écosystème de langage. Après avoir installé une distribution séparément, utilisez `desktop.sh` dans celle-ci pour configurer un environnement de développement complet.

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

1. Valide Windows 11 22H2 ou ultérieur et l'architecture x64.
2. Demande les privilèges administrateur via l'UAC.
3. Répertorie les processus d'installation concurrents et demande s'ils doivent être arrêtés. En cas d'acceptation, il essaie normalement, force ceux qui restent et exécute `sfc.exe /scannow` ; en cas de refus, il attend ENTER et se ferme.
4. Refuse les redémarrages en attente, démarre les services requis, exécute `sfc.exe /scannow` s'il ne l'a pas déjà été, vérifie la stratégie WSUS et valide le magasin de composants Windows.
5. Résout le dernier MSI x64 officiel de Microsoft Win32-OpenSSH sans utiliser l'API des releases GitHub, valide sa signature, force l'installation du client et du serveur, configure le `PATH` de la machine, valide `ssh.exe -V`, démarre automatiquement `sshd` et autorise le trafic TCP/22 entrant.
6. Copie les scripts auxiliaires Windows de SetupVibe dans `%USERPROFILE%\.setupvibe\bin` et ajoute ce répertoire au `PATH` de l'utilisateur.
7. Installe le système WSL de base sans distribution Linux et définit WSL 2 par défaut.
8. Applique à WSL le réseau en mode miroir, l'accès VPN/LAN, le DNS, le proxy, le pare-feu, la récupération de mémoire et les disques VHD épars.
9. Installe WinGet et Chocolatey si nécessaire.
10. Télécharge Python 3.14 depuis `python.org` et Node.js LTS depuis `nodejs.org` sans WinGet ni Chocolatey, valide leurs signatures Authenticode et le SHA-256 officiel de Node.js, place leurs répertoires au début du `PATH` de la machine et valide leurs commandes pour Claude et Codex.
11. Installe chaque utilitaire Windows restant indépendamment et continue après les échecs isolés.
12. Supprime les anciens blocs Starship et zoxide ainsi que Starship lui-même installés par les versions Beta précédentes, et conserve le profil et la stratégie d'exécution PowerShell d'origine.
13. Affiche un résumé final et l'emplacement du journal complet.

Le processus peut prendre du temps, car les gestionnaires de paquets téléchargent et installent chaque utilitaire séparément.

## Après L'installation

1. Redémarrez Windows lorsque cela est demandé pour terminer les modifications de composants ou de paquets en attente.
2. Ouvrez Windows Terminal ou PowerShell 7 pour charger le nouveau `PATH`.
3. Effectuez les authentifications initiales requises par GitHub CLI ou Tailscale.

Les scripts auxiliaires SetupVibe sont stockés dans `%USERPROFILE%\.setupvibe\bin`. Le noyau `ssh_copy_id.ps1` et son lanceur minimal `ssh_copy_id.cmd` peuvent être lancés avec `ssh_copy_id` depuis toute nouvelle session PowerShell, Windows Terminal ou Invite de commandes.

Vérifiez les principaux composants dans un nouveau terminal :

```powershell
winget --version
choco --version
git --version
gh --version
rg --version
fzf --version
pwsh --version
python --version
pip --version
node --version
npm --version
npx --version
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

Avant d'installer ou de supprimer des composants, SetupVibe vérifie les processus actifs `DISM`, `dismhost`, `TiWorker`, Windows Installer, les programmes d'installation Windows Update, WinGet, Chocolatey et d'autres processus d'installation connus. Il répertorie leurs noms et PID et demande l'autorisation avant de les arrêter. En cas d'acceptation, il utilise d'abord `Stop-Process`, force les processus restants, puis exécute `sfc.exe /scannow`. En cas de refus, il attend ENTER et se ferme sans lancer une autre opération de maintenance. Il refuse ensuite les redémarrages en attente de Component Based Servicing ou Windows Update, démarre les services requis et exécute `DISM /Online /Cleanup-Image /CheckHealth`.

Les détails du Vérificateur des fichiers système sont enregistrés dans `C:\Windows\Logs\CBS\CBS.log`.

Si un processus reste actif après les tentatives d'arrêt normal et forcé, SetupVibe termine la vérification SFC, attend ENTER et se ferme en recommandant de redémarrer le PC.

OpenSSH n'utilise pas les fonctionnalités à la demande de Windows ni l'API des releases GitHub. SetupVibe résout la page officielle `releases/latest` et ses assets étendus, accepte uniquement le MSI x64 `OpenSSH-Win64-*.msi`, valide sa signature Authenticode, installe `ADDLOCAL=Client,Server`, force la réparation des fichiers installés, place le répertoire d'installation au début du `PATH` de la machine, configure `sshd` pour un démarrage automatique, démarre le service, active la règle de pare-feu `OpenSSH-Server-In-TCP` pour le trafic TCP/22 entrant et enregistre `openssh-client-msi-*.log` et `openssh-client-repair-*.log` dans `C:\ProgramData\SetupVibe\Logs`.

## Options

Redémarrez automatiquement Windows après une installation entièrement réussie lorsque le système indique qu'un redémarrage est nécessaire :

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Restart
```

Sans `-Restart`, le programme ne redémarre jamais Windows automatiquement.

### Désinstallation

Supprimez tous les utilitaires et toutes les configurations gérés par l'Édition Windows depuis un clone local :

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1 -Uninstall
```

Ou exécutez le programme de désinstallation depuis la branche `windows` :

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Uninstall
```

Le mode de désinstallation supprime le client et le serveur OpenSSH, Python et Node.js via leurs programmes de désinstallation officiels, les fichiers gérés par SetupVibe dans `%USERPROFILE%\.setupvibe\bin` et leur entrée dans le `PATH` utilisateur, restaure les états précédents des fonctionnalités facultatives et du pare-feu WSL, supprime la configuration WSL appliquée par SetupVibe, supprime tous les utilitaires WinGet et Chocolatey gérés par SetupVibe et supprime les entrées des runtimes du `PATH` de la machine ainsi que les anciens blocs Starship et zoxide créés par SetupVibe. Il supprime également les anciens outils de frameworks, les chemins des gestionnaires de runtimes et les paquets npm installés par les versions Beta Windows précédentes. Les distributions Linux existantes ne sont pas supprimées. WinGet, Chocolatey, les journaux et les fichiers sans rapport dans `%USERPROFILE%\.setupvibe` sont conservés.

**Avertissement de désinstallation :** la version Beta actuelle ne détermine pas si le client et le serveur OpenSSH ou un paquet géré existaient avant SetupVibe. Par conséquent, `-Uninstall` supprime le produit MSI OpenSSH et tous les paquets de ses listes gérées, y compris les composants qui ont pu être installés séparément avant SetupVibe.

Associez `-Uninstall` à `-Restart` pour redémarrer automatiquement lorsque Windows indique qu'un redémarrage est nécessaire.

## Portée Et Limites

- Windows 10, Windows Server, les builds de Windows 11 antérieures à 22621, Windows 32 bits et Windows sur ARM sont refusés ; seul x64 est pris en charge.
- WSL est installé et configuré pour WSL 2, le réseau en mode miroir via VPN/LAN et les optimisations de développement courantes, mais aucune distribution Linux n'est installée.
- Starship et ZSH ne sont pas installés, les profils PowerShell ne sont pas personnalisés et aucune modification persistante de la stratégie d'exécution n'est effectuée ; zoxide reste uniquement disponible comme utilitaire CLI.
- Python 3.14 et Node.js LTS sont installés pour l'automatisation locale, Claude et Codex ; aucun autre langage de programmation, framework, gestionnaire de runtime ou outil CLI d'IA n'est installé.
- Docker Desktop et un moteur Docker local ne sont pas installés.
