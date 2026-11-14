# 🎮 Guide Complet : Configuration & Modernisation d'une Borne d'Arcade

Ce document rassemble l'ensemble des procédures pour configurer, automatiser et personnaliser une borne d'arcade fait main. Il est divisé en deux grandes parties : la **Méthode PC (Windows)** et la **Méthode Raspberry Pi (RetroPie / Batocera / Recalbox)**.

---

## 🖥️ PARTIE 1 : La Solution PC (Windows)

Si vous souhaitez conserver votre PC actuel avec vos scripts Python et RomStation, voici comment le transformer en véritable console d'arcade autonome.

### 1.1 Fichier `.py` vs Fichier `.exe`

Pour distribuer ou exécuter votre programme sur un PC d'arcade, la conversion en `.exe` est vivement recommandée :

* **Fichier `.py` (Brut) :** Nécessite une installation complète de Python et de ses dépendances sur le PC. Pratique uniquement pendant la phase de développement.
* **Fichier `.exe` (Recommandé) :** Programme autonome ("Standalone"). Il embarque l'interpréteur Python et toutes les bibliothèques. Il ne nécessite aucune installation préalable sur la machine hôte.

#### Comment compiler votre script Python en `.exe` ?

Dans votre terminal (sur le PC de développement) :

```cmd
# Pour la version finale (Masque la console Windows noire)
pyinstaller --noconsole --onefile mon_programme.py

# Pour la version de test / débogage (Garde la console ouverte pour lire les logs)
pyinstaller --console --onefile mon_programme.py
```

### 1.2 Gestion de la Console et Pop-ups d'Erreur

Lorsqu'on utilise `--noconsole`, le programme n'affiche plus la fenêtre noire en arrière-plan pour garder une interface propre ("effet console de jeu"). Cependant, si une erreur survient, le programme risque de se fermer en silence.

Pour résoudre cela sans réactiver la console, vous pouvez intercepter les erreurs dans votre code Python et afficher un **pop-up graphique d'alerte (message box)** avec la bibliothèque native `tkinter`.

#### Exemple d'intégration dans votre code Python :

```python
import tkinter as tk
from tkinter import messagebox

try:
    # ─── VOTRE CODE DE BORNE D'ARCADE ───
    # Lancement de RomStation, lecture des scores, etc.
    pass

except Exception as e:
    # En cas de problème, on masque la fenêtre principale Tkinter
    root = tk.Tk()
    root.withdraw()
    
    # On affiche une vraie boite de dialogue Windows
    messagebox.showerror(
        "Erreur Arcade", 
        f"Une erreur est survenue lors de l'exécution :\n\n{str(e)}"
    )
```

### 1.3 Transférer le projet sur un autre PC (Structure du Pack)

Un fichier `.exe` compilé avec `--onefile` se décompresse dans un dossier temporaire à chaque exécution. **Il ne faut donc pas y inclure RomStation ou les fichiers de sauvegarde de score**, sous peine de perdre les données à la fermeture.

**Structure recommandée du dossier autonome :**

```text
📁 MaBorneArcade/
├── 📜 mon_programme.exe         <-- Votre programme Python compilé
├── 📁 romstation/               <-- Le dossier complet de RomStation (ROMs + émulateurs)
├── 📁 scores/                   <-- Dossier d'écriture des fichiers de scores (.json / .txt)
└── ⚙️ config.ini                 <-- Fichiers de configuration
```

> ⚠️ **Règle d'or (Chemins Relatifs) :**
> Dans votre script Python, n'utilisez **jamais** de chemins absolus (ex: `C:\Users\Moi\...`). Utilisez `os.path.dirname(os.path.abspath(__file__))` pour que le programme retrouve RomStation quel que soit l'emplacement du dossier sur le PC cible.

### 1.4 Auto-Démarrage et Masquage de Windows

#### Étape A : Connexion Automatique (Auto-Login)
1. Appuyez sur **Windows + R**, tapez `netplwiz` et validez.
2. Décochez *"Les utilisateurs doivent entrer un nom d'utilisateur et un mot de passe..."*.
3. Cliquez sur **Appliquer**, puis renseignez votre mot de passe pour valider.

#### Étape B : Lancement du programme au démarrage
1. Appuyez sur **Windows + R**, tapez `shell:startup` (ouvre le dossier de démarrage caché).
2. Créez un **Raccourci** vers votre fichier `mon_programme.exe` à cet endroit.

#### Étape C : Cacher Windows (Effet Console)
* **Barre des tâches :** Clic droit sur la barre des tâches > *Paramètres* > Activer *Masquer automatiquement la barre des tâches*.
* **Fond d'écran :** Appliquez une image entièrement noire.
* **Sons :** Désactivez le son de démarrage de Windows dans le Panneau de configuration Son.

---

## 🍓 PARTIE 2 : La Solution Raspberry Pi (Pi 4 & Pi 5)

Le Raspberry Pi tourne sous une architecture **ARM** (Linux). Il ne peut pas exécuter les fichiers `.exe` de Windows ni RomStation, mais offre un système dédié au retrogaming léger et optimisé.

### 2.1 Comparatif Matériel (Pi 4 vs Pi 5) & Carte MicroSD

| Composant | Raspberry Pi 4 (4 Go) | Raspberry Pi 5 (4 Go ou 8 Go) |
| :--- | :--- | :--- |
| **Installation OS** | **Simple** : Image RetroPie prête à flasher. | **Avancée** : RetroPie s'installe manuellement sur OS Lite (ou utiliser Batocera / Recalbox natifs). |
| **Consoles supportées** | Arcade, 2D, PS1, N64, Dreamcast. | Tout cela + GameCube, Wii, PS2 (jeux légers) et shaders lourds. |
| **Refroidissement** | Passif ou petit ventilateur. | **Ventilateur actif indispensable** (*Active Cooler*). |
| **Alimentation** | USB-C standard (5V / 3A). | Alimentation officielle recommandée (**5V / 5A - 27W**). |
| **MicroSD** | **SanDisk Extreme** ou **Samsung EVO Plus** (norme A1/A2 U3). Capacité idéale : **128 Go** (16 Go suffisent pour les tests). |

#### Comment vérifier la RAM de son Raspberry Pi ?
Une fois le Pi démarré, ouvrez un terminal (ou connectez-vous en SSH) et tapez :
```bash
free -h
```
Regardez la ligne `Mem:` (colonne `total`) : `3.8G` correspond à **4 Go de RAM**, et `7.4G` à **8 Go de RAM**.

---

### 2.2 Choix du Système & Installation via Raspberry Pi Imager

#### A. Choisir son OS selon son modèle de Pi
* **Sur Raspberry Pi 4 :** Téléchargez l'image officielle RetroPie (`.img.gz`) sur [retropie.org.uk/download](https://retropie.org.uk/download/), puis choisissez l'option **"Use custom" (Utiliser un fichier personnalisé)** dans Raspberry Pi Imager.
* **Sur Raspberry Pi 5 (Option Clés en main) :** Choisissez **Recalbox** (directement dans Raspberry Pi Imager) ou **Batocera** (à télécharger sur *batocera.org* en version Pi 5). Ces systèmes sont 100 % natifs pour le Pi 5.
* **Sur Raspberry Pi 5 (Option RetroPie manuel) :** Flashez **Raspberry Pi OS Lite (64-bit)** (sans bureau graphique, la sortie HDMI reste 100 % fonctionnelle et libère la RAM).

#### B. Comprendre les options de réglage dans Raspberry Pi Imager
Avant de lancer l'écriture de la carte SD, cliquez sur **Modifier les réglages** (*Edit Settings*) :

* **Utilisateur et Mot de passe :** Le compte de connexion au système (ex: `admin` avec un mot de passe sécurisé).
* **Nom d'hôte (*Hostname*) :** Le nom de la borne sur votre réseau local (ex: `ensearcade`). Évitez de mettre le même nom que l'utilisateur pour plus de clarté dans le terminal (`admin@ensearcade`).
* **Configurer le Wi-Fi :** Permet d'entrer vos identifiants box pour télécharger les mises à jour ou installer RetroPie.
* **Activer le SSH :** Indispensable pour piloter le Raspberry Pi à distance depuis un PC Windows sans brancher de clavier sur la borne.
* **Paramètres régionaux :** Définir le fuseau horaire (`Europe/Paris`) et le clavier en français (`fr`).
* **Raspberry Pi Connect :** Service d'accès à distance via navigateur web passant par internet. **À laisser désactivé** pour une borne destinée à fonctionner en local ou hors-ligne.

> 💡 **Bonnes pratiques de test :** Utilisez une petite carte MicroSD dédiée aux tests matériels (affichage HDMI, manettes, température) avant de configurer votre carte SD définitive de 128 Go.

---

### 2.3 Installation manuelle de RetroPie sur Raspberry Pi 5 (Via OS Lite)

Si vous avez flashé **Raspberry Pi OS Lite (64-bit)** sur votre Pi 5 :

1. Connectez-vous en SSH depuis le terminal Windows :
   ```cmd
   ssh admin@ensearcade.local
   ```
2. Mettez à jour le système et installez Git :
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y git lsb-release
   ```
3. Téléchargez et lancez le script d'installation RetroPie :
   ```bash
   cd ~
   git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
   cd RetroPie-Setup
   chmod +x retropie_setup.sh
   sudo ./retropie_setup.sh
   ```
4. Dans le menu bleu, sélectionnez **Basic Install** (comptez 20 à 40 minutes de compilation).
5. Une fois terminé, allez dans **Configuration / tools** > **autostart** > **Start EmulationStation at boot**, puis redémarrez.

---

### 2.4 Gestion du Réseau & Passage en Mode 100 % Hors-Ligne

La configuration Wi-Fi faite dans Raspberry Pi Imager n'est pas définitive :
* **Modifier le Wi-Fi :** Accessible à tout moment via le menu graphique (*Network Settings* sous Batocera/Recalbox) ou en tapant `sudo raspi-config` dans le terminal sous Raspberry Pi OS.
* **Désactiver le Wi-Fi (Sécurité Hors-Ligne) :** Une fois les ROMs et thèmes transférés, vous pouvez désactiver la puce Wi-Fi dans les paramètres système pour isoler totalement la borne d'internet.

---

### 2.5 Formats des ROMs et BIOS

Les jeux se copient sur le Pi via le réseau local (`\\ensearcade\roms` ou `\\RETROPIE\roms`) ou par clé USB.

```text
📁 roms/
├── 📁 snes/      --> (.sfc, .smc, .zip)
├── 📁 megadrive/  --> (.md, .zip)
├── 📁 arcade/    --> (.zip - Ne pas décompresser !)
├── 📁 psx/       --> (.chd, .pbp, .cue/.bin)
└── 📁 dreamcast/ --> (.chd, .cdi)
```

> 📌 **Conseil Format PS1/Dreamcast :** Privilégiez le format **`.chd`**, qui compresse le jeu et réunit toutes les pistes en un seul fichier.
> 📌 **BIOS Obligatoires :** Déposez les fichiers BIOS (ex: `scph5501.bin` pour la PS1) dans le dossier `bios/`.

---

### 2.6 Personnalisation Avancée (Thèmes, Vidéo d'intro & Off-line)

```text
                            [ ALLUMAGE DE LA BORNE ]
                                       │
                                       ▼
                       ┌──────────────────────────────┐
                       │  Vidéo d'attente (MP4)       │
                       │  Se lance en plein écran     │
                       └──────────────┬───────────────┘
                                      │ (Appui sur START)
                                      ▼
                       ┌──────────────────────────────┐
                       │  Interface EmulationStation  │
                       │  Thème fait maison / XML     │
                       │  Vidéos & jaquettes en local │
                       └──────────────────────────────┘
```

#### A. Vidéo d'attente (Splashscreen)
* Format idéal : **MP4 (H.264), 720p ou 1080p**.
* Déposez votre vidéo dans `/home/admin/RetroPie/splashscreens/` (ou `/userdata/splash/` sous Batocera).
* Sélectionnez-la dans le menu **Splashscreen** de l'interface.

#### B. Intégrer un Thème Personnalisé (Fait maison)
* Placez votre dossier de thème (contenant `theme.xml` et vos images PNG) dans `/home/admin/.emulationstation/themes/mon_theme_arcade/` (ou `/userdata/themes/` sous Batocera).
* Activez-le dans **UI Settings** > **Theme Set**.

#### C. Scraping Hors-Ligne (Vidéos de Gameplay sans Internet)
1. Téléchargez [**Skraper**](https://www.skraper.net/) sur votre PC et pointez-le vers votre dossier de ROMs local.
2. Skraper récupère les jaquettes, descriptions et vidéos de gameplay (`.mp4`).
3. Copiez les ROMs et le dossier `media` généré sur le Raspberry Pi : la borne affichera tous les aperçus vidéo en local sans aucune connexion réseau.

---

### 2.7 Administration SSH & Contrôles

#### Connexion SSH & Transfert SFTP
* **Terminal Windows :** `ssh admin@ensearcade.local`
* **Transfert de fichiers système :** Utilisez **FileZilla** ou **WinSCP** en protocole **SFTP** sur le port `22`.

#### Gestion des Contrôles & Boutons Faits Maison
* **Encodeurs USB (Zero Delay) :** Reconnus instantanément comme des manettes standard (100 % compatibles Pi 4 et Pi 5).
* **Hack Clavier :** Reconnu comme un clavier USB standard.
* **Branchement GPIO Direct :** Sur Pi 4, utilisez `mk_arcade_joystick_rpi` ou `Retrogame`. Sur Pi 5 (puce RP1), privilégiez un encodeur USB ou les pilotes GPIO compatibles noyau récent (`gpiod`).

---

## 🔗 Liens et Ressources Utiles

* 📖 **Documentation Officielle RetroPie :** [retropie.org.uk/docs/](https://retropie.org.uk/docs/)
* 🛠️ **Logiciel de Scraping (Skraper) :** [skraper.net](https://www.skraper.net/)
* 📦 **Outil de Flash SD (Raspberry Pi Imager) :** [raspberrypi.com/software](https://www.raspberrypi.com/software/)
* 🎥 **Tutoriel Vidéo (Installation RetroPie pas à pas) :** [Visionner sur YouTube](http://www.youtube.com/watch?v=7sd1H9N4D70)