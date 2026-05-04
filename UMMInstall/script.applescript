-- ============================================================
-- Mod registry
-- ============================================================

set modRegistry to {¬
	{modID:"AdofaiTweaks", modURL:"https://github.com/PizzaLovers007/AdofaiTweaks/releases/latest/download/AdofaiTweaks-2.8.1.zip"}, ¬
	{modID:"TUFHelper", modURL:"https://github.com/coyami-ke/TUFHelper/releases/latest/download/TUFHelper.OSX.zip"}, ¬
	{modID:"JipperResourcePack", modURL:"https://github.com/Jongye0l/JipperResourcePack/releases/latest/download/JipperResourcePack.zip"}, ¬
	{modID:"PACL2", modURL:"https://jalib.jongyeol.kr/downloadMod/PACL2/2.4.205"}, ¬
	{modID:"TogetherBootstrap", modURL:"https://github.com/fangshenghan/TogetherBootstrap-Mod/releases/latest/download/TogetherBootstrap.v1.5.5.zip"}, ¬
	{modID:"YouTubeStream", modURL:"https://fixcdn.hyonsu.com/attachments/886661471533162526/1343622558813130855/YouTubeStream-1.0.3.zip"}, ¬
	{modID:"KeyboardChatterBlocker", modURL:"https://fixcdn.hyonsu.com/attachments/886661471533162526/1239183582975627304/KeyboardChatterBlocker_v0.0.9.zip"}, ¬
	{modID:"EnhancedEffectRemover", modURL:"https://fixcdn.hyonsu.com/attachments/886661471533162526/1279566899109433385/EnhancedEffectRemover_1.6.1.zip"}, ¬
	{modID:"XPerfect", modURL:"https://github.com/8100print/XPerfect/releases/latest/download/XPerfect.zip"} ¬
}

set modNames to {}
repeat with m in modRegistry
	set end of modNames to modID of m
end repeat

-- ============================================================
-- Build comma-separated mod name list¬
-- ============================================================
set modNamesCSV to ""
repeat with i from 1 to count of modNames
	set modNamesCSV to modNamesCSV & item i of modNames
	if i < (count of modNames) then set modNamesCSV to modNamesCSV & ","
end repeat

-- ============================================================
-- Download HTML template and JXA from GitHub, inject mod list
-- ============================================================
set htmlPath to "/tmp/gui.html"
set jxaPath to "/tmp/gui.jxa"
set resultPath to "/tmp/installer_result.txt"
set baseURL to "https://raw.githubusercontent.com/sbrothers7/scripts/main/UMMInstall/"
set curlUA to "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

try
	do shell script "curl -sfL -A " & quoted form of curlUA & " " & quoted form of (baseURL & "gui.html") & " -o " & quoted form of htmlPath
	do shell script "curl -sfL -A " & quoted form of curlUA & " " & quoted form of (baseURL & "gui.jxa") & " -o " & quoted form of jxaPath
on error errMsg
	display dialog "❌ Failed to download UI files." & return & return & errMsg buttons {"OK"} with icon stop with title "ADOFAI Mod Manager Installer"
	return
end try

-- Inject the mod list into the HTML template (replace %%MOD_LIST%% placeholder)
do shell script "MODS=" & quoted form of modNamesCSV & " /usr/bin/python3 -c \"" & ¬
	"import os, pathlib; " & ¬
	"mods = os.environ['MODS'].split(','); " & ¬
	"js = ','.join([repr(m) for m in mods]); " & ¬
	"p = pathlib.Path('/tmp/gui.html'); " & ¬
	"p.write_text(p.read_text().replace('%%MOD_LIST%%', js))\""

-- Remove any previous result
do shell script "rm -f " & quoted form of resultPath

-- ============================================================
-- Run the JXA UI
-- ============================================================
do shell script "osascript -l JavaScript " & quoted form of jxaPath

-- Read result
set userResult to do shell script "cat " & quoted form of resultPath & " 2>/dev/null || echo 'CANCEL'"

-- Clean up
do shell script "rm -f " & quoted form of htmlPath & " " & quoted form of jxaPath & " " & quoted form of resultPath

-- ============================================================
-- Handle selection
-- ============================================================
if userResult is "CANCEL" then return

if userResult is "SKIP" then
	set selectedMods to {}
else if userResult starts with "INSTALL:" then
	set AppleScript's text item delimiters to ":"
	set afterPrefix to text item 2 of userResult
	set AppleScript's text item delimiters to ","
	set selectedMods to text items of afterPrefix
	set AppleScript's text item delimiters to ""
else
	return
end if

-- ============================================================
-- Install UMM
-- ============================================================
set response to display dialog "This will install Unity Mod Manager for A Dance of Fire and Ice." & return & return & "Make sure the game is installed via Steam before continuing." buttons {"Cancel", "Install"} default button "Install" with icon note with title "ADOFAI Mod Manager Installer"

if button returned of response is "Cancel" then return

set scriptPath to (POSIX path of (path to home folder)) & ".adofai_umm.sh"

display dialog "Downloading installer..." buttons {} giving up after 1 with title "ADOFAI Mod Manager Installer"

try
	do shell script "curl -sfL -A " & quoted form of curlUA & " " & quoted form of (baseURL & "adofai_umm.sh") & " -o " & quoted form of scriptPath
on error errMsg
	display dialog "❌ Failed to download installer script." & return & return & errMsg buttons {"OK"} with icon stop with title "ADOFAI Mod Manager Installer"
	return
end try

display dialog "Installing Unity Mod Manager... This may take a few minutes." buttons {} giving up after 1 with title "ADOFAI Mod Manager Installer"

try
	do shell script "zsh " & quoted form of scriptPath with administrator privileges
on error errMsg
	display dialog "❌ UMM installation failed." & return & return & errMsg buttons {"OK"} with icon stop with title "ADOFAI Mod Manager Installer"
	return
end try

try
	do shell script "rm -f " & quoted form of scriptPath
end try

-- ============================================================
-- Download mods
-- ============================================================
set modsPath to (POSIX path of (path to home folder)) & "Library/Application Support/Steam/steamapps/common/A Dance of Fire and Ice/Mods"
do shell script "mkdir -p " & quoted form of modsPath

if (count of selectedMods) > 0 then
	set installedMods to {}
	set failedMods to {}
	set totalMods to count of selectedMods
	
	repeat with i from 1 to totalMods
		set modName to item i of selectedMods
		set modURL to ""
		
		repeat with m in modRegistry
			if modID of m is modName then
				set modURL to modURL of m
				exit repeat
			end if
		end repeat
		
		if modURL is not "" then
			-- Resolve GitHub API URLs (for mods with version-dependent asset names)
			if modURL starts with "GITHUB_API:" then
				set repoSlug to text 12 thru -1 of modURL
				try
					set modURL to do shell script "curl -sfL -A " & quoted form of curlUA & " 'https://api.github.com/repos/" & repoSlug & "/releases/latest' | /usr/bin/python3 -c \"import sys,json; assets=json.load(sys.stdin).get('assets',[]); zips=[a['browser_download_url'] for a in assets if a['name'].endswith('.zip')]; print(zips[0]) if zips else sys.exit(1)\""
				on error
					set modURL to ""
				end try
			end if
			
			if modURL is "" then
				set end of failedMods to modName
			else
				display dialog "Downloading " & modName & " (" & i & "/" & totalMods & ")..." buttons {} giving up after 1 with title "ADOFAI Mod Manager Installer"
				
				set tmpZip to "/tmp/adofai_mod_" & modName & ".zip"
				set tmpExtract to "/tmp/adofai_extract_" & modName
				try
					-- Use wget for Discord CDN links (fixcdn.hyonsu.com), curl for others
					if modURL contains "fixcdn.hyonsu.com" then
						do shell script "wget --user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' -O " & quoted form of tmpZip & " " & quoted form of modURL
					else
						do shell script "curl -sfL " & quoted form of modURL & " -o " & quoted form of tmpZip
					end if
					do shell script "rm -rf " & quoted form of tmpExtract & " && mkdir -p " & quoted form of tmpExtract
					do shell script "unzip -q -o " & quoted form of tmpZip & " -d " & quoted form of tmpExtract
					do shell script "cd " & quoted form of tmpExtract & " && " & ¬
						"items=$(ls -1) && count=$(echo \"$items\" | wc -l | tr -d ' ') && " & ¬
						"first=$(echo \"$items\" | head -1) && " & ¬
						"if [ \"$count\" -eq 1 ] && [ -d \"$first\" ]; then " & ¬
						"  rm -rf " & quoted form of modsPath & "/\"$first\" && " & ¬
						"  mv \"$first\" " & quoted form of modsPath & "/; " & ¬
						"else " & ¬
						"  rm -rf " & quoted form of modsPath & "/" & quoted form of modName & " && " & ¬
						"  mkdir -p " & quoted form of modsPath & "/" & quoted form of modName & " && " & ¬
						"  mv * " & quoted form of modsPath & "/" & quoted form of modName & "/; " & ¬
						"fi"
						
					do shell script "rm -rf " & quoted form of tmpExtract & " " & quoted form of tmpZip
					set end of installedMods to modName
				on error errMsg
					do shell script "rm -rf " & quoted form of tmpExtract & " " & quoted form of tmpZip
					set end of failedMods to modName
				end try
			end if
		end if
	end repeat
	
	set summaryText to ""
	if (count of installedMods) > 0 then
		set summaryText to "Installed mods:" & return
		repeat with m in installedMods
			set summaryText to summaryText & "  - " & (contents of m) & return
		end repeat
	end if
	if (count of failedMods) > 0 then
		set summaryText to summaryText & return & "Failed mods:" & return
		repeat with m in failedMods
			set summaryText to summaryText & "  - " & (contents of m) & return
		end repeat
	end if
	
	display notification "Installation complete!" with title "ADOFAI Mod Manager"
	display dialog "Installation complete!" & return & return & "Unity Mod Manager has been installed." & return & return & summaryText buttons {"OK"} default button "OK" with icon note with title "ADOFAI Mod Manager Installer"
else
	display notification "Installation complete!" with title "ADOFAI Mod Manager"
	display dialog "✅ Unity Mod Manager has been installed." & return & return & "No mods were selected." buttons {"OK"} default button "OK" with icon note with title "ADOFAI Mod Manager Installer"
end if