#!/usr/bin/env bash
# This script installs and sets up a Minecraft Beta 1.7.3 server.
#
# It installs the appropriate Java runtime (OpenJDK 8), downloads the
# legacy server JAR from the specified archive and prepares a simple
# start script.  Because Beta 1.7.3 predates Mojang’s later EULA
# enforcement, there is no need to write an `eula.txt` file.  See the
# community guide for Beta 1.7.3 servers, which recommends downloading
# the jar, placing it in a folder, running it once to generate the
# server files and then creating a simple start script using the
# `java -Xmx… -Xms… -jar server.jar nogui` command【505783385595142†L210-L218】.
#
# After running this script you will find a `start.sh` in
# `$HOME/minecraft_beta_server` which you can use to launch the server
# with appropriate memory settings.

set -euo pipefail

# Function to install dependencies using apt-get if available.
install_dependencies() {
  # Only run on systems with apt-get (Debian/Ubuntu).  Other distros
  # should install Java 8 manually.
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    # Install OpenJDK 8 runtime and additional helpers.  Beta 1.7.3
    # requires Java 8 to run reliably【105768211690398†L57-L69】.
    sudo apt-get install -y openjdk-8-jre-headless wget screen
  else
    echo "apt-get not found. Please install a Java 8 runtime and wget manually before running this script."
  fi
}

# Function to download the server jar.
download_server() {
  local jar_url="http://web.archive.org/web/20200226130144/https://betacraft.pl/server-archive/minecraft/b1.7.3.jar"
  local jar_file="b1.7.3.jar"
  if [ ! -f "$jar_file" ]; then
    echo "Downloading Minecraft Beta 1.7.3 server JAR…"
    wget -O "$jar_file" "$jar_url"
  fi
  # Copy to server.jar for convenience
  cp "$jar_file" server.jar
}

# Function to generate server files.  The first run creates
# server.properties and other files; we pipe `stop` into the server to
# shut it down immediately after startup【505783385595142†L210-L218】.
generate_server_files() {
  if [ ! -f server.properties ]; then
    echo "Generating initial server files…"
    # Use a subshell to send the stop command via stdin after startup.
    (printf "stop\n") | java -Xmx1G -Xms1G -jar server.jar nogui || true
  fi
}

# Function to create a simple start script.
create_start_script() {
  cat > start.sh <<'EOS'
#!/usr/bin/env bash
# Launches the Minecraft Beta 1.7.3 server with 1 GiB of RAM.
java -Xmx1G -Xms1G -jar server.jar nogui
EOS
  chmod +x start.sh
}

# Main routine
main() {
  install_dependencies
  # Create installation directory
  local install_dir="$HOME/minecraft_beta_server"
  mkdir -p "$install_dir"
  cd "$install_dir"
  download_server
  generate_server_files
  create_start_script
  echo "Minecraft Beta 1.7.3 server installation complete."
  echo "To start the server, run: $install_dir/start.sh"
}

main "$@"