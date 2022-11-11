#!/bin/bash

set -o allexport
source /tmp/.env
set +o allexport

curl https://downloads.plex.tv/plex-keys/PlexSign.key | apt-key add -
echo deb https://downloads.plex.tv/repo/deb public main | tee /etc/apt/sources.list.d/plexmediaserver.list

apt update
ln -s $gluster_volume_dir/$gluster_volume_config/plex /var/lib/plexmediaserver
apt install -y plexmediaserver

# ufw allow ssh   
# ufw --force enable


# echo "[plexmediaserver] 
# title=Plex Media Server (Standard) 
# description=The Plex Media Server 
# ports=32400/tcp|3005/tcp|5353/udp|8324/tcp|32410:32414/udp 

# [plexmediaserver-dlna] 
# title=Plex Media Server (DLNA) 
# description=The Plex Media Server (additional DLNA capability only) 
# ports=1900/udp|32469/tcp 

# [plexmediaserver-all] 
# title=Plex Media Server (Standard + DLNA) 
# description=The Plex Media Server (with additional DLNA capability) 
# ports=32400/tcp|3005/tcp|5353/udp|8324/tcp|32410:32414/udp|1900/udp|32469/tcp" >> /etc/ufw/applications.d/plexmediaserver

# ufw app update plexmediaserver
# ufw allow plexmediaserver-all
# ufw status verbose