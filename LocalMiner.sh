#!/bin/bash

echo "  __                _ _____ _                "
echo " |  |   ___ ___ ___| |     |_|___ ___ ___ ©️  "
echo " |  |__| . |  _| .'| | | | | |   | -_|  _|   "
echo " |_____|___|___|__,|_|_|_|_|_|_|_|___|_|     "
echo " https://localminer.me , https://github.com/localminer "
echo
echo "LocalMiner: Host Locally!"
echo "============================"

##### USER CONFIGURATIONS #####
read -p "Using Paper (yes/[no])? " USE_Paper
USE_Paper=${USE_Paper:-no}

read -p "Using ngrok ([yes]/no)? " USE_NGROK
USE_NGROK=${USE_NGROK:-yes}

if [ "$USE_NGROK" = "yes" ]; then
  read -p "ngrok authtoken (REQUIRED): " AUTHTOKEN
  read -p "ngrok region ([us]/eu/ap/au/in): " NGROK_REGION
  NGROK_REGION=${NGROK_REGION:-us}
fi

DEF_Paper_INSTALLER="https://api.papermc.io/v2/projects/paper/versions/1.20.4/builds/405/downloads/paper-1.20.4-405.jar"
DEF_VANILLA_SERVER="https://launcher.mojang.com/v1/objects/125e5adf40c659fd3bce3e66e67a16bb49ecc1b9/server.jar"

if [ "$USE_Paper" = "yes" ]; then
  read -p "Custom Paper installer (leave blank for default: $DEF_Paper_INSTALLER)? " Paper_SERVER
  Paper_SERVER=${Paper_SERVER:-$DEF_Paper_INSTALLER}
else
  read -p "Custom vanilla server (leave blank for default: $DEF_VANILLA_SERVER)? " VANILLA_SERVER
  VANILLA_SERVER=${VANILLA_SERVER:-$DEF_VANILLA_SERVER}
fi

EXEC_SERVER_NAME="minecraft_server.jar"

##### JAVA INSTALLATION #####
echo "STATUS: installing Java 8 (required for Beta 1.7.3)"
pkg uninstall openjdk-17 -y >/dev/null 2>&1
pkg install unzip -y

if [ ! -x "$HOME/.java/bin/java" ]; then
  wget -q https://raw.githubusercontent.com/MasterDevX/java/master/installjava -O installjava
  bash installjava
  rm installjava
fi

export PATH="$HOME/.java/bin:$PATH"
java -version || { echo "ERROR: Java install failed"; exit 1; }

##### MINECRAFT/NGROK SETUP #####
echo "STATUS: setting up Minecraft Server"
mkdir -p LocalMiner
cd LocalMiner
echo "eula=true" > eula.txt

if [ "$USE_Paper" = "yes" ]; then
  wget $Paper_SERVER
  installer_jar=$(basename $Paper_SERVER)
  java -jar $installer_jar --installServer
  echo "cd LocalMiner && java -Xmx1G -jar paper-1.20.4-405.jar nogui" > ../m.sh
else
  wget -O $EXEC_SERVER_NAME $VANILLA_SERVER
  echo "cd LocalMiner && java -Xmx1G -jar ${EXEC_SERVER_NAME} nogui" > ../m.sh
fi
chmod +x ../m.sh

if [ "$USE_NGROK" = "yes" ]; then
  echo "STATUS: setting up ngrok"
  cd ..
  wget -O ngrok.tgz https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.tgz
  tar -xzf ngrok.tgz
  chmod +x ngrok
  echo "./ngrok tcp --region=$NGROK_REGION 25565" > n.sh
  chmod +x n.sh
  ./ngrok authtoken $AUTHTOKEN
fi

echo
echo "-------------------------------------------------"
echo "STATUS: installation complete!"
echo "Run ./m.sh to start Minecraft server"
echo "Run ./n.sh in another session to start ngrok"
echo "-------------------------------------------------"
