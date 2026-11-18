# Utiliser VS Code Remote - SSH avec le Raspberry Pi

Remote - SSH permet d'ouvrir dans VS Code un dossier qui se trouve sur le Raspberry Pi. Le code et les commandes du terminal sont alors exécutés sur le Pi ; l'extension ne copie pas automatiquement le dossier Windows vers celui-ci.

## 1. Préparer le Raspberry Pi

Pour un usage de développement, utilisez de préférence **Raspberry Pi OS** et vérifiez que :

- le Pi est démarré et connecté au même réseau que le PC ;
- SSH est activé (dans Raspberry Pi Imager ou dans les réglages du système) ;
- vous connaissez le nom d'utilisateur créé à l'installation et le nom d'hôte ou l'adresse IP du Pi.

Dans les exemples ci-dessous, `admin` et `ensearcade.local` sont des valeurs d'exemple à remplacer par vos propres valeurs. Sous Raspberry Pi OS, le nom d'hôte `.local` peut être utilisé si sa résolution fonctionne sur votre réseau.

## 2. Déclarer le Pi dans la configuration SSH de Windows

Dans VS Code, ouvrez la palette de commandes avec **Ctrl+Maj+P**, puis choisissez **Remote-SSH: Open SSH Configuration File...** et ouvrez le fichier `config` de votre dossier utilisateur Windows (généralement `C:\Users\<votre-nom>\.ssh\config`). Ajoutez :

```sshconfig
Host ensearcade
    HostName ensearcade.local
    User admin
    Port 22
```

Remplacez `HostName` par l'adresse IP du Pi si le nom `.local` ne fonctionne pas, et `User` par le compte configuré sur le Pi. Ce fichier est propre à votre PC : ne le placez pas dans le dépôt et n'y inscrivez jamais de mot de passe.

Vous pouvez d'abord tester la connexion dans le terminal Windows :

```powershell
ssh ensearcade
```

À la première connexion, vérifiez l'empreinte affichée puis confirmez-la si vous reconnaissez votre Pi. Saisissez ensuite le mot de passe du compte du Pi.

## 3. Ouvrir le dossier du projet sur le Pi

Dans VS Code, faites **Ctrl+Maj+P** > **Remote-SSH: Connect to Host...** > **ensearcade**. Choisissez **Linux** si VS Code le demande. Une nouvelle fenêtre s'ouvre et installe son composant serveur sur le Pi.

Pour obtenir une copie du dépôt sur le Pi, ouvrez le terminal intégré de cette fenêtre (**Terminal > New Terminal**) et exécutez :

```bash
mkdir -p ~/projets
cd ~/projets
git clone https://github.com/NewCalBoy/EnseArcade.git
```

Puis choisissez **File > Open Folder...** et ouvrez `/home/admin/projets/EnseArcade` (adaptez `admin` à votre nom d'utilisateur). Si le dépôt est déjà présent sur le Pi, ouvrez directement son chemin existant au lieu de le cloner à nouveau.

Le dépôt contient actuellement le README, le guide `EnseArcadeV1.md` et des médias ; il ne contient pas encore le code de l'application de la borne.

## 4. Travailler et synchroniser le projet

Les modifications faites dans cette fenêtre VS Code sont enregistrées sur le Pi. Le terminal intégré est également connecté au Pi. Pour récupérer les changements publiés sur GitHub :

```bash
cd ~/projets/EnseArcade
git pull
```

Pour publier vos changements, utilisez votre flux Git habituel (`git status`, `git add`, `git commit`, puis `git push`). Si vous modifiez aussi une copie locale du projet sur Windows, synchronisez-la avec Git : Remote - SSH ne synchronise pas les deux dossiers automatiquement. Évitez de modifier simultanément le même fichier dans les deux copies.

> **À noter :** Remote - SSH est destiné à Raspberry Pi OS ou à une distribution Linux comparable. Batocera et Recalbox peuvent avoir un accès SSH différent ou limité ; ils sont généralement moins adaptés à l'édition du système avec VS Code. N'ajoutez jamais de clé privée, mot de passe ou autre secret au dépôt.

## 5. Vérifier les manettes et lancer le script de démarrage

Ces commandes sont à entrer dans le terminal Linux du Pi (par exemple le terminal intégré à VS Code connecté en Remote - SSH), pas dans PowerShell sur Windows.

`ls` liste des fichiers ou périphériques ; `cd` change de dossier. Il n'est pas nécessaire de faire `cd` dans `/dev/input` pour vérifier les manettes : on peut donner directement leur chemin à `ls`.

```bash
ls /dev/input/js*
```

Les résultats sont généralement `/dev/input/js0` et `/dev/input/js1`. Chaque numéro correspond à un périphérique de joystick, mais ne garantit pas à lui seul quel joueur il représente. Si aucun périphérique n'apparaît, Linux ne détecte pas les manettes via l'interface joystick `js`.

Pour afficher les événements d'une manette, lancez :

```bash
jstest --event /dev/input/js0
```

Bougez le levier et appuyez sur les boutons pour voir les événements, puis quittez avec **Ctrl+C**. Répétez avec `/dev/input/js1` s'il existe. Si `jstest` n'est pas installé sur Raspberry Pi OS, installez-le avec :

```bash
sudo apt update
sudo apt install joystick
```

Le script `demarrage-borne.sh` attend les événements de boutons et de leviers exposés dans `/dev/input/js*`. Un bouton configuré comme touche clavier ne sera pas détecté par cette version. Avant de le lancer, vérifiez que le fichier a bien été copié dans le dossier du projet sur le Pi.

Depuis le dossier du projet sur le Pi, rendez le script exécutable puis lancez-le :

```bash
cd ~/projets/EnseArcade
chmod +x demarrage-borne.sh
./demarrage-borne.sh
```

Par défaut, le script cherche la vidéo dans `/home/admin/RetroPie/splashscreens/intro_ensearcade.mp4`. Si elle se trouve ailleurs, indiquez son chemin après le nom du script, par exemple :

```bash
./demarrage-borne.sh "$HOME/projets/EnseArcade/media/Intro_arcade_Vfinale.mp4"
```
