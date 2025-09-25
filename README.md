
# Simple Scripts for Ubuntu

Designed to automate maintenance tasks for docker running on Ubuntu.


## Authors

- [@vcantrell](https://www.github.com/vcantrell)


## Documentation

### Instructions:

1.  Download the script to a location such as /scripts and make it executable with chmod +x 
2.  If you use HealthChecks (Recommend: docs.linuxserver.io/images/docker-healthchecks/) Download Runitor to /usr/sbin/runitor (github.com/bdd/runitor)
3.  Add the following line to your crontab: 00 4 * * * /usr/sbin/runitor -api-url="%%YOUR_PING_URL%%" -uuid %%YOUR_UUID%% -- /scripts/DailyUbuntuMaintenance.sh
4.  Optionally: Install apt-fast to help with streamlining the updating of apps from aptitude. (github.com/ilikenwf/apt-fast)
5.  When running this intiially on a NON-REBOOT machine, run: REBOOT_POLICY=manual ./DailyUbuntuMaintenance.sh  and/or  ./DailyUbuntuMaintenance.sh --no-auto-reboot
6.  If the machine SHOUDLD automatically reboot, you shouldn't have to do anything, but running the following can't hurt: ./DailyUbuntuMaintenance.sh --auto-reboot
## Deployment

To deploy this project run

```bash
  mkdir -p /scripts && cd /scripts
```
```
  wget https://raw.githubusercontent.com/vcantrell/Scripts/refs/heads/Main/docker/DailyUbuntuMaintenance.sh
```
```
  chmod +x DailyUbuntuMaintenance.sh
```

At this point, if you've setup your own HealthChecks or setuo a. free HealthChecks account, proceed witht following steps. If not, proceed to the section below.

Add the following line to your crontab:
```
  00 4 * * * /usr/sbin/runitor -api-url="%%YOUR_PING_URL%%" -uuid %%YOUR_UUID%% -- /scripts/DailyUbuntuMaintenance.sh
```
If not, add this line to your crontab:
```
  00 4 * * * /DailyUbuntuMaintenance.sh
```
## Support

I do not offer support on this as this is a side project for me. For support, open an issue and I will look at it when I get a chance.


## FAQ

#### Do I need to specify a reboot preference like is noted in steps 5 and 6?

No. The script should handle that automatically. Those are just safeguards.

#### Can I change the time / frequency in the CRONTAB?

Yes. Those are just examples from my script.

#### Can I run this on a non-Ubuntu system?

While this script is designed for Ubuntu, it may work on other Debian-based systems with minor modifications. However, I cannot guarantee compatibility with non-Ubuntu systems.

#### Can I run this on a non-Docker system?

Yes but. This script is specifically designed to work with Docker containers and relies on Docker commands to function. If you're not using Docker, you'll need to modify the script significantly to work in a non-Docker environment.

#### Can I modify the script to fit my needs?

Yes. The script is open-source and can be modified to suit your specific requirements. However, please ensure you understand the changes you're making to avoid any unintended consequences.

#### How do I uninstall or remove the script?

To uninstall or remove the script, simply delete the script file from your system. If you added a cron job, make sure to remove that entry from your crontab as well.