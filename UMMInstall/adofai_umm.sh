#!/bin/bash

if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
fi

if ! command -v mono &>/dev/null; then
    echo "Installing Mono..."
    brew install mono
fi

if ! command -v expect &>/dev/null; then
    echo "Installing expect..."
    brew install expect
fi

if ! command -v wget &>/dev/null; then
    echo "Installing wget..."
    brew install wget
fi

echo "Downloading UnityModManager..."
wget -O "$HOME/Downloads/UnityModMangerInstaller.zip" "https://adof.ai/umm"
echo "Download complete."

echo "Extracting..."
rm -rf "$HOME/Downloads/UnityModManagerInstaller"
unzip -o -q "$HOME/Downloads/UnityModManager.zip" -d "$HOME/Downloads/UnityModManagerInstaller"

CONSOLE_EXE=$(find "$HOME/Downloads/UnityModManagerInstaller" -name "Console.exe" -maxdepth 3 | head -1)
CONSOLE_DIR=$(dirname "$CONSOLE_EXE")
echo "Found Console.exe at: $CONSOLE_EXE"

rm -f "$CONSOLE_DIR/UnityModManagerConfigLocal.xml"

expect << EOF
set env(TERM) dumb

puts "Launching installer..."
spawn mono $CONSOLE_EXE

expect -re "change sel"
send "y\r"
after 500

expect {
    -re "Enter a number" {
        send "1\r"
        expect -re "Key:"
    }
    -re "Key:" {}
}

expect {
    -re "Enter the full path" {
        send "$HOME/Library/Application Support/Steam/steamapps/common/A Dance of Fire and Ice/\r"
        expect -re "Key:"
    }
    -re "Key:" {}
}

send "R\r"
expect -re "I\. Install"
send "I\r"

expect -re "Do you want to change it"
send "\r"

expect -re "Key:"
send "\r"

expect eof
EOF

echo "\nSetting game to open with Rosetta..."
xattr -w com.apple.arch x86_64 "/Users/$USER/Library/Application Support/Steam/steamapps/common/A Dance of Fire and Ice/ADanceOfFireAndIce.app"
echo "Done! UMM installed and Rosetta enabled."