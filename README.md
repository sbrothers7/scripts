# macOS scripts

## UnityModManager for ADOFAI

``` sh
curl -fsSL https://raw.githubusercontent.com/sbrothers7/scripts/main/UMMInstall/script.applescript | osascript
```

The script will:

- download and install UnityModManager
- set ADOFAI to open using Rosetta
- download mods and unzip them at the Mods directory (if any are selected)

> [!Note]
> You will still need to set Steam launch options or remove the arm64 binary to always launch the x86_64 binary if you're on Apple Silicon. Refer to [this page](https://sbrothers7.github.io/docs/macOS/ADOFAI%20Modding/x86_64/).

## Other

Clone script(s) with git:

``` sh
git clone "https://github.com/sbrothers7/scripts/script_example.sh"
```

Run once per script:

``` sh
chmod u+x script_example.sh
sh script_example.sh
```
