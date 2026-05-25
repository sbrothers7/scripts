# macOS scripts

## UnityModManager for ADOFAI

``` sh
curl -fsSL https://raw.githubusercontent.com/sbrothers7/scripts/main/UMMInstall/script.applescript | osascript
```

The script will:

- install the following dependencies if not present:
  - Homebrew
  - wget
  - expect
- download and install UnityModManager
- patch UMM
- set ADOFAI to open using Rosetta
- download mods and unzip them at the Mods directory (if any are selected)

> [!Warning]
> Running this script will remove the arm64 slice of the ADOFAI binary.

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
- 다음 의존성 패키지를 설치:
  - Homebrew
  - wget
  - expect
- UnityModManager 다운로드 및 설치
- UMM 패치
- 모드 다운로드 및 설치
- 얼불춤을 Rosetta 2로 실행하게 설정

> [!Warning]
> 이 스크립트는 얼불춤 바이너리의 arm64 슬라이스를 제거합니다.

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

