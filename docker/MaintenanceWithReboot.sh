#!/bin/sh
echo "---------------------------------------------------------------"
echo "Commencing System & Docker Update & Cleanup: `date`"
echo "---------------------------------------------------------------"
echo "1. Updating Ubuntu"
sudo apt-fast update -y # Get updates
sudo apt-fast dist-upgrade -y # Perform updates
echo "Ubuntu Update Complete!"
echo "---------------------------------------------------------------"
echo "2. Commencing Ubuntu Cleanup"
apt-fast autoclean -y
echo "Outdated packages have been removed"
apt-fast clean -y
echo "The apt cache has been emptied"
apt-fast autoremove -y
echo "Packages installed as dependencies no longer needed have been removed"
echo "---------------------------------------------------------------"
echo "3. Commencing Docker Pull and Up"
# Do a pull then an update
if [ -d /compose/core ] 
then
	cd /compose/core
	docker compose pull > /dev/null 2>&1 
	docker compose up -d --remove-orphans
fi
if [ -d /compose/services ] 
then
	cd /compose/services
	docker compose pull > /dev/null 2>&1 
	docker compose up -d --remove-orphans
fi
if [ -d /compose/vinceflix ] 
then
	cd /compose/vinceflix
	docker compose pull > /dev/null 2>&1 
	docker compose up -d --remove-orphans
fi
if [ -d /compose/wordpress ] 
then
	cd /compose/wordpress
	docker compose pull > /dev/null 2>&1 
	docker compose up -d --remove-orphans
fi
echo "---------------------------------------------------------------"
echo "4. Pruning Docker"
docker system prune --volumes -af
echo "---------------------------------------------------------------"
echo "5. Rebooting if necessary"
if [ -f /var/run/reboot-required ] 
then
    echo "Reboot is required. Rebooting in 1 minute."
    shutdown -r +1
else
	echo "No Reboot Necessary!"
fi
echo "---------------------------------------------------------------"
echo "Finished System & Docker Update & Cleanup: `date`"
echo "---------------------------------------------------------------"