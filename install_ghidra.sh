#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

function print_info {
    echo "--------------------"
    echo -e "${GREEN}$1${ENDCOLOR}"
    echo "--------------------"
}


print_info "Installing latest version of Ghidra to /opt/ghidra"
if [ ! -d "/opt/ghidra" ]; then
    
    wget -O ~/ghidra_install.zip $(curl -L api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | jq -r ".assets[0].browser_download_url")
    
    sudo unzip -q ~/ghidra_install.zip -d /opt/
    sudo mv /opt/ghidra* /opt/ghidra
    # :user is for Ubuntu server - so everyone can access it
    sudo chown $(whoami):users -R /opt/ghidra

cat << EOF > ~/.ghidra.desktop
[Desktop Entry]
Categories=Application;Development;
Comment[en_US]=Ghidra Software Reverse Engineering Suite
Comment=Ghidra Software Reverse Engineering Suite
Exec=/opt/ghidra/ghidraRun
GenericName[en_US]=Ghidra Software Reverse Engineering Suite
GenericName=Ghidra Software Reverse Engineering Suite
Icon=/opt/ghidra/support/ghidra.png
MimeType=
Name[en_US]=Ghidra
Name=Ghidra
Path=/opt/ghidra
StartupNotify=false
Terminal=false
TerminalOptions=
Type=Application
Version=1.0
X-DBUS-ServiceName=
X-DBUS-StartupType=none
X-KDE-SubstituteUID=false
X-KDE-Username=
EOF

    print_info "Adding ghidra to applications list"
    sudo mv ~/.ghidra.desktop /usr/share/applications/ghidra.desktop

    print_info "Deleting ghidra_install.zip"
    rm ~/ghidra_install.zip

    if [[ "$XDG_CURRENT_DESKTOP" == *GNOME* ]]; then
        if which gsettings >/dev/null; then
            # /opt/ghidra/support/ghidra.ico appears corrupted in VM, so download the logo as a png
            # wget -O ~/.ghidra.png https://upload.wikimedia.org/wikipedia/commons/a/a3/Ghidra_Logo.png
            # mv ~/.ghidra.png /opt/ghidra/support/ghidra.png
            cp /opt/ghidra/docs/GhidraClass/AdvancedDevelopment/Images/GhidraLogo64.png /opt/ghidra/support/ghidra.png

            log "Adding ghidra to favorites bar"
            gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'ghidra.desktop']"
            gsettings set org.gnome.desktop.wm.preferences audible-bell false
        fi
    fi

else
    print_info "Ghidra is already installed. To remove, run 'rm -rf /opt/ghidra'"
fi

# print_info "Installing ghidra2dwarf"
# if [ ! -d "$HOME/ghidra_scripts" ]; then
#     mkdir -p ~/ghidra_scripts
#     cd ~/ghidra_scripts
#     wget https://github.com/cesena/ghidra2dwarf/releases/download/latest/ghidra2dwarf.zip
#     unzip ghidra2dwarf.zip
# fi
