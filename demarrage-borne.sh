#!/bin/bash

set -u

# Utilise le premier argument comme chemin vidéo, ou le chemin par défaut.
VIDEO="${1:-/home/admin/RetroPie/splashscreens/Intro_arcade_Vfinale.mp4}"

# Vérifie les dépendances avant de démarrer la borne.
if ! command -v cvlc >/dev/null 2>&1; then
    echo "Erreur : cvlc est introuvable. Vérifiez que VLC est installé." >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Erreur : python3 est introuvable." >&2
    exit 1
fi

if [ ! -f "$VIDEO" ]; then
    echo "Erreur : vidéo introuvable : $VIDEO" >&2
    echo "Utilisation : $0 [chemin/vers/la/video.mp4]" >&2
    exit 1
fi

# Surveille les événements des manettes pendant que VLC boucle la vidéo.
python3 - "$VIDEO" <<'PY'
import glob
import os
import select
import struct
import subprocess
import sys
import time

video = sys.argv[1]
# VLC lit la vidéo en boucle jusqu'à la détection d'une commande.
player = subprocess.Popen([
    "cvlc",
    "--fullscreen",
    "--no-video-title-show",
    "--loop",
    video,
])

devices = {}
unavailable = set()
stopped_for_input = False

try:
    while player.poll() is None:
        # Cherche les manettes connectées, y compris si elles sont branchées après le lancement.
        paths = set(glob.glob("/dev/input/js*"))
        unavailable.intersection_update(paths)
        for path in paths:
            if path in devices or path in unavailable:
                continue
            try:
                devices[path] = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
            except OSError as exc:
                print(f"Impossible d'ouvrir {path} : {exc}", file=sys.stderr)
                unavailable.add(path)

        if not devices:
            time.sleep(0.2)
            continue

        readable, _, _ = select.select(list(devices.values()), [], [], 0.2)
        for fd in readable:
            try:
                data = os.read(fd, 8)
            except BlockingIOError:
                continue
            except OSError:
                data = b""

            if len(data) != 8:
                disconnected = next(
                    (path for path, device_fd in devices.items() if device_fd == fd),
                    None,
                )
                if disconnected is not None:
                    os.close(fd)
                    del devices[disconnected]
                    unavailable.add(disconnected)
                continue

            _, value, event_type, _ = struct.unpack("<IhBB", data)
            # Les événements initiaux décrivent l'état courant, pas une nouvelle action.
            is_initial_event = bool(event_type & 0x80)
            event_type &= 0x7F

            button_pressed = event_type == 1 and value == 1
            joystick_moved = event_type == 2 and value != 0

            if not is_initial_event and (button_pressed or joystick_moved):
                stopped_for_input = True
                player.terminate()
                break

    player_status = player.wait()
finally:
    for fd in devices.values():
        os.close(fd)
    if player.poll() is None:
        player.terminate()
        try:
            player.wait(timeout=3)
        except subprocess.TimeoutExpired:
            player.kill()
            player.wait()

if stopped_for_input:
    print("Entrée de manette détectée : lancement d'EmulationStation.")
elif player_status != 0:
    print(f"VLC s'est arrêté avec le code {player_status}.", file=sys.stderr)
    sys.exit(1)
PY

python_status=$?
if [ "$python_status" -ne 0 ]; then
    echo "Erreur pendant la lecture de la vidéo ou la détection des manettes." >&2
    exit "$python_status"
fi

# Lance l'interface de la borne après la fin de la vidéo.
exec emulationstation
