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

expect << 'EOF'
set game_path "/Users/$env(USER)/Library/Application Support/Steam/steamapps/common/A Dance of Fire and Ice/"
set download_url "https://files.nexus-cdn.com/2295/21/UnityModManager-21-0-32-4a-1757352298.zip?md5=JSiBkgX6ZbcapO8jFt-h5Q&expires=1777478461&user_id=217166278"
set zip_file "$env(HOME)/Downloads/UnityModManager.zip"
set extract_dir "$env(HOME)/Downloads/UnityModManagerInstaller"

puts "Downloading UnityModManager..."
exec curl -L -s -o $zip_file $download_url
puts "Download complete."

puts "Extracting..."
exec rm -rf $extract_dir
exec unzip -o $zip_file -d $extract_dir

set console_exe [string trim [exec find $extract_dir -name "Console.exe" -maxdepth 3]]
set console_dir [file dirname $console_exe]
puts "Found Console.exe at: $console_exe"

exec rm -f "$console_dir/UnityModManagerConfigLocal.xml"

set env(TERM) dumb

puts "Launching installer..."
spawn mono $console_exe

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
        send "$game_path\r"
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
puts "Done!"
EOF
