#!/bin/bash
set -euo pipefail
# ---------------------------------------------------------------------------------
# Update OS and Install Required Packages
# ---------------------------------------------------------------------------------
# Refresh package metadata
apt-get update -y

# Prevent interactive prompts during package installs
export DEBIAN_FRONTEND=noninteractive

# Install packages needed for:
#   - Active Directory integration: realmd, sssd-ad, adcli, krb5-user
#   - NSS/PAM integration: libnss-sss, libpam-sss, winbind, libpam-winbind, libnss-winbind
#   - Samba file services: samba, samba-common-bin, samba-libs
#   - Home directory automation: oddjob, oddjob-mkhomedir
#   - Utilities: less, unzip, nano, vim, nfs-common, stunnel4, jq

echo "=== Phase 1: Base utilities and AD join tools ==="  

apt-get install -y less unzip realmd sssd-ad sssd-tools libnss-sss \
    libpam-sss adcli samba-common-bin samba-libs oddjob \
    oddjob-mkhomedir packagekit krb5-user nano vim stunnel4 \
    nfs-common curl sudo passwd adduser wget jq pamtester
 
echo "=== Phase 2: Core build chain for R ==="  
apt-get install -y build-essential gfortran python3-pip \
    libxml2-dev libcurl4-openssl-dev libssl-dev cmake

echo "=== Phase 3: Math & compression libraries ==="  
apt-get install -y libgsl-dev libblas-dev liblapack-dev \
    zlib1g-dev libbz2-dev liblzma-dev  

echo "=== Phase 4: Graphics & text stack ==="  
apt-get install -y libcairo2-dev libxt-dev libx11-dev libxpm-dev \
    libfreetype6-dev libharfbuzz-dev libfribidi-dev  \
    libglu1-mesa-dev freeglut3-dev mesa-common-dev libabsl-dev

echo "=== Phase 5: Database & spatial libraries ==="  
apt-get install -y libsqlite3-dev libpq-dev libmariadb-dev \
    libmariadb-dev-compat libudunits2-dev libgeos-dev libproj-dev  

echo "=== Phase 6: Extra formats and science libs ==="  
apt-get install -y libpoppler-cpp-dev \
    libhdf5-dev libnetcdf-dev default-jdk  

# echo "=== Phase 7: LaTeX (optional, heavy) ==="  
# apt-get install -y texlive-latex-base texlive-fonts-recommended \
#     texlive-fonts-extra texlive-latex-extra  

echo "=== Phase 8: Clean up ==="  
apt-get autoremove -y  
apt-get clean  

echo "=== Userdata completed successfully ==="    


