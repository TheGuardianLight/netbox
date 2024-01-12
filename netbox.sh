#!/bin/sh

# Vérifie si le script est lancé avec les permissions administrateurs
echo "Vérification des permissions administrateurs..."
if [ $EUID -ne 0 ]; then
    echo "Vous devez lancer ce script avec les permissions administrateurs"
    exit 1
    else echo "Vous avez les permissions administrateurs"
fi

# Mise à jour des paquets et installation des dépendances
echo "Mise à jour des paquets"
apt update && apt upgrade -y

# Installation de Postgresql
echo "Installation de Postgresql"
apt install -y postgresql
echo "Vérifiez la version de postgresql"
psql -V$
echo "Est-ce correct pour vous ? (Y/N)"
read pgsql-version
if [$pgsql-version = "Y"]; then
    echo "Ok, continuon l'installation de Netbox..."
fi

# Création de la base de donnée
echo "Connection à postgresql. Vous devrez créer la base de donnée."
sudo -u postgres psql
exit

# Installation de Redis
echo "Installation de Redis"
apt install -y redis-server
redis-server -v
redis-cli ping

# installation de Netbox
echo "Installation de Netbox et de ses dépendances..."
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev
mkdir -p /opt/netbox/
cd /opt/netbox/
apt install -y git
git clone -b master --depth 1 https://github.com/netbox-community/netbox.git .

# Création de l'utilisateur
echo "Création de l'utilisateur Netbox"
adduser --system --group netbox
chown --recursive netbox /opt/netbox/netbox/media/
chown --recursive netbox /opt/netbox/netbox/reports/
chown --recursive netbox /opt/netbox/netbox/scripts/

# Génération de la configuration
echo "génération de la configuration"
cd /opt/netbox/netbox/netbox/
cp configuration_example.py configuration.py
python3 ../generate_secret_key.py
sleep 10
vim configuration.py

/opt/netbox/upgrade.sh

# Création du super utilisateur
echo "Création du super utilisateur"
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
python3 manage.py createsuperuser

ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

# test de l'environnement de développement
echo "LANCEMENT DU TEST DE L'ENVIRONNEMENT DE DEVELOPPEMENT !!!"
sleep 2
echo "LANCEMENT DU TEST DE L'ENVIRONNEMENT DE DEVELOPPEMENT !!!"
sleep 2
echo "LANCEMENT DU TEST DE L'ENVIRONNEMENT DE DEVELOPPEMENT !!!"
sleep 2
python3 manage.py runserver 0.0.0.0:8000 --insecure

# Configuration de Gunicorn
echo "Configuration de Gunicorn"
cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py

# Configuration de Systemd
echo "Configuration de Systemd"
cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl start netbox netbox-rq
systemctl enable netbox netbox-rq
sleep 2
echo ""
systemctl status netbox.service
sleep 2

# Installation et configuration de Apache
apt install -y apache2
cp /opt/netbox/contrib/apache.conf /etc/apache2/sites-available/netbox.conf
vim /etc/apache2/sites-available/netbox.conf
a2enmod ssl proxy proxy_http headers rewrite
a2ensite netbox
systemctl restart apache2

# Installation de Let's Encrypt
echo "Installation de Let's Encrypt..."
apt install -y snapd
snap install core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
certbot --apache

# Fin de l'installation
echo "Installation terminé !"