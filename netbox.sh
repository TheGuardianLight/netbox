#!/bin/sh

# Vérifie si le script est lancé avec les permissions administrateurs
echo "Vérification des permissions administrateurs..."
if [ $EUID -ne 0 ]; then
    echo "Vous devez lancer ce script avec les permissions administrateurs"
    exit 1
    else echo "Vous avez les permissions administrateurs"
fi

# Mise à jour des paquets et installation des dépendances
echo "Mise à jour des paquets puis installation des dépendances..."
apt update && apt upgrade -y

# Installation de Postgresql
