#!/usr/bin/bash

set -eu

INSTALL_ROOT="$HOME/.local/opt"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
IDEA_DIR="$INSTALL_ROOT/intellij"

AGENT_DIR="$INSTALL_ROOT/ja-netfilter"

IDEA_URL="https://dl4.soft98.ir/linux/ideaIU-2025.3.3.tar.gz"
AGENT_URL="https://dl4.soft98.ir/programing/ja-netfilter-202x.zip"

download_file() {
    if command -v wget &> /dev/null; then
        wget --show-progress "$1" -O "$2"
    elif command -v curl &> /dev/null; then
        curl -L "$1" -o "$2" -#
    else
        echo "ERROR: install wget or curl." && exit 1
    fi
}

copy_to_clipboard() {
    local file=$1
    if [ ! -f "$file" ]; then return 1; fi

    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v wl-copy &> /dev/null; then
        wl-copy < "$file"
        echo "Activation code copied to clipboard."
    elif command -v xclip &> /dev/null; then
        xclip -sel clip < "$file"
        echo "Activation code copied to clipboard."
    elif command -v xsel &> /dev/null; then
        xsel --clipboard --input < "$file"
        echo "Activation code copied to X11 clipboard (via xsel)."
    else
        echo "Clipboard tool (wl-copy/xclip) not found."
        echo "PLEASE MANUALLY COPY THIS CODE:"
        echo "-------------------------------------------------------"
        cat "$file"
        echo "-------------------------------------------------------"
        echo "Or if you cannot copy it, here is the file: $(readlink -f "$file")"
    fi
}

echo "Starting Setup..."
mkdir -p "$INSTALL_ROOT" "$BIN_DIR" "$DESKTOP_DIR" "$HOME/Downloads"
cd "$HOME/Downloads"

download_file "$IDEA_URL" "intellij.tar.gz"
download_file "$AGENT_URL" "ja-netfilter.zip"

echo "Extracting IntelliJ..."
mkdir -p "$IDEA_DIR"
tar -xzf "intellij.tar.gz" -C "$IDEA_DIR" --strip-components=1

echo "Extracting ja-netfilter..."
unzip -o "ja-netfilter.zip" -d "$INSTALL_ROOT"

VM_OPTIONS="$IDEA_DIR/bin/idea64.vmoptions"
AGENT_JAR="$AGENT_DIR/ja-netfilter.jar"

if [ -f "$VM_OPTIONS" ]; then
    sed -i '/-javaagent:/d' "$VM_OPTIONS"
    sed -i '/--add-opens=java.base\/jdk.internal.org.objectweb.asm/d' "$VM_OPTIONS"
    {
        echo ""
        echo "-javaagent:$AGENT_JAR=jetbrains"
        echo "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED"
        echo "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED"
    } >> "$VM_OPTIONS"
fi

cat <<EOF > "$DESKTOP_DIR/intellij.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA Ultimate
Icon=$IDEA_DIR/bin/idea.png
Exec="$IDEA_DIR/bin/idea.sh" %f
Categories=Development;IDE;
StartupWMClass=jetbrains-idea
EOF

ln -sf "$IDEA_DIR/bin/idea.sh" "$BIN_DIR/idea"
update-desktop-database "$DESKTOP_DIR" || true

echo "Setup Complete."
copy_to_clipboard "$AGENT_DIR/Activation Code_Plugins.txt"
