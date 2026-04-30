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

# macOS 스크립트

## 얼불춤 모드 딸깍설치기

아래 명령어를 `터미널.app`을 열고 붙여넣어 실행해주세요
``` sh
curl -fsSL https://raw.githubusercontent.com/sbrothers7/scripts/main/UMMInstall/script.applescript | osascript
```

기능:

- UnityModManager 다운로드 및 설치
- 모드 다운로드 및 설치
- 얼불춤을 Rosetta 2로 실행하게 설정

> [!Note]
> 애플의 M시리즈 칩을 탑재한 기기라면 설치 이후 x86_64 실행 파일로만 게임을 열게 설정해야 할 수도 있습니다. 스팀에서 실행 옵션을 바꾸거나 `lipo`로 arm64 바이너리를 없애는 방법이 있습니다. [이 페이지](https://sbrothers7.github.io/docs/macOS/ADOFAI%20Modding/x86_64/)를 참조하세요.

## 기타

`git`으로 스크립트를 복제:

``` sh
git clone "https://github.com/sbrothers7/scripts/script_example.sh"
```

스크립트 실행:

``` sh
chmod u+x script_example.sh
sh script_example.sh
```

