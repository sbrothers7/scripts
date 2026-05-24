#!/bin/bash
set -e

GAME_PATH="$HOME/Library/Application Support/Steam/steamapps/common/A Dance of Fire and Ice"
APP="$GAME_PATH/ADanceOfFireAndIce.app"
MACOS_DIR="$APP/Contents/MacOS"
EXE="$MACOS_DIR/ADanceOfFireAndIce"
REAL="$MACOS_DIR/ADanceOfFireAndIce.real"

if [ ! -d "$APP" ]; then
    echo "ADOFAI not found at $APP" >&2
    exit 1
fi

if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
fi
command -v mono &>/dev/null || brew install mono
command -v expect &>/dev/null || brew install expect
command -v wget &>/dev/null || brew install wget
command -v clang &>/dev/null || xcode-select --install

echo "Downloading UnityModManager..."
wget -q -O "$HOME/Downloads/UnityModManager.zip" "https://adof.ai/umm"
rm -rf "$HOME/Downloads/UnityModManagerInstaller"
unzip -o -q "$HOME/Downloads/UnityModManager.zip" -d "$HOME/Downloads/UnityModManagerInstaller"

CONSOLE_EXE=$(find "$HOME/Downloads/UnityModManagerInstaller" -name "Console.exe" -maxdepth 3 | head -1)
rm -f "$(dirname "$CONSOLE_EXE")/UnityModManagerConfigLocal.xml"

echo "Patching UnityEngine.CoreModule.dll via UMM Console.exe..."
expect <<EOF
set timeout 30
set env(TERM) dumb
spawn mono "$CONSOLE_EXE"
expect -re "change sel"
send "y\r"
after 500
expect {
    -re "Enter a number" {
        send "1\r"
        exp_continue
    }
    -re "Enter the full path" {
        send "$GAME_PATH/\r"
        exp_continue
    }
    -re "D\\. Delete" {
        expect -re "Key:"
        send "R\r"
        expect -re "I\\. Install"
        expect -re "Key:"
        send "I\r"
    }
    -re "I\\. Install" {
        expect -re "Key:"
        send "I\r"
    }
}
expect {
    -re "Do you want to change it" { send "\r"; exp_continue }
    -re "Key:" { send "\r" }
    timeout { send "\r" }
}
expect eof
EOF

if [ "$(uname -m)" = "arm64" ] && lipo -info "$REAL" 2>/dev/null | grep -q "arm64" || lipo -info "$EXE" 2>/dev/null | grep -q "arm64"; then
    TARGET="$EXE"
    [ -f "$REAL" ] && TARGET="$REAL"
    echo "Apple Silicon detected — stripping arm64 slice from $TARGET so Steam launches the x86_64 slice under Rosetta (required for Harmony's mprotect JIT patching, which fails under arm64 W^X)..."
    if lipo -info "$TARGET" 2>/dev/null | grep -q "arm64"; then
        lipo -remove arm64 "$TARGET" -output "$TARGET.tmp"
        mv "$TARGET.tmp" "$TARGET"
        chmod +x "$TARGET"
    fi
fi

echo "Installing x86_64-only launcher (passes -force-metal so Rosetta uses Metal, not the unstable OpenGL fallback)..."
if [ ! -f "$REAL" ]; then
    mv "$EXE" "$REAL"
fi
SRC="/tmp/umm_adofai_launcher_$$.c"
cat > "$SRC" <<'LAUNCHER_C'
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <mach-o/dyld.h>

int main(int argc, char **argv) {
    char self[4096];
    uint32_t sz = sizeof(self);
    if (_NSGetExecutablePath(self, &sz) != 0) return 1;
    char *slash = strrchr(self, '/');
    if (!slash) return 1;
    *slash = 0;
    char real[4096];
    snprintf(real, sizeof(real), "%s/ADanceOfFireAndIce.real", self);
    char *newargv[256];
    int i = 0;
    newargv[i++] = real;
    newargv[i++] = "-force-metal";
    for (int j = 1; j < argc && i < 255; j++) newargv[i++] = argv[j];
    newargv[i] = NULL;
    execv(real, newargv);
    perror("execv");
    return 1;
}
LAUNCHER_C
clang -arch x86_64 -O2 -o "$EXE" "$SRC"
rm -f "$SRC"
chmod 755 "$EXE"

echo "Re-signing .app bundle ad-hoc (strip stale signatures first so the new seal is honored)..."
codesign --remove-signature "$APP" 2>/dev/null || true
rm -rf "$APP/Contents/_CodeSignature"
find "$APP" -type f \( -name "*.dylib" -o -name "*.bundle" \) -print0 2>/dev/null | while IFS= read -r -d '' f; do
    codesign --remove-signature "$f" 2>/dev/null || true
done
codesign --remove-signature "$EXE" 2>/dev/null || true
codesign --remove-signature "$REAL" 2>/dev/null || true
codesign --force --sign - "$REAL"
codesign --force --deep --sign - "$APP"

echo "Done! Launch the game via Steam and press Ctrl+F10 for the UMM menu."
