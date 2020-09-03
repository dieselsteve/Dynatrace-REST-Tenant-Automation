#!/bin/bash

USER="dynatrace"

# ---- Workshop User  ---- 
# The flag 'create_workshop_user'=true is per default set to false. If it's set to to it'll clone the home directory from USER and allow SSH login with the given text password )
NEWUSER="dynatrace"
NEWPWD="secr3t"

# - Keptn in a Box release
KIAB_RELEASE="release-0.7.0"

# ==================================================
#      ----- Variables Definitions -----           #
# ==================================================
LOGFILE='/tmp/workshop.log'
touch $LOGFILE
chmod 775 $LOGFILE
pipe_log=true

# ---- Define Dynatrace Environment ---- 
# Sample: https://{your-domain}/e/{your-environment-id} for managed or https://{your-environment-id}.live.dynatrace.com for SaaS
TENANT=
PAASTOKEN=
APITOKEN=

KIAB_FILE="https://raw.githubusercontent.com/keptn-sandbox/keptn-in-a-box/${KIAB_RELEASE}/keptn-in-a-box.sh"

setUpBox() {
    echo "Creating Workshop User from user($USER) into($NEWUSER)"
    homedirectory=$(eval echo ~$USER)
    echo "copy home directories and configurations"
    cp -R $homedirectory /home/$NEWUSER
    echo "Create user"
    useradd -s /bin/bash -d /home/$NEWUSER -m -G sudo -p $(openssl passwd -1 $NEWPWD) $NEWUSER
    
    usermod -a -G docker $NEWUSER
    usermod -a -G microk8s $NEWUSER
    echo "Warning: allowing SSH passwordAuthentication into the sshd_config"
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    service sshd restart
    curl -o keptn-in-a-box.sh $KIAB_FILE
    cat keptn-in-a-box.sh | sed -e 's~TENANT=~'"TENANT=$TENANT"'~' -e 's~PAASTOKEN=~'"PAASTOKEN=$PAASTOKEN"'~' -e 's~APITOKEN=~'"APITOKEN=$APITOKEN"'~' -e 's~#create_workshop_user=true~jenkins_deploy=true~' > /home/$NEWUSER/keptn-in-a-box.sh
    chmod +x /home/$NEWUSER/keptn-in-a-box.sh

    git clone https://github.com/sergiohinojosa/kubernetes-deepdive /home/$NEWUSER/kubernetes-deepdive  

    echo "Change diretores rights -r"
    chown -R $NEWUSER:$NEWUSER /home/$NEWUSER

    # Just to kick the install for ubuntu
    # Remove for the workshop
    #cd /home/$NEWUSER/ && bash ./keptn-in-a-box.sh &
    #echo "sent to background?"

}


## ----  Write all output to the logfile ----
if [ "$pipe_log" = true ] ; then
  echo "Piping all output to logfile $LOGFILE"
  echo "Type 'less +F $LOGFILE' for viewing the output of installation on realtime"
  echo ""
  # Saves file descriptors so they can be restored to whatever they were before redirection or used 
  # themselves to output to whatever they were before the following redirect.
  exec 3>&1 4>&2
  # Restore file descriptors for particular signals. Not generally necessary since they should be restored when the sub-shell exits.
  trap 'exec 2>&4 1>&3' 0 1 2 3
  # Redirect stdout to file log.out then redirect stderr to stdout. Note that the order is important when you 
  # want them going to the same file. stdout must be redirected before stderr is redirected to stdout.
  exec 1>$LOGFILE 2>&1
else
  echo "Not piping stdout stderr to the logfile, writing the installation to the console"
fi

# Comfortable function for setting the sudo user.
if [ -n "${SUDO_USER}" ] ; then
  USER=$SUDO_USER
fi
echo "running sudo commands as $USER"

setUpBox