# Édition Windows de SetupVibe (Beta)

> Configuration des utilitaires Windows natifs — v0.41.6

L'Édition Windows (Beta) configure un ensemble ciblé d'utilitaires Windows natifs, avec WinGet comme source principale et Chocolatey pour les paquets indisponibles via WinGet.

## Prérequis

- Windows 10 version 1809 (build 17763) ou ultérieure, ou Windows 11
- Une édition de bureau Windows 64 bits ; Windows Server n'est pas pris en charge
- Windows PowerShell 5.1 ou ultérieur
- Un compte administrateur
- Un accès à Internet

## Éléments Installés

- Demande s'il faut désactiver le contrôle de compte d'utilisateur (UAC), avec `Yes` comme choix par défaut, et définit la stratégie globale `EnableLUA` sur `0` après confirmation
- Client OpenSSH
- WinGet via le processus officiel de réparation `Microsoft.WinGet.Client` s'il est absent
- Chocolatey via son script d'amorçage officiel s'il est absent
- Git, 7-Zip, Wget, FFmpeg, ImageMagick et GitHub CLI
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf et jq
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy et RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font et JetBrains Mono Nerd Font

Le programme d'installation est idempotent : les paquets WinGet installés sont détectés et ignorés, tandis que Chocolatey garantit la présence de ses paquets. Les échecs sont enregistrés par paquet afin que les autres installations puissent continuer. Un journal complet est enregistré dans `C:\ProgramData\SetupVibe\Logs`.

Starship et zoxide sont initialisés dans les profils Windows PowerShell et PowerShell 7.

Ce script est exclusivement destiné aux utilitaires Windows natifs. Il n'installe aucun langage de programmation, framework, gestionnaire de runtime, outil CLI d'IA ou WSL. Utilisez `desktop.sh` dans WSL pour configurer un environnement de développement complet.

Docker Desktop est volontairement exclu, car ses moteurs habituels nécessitent WSL 2 ou Hyper-V.

**Avertissement de sécurité :** la désactivation de l'UAC supprime ses avantages de sécurité pour l'ensemble de l'ordinateur. [Microsoft recommande de maintenir cette stratégie activée](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/user-account-control-run-all-administrators-in-admin-approval-mode). SetupVibe modifie ce paramètre uniquement si vous répondez `Yes` ; Windows doit redémarrer pour que la modification prenne effet.

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
6. Répondez `Yes` ou `No` lorsque le script demande s'il faut désactiver l'UAC. Appuyer sur `Entrée` sélectionne le choix par défaut, `Yes`.
7. Gardez les fenêtres PowerShell ouvertes jusqu'à l'affichage du résumé.
8. Redémarrez Windows si cela est demandé pour appliquer la stratégie UAC et les éventuelles modifications de paquets en attente.

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

1. Valide l'édition, la build et l'architecture 64 bits de Windows.
2. Demande les privilèges administrateur via l'UAC.
3. Demande s'il faut désactiver l'UAC, avec `Yes` comme choix par défaut, et définit la stratégie globale de registre `EnableLUA` sur `0` après confirmation.
4. Installe le client OpenSSH, WinGet et Chocolatey si nécessaire.
5. Installe chaque utilitaire Windows indépendamment et continue après les échecs isolés.
6. Configure Starship et zoxide pour Windows PowerShell et PowerShell 7.
7. Affiche un résumé final et l'emplacement du journal complet.

Le processus peut prendre du temps, car les gestionnaires de paquets téléchargent et installent chaque utilitaire séparément.

## Après L'installation

1. Redémarrez Windows lorsque cela est demandé. Si vous avez choisi de désactiver l'UAC, il reste actif jusqu'à la fin de ce redémarrage.
2. Ouvrez Windows Terminal ou PowerShell 7 pour charger le nouveau `PATH`, Starship et zoxide.
3. Effectuez les authentifications initiales requises par GitHub CLI ou Tailscale.

Vérifiez les principaux composants dans un nouveau terminal :

```powershell
winget --version
choco --version
git --version
rg --version
fzf --version
pwsh --version
Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA
```

La dernière commande doit renvoyer `0` après le redémarrage si vous avez répondu `Yes` à la question sur l'UAC. Répondre `No` conserve la stratégie existante et ne réactive pas l'UAC s'il était déjà désactivé.

## Nouvelle Exécution Et Journaux

Le programme est conçu pour être réexécuté. Les paquets WinGet déjà présents sont ignorés, tandis que Chocolatey garantit la présence de ses utilitaires gérés.

Les journaux complets sont enregistrés dans :

```text
C:\ProgramData\SetupVibe\Logs
```

Si un paquet échoue, consultez le résumé final et le journal, corrigez le problème signalé, puis exécutez à nouveau la même commande.

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

Le mode de désinstallation supprime le client OpenSSH, tous les utilitaires WinGet et Chocolatey gérés par SetupVibe, le bloc de profil Starship et zoxide et la configuration Starship générée. Il supprime également les runtimes de langages, les outils de frameworks, les chemins des gestionnaires de runtimes et les paquets npm installés par les versions Beta Windows précédentes, puis réactive l'UAC. WinGet, Chocolatey et les journaux sont conservés.

**Avertissement de désinstallation :** la version Beta actuelle ne détermine pas si le client OpenSSH ou un paquet géré existait avant SetupVibe. Par conséquent, `-Uninstall` supprime le client OpenSSH et tous les paquets de ses listes gérées, y compris les composants qui ont pu être installés séparément avant SetupVibe.

Associez `-Uninstall` à `-Restart` pour redémarrer automatiquement lorsque Windows indique qu'un redémarrage est nécessaire.

## Réactivation De L'UAC

Pour restaurer le comportement de sécurité par défaut de Windows, exécutez la commande suivante dans une session PowerShell administrateur, puis redémarrez Windows :

```powershell
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -PropertyType DWord -Value 1 -Force
```

## Portée Et Limites

- Windows Server et les éditions 32 bits de Windows sont refusés lors des contrôles initiaux.
- Lorsqu'elle est confirmée, la désactivation de l'UAC s'applique à l'ensemble de l'ordinateur et réduit la sécurité de Windows. Une stratégie de domaine ou de gestion de l'appareil peut restaurer le paramètre après sa modification par le script.
- WSL n'est ni installé ni configuré. Exécutez `desktop.sh` dans une distribution WSL existante pour configurer l'environnement Linux.
- Aucun langage de programmation, framework, gestionnaire de runtime ou outil CLI d'IA n'est installé.
- Docker Desktop et un moteur Docker local ne sont pas installés.
