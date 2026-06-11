#!/bin/bash

# ---------------------------------------------------------------------------------
# Install R
# ---------------------------------------------------------------------------------

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y software-properties-common dirmngr
apt-get update
apt-get install -y r-base r-base-dev

# ---------------------------------------------------------------------------------
# Install Various R packages and rebuild them.
# ---------------------------------------------------------------------------------

# Installing R Packages can take a quite a long time - users can install these
# dynamically so I'll skip making these part of the AMI.

#Rscript -e 'install.packages(c("jsonlite", "png", "reticulate","ggplot2","gganimate"), repos="https://cloud.r-project.org")'

# ---------------------------------------------------------------------------------
# Install RStudio Community Edition
# ---------------------------------------------------------------------------------

cd /tmp
wget -q https://rstudio.org/download/latest/stable/server/jammy/rstudio-server-latest-amd64.deb
apt-get install -y ./rstudio-server-latest-amd64.deb
rm -f -r rstudio-server-latest-amd64.deb

# ---------------------------------------------------------------------------------
# Configure PAM for RStudio to use SSSD and AD
# ---------------------------------------------------------------------------------

cat <<'EOF' | tee /etc/pam.d/rstudio > /dev/null
#%PAM-1.0
# RStudio PAM stack supporting both AD (SSSD) and local users

# --- Authentication ---
auth     optional     pam_exec.so debug /etc/pam.d/rstudio-mkhomedir.sh
auth     sufficient   pam_sss.so
auth     sufficient   pam_unix.so
auth     required     pam_deny.so

# --- Account management ---
account  sufficient   pam_sss.so
account  sufficient   pam_unix.so
account  required     pam_deny.so

# --- Session setup ---
session  required     pam_limits.so
session  optional     pam_sss.so
session  optional     pam_unix.so

EOF

# ---------------------------------------------------------------------------------
# Configure PAM to auto-create home directories on first login
# ---------------------------------------------------------------------------------

grep -qF "pam_mkhomedir.so" /etc/pam.d/common-session || {
  echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" \
  | sudo tee -a /etc/pam.d/common-session
}

# ---------------------------------------------------------------------------------
# Deploy PAM script to create home directories on first rstudio login
# ---------------------------------------------------------------------------------

cat <<'EOF' | tee /etc/pam.d/rstudio-mkhomedir.sh > /dev/null
#!/bin/bash
echo "NOTE: Creating home directory for user $PAM_USER"
su -c "exit" $PAM_USER
chmod 700 /home/*
EOF

chmod +x /etc/pam.d/rstudio-mkhomedir.sh

