# Use the official Ubuntu 24.04 base image
FROM ubuntu:24.04

# Create the directory for the installs
RUN mkdir /rstudio

# Install packages for RStudio and R
COPY packages.sh /rstudio
RUN chmod +x /rstudio/packages.sh && /rstudio/packages.sh

# Install AWS CLI
COPY awscli.sh /rstudio
RUN chmod +x /rstudio/awscli.sh && /rstudio/awscli.sh

# Install RStudio Server
COPY rstudio.sh /rstudio
RUN chmod +x /rstudio/rstudio.sh && /rstudio/rstudio.sh

# ===================================================================
# USER CREATION: Local RStudio fallback account
# -------------------------------------------------------------------
# A local RStudio user is created for emergency access when the
# external identity provider (e.g., AD/LDAP) is unavailable.
#
# - USER:               Local username (default: rstudio)
# - RSTUDIO_PASSWORD:   Password provided via build-time ARG
#                       (default: "rstudio" if not specified)
# ===================================================================

# Define build-time argument and default password
ARG RSTUDIO_PASSWORD

# Define environment variables
ENV USER=rstudio \
    HOME=/home/rstudio

# Create the user and set the password
RUN useradd -m -s /bin/bash ${USER} && \
    echo "${USER}:${RSTUDIO_PASSWORD}" | chpasswd && \
    adduser ${USER} sudo

# Expose port 8787 for RStudio Server
EXPOSE 8787

# ===================================================================
# STARTUP CONFIGURATION: Runtime initialization
# -------------------------------------------------------------------
# Copies and enables scripts/configurations required for startup,
# logging, and simulated systemctl behavior in containerized mode.
# ===================================================================
COPY startup.sh /rstudio/
RUN chmod +x /rstudio/startup.sh
COPY logging.conf /etc/rstudio/

# Replace systemctl binary with a Python wrapper to enable
# service management in containerized environments.
RUN rm -f /usr/bin/systemctl
COPY systemctl.py /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

# Create and adjust log directory permissions for RStudio
RUN mkdir -p /var/log/rstudio/rstudio-server && \
    chown -R rstudio-server:rstudio-server /var/log/rstudio && \
    chmod -R 777 /var/log/rstudio

# Set the default startup command
ENTRYPOINT [ "/rstudio/startup.sh" ]
