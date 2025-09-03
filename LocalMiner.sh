#!/bin/bash
set -e

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

##### PROOT + JAVA 8 SETUP #####
echo "STATUS: installing Debian bullseye proot with Java 8"
pkg install proot-distro wget unzip -y

if ! proot-distro list | grep -q debian-bullseye; then
  proot-distro install debian-bullseye
fi

cat > $PREFIX/bin/localminer-debian.sh <<'EOF'
#!/bin/bash
set -e
proot-distro login debian-bullseye -- /bin/bash -c "
  apt update &&
  apt install -y openjdk-8-jre wget unzip &&
  mkdir -p /root/LocalMiner &&
  cd /root/LocalMiner &&
  echo 'eula=true' > eula.txt
"
EOF
chmod +x $PREFIX/bin/localminer-debian.sh
$PREFIX/bin/localminer-debian.sh

##### MINECRAFT SERVER SETUP #####
if [ "$USE_Paper" = "yes" ]; then
  proot-distro login debian -- /bin/bash -c "
    cd /root/LocalMiner &&
    wget $Paper_SERVER &&
    installer_jar=\$(basename $Paper_SERVER) &&
    java -jar \$installer_jar --installServer &&
    echo \"cd /root/LocalMiner && java -Xmx1G -jar paper-1.20.4-405.jar nogui\" > /root/m.sh &&
    chmod +x /root/m.sh
  "
else
  proot-distro login debian -- /bin/bash -c "
    cd /root/LocalMiner &&
    wget -O $EXEC_SERVER_NAME $VANILLA_SERVER &&
    echo \"cd /root/LocalMiner && java -Xmx1G -jar $EXEC_SERVER_NAME nogui\" > /root/m.sh &&
    chmod +x /root/m.sh
  "
fi

##### NGROK SETUP #####
if [ "$USE_NGROK" = "yes" ]; then
  echo "STATUS: setting up ngrok"
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
echo "To start server:  proot-distro login debian -- /root/m.sh"
echo "To start ngrok :  ./n.sh   (in a new Termux session)"
echo "-------------------------------------------------"
