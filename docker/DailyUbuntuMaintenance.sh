#!/bin/bash
##########################################################################################################################################################################
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## + Name: DailyUbuntuMaintenance.sh
## + Purpose: Performs daily Ubuntu maintenance tasks and updates Docker containers. Reboots machine if need after updates are installed.
## + Author: Vince Cantrell
## + 
## + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## + Instructions: 
## +    1.  Download the script to a location such as /scripts and make it executable with chmod +x 
## +    2.  If you use HealthChecks (Recommend: docs.linuxserver.io/images/docker-healthchecks/) Download Runitor to /usr/sbin/runitor (github.com/bdd/runitor)
## +    3.  Add the following line to your crontab: 00 4 * * * /usr/sbin/runitor -api-url="%%YOUR_PING_URL%%" -uuid %%YOUR_UUID%% -- /scripts/DailyUbuntuMaintenance.sh
## +    4.  Optionally: Install apt-fast to help with streamlining the updating of apps from aptitude. (github.com/ilikenwf/apt-fast)
## +    5.  When running this intiially on a NON-REBOOT machine, run: REBOOT_POLICY=manual ./DailyUbuntuMaintenance.sh  and/or  ./DailyUbuntuMaintenance.sh --no-auto-reboot
## +    6.  If the machine SHOUDLD automatically reboot, you shouldn't have to do anything, but running the following can't hurt: ./DailyUbuntuMaintenance.sh --auto-reboot
## + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## +
## + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## + Last Modification Date: 09/25/2025
## + DevOps Pipeline Version Number: 1.6
## + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## +
## + ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
## + Change Log:
## +
## + v1.6 - 09/25/2025 - Vince Cantrell - Combined two scripts into one. See the instructions for set non-reboot machines to not reboot.
## + 
## + v1.5 - 03/19/2024 - Vince Cantrell - Enhanced formatting and rewrote the update section to work whether apt-fast is installed or not. Re-released script.
## + 
## + v1.4 - 02/15/2024 - Vince Cantrell - Completely rewrote the docker section to recursively loop through all directories underneath '/compose/'.
## + 
## + v1.3 - 03/17/2021 - Vince Cantrell - Formatted and released the initial release of this maintenance script and distributed it to all my ubuntu hosts.
## + 
## + v1.2 - 02/21/2021 - Vince Cantrell - Added the docker cleanup section and updated the aptitude section to use apt-fast.
## + 
## + v1.1 - 01/11/2021 - Vince Cantrell - Added in the docker update section to update all docker-compose directories under '/compose/'.
## + 
## + v1.0 - 12/07/2020 - Vince Cantrell - Initial build of the Script with just the basic aptitude update sections without structure or formatting.
## + ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##########################################################################################################################################################################

################################################################################################################################
###=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~==~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=###
################################################################################################################################

#------------------------------------------------------------------------
# at the very top of the script
REBOOT_POLICY_FILE="/var/noreboot"
is_manual_reboot_host() { [ -f "$REBOOT_POLICY_FILE" ]; }

# optional CLI policy toggles
case "$1" in
  --no-auto-reboot) touch "$REBOOT_POLICY_FILE" ;;
  --auto-reboot)    rm -f "$REBOOT_POLICY_FILE" ;;
esac

# optional env policy for first run automation
[ "${REBOOT_POLICY:-auto}" = "manual" ] && touch "$REBOOT_POLICY_FILE"
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# To reduce dpkg passive-aggression
export DEBIAN_FRONTEND=noninteractive
#------------------------------------------------------------------------

####################################################################################################
#///////////////////////////////////////////////////////////////////////////////////////////////////
#//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#//   SCRIPT SETUP: SET FUNCTIONS AND VARIABLES
#//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#///////////////////////////////////////////////////////////////////////////////////////////////////
####################################################################################################

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

##///////////////////////////////////////////////////////////##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##=~=~=~=~=~=~=~=      Script Functions      =~=~=~=~=~=~=~=~##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##///////////////////////////////////////////////////////////##

#------------------------------------------------------------------------

#########################################################
###    Docker Compose Process Directories Function    ###
#########################################################

# Function to process each directory 
process_directory() {
    for dir in "$1"/*; do
        if [ -d "$dir" ]; then
            echo "Processing $dir"
            # Change to the directory
            cd "$dir" || exit
            # Pull the docker compose, suppressing stdout and stderr
            docker compose pull > /dev/null 2>&1
            docker compose up -d --remove-orphans
            # Go back to the previous directory
            cd - > /dev/null 2>&1
            # Recursively process subdirectories
            process_directory "$dir"
        fi
    done
}

#------------------------------------------------------------------------

#########################################################
###     Function to verify no reboots are needed      ###
#########################################################

# Functiion to determine if the deivce neeeds a reboot
needs_reboot() {
    # Prefer the canonical sentinel if present
    if [ -f /run/reboot-required ] || [ -f /var/run/reboot-required ]; then
        return 0
    fi

    # Compare running vs latest installed kernel
    current_kernel="$(uname -r)"
    latest_installed_kernel="$(ls -1 /lib/modules 2>/dev/null | sort -V | tail -1)"

    if [ -n "$latest_installed_kernel" ] && [ "$latest_installed_kernel" != "$current_kernel" ]; then
        return 0
    fi

    # Fallback: ask needrestart if available (exit 1/2 usually implies restarts/reboot needed)
    if command -v needrestart >/dev/null 2>&1; then
        needrestart -p -r a >/dev/null 2>&1
        case $? in
            1|2) return 0 ;;
        esac
    fi

    return 1
}

#------------------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

################################################################################################################################
###=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~==~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=###
################################################################################################################################

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#------------------------------------------------------------------------

##///////////////////////////////////////////////////////////##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##=~=~=~=~=~=~=~=      Script Variables      =~=~=~=~=~=~=~=~##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##///////////////////////////////////////////////////////////##

#------------------------------------------------------------------------

#########################################################
###    Docker Compose Directory Location Variable     ###
#########################################################

# Directory that houses all of the docker-compose directories on the system
compose_dir="/compose"

#------------------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

################################################################################################################################
###=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~==~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=###
################################################################################################################################

####################################################################################################
#///////////////////////////////////////////////////////////////////////////////////////////////////
#//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#//   SCRIPT EXECUTION SECTION: UPDATE UBUNTU VIA APT AND DOCKER VIA DOCKER-COMPOSE
#//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#///////////////////////////////////////////////////////////////////////////////////////////////////
####################################################################################################

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

##///////////////////////////////////////////////////////////##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##=~=~=~=~=~=~=~=    System Update Section    =~=~=~=~=~=~=~=##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##///////////////////////////////////////////////////////////##

#########################################################
###  Update using Apt-Get or Apt-Fast (If Installed)  ###
#########################################################

echo "---------------------------------------------------------------"
echo "Commencing System & Docker Update & Cleanup: `date`"
echo "---------------------------------------------------------------"
echo "1. Commencing Apt Update and Cleanup..."

# Check if apt-fast is installed
if command -v apt-fast &> /dev/null; then
    echo "apt-fast is installed"

    # Update and upgrade with apt-fast, handling potential interactivity
    apt-fast update -y || true  # Update, suppress errors if interaction is needed
    apt-fast upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || true
    apt-fast dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || true
    apt-fast autoclean -y 
    apt-fast clean -y
    apt-fast autoremove -y

else
    echo "apt-fast is not installed, using apt-get"

    # Update and upgrade with apt-get, handling potential interactivity 
    apt-get update -y || true
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || true
    apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || true
    apt-get autoclean -y
    apt-get clean -y
    apt-get autoremove -y
fi
echo "Ubuntu Apt Update and Cleanup Complete!"
echo "---------------------------------------------------------------"

#------------------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

##///////////////////////////////////////////////////////////##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##=~=~=~=~=~=~=~=    Docker Update Section    =~=~=~=~=~=~=~=##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##///////////////////////////////////////////////////////////##

#------------------------------------------------------------------------

#########################################################
###   Update All Docker Containers and Prune System   ###
#########################################################

echo "---------------------------------------------------------------"
echo "2. Commencing Docker Pull and Up"
process_directory "$compose_dir"
echo "---------------------------------------------------------------"
echo "4. Pruning Docker & Restarting Code Server"
docker system prune --volumes -af
service code-server@root restart
echo "---------------------------------------------------------------"

#------------------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

##///////////////////////////////////////////////////////////##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##=~=~=~=~=~=~=~=    System Reboot Section    =~=~=~=~=~=~=~=##
##=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=##
##///////////////////////////////////////////////////////////##

#------------------------------------------------------------------------

#######################################################################################
###  System Reboot Section (single-script, policy-controlled, verbose kernel info)  ###
#######################################################################################

echo "---------------------------------------------------------------"
echo "5. Reboot policy check"

# Get running and latest installed kernels
running_kernel="$(uname -r 2>/dev/null || true)"
installed_kernel="$(ls -1 /lib/modules 2>/dev/null | sort -V | tail -1)"

echo ">> Kernel status"
echo ">> Running kernel : ${running_kernel:-unknown}"
echo ">> Latest installed: ${installed_kernel:-unknown}"

if needs_reboot; then
    echo ">> REBOOT REQUIRED"

    if is_manual_reboot_host; then
        echo ">> Policy: MANUAL reboot host (marker: ${REBOOT_POLICY_FILE})"
        echo ">> No reboot performed. Schedule a reboot to load the new kernel."
        {
            echo "reboot-required $(date -Is)"
            echo "running=${running_kernel:-unknown}"
            echo "installed=${installed_kernel:-unknown}"
        } > /var/tmp/maintenance-reboot-required 2>/dev/null || true
        # Non-zero so healthchecks can alert
        exit 20
    else
        echo ">> Policy: AUTO reboot host"
        if [ -n "$installed_kernel" ] && [ "$installed_kernel" != "$running_kernel" ]; then
            echo ">> Rebooting in 1 minute to switch kernel ${running_kernel} -> ${installed_kernel}"
        else
            echo ">> Rebooting in 1 minute (sentinel/needrestart requested reboot)"
        fi
        shutdown -r +1
    fi
else
    echo "No Reboot Necessary!"
fi

echo "---------------------------------------------------------------"
echo "Finished System & Docker Update & Cleanup: $(date)"
echo "---------------------------------------------------------------"

#------------------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#// END OF FILE
#//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////