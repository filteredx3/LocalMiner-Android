#!/data/data/com.termux/files/usr/bin/bash

echo "  __                _ _____ _                "
echo " |  |   ___ ___ ___| |     |_|___ ___ ___ ©️  "
echo " |  |__| . |  _| .'| | | | | |   | -_|  _|   "
echo " |_____|___|___|__,|_|_|_|_|_|_|_|___|_|     "
echo " https://localminer.me , https://github.com/localminer "
echo " "
echo "LocalMiner: Host Locally! (Termux Edition - Beta 1.7.3)"
echo "======================================================="
echo "Website : https://localminer.me"
echo "Github  : https://github.com/localminer"


##### USER CONFIGURATIONS #####
# Beta 1.7.3 doesn't have Paper support, so we only use vanilla
echo "Note: Using Minecraft Beta 1.7.3 (Paper not available for beta versions)"
USE_Paper="no"

# set to false if you have your own port-forwarding setup
# leave as true to forward local ip to online through ngrok so other people can join
read -p "Using ngrok ([yes]/no)? " USE_NGROK
USE_NGROK=${USE_NGROK:-yes}

if [ "$USE_NGROK" = "yes" ] ; then
  read -p "ngrok authtoken (REQUIRED see https://dashboard.ngrok.com/get-started/your-authtoken): " AUTHTOKEN
  read -p "ngrok region ([us]/eu/ap/au/in): " NGROK_REGION
  NGROK_REGION=${NGROK_REGION:-us}
fi

# Minecraft Beta 1.7.3 server jar
# Note: This is a placeholder URL - you'll need to obtain the actual Beta 1.7.3 server jar
# Beta versions are not officially distributed by Mojang anymore
DEF_VANILLA_SERVER="https://files.betacraft.uk/server-archive/beta/b1.7.3.jar"
read -p "Minecraft Beta 1.7.3 server jar URL (required - obtain from archive): " VANILLA_SERVER
VANILLA_SERVER=${VANILLA_SERVER:-$DEF_VANILLA_SERVER}

# don't need to edit this
EXEC_SERVER_NAME="minecraft_server.jar"

##### JAVA/NGROK INSTALLATION #####

echo "STATUS: Installing required packages for Termux..."
pkg update -y
pkg install wget curl unzip zip -y

# Install OpenJDK 11 (works better than 8 on aarch64 Termux and is compatible with older MC versions)
echo "STATUS: Installing OpenJDK 11 (compatible with Beta 1.7.3)..."
pkg install openjdk-11 -y

# Verify Java installation
echo "STATUS: Verifying Java installation..."
java -version
if [ $? -ne 0 ]; then
    echo "ERROR: Java installation failed!"
    echo "Trying alternative Java installation method..."
    pkg install ecj dx -y
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not install Java. Please install manually."
        exit 1
    fi
fi

# minecraft server download and setup
echo "STATUS: setting up Minecraft Beta 1.7.3 Server"
mkdir -p LocalMiner
cd LocalMiner

# Create eula.txt (though Beta 1.7.3 might not require it)
echo "eula=true" > eula.txt

# Download the server jar
echo "STATUS: Downloading Minecraft Beta 1.7.3 server..."
wget -O $EXEC_SERVER_NAME $VANILLA_SERVER

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download server jar."
    echo "Please manually place the Minecraft Beta 1.7.3 server jar in the LocalMiner directory as 'minecraft_server.jar'"
    echo "You can find Beta 1.7.3 server jars in various Minecraft archives online."
fi

# Create server startup script with lower memory allocation for Termux
echo "cd LocalMiner && java -Xmx512M -Xms256M -jar ${EXEC_SERVER_NAME} nogui" > ../m.sh
chmod +x ../m.sh

# Create server.properties file with Beta 1.7.3 appropriate settings
cat > server.properties << EOF
#Minecraft server properties
server-ip=
server-port=25565
level-name=world
gamemode=0
difficulty=1
level-type=DEFAULT
level-seed=
spawn-monsters=true
spawn-animals=true
spawn-npcs=true
pvp=true
enable-command-block=false
player-idle-timeout=0
max-players=20
level-seed=
allow-nether=true
view-distance=10
motd=Minecraft Beta 1.7.3 Server - Termux
online-mode=false
white-list=false
EOF

# ngrok download and setup
if [ "$USE_NGROK" = "yes" ] ; then
  echo "STATUS: setting up ngrok for aarch64"
  cd ..
  
  # Download ngrok for ARM64 (aarch64)
  echo "STATUS: Downloading ngrok for ARM64..."
  wget -O ngrok.tgz "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
  
  if [ $? -ne 0 ]; then
      echo "ERROR: Failed to download ngrok. Trying alternative method..."
      curl -o ngrok.tgz "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
  fi
  
  tar -xzf ngrok.tgz
  chmod +x ngrok
  rm ngrok.tgz
  
  # Create ngrok startup script
  echo "./ngrok tcp --region=$NGROK_REGION 25565" > n.sh
  chmod +x n.sh
  
  # Set ngrok authtoken
  ./ngrok authtoken $AUTHTOKEN
  
  if [ $? -ne 0 ]; then
      echo "WARNING: Failed to set ngrok authtoken. You may need to run './ngrok authtoken YOUR_TOKEN' manually."
  fi
fi

echo " "
echo "-------------------------------------------------"
echo "STATUS: installation complete!"
echo " "
echo "IMPORTANT NOTES FOR BETA 1.7.3:"
echo "- Beta 1.7.3 may not have all modern server features"
echo "- Lower memory allocation (512MB) for Termux compatibility"
echo "- online-mode set to false (recommended for beta versions)"
echo "- You may need to manually obtain the Beta 1.7.3 server jar"
echo " "
echo "TO START:"
echo "1. Run './m.sh' to start minecraft server"
echo "2. Open a new Termux session (swipe from left)"
echo "3. Run './n.sh' to start ngrok (if enabled)"
echo " "
echo "TROUBLESHOOTING:"
echo "- If server jar download fails, manually place it in LocalMiner/"
echo "- Beta 1.7.3 server jars can be found in Minecraft archives"
echo "- For Java issues, try: pkg install openjdk-17"
echo "-------------------------------------------------"
echo "L O C A L  M I N E R | H O S T  L O C A L L Y !"
echo "                    Termux Beta 1.7.3 Edition"
echo "-------------------------------------------------"
echo " "
