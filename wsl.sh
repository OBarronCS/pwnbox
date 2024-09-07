#/bin/bash
## This script should be run as sudo

cat <<EOF > /etc/wsl.conf
[user]
default=ubuntu
[boot]
systemd=true
EOF

